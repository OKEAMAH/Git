(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(**

   A Merkelized inbox represents a list of messages. This list
   is decomposed into sublists of messages, one for each non-empty Tezos
   level greater than the level of the Last Cemented Commitment (LCC).

   This module is designed to:

   1. provide a space-efficient representation for proofs of inbox
   inclusions (only for inboxes obtained at the end of block
   validation) ;

   2. offer an efficient function to add a new batch of messages in the
   inbox at the current level.

   To solve (1), we use a proof tree H which is implemented by a sparse
   merkelized skip list allowing for compact inclusion proofs (See
   {!skip_list_repr.ml}).

   To solve (2), we maintain a separate proof tree C witnessing the
   contents of messages of the current level.

   The protocol maintains the hashes of the head of H, and the root hash of C.

   The rollup node needs to maintain a full representation for C and a
   partial representation for H back to the level of the LCC.

*)
type error += Invalid_level_add_messages of Raw_level_repr.t

type error += Inbox_proof_error of string

type error += Tried_to_add_zero_messages

type error += Empty_upper_level of Raw_level_repr.t

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox.invalid_level_add_messages"
    ~title:"Internal error: Trying to add a message to an inbox from the past"
    ~description:
      "An inbox can only accept messages for its current level or for the next \
       levels."
    (obj1 (req "level" Raw_level_repr.encoding))
    (function Invalid_level_add_messages level -> Some level | _ -> None)
    (fun level -> Invalid_level_add_messages level) ;

  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox.inbox_proof_error"
    ~title:
      "Internal error: error occurred during proof production or validation"
    ~description:"An inbox proof error."
    ~pp:(fun ppf e -> Format.fprintf ppf "Inbox proof error: %s" e)
    (obj1 (req "error" string))
    (function Inbox_proof_error e -> Some e | _ -> None)
    (fun e -> Inbox_proof_error e) ;

  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox.add_zero_messages"
    ~title:"Internal error: trying to add zero messages"
    ~description:
      "Message adding functions must be called with a positive number of \
       messages"
    ~pp:(fun ppf _ -> Format.fprintf ppf "Tried to add zero messages")
    empty
    (function Tried_to_add_zero_messages -> Some () | _ -> None)
    (fun () -> Tried_to_add_zero_messages) ;

  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox.empty_upper_level"
    ~title:"Internal error: No payload found in a [Level_crossing] proof"
    ~description:
      "Failed to find any message in the [upper_level] of a [Level_crossing] \
       proof"
    (obj1 (req "upper_level" Raw_level_repr.encoding))
    (function Empty_upper_level upper_level -> Some upper_level | _ -> None)
    (fun upper_level -> Empty_upper_level upper_level)

module Int64_map = Map.Make (Int64)

(* 32 *)
let hash_prefix = "\003\250\174\238\208" (* scib1(55) *)

module Hash = struct
  let prefix = "scib1"

  let encoded_size = 55

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "inbox_hash"

        let title = "The hash of an inbox of a smart contract rollup"

        let b58check_prefix = hash_prefix

        (* defaults to 32 *)
        let size = None
      end)

  include H

  let () = Base58.check_encoded_prefix b58check_encoding prefix encoded_size

  let of_context_hash context_hash =
    Context_hash.to_bytes context_hash |> of_bytes_exn

  let to_context_hash hash = to_bytes hash |> Context_hash.of_bytes_exn

  include Path_encoding.Make_hex (H)
end

module Skip_list_parameters = struct
  let basis = 2
end

module Skip_list = Skip_list_repr.Make (Skip_list_parameters)

module Merkelized_messages = struct
  (* 32 *)
  let hash_prefix = "\003\250\174\238\238" (* scib2(55) *)

  module Hash = struct
    let prefix = "scib2"

    let encoded_size = 55

    module H =
      Blake2B.Make
        (Base58)
        (struct
          let name = "inbox_hash"

          let title = "The hash of an inbox of a smart contract rollup"

          let b58check_prefix = hash_prefix

          (* defaults to 32 *)
          let size = None
        end)

    include H

    let () = Base58.check_encoded_prefix b58check_encoding prefix encoded_size

    include Path_encoding.Make_hex (H)
  end

  type message_proof =
    (Sc_rollup_inbox_message_repr.serialized, Hash.t) Skip_list.cell

  let pp_message_proof =
    Skip_list.pp
      ~pp_content:Sc_rollup_inbox_message_repr.pp_serialize
      ~pp_ptr:Hash.pp

  type messages_proof = {
    current_message : message_proof;
    level : Raw_level_repr.t;
  }

  type t = messages_proof

  let equal_message_proof =
    Skip_list.equal Hash.equal Sc_rollup_inbox_message_repr.equal_serialize

  let message_proof_encoding : message_proof Data_encoding.t =
    Skip_list.encoding
      Hash.encoding
      Sc_rollup_inbox_message_repr.serialized_encoding

  let equal messages1 messages2 =
    Raw_level_repr.equal messages1.level messages2.level
    && equal_message_proof messages1.current_message messages2.current_message

  let hash {current_message; level} =
    let level_bytes =
      Raw_level_repr.to_int32 level |> Int32.to_string |> Bytes.of_string
    in
    let payload = Skip_list.content current_message in
    let back_pointers_hashes = Skip_list.back_pointers current_message in
    Bytes.of_string
      (payload : Sc_rollup_inbox_message_repr.serialized :> string)
    :: level_bytes
    :: List.map Hash.to_bytes back_pointers_hashes
    |> Hash.hash_bytes

  let pp fmt {current_message; level} =
    Format.fprintf
      fmt
      "level: %a@,@[<v 2>current message:@,%a@]"
      Raw_level_repr.pp
      level
      (Skip_list.pp
         ~pp_content:Sc_rollup_inbox_message_repr.pp_serialize
         ~pp_ptr:Hash.pp)
      current_message

  let encoding =
    Data_encoding.conv
      (fun {current_message; level} -> (current_message, level))
      (fun (current_message, level) -> {current_message; level})
      (Data_encoding.tup2 message_proof_encoding Raw_level_repr.encoding)

  module History = struct
    include
      Bounded_history_repr.Make
        (struct
          let name = "level_inbox_history"
        end)
        (Hash)
        (struct
          type nonrec t = messages_proof

          let pp = pp

          let equal = equal

          let encoding = encoding
        end)

    let no_history = empty ~capacity:0L
  end

  let genesis payload level =
    {current_message = Skip_list.genesis payload; level}

  let add_to_history history messages_proof =
    let prev_cell_ptr = hash messages_proof in
    History.remember prev_cell_ptr messages_proof history

  let add_message history messages_proof payload =
    let open Tzresult_syntax in
    let prev_message = messages_proof.current_message in
    let prev_message_ptr = hash messages_proof in
    let current_message =
      Skip_list.next
        ~prev_cell:prev_message
        ~prev_cell_ptr:prev_message_ptr
        payload
    in
    let new_messages_proof = {current_message; level = messages_proof.level} in
    let* history = add_to_history history new_messages_proof in
    return (history, new_messages_proof)

  let get_number_of_messages {current_message; _} =
    Skip_list.index current_message

  let get_message_payload = Skip_list.content

  let get_current_message_payload {current_message; _} =
    get_message_payload current_message

  let get_level {level; _} = level

  let find_message messages_history ~message_index messages =
    let open Option_syntax in
    let deref ptr =
      let+ {current_message; _} = History.find ptr messages_history in
      current_message
    in
    let cell_ptr = hash messages in
    Skip_list.find ~deref ~cell_ptr ~target_index:message_index

  let to_bytes = Data_encoding.Binary.to_bytes_exn encoding

  let of_bytes = Data_encoding.Binary.of_bytes_opt encoding

  type proof = {message : message_proof; inclusion_proof : message_proof list}

  let pp_proof fmt {message; inclusion_proof} =
    Format.fprintf
      fmt
      "message: %a; inclusion proof: %a"
      pp_message_proof
      message
      (Format.pp_print_list pp_message_proof)
      inclusion_proof

  let proof_encoding =
    let open Data_encoding in
    conv
      (fun {message; inclusion_proof} -> (message, inclusion_proof))
      (fun (message, inclusion_proof) -> {message; inclusion_proof})
      (obj2
         (req "message" message_proof_encoding)
         (req "inclusion_proof" (list message_proof_encoding)))

  let produce_proof history ~message_index messages : proof option =
    let open Option_syntax in
    let deref ptr =
      let+ {current_message; level = _} = History.find ptr history in
      current_message
    in
    let current_ptr = hash messages in
    let lift_ptr =
      let rec aux acc = function
        | [] -> None
        | [last_ptr] ->
            let+ message = History.find last_ptr history in
            {
              message = message.current_message;
              inclusion_proof = List.rev (message.current_message :: acc);
            }
        | x :: xs ->
            let* cell = deref x in
            aux (cell :: acc) xs
      in
      aux []
    in
    let* ptr_path =
      Skip_list.back_path
        ~deref
        ~cell_ptr:current_ptr
        ~target_index:message_index
    in
    lift_ptr ptr_path

  let verify_proof {message; inclusion_proof} messages =
    let open Tzresult_syntax in
    let level = messages.level in
    let hash_map, ptr_list =
      List.fold_left
        (fun (hash_map, ptr_list) message_proof ->
          let message_ptr = hash {current_message = message_proof; level} in
          ( Hash.Map.add message_ptr message_proof hash_map,
            message_ptr :: ptr_list ))
        (Hash.Map.empty, [])
        inclusion_proof
    in
    let ptr_list = List.rev ptr_list in
    let equal_ptr = Hash.equal in
    let deref ptr = Hash.Map.find ptr hash_map in
    let cell_ptr = hash messages in
    let target_ptr = hash {current_message = message; level} in
    let* () =
      error_unless
        (Skip_list.valid_back_path
           ~equal_ptr
           ~deref
           ~cell_ptr
           ~target_ptr
           ptr_list)
        (Inbox_proof_error "invalid back path")
    in
    return (Skip_list.content message, level, Skip_list.index message)
end

let hash_history_proof cell =
  let current_level_messages_hash = Skip_list.content cell in
  let back_pointers_hashes = Skip_list.back_pointers cell in
  Merkelized_messages.Hash.to_bytes current_level_messages_hash
  :: List.map Hash.to_bytes back_pointers_hashes
  |> Hash.hash_bytes

module V1 = struct
  type history_proof = (Merkelized_messages.Hash.t, Hash.t) Skip_list.cell

  let equal_history_proof =
    Skip_list.equal Hash.equal Merkelized_messages.Hash.equal

  let history_proof_encoding : history_proof Data_encoding.t =
    Skip_list.encoding Hash.encoding Merkelized_messages.Hash.encoding

  let pp_history_proof fmt history_proof =
    (Skip_list.pp ~pp_content:Merkelized_messages.Hash.pp ~pp_ptr:Hash.pp)
      fmt
      history_proof

  (** Construct an inbox [history] with a given [capacity]. If you
       are running a rollup node, [capacity] needs to be large enough to
       remember any levels for which you may need to produce proofs. *)
  module History =
    Bounded_history_repr.Make
      (struct
        let name = "inbox_history"
      end)
      (Hash)
      (struct
        type t = history_proof

        let pp = pp_history_proof

        let equal = equal_history_proof

        let encoding = history_proof_encoding
      end)

  (*

   At a given level, an inbox is composed of metadata of type [t] and
   [current_level], a [tree] representing the messages of the current level
   (held by the [Raw_context.t] in the protocol).

   The metadata contains :
   - [rollup] : the address of the rollup ;
   - [level] : the inbox level ;
     the number of messages that have not been consumed by a commitment cementing ;
   - [nb_messages_in_commitment_period] :
     the number of messages during the commitment period ;
   - [starting_level_of_current_commitment_period] :
     the level marking the beginning of the current commitment period ;
   - [current_level_hash] : the root hash of [current_level] ;
   - [old_levels_messages] : a witness of the inbox history.

   When new messages are appended to the current level inbox, the
   metadata stored in the context may be related to an older level.
   In that situation, an archival process is applied to the metadata.
   This process saves the [current_level_hash] in the
   [old_levels_messages] and empties [current_level]. It then
   initialises a new level tree for the new messages---note that any
   intermediate levels are simply skipped. See
   {!Make_hashing_scheme.archive_if_needed} for details.

  *)
  type t = {
    rollup : Sc_rollup_repr.t;
    level : Raw_level_repr.t;
    nb_messages_in_commitment_period : int64;
    starting_level_of_current_commitment_period : Raw_level_repr.t;
    (* Lazy to avoid hashing O(n^2) time in [add_messages] *)
    current_level_hash : unit -> Merkelized_messages.Hash.t;
    old_levels_messages : history_proof;
  }

  let equal inbox1 inbox2 =
    (* To be robust to addition of fields in [t]. *)
    let {
      rollup;
      level;
      nb_messages_in_commitment_period;
      starting_level_of_current_commitment_period;
      current_level_hash;
      old_levels_messages;
    } =
      inbox1
    in
    Sc_rollup_repr.Address.equal rollup inbox2.rollup
    && Raw_level_repr.equal level inbox2.level
    && Compare.Int64.(
         equal
           nb_messages_in_commitment_period
           inbox2.nb_messages_in_commitment_period)
    && Raw_level_repr.(
         equal
           starting_level_of_current_commitment_period
           inbox2.starting_level_of_current_commitment_period)
    && Merkelized_messages.Hash.equal
         (current_level_hash ())
         (inbox2.current_level_hash ())
    && equal_history_proof old_levels_messages inbox2.old_levels_messages

  let pp fmt
      {
        rollup;
        level;
        nb_messages_in_commitment_period;
        starting_level_of_current_commitment_period;
        current_level_hash;
        old_levels_messages;
      } =
    Format.fprintf
      fmt
      "rollup: %a@,\
       level: %a@,\
       current messages hash: %a@,\
       nb messages in commitment period: %s@,\
       starting level of current commitment period: %a@,\
       @[<v 2>old levels messages:@,\
       %a@]"
      Sc_rollup_repr.Address.pp
      rollup
      Raw_level_repr.pp
      level
      Merkelized_messages.Hash.pp
      (current_level_hash ())
      (Int64.to_string nb_messages_in_commitment_period)
      Raw_level_repr.pp
      starting_level_of_current_commitment_period
      pp_history_proof
      old_levels_messages

  let inbox_level inbox = inbox.level

  let old_levels_messages inbox = inbox.old_levels_messages

  let current_level_hash inbox = inbox.current_level_hash ()

  let encoding =
    Data_encoding.(
      conv
        (fun {
               rollup;
               nb_messages_in_commitment_period;
               starting_level_of_current_commitment_period;
               level;
               current_level_hash;
               old_levels_messages;
             } ->
          ( rollup,
            nb_messages_in_commitment_period,
            starting_level_of_current_commitment_period,
            level,
            current_level_hash (),
            old_levels_messages ))
        (fun ( rollup,
               nb_messages_in_commitment_period,
               starting_level_of_current_commitment_period,
               level,
               current_level_hash,
               old_levels_messages ) ->
          {
            rollup;
            nb_messages_in_commitment_period;
            starting_level_of_current_commitment_period;
            level;
            current_level_hash = (fun () -> current_level_hash);
            old_levels_messages;
          })
        (obj6
           (req "rollup" Sc_rollup_repr.encoding)
           (req "nb_messages_in_commitment_period" int64)
           (req
              "starting_level_of_current_commitment_period"
              Raw_level_repr.encoding)
           (req "level" Raw_level_repr.encoding)
           (req "current_level_hash" Merkelized_messages.Hash.encoding)
           (req "old_levels_messages" history_proof_encoding)))

  let number_of_messages_during_commitment_period inbox =
    inbox.nb_messages_in_commitment_period

  let start_new_commitment_period inbox level =
    {
      inbox with
      starting_level_of_current_commitment_period = level;
      nb_messages_in_commitment_period = 0L;
    }

  let starting_level_of_current_commitment_period inbox =
    inbox.starting_level_of_current_commitment_period

  let refresh_commitment_period ~commitment_period ~level inbox =
    let start = starting_level_of_current_commitment_period inbox in
    let freshness = Raw_level_repr.diff level start in
    let open Int32 in
    let open Compare.Int32 in
    if freshness >= commitment_period then (
      let nb_periods =
        to_int ((mul (div freshness commitment_period)) commitment_period)
      in
      let new_starting_level = Raw_level_repr.(add start nb_periods) in
      assert (Raw_level_repr.(new_starting_level <= level)) ;
      assert (
        rem (Raw_level_repr.diff new_starting_level start) commitment_period
        = 0l) ;
      start_new_commitment_period inbox new_starting_level)
    else inbox
end

type versioned = V1 of V1.t

let versioned_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"V1"
        (Tag 0)
        V1.encoding
        (function V1 inbox -> Some inbox)
        (fun inbox -> V1 inbox);
    ]

include V1

let of_versioned = function V1 inbox -> inbox [@@inline]

let to_versioned inbox = V1 inbox [@@inline]

type serialized_proof = bytes

let serialized_proof_encoding = Data_encoding.bytes

module type Merkelized_operations = sig
  val add_messages :
    History.t ->
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    Merkelized_messages.History.t ->
    Merkelized_messages.t option ->
    (Merkelized_messages.History.t * Merkelized_messages.t * History.t * t)
    tzresult

  val add_messages_no_history :
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    Merkelized_messages.t option ->
    (Merkelized_messages.t * t) tzresult

  val find_level_messages :
    History.t ->
    (Merkelized_messages.Hash.t -> Merkelized_messages.History.t option Lwt.t) ->
    Raw_level_repr.t ->
    history_proof ->
    (Merkelized_messages.History.t * Merkelized_messages.t) option Lwt.t

  val find_message :
    History.t ->
    (Merkelized_messages.Hash.t -> Merkelized_messages.History.t option Lwt.t) ->
    Raw_level_repr.t * int ->
    history_proof ->
    Merkelized_messages.message_proof option Lwt.t

  val form_history_proof :
    History.t -> t -> (History.t * history_proof) tzresult

  val take_snapshot : current_level:Raw_level_repr.t -> t -> history_proof

  type inclusion_proof

  val inclusion_proof_encoding : inclusion_proof Data_encoding.t

  val pp_inclusion_proof : Format.formatter -> inclusion_proof -> unit

  val number_of_proof_steps : inclusion_proof -> int

  val search_history_proof :
    History.t ->
    (Merkelized_messages.Hash.t -> Merkelized_messages.History.t option Lwt.t) ->
    Raw_level_repr.t ->
    into_history_proof:history_proof ->
    (inclusion_proof * history_proof) tzresult Lwt.t

  val produce_inclusion_proof :
    History.t ->
    target_history_proof_index:int ->
    into_history_proof:history_proof ->
    inclusion_proof option

  val verify_inclusion_proof :
    inclusion_proof ->
    target_history_proof:history_proof ->
    into_history_proof:history_proof ->
    bool

  type proof

  val pp_proof : Format.formatter -> proof -> unit

  val to_serialized_proof : proof -> serialized_proof

  val of_serialized_proof : serialized_proof -> proof option

  val verify_proof :
    Raw_level_repr.t * Z.t ->
    history_proof ->
    proof ->
    Sc_rollup_PVM_sig.inbox_message option tzresult Lwt.t

  val produce_proof :
    History.t ->
    (Merkelized_messages.Hash.t -> Merkelized_messages.History.t option Lwt.t) ->
    history_proof ->
    Raw_level_repr.t * int ->
    (proof * Sc_rollup_PVM_sig.inbox_message option) tzresult Lwt.t

  val empty : Sc_rollup_repr.t -> Raw_level_repr.t -> t
end

let add_message inbox level_history level_messages payload =
  let open Tzresult_syntax in
  let+ level_history, level_messages =
    Merkelized_messages.add_message level_history level_messages payload
  in
  let nb_messages_in_commitment_period =
    Int64.succ inbox.nb_messages_in_commitment_period
  in
  let inbox = {inbox with nb_messages_in_commitment_period} in
  (level_history, level_messages, inbox)

let is_level_messages_initialized inbox level_history level_messages level
    payloads =
  let open Tzresult_syntax in
  match level_messages with
  | Some level_messages ->
      return (inbox, level_history, level_messages, payloads)
  | None ->
      let* first_payload, payloads =
        match payloads with
        | hd :: tl -> ok (hd, tl)
        | [] -> error Tried_to_add_zero_messages
      in
      let level_messages = Merkelized_messages.genesis first_payload level in
      let* level_history =
        Merkelized_messages.add_to_history level_history level_messages
      in
      let nb_messages_in_commitment_period =
        Int64.succ inbox.nb_messages_in_commitment_period
      in
      let inbox = {inbox with nb_messages_in_commitment_period} in
      return (inbox, level_history, level_messages, payloads)

(** [no_history] creates an empty history with [capacity] set to
zero---this makes the [remember] function a no-op. We want this
behaviour in the protocol because we don't want to store
previous levels of the inbox. *)
let no_history = History.empty ~capacity:0L

let form_history_proof history inbox =
  let open Tzresult_syntax in
  let prev_cell = inbox.old_levels_messages in
  let prev_cell_ptr = hash_history_proof prev_cell in
  let* history = History.remember prev_cell_ptr prev_cell history in
  let next_cell =
    Skip_list.next ~prev_cell ~prev_cell_ptr (current_level_hash inbox)
  in
  return (history, next_cell)

(** [archive_if_needed ctxt history inbox new_level level_tree]
    is responsible for ensuring that the {!add_messages} function
    below has a correctly set-up [level_tree] to which to add the
    messages. If [new_level] is a higher level than the current inbox,
    we create a new inbox level tree at that level in which to start
    adding messages, and archive the earlier levels depending on the
    [history] parameter's [capacity]. If [level_tree] is [None] (this
    happens when the inbox is first created) we similarly create a new
    empty level tree with the right [level] key.

    This function and {!form_history_proof} are the only places we
    begin new level trees. *)
let archive_if_needed history inbox new_level =
  let open Tzresult_syntax in
  if Raw_level_repr.(inbox.level = new_level) then return (history, inbox)
  else
    let* history, old_levels_messages = form_history_proof history inbox in
    let inbox =
      {
        starting_level_of_current_commitment_period =
          inbox.starting_level_of_current_commitment_period;
        current_level_hash = (fun () -> Merkelized_messages.Hash.zero);
        rollup = inbox.rollup;
        nb_messages_in_commitment_period =
          inbox.nb_messages_in_commitment_period;
        old_levels_messages;
        level = new_level;
      }
    in
    return (history, inbox)

let add_messages history inbox level payloads level_history level_messages =
  let open Tzresult_syntax in
  let* () =
    error_when
      (match payloads with [] -> true | _ -> false)
      Tried_to_add_zero_messages
  in
  let* () =
    error_when
      Raw_level_repr.(level < inbox.level)
      (Invalid_level_add_messages level)
  in
  let* history, inbox = archive_if_needed history inbox level in
  let* inbox, level_history, level_messages, payloads =
    is_level_messages_initialized
      inbox
      level_history
      level_messages
      level
      payloads
  in
  let* level_history, level_messages, inbox =
    List.fold_left_e
      (fun (level_history, level_messages, inbox) payload ->
        add_message inbox level_history level_messages payload)
      (level_history, level_messages, inbox)
      payloads
  in
  let current_level_hash () = Merkelized_messages.hash level_messages in
  return
    (level_history, level_messages, history, {inbox with current_level_hash})

let add_messages_no_history inbox level payloads level_messages =
  let open Tzresult_syntax in
  let+ _level_history, level_messages, _history, inbox =
    add_messages
      no_history
      inbox
      level
      payloads
      Merkelized_messages.History.no_history
      level_messages
  in
  (level_messages, inbox)

let take_snapshot ~current_level inbox =
  let prev_cell = inbox.old_levels_messages in
  if Raw_level_repr.(inbox.level < current_level) then
    (* If the level of the inbox is lower than the current level, there
       is no new messages in the inbox for the current level. It is then safe
       to take a snapshot of the actual inbox. *)
    let prev_cell_ptr = hash_history_proof prev_cell in
    Skip_list.next ~prev_cell ~prev_cell_ptr (current_level_hash inbox)
  else
    (* If there is a level tree for the [current_level] in the inbox, we need
       to ignore this new level as it is not finished yet (regarding the
       block's completion). We take the inbox's current predecessor instead.
    *)
    prev_cell

type inclusion_proof = history_proof list

let inclusion_proof_encoding =
  let open Data_encoding in
  list history_proof_encoding

let pp_inclusion_proof fmt proof =
  Format.pp_print_list pp_history_proof fmt proof

let number_of_proof_steps proof = List.length proof

let map_concat_option f_bind_opt =
  let rec aux accu = function
    | [] -> Some (List.rev accu)
    | x :: xs ->
        let open Option_syntax in
        let* x = f_bind_opt x in
        aux (x :: accu) xs
  in
  aux []

let search_history_proof history find_level_history level_to_find
    ~into_history_proof =
  let open Lwt_tzresult_syntax in
  let deref ptr = History.find ptr history in
  let compare cell =
    let cell_ptr = hash_history_proof cell in
    let*! level_messages_level =
      let open Lwt_option_syntax in
      let*? cell = History.find cell_ptr history in
      let* level_history = find_level_history (Skip_list.content cell) in
      let*? level_messages =
        Merkelized_messages.History.find (Skip_list.content cell) level_history
      in
      return (Merkelized_messages.get_level level_messages)
    in
    Lwt.return
    @@
    match level_messages_level with
    | None -> -1
    | Some level_messages_level ->
        Raw_level_repr.compare level_messages_level level_to_find
  in
  let*! research_result =
    Skip_list.search ~deref ~compare ~cell:into_history_proof
  in
  match research_result with
  | Skip_list.{rev_path; last_cell = Found level_messages_cell} ->
      return (List.rev rev_path, level_messages_cell)
  | {last_cell = Nearest _; _}
  | {last_cell = No_exact_or_lower_ptr; _}
  | {last_cell = Deref_returned_none; _} ->
      (* We are only interested to the result where [search] than a
         path to the cell we were looking for. All the other cases
         should be considered as an error. *)
      fail
        (Inbox_proof_error
           (Format.asprintf
              "Skip_list.search failed to find a valid path: %a"
              (Skip_list.pp_search_result ~pp_cell:pp_history_proof)
              research_result))

let produce_inclusion_proof history ~target_history_proof_index
    ~into_history_proof =
  let open Option_syntax in
  let current_history_proof_hash = hash_history_proof into_history_proof in
  let deref ptr = History.find ptr history in
  let* ptr_path =
    Skip_list.back_path
      ~deref
      ~target_index:target_history_proof_index
      ~cell_ptr:current_history_proof_hash
  in
  map_concat_option deref ptr_path

let verify_inclusion_proof inclusion_proof ~target_history_proof
    ~into_history_proof =
  let hash_map, ptr_list =
    List.fold_left
      (fun (hash_map, ptr_list) history_proof ->
        let history_proof_ptr = hash_history_proof history_proof in
        ( Hash.Map.add history_proof_ptr history_proof hash_map,
          history_proof_ptr :: ptr_list ))
      (Hash.Map.empty, [])
      inclusion_proof
  in
  let ptr_list = List.rev ptr_list in
  let equal_ptr = Hash.equal in
  let deref ptr = Hash.Map.find ptr hash_map in
  let cell_ptr = hash_history_proof target_history_proof in
  let target_ptr = hash_history_proof into_history_proof in
  Skip_list.valid_back_path ~equal_ptr ~deref ~cell_ptr ~target_ptr ptr_list

type message_proof = Merkelized_messages.proof

type proof =
  (* See the main docstring for this type (in the mli file) for
     definitions of the three proof parameters [starting_point],
     [message] and [snapshot]. In the below we deconstruct
     [starting_point] into [(l, n)] where [l] is a level and [n] is a
     message index.

     In a [Single_level] proof, [level] is the skip list cell for the
     level [l], [inc] is an inclusion proof of [level] into
     [snapshot] and [message_proof] is a tree proof showing that

       [exists level_tree .
            (hash_level_tree level_tree = level.content)
        AND (payload_and_level n level_tree = (_, (message, l)))]

     Note: in the case that [message] is [None] this shows that
     there's no value at the index [n]; in this case we also must
     check that [level] equals [snapshot] (otherwise, we'd need a
     [Level_crossing] proof instead. *)
  | Single_level of {
      level_messages : Merkelized_messages.t;
      level : history_proof;
      inc : inclusion_proof;
      message_proof : message_proof option;
    }
  (* See the main docstring for this type (in the mli file) for
                                                                                                                                                                             definitions of the three proof parameters [starting_point],
                                                                                                                                                                             [message] and [snapshot]. In the below we deconstruct
                                                                                                                                                                             [starting_point] as [(l, n)] where [l] is a level and [n] is a
                                                                                                                                                                             message index.

                                                                                                                                                                             In a [Level_crossing] proof, [lower] is the skip list cell for
                                                                                                                                                                             the level [l] and [upper] must be the skip list cell that comes
                                                                                                                                                                             immediately after it in [snapshot]. If the inbox has been
                                                                                                                                                                             constructed correctly using the functions in this module that
                                                                                                                                                                             will be the next non-empty level in the inbox.

                                                                                                                                                                             [inc] is an inclusion proof of [upper] into [snapshot].
                                                                                                                                                                             [upper_level] is the level of [upper].

                                                                                                                                                                             The tree proof [lower_message_proof] shows the following:

                                                                                                                                                                               [exists level_tree .
                                                                                                                                                                                     (hash_level_tree level_tree = lower.content)
                                                                                                                                                                                 AND (payload_and_level n level_tree = (_, (None, l)))]

                                                                                                                                                                             in other words, there is no message at index [n] in
                                                                                                                                                                             level [l]. This means that level has been fully read.

                                                                                                                                                                             The tree proof [upper_message_proof] shows the following:

                                                                                                                                                                               [exists level_tree .
                                                                                                                                                                                     (hash_level_tree level_tree = upper.content)
                                                                                                                                                                                 AND (payload_and_level 0 level_tree = (_, (message, upper_level)))]

                                                                                                                                                                                  in other words, if we look in the next non-empty level the
                                                                                                                                                                                  message at index zero is [message]. *)
  | Level_crossing of {
      lower : history_proof;
      lower_level_messages : Merkelized_messages.t;
      upper : history_proof;
      upper_level_messages : Merkelized_messages.t;
      inc : inclusion_proof;
      upper_message_proof : message_proof;
      upper_level : Raw_level_repr.t;
    }

let pp_proof fmt proof =
  match proof with
  | Single_level {level_messages; _} ->
      let hash = Merkelized_messages.hash level_messages in
      Format.fprintf
        fmt
        "Single_level inbox proof at %a"
        Merkelized_messages.Hash.pp
        hash
  | Level_crossing {lower; upper; upper_level; _} ->
      let lower_hash = Skip_list.content lower in
      let upper_hash = Skip_list.content upper in
      Format.fprintf
        fmt
        "Level_crossing inbox proof between %a and %a (upper_level %a)"
        Merkelized_messages.Hash.pp
        lower_hash
        Merkelized_messages.Hash.pp
        upper_hash
        Raw_level_repr.pp
        upper_level

let proof_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Single_level"
        (Tag 0)
        (obj4
           (req "level" history_proof_encoding)
           (req "level_messages" Merkelized_messages.encoding)
           (req "inclusion_proof" inclusion_proof_encoding)
           (opt "message_proof" Merkelized_messages.proof_encoding))
        (function
          | Single_level {level; level_messages; inc; message_proof} ->
              Some (level, level_messages, inc, message_proof)
          | _ -> None)
        (fun (level, level_messages, inc, message_proof) ->
          Single_level {level; level_messages; inc; message_proof});
      case
        ~title:"Level_crossing"
        (Tag 1)
        (obj7
           (req "lower" history_proof_encoding)
           (req "lower_level_messages" Merkelized_messages.encoding)
           (req "upper" history_proof_encoding)
           (req "upper_level_messages" Merkelized_messages.encoding)
           (req "inclusion_proof" inclusion_proof_encoding)
           (req "upper_message_proof" Merkelized_messages.proof_encoding)
           (req "upper_level" Raw_level_repr.encoding))
        (function
          | Level_crossing
              {
                lower;
                lower_level_messages;
                upper;
                upper_level_messages;
                inc;
                upper_message_proof;
                upper_level;
              } ->
              Some
                ( lower,
                  lower_level_messages,
                  upper,
                  upper_level_messages,
                  inc,
                  upper_message_proof,
                  upper_level )
          | _ -> None)
        (fun ( lower,
               lower_level_messages,
               upper,
               upper_level_messages,
               inc,
               upper_message_proof,
               upper_level ) ->
          Level_crossing
            {
              lower;
              lower_level_messages;
              upper;
              upper_level_messages;
              inc;
              upper_message_proof;
              upper_level;
            });
    ]

let of_serialized_proof = Data_encoding.Binary.of_bytes_opt proof_encoding

let to_serialized_proof = Data_encoding.Binary.to_bytes_exn proof_encoding

let proof_error reason =
  let open Lwt_tzresult_syntax in
  fail (Inbox_proof_error reason)

let check p reason = unless p (fun () -> proof_error reason)

(** Utility function that checks the inclusion proof [inc] for any
inbox proof.

In the case of a [Single_level] proof this is just an inclusion
proof between [level] and the inbox snapshot targeted the proof.

In the case of a [Level_crossing] proof [inc] must be an inclusion
proof between [upper] and the inbox snapshot. In this case we must
additionally check that [lower] is the immediate predecessor of
[upper] in the inbox skip list. NB: there may be many 'inbox
levels' apart, but if the intervening levels are empty they will
be immediate neighbours in the skip list because it misses empty
levels out. *)
let check_inclusions proof snapshot =
  check
    (match proof with
    | Single_level {inc; level; level_messages; _} ->
        assert (
          Merkelized_messages.Hash.equal
            (Skip_list.content level)
            (Merkelized_messages.hash level_messages)) ;
        verify_inclusion_proof
          inc
          ~target_history_proof:level
          ~into_history_proof:snapshot
    | Level_crossing {inc; lower; upper; _} -> (
        let prev_cell = Skip_list.back_pointer upper 0 in
        match prev_cell with
        | None -> false
        | Some p ->
            verify_inclusion_proof
              inc
              ~target_history_proof:upper
              ~into_history_proof:snapshot
            && Hash.equal p (hash_history_proof lower)))
    "invalid inclusions"

(** Utility function that handles all the verification needed for a
    particular message proof at a particular level. It calls
    [P.verify_proof], but also checks the proof has the correct
    [P.proof_before] hash and the [level] stored inside the tree is
    the expected one. *)
let check_message_proof message_proof level_messages_hash (l, n) label =
  let open Tzresult_syntax in
  let* payload, level, message_counter =
    Merkelized_messages.verify_proof message_proof level_messages_hash
  in
  let* () =
    error_unless
      (Raw_level_repr.equal l level && Compare.Int.(n = message_counter))
      (Inbox_proof_error
         (Format.sprintf "incorrect level in message_proof (%s)" label))
  in
  let* () =
    error_unless
      (Raw_level_repr.equal l level && Compare.Int.(n = message_counter))
      (Inbox_proof_error
         (Format.sprintf
            "incorrect message counter in message_proof (%s)"
            label))
  in
  return payload

let verify_proof (l, n) snapshot proof =
  assert (Z.(geq n zero)) ;
  let open Lwt_tzresult_syntax in
  let* () = check_inclusions proof snapshot in
  match proof with
  | Single_level p -> (
      let level_messages = p.level_messages in
      match p.message_proof with
      | Some message_proof ->
          let*? payload =
            check_message_proof
              message_proof
              level_messages
              (l, Z.to_int n)
              "single level"
          in
          return_some
            Sc_rollup_PVM_sig.{inbox_level = l; message_counter = n; payload}
      | None ->
          let level_messages_number_of_messages =
            Merkelized_messages.get_number_of_messages level_messages
          in
          let* () =
            fail_unless
              Compare.Int.(Z.to_int n < level_messages_number_of_messages)
              (Inbox_proof_error
                 "there should be an inbox proof for that level and index.")
          in
          return_none)
  | Level_crossing p ->
      let lower_level_messages = p.lower_level_messages in
      let level_messages_number_of_messages =
        Merkelized_messages.get_number_of_messages lower_level_messages
      in
      let* () =
        fail_unless
          Compare.Int.(Z.to_int n < level_messages_number_of_messages)
          (Inbox_proof_error "more messages to read in lower level")
      in
      let upper_level_messages = p.upper_level_messages in
      let*? payload =
        check_message_proof
          p.upper_message_proof
          upper_level_messages
          (p.upper_level, 0)
          "upper"
      in
      return
      @@ Some
           Sc_rollup_PVM_sig.
             {inbox_level = p.upper_level; message_counter = Z.zero; payload}

let find_level_messages history find_level_history level current_cell =
  let open Lwt_option_syntax in
  let deref ptr =
    let open Option_syntax in
    let+ cell = History.find ptr history in
    cell
  in
  let compare level_to_find cell =
    let cell_ptr = hash_history_proof cell in
    let*! level_messages_level =
      let open Lwt_option_syntax in
      let*? cell = History.find cell_ptr history in
      let* level_history = find_level_history (Skip_list.content cell) in
      let*? level_messages =
        Merkelized_messages.History.find (Skip_list.content cell) level_history
      in
      return @@ Merkelized_messages.get_level level_messages
    in
    Lwt.return
    @@
    match level_messages_level with
    | None -> -1
    | Some level_messages_level ->
        Raw_level_repr.compare level_messages_level level_to_find
  in
  let*! research_result =
    Skip_list.search ~deref ~compare:(compare level) ~cell:current_cell
  in
  (*   let () = assert false in *)
  let* level_messages_cell =
    match research_result with
    | Skip_list.{last_cell = Found level_messages_cell; _} ->
        return level_messages_cell
    | {last_cell = Nearest _; _}
    | {last_cell = No_exact_or_lower_ptr; _}
    | {last_cell = Deref_returned_none; _} ->
        fail
  in
  let cell_hash = hash_history_proof level_messages_cell in
  let*? cell = History.find cell_hash history in
  let level_messages_hash = Skip_list.content cell in
  let* level_history = find_level_history level_messages_hash in
  let*? level_messages =
    Merkelized_messages.History.find level_messages_hash level_history
  in
  return (level_history, level_messages)

let find_message history find_level_history (level, message_index) history_proof
    =
  let open Lwt_option_syntax in
  let* level_history, level_messages =
    find_level_messages history find_level_history level history_proof
  in
  Lwt.return
  @@ Merkelized_messages.find_message
       level_history
       ~message_index
       level_messages

let lift_opt reason opt =
  match opt with None -> error (Inbox_proof_error reason) | Some x -> ok x

(** Utility function; we convert all our calls to be consistent with
    [Lwt_tzresult_syntax]. *)
let lift_lwt_opt e lwt_opt = Lwt.map (lift_opt e) lwt_opt

let produce_proof history find_level_history inbox (level, message_index) =
  let open Lwt_tzresult_syntax in
  let* inclusion_proof, level_history_proof =
    search_history_proof
      history
      find_level_history
      level
      ~into_history_proof:inbox
  in
  let level_messages_hash = Skip_list.content level_history_proof in
  let* level_messages_history =
    lift_lwt_opt
      "Could not find level history."
      (find_level_history level_messages_hash)
  in
  let*? level_messages_proof =
    lift_opt
      "could not find level_tree in the inbox_context"
      (Merkelized_messages.History.find
         level_messages_hash
         level_messages_history)
  in
  let message_proof =
    Merkelized_messages.produce_proof
      level_messages_history
      ~message_index
      level_messages_proof
  in
  match message_proof with
  | Some message_proof ->
      return
        ( Single_level
            {
              level = level_history_proof;
              level_messages = level_messages_proof;
              inc = inclusion_proof;
              message_proof = Some message_proof;
            },
          Some
            Sc_rollup_PVM_sig.
              {
                inbox_level = level;
                message_counter = Z.of_int message_index;
                payload =
                  Merkelized_messages.get_message_payload message_proof.message;
              } )
  | None ->
      let current_level_messages_hash = Skip_list.content inbox in
      if
        Merkelized_messages.Hash.equal
          level_messages_hash
          current_level_messages_hash
      then
        return
          ( Single_level
              {
                level = level_history_proof;
                level_messages = level_messages_proof;
                inc = inclusion_proof;
                message_proof = None;
              },
            None )
      else
        let upper_index = Skip_list.index level_history_proof + 1 in
        let inclusion_proof =
          produce_inclusion_proof
            history
            ~target_history_proof_index:upper_index
            ~into_history_proof:inbox
        in
        let*? inclusion_proof =
          lift_opt "failed to find path to upper level." inclusion_proof
        in
        let*? upper_level_messages_cell =
          lift_opt
            "back_path returned empty list"
            (List.last_opt inclusion_proof)
        in
        let*? upper_level_messages =
          lift_opt
            "could not find upper_level_tree in the inbox_context"
            (Merkelized_messages.History.find
               (Skip_list.content upper_level_messages_cell)
               level_messages_history)
        in
        let*? upper_message_proof =
          lift_opt
            "failed to produce message proof for upper_level_tree"
            (Merkelized_messages.produce_proof
               level_messages_history
               upper_level_messages
               ~message_index:0)
        in
        let upper_message_level =
          Merkelized_messages.get_level upper_level_messages
        in
        let upper_message_payload =
          Merkelized_messages.get_message_payload upper_message_proof.message
        in
        let input_given =
          Some
            Sc_rollup_PVM_sig.
              {
                inbox_level = upper_message_level;
                message_counter = Z.zero;
                payload = upper_message_payload;
              }
        in
        return
          ( Level_crossing
              {
                lower = level_history_proof;
                lower_level_messages = level_messages_proof;
                upper = upper_level_messages_cell;
                upper_level_messages;
                inc = inclusion_proof;
                upper_message_proof;
                upper_level = upper_message_level;
              },
            input_given )

let empty rollup level =
  assert (Raw_level_repr.(level <> Raw_level_repr.root)) ;
  let initial_hash = Merkelized_messages.Hash.zero in
  {
    rollup;
    level;
    nb_messages_in_commitment_period = 0L;
    starting_level_of_current_commitment_period = level;
    current_level_hash = (fun () -> initial_hash);
    old_levels_messages = Skip_list.genesis initial_hash;
  }

module Internal_for_tests = struct
  let serialized_proof_of_string x = Bytes.of_string x

  let hash_of_history_proof = hash_history_proof

  let equal_inclusion_proof = List.equal equal_history_proof

  let history_proof_index = Skip_list.index
end

type inbox = t
