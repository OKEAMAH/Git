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

let hash_skip_list_cell cell =
  let current_level_hash = Skip_list.content cell in
  let back_pointers_hashes = Skip_list.back_pointers cell in
  Hash.to_bytes current_level_hash
  :: List.map Hash.to_bytes back_pointers_hashes
  |> Hash.hash_bytes

module V1 = struct
  type history_proof = (Hash.t, Hash.t) Skip_list.cell

  let equal_history_proof = Skip_list.equal Hash.equal Hash.equal

  let history_proof_encoding : history_proof Data_encoding.t =
    Skip_list.encoding Hash.encoding Hash.encoding

  let pp_history_proof fmt history =
    let history_hash = hash_skip_list_cell history in
    Format.fprintf
      fmt
      "@[hash : %a@;%a@]"
      Hash.pp
      history_hash
      (Skip_list.pp ~pp_content:Hash.pp ~pp_ptr:Hash.pp)
      history

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
   - [message_counter] : the number of messages in the [level]'s inbox ;
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
    message_counter : Z.t;
    (* Lazy to avoid hashing O(n^2) time in [add_messages] *)
    current_level_hash : unit -> Hash.t;
    old_levels_messages : history_proof;
  }

  let equal inbox1 inbox2 =
    (* To be robust to addition of fields in [t]. *)
    let {
      rollup;
      level;
      nb_messages_in_commitment_period;
      starting_level_of_current_commitment_period;
      message_counter;
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
    && Z.equal message_counter inbox2.message_counter
    && Hash.equal (current_level_hash ()) (inbox2.current_level_hash ())
    && equal_history_proof old_levels_messages inbox2.old_levels_messages

  let pp fmt
      {
        rollup;
        level;
        nb_messages_in_commitment_period;
        starting_level_of_current_commitment_period;
        message_counter;
        current_level_hash;
        old_levels_messages;
      } =
    Format.fprintf
      fmt
      "@[<hov 2>{ rollup = %a@;\
       level = %a@;\
       current messages hash  = %a@;\
       nb_messages_in_commitment_period = %s@;\
       starting_level_of_current_commitment_period = %a@;\
       message_counter = %a@;\
       old_levels_messages = %a@;\
       }@]"
      Sc_rollup_repr.Address.pp
      rollup
      Raw_level_repr.pp
      level
      Hash.pp
      (current_level_hash ())
      (Int64.to_string nb_messages_in_commitment_period)
      Raw_level_repr.pp
      starting_level_of_current_commitment_period
      Z.pp_print
      message_counter
      pp_history_proof
      old_levels_messages

  let inbox_level inbox = inbox.level

  let old_levels_messages inbox = inbox.old_levels_messages

  let current_level_hash inbox = inbox.current_level_hash ()

  let old_levels_messages_encoding =
    Skip_list.encoding Hash.encoding Hash.encoding

  let encoding =
    Data_encoding.(
      conv
        (fun {
               rollup;
               message_counter;
               nb_messages_in_commitment_period;
               starting_level_of_current_commitment_period;
               level;
               current_level_hash;
               old_levels_messages;
             } ->
          ( rollup,
            message_counter,
            nb_messages_in_commitment_period,
            starting_level_of_current_commitment_period,
            level,
            current_level_hash (),
            old_levels_messages ))
        (fun ( rollup,
               message_counter,
               nb_messages_in_commitment_period,
               starting_level_of_current_commitment_period,
               level,
               current_level_hash,
               old_levels_messages ) ->
          {
            rollup;
            message_counter;
            nb_messages_in_commitment_period;
            starting_level_of_current_commitment_period;
            level;
            current_level_hash = (fun () -> current_level_hash);
            old_levels_messages;
          })
        (obj7
           (req "rollup" Sc_rollup_repr.encoding)
           (req "message_counter" n)
           (req "nb_messages_in_commitment_period" int64)
           (req
              "starting_level_of_current_commitment_period"
              Raw_level_repr.encoding)
           (req "level" Raw_level_repr.encoding)
           (req "current_level_hash" Hash.encoding)
           (req "old_levels_messages" old_levels_messages_encoding)))

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

module Level_messages_inbox : sig
  type t

  val hash : t -> Hash.t

  val empty : Raw_level_repr.t -> t

  val add_message : t -> Z.t -> Sc_rollup_inbox_message_repr.serialized -> t

  val get_message_payload :
    t -> Z.t -> Sc_rollup_inbox_message_repr.serialized option Lwt.t

  val get_level : t -> Raw_level_repr.t

  val to_bytes : t -> bytes

  val of_bytes : bytes -> t option
end = struct
  type value = Sc_rollup_inbox_message_repr.serialized

  type ptr = Hash.t

  type t = {skip_list : (value, ptr) Skip_list.cell; level : Raw_level_repr.t}

  let encoding =
    Data_encoding.conv
      (fun {skip_list; level} -> (skip_list, level))
      (fun (skip_list, level) -> {skip_list; level})
      (Data_encoding.tup2
         (Skip_list.encoding
            Hash.encoding
            Sc_rollup_inbox_message_repr.serialized_encoding)
         Raw_level_repr.encoding)

  let hash {skip_list; _} =
    let payload = Skip_list.content skip_list in
    let back_pointers_hashes = Skip_list.back_pointers skip_list in
    Bytes.of_string
      (payload : Sc_rollup_inbox_message_repr.serialized :> string)
    :: List.map Hash.to_bytes back_pointers_hashes
    |> Hash.hash_bytes

  let empty level =
    let first_msg = Sc_rollup_inbox_message_repr.unsafe_of_string "" in
    {skip_list = Skip_list.genesis first_msg; level}

  let add_message messages _message_index payload =
    let prev_cell = messages.skip_list in
    let prev_cell_ptr = hash messages in
    {messages with skip_list = Skip_list.next ~prev_cell ~prev_cell_ptr payload}

  let get_message_payload _skip_list _message_index = Lwt.return_none

  let get_level {level; _} = level

  let to_bytes = Data_encoding.Binary.to_bytes_exn encoding

  let of_bytes = Data_encoding.Binary.of_bytes_opt encoding
end

module type Merkelized_operations = sig
  type tree

  val add_messages :
    History.t ->
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    Level_messages_inbox.t option ->
    (Level_messages_inbox.t * History.t * t) tzresult Lwt.t

  val add_messages_no_history :
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    Level_messages_inbox.t option ->
    (Level_messages_inbox.t * t) tzresult Lwt.t

  val get_message_payload :
    Level_messages_inbox.t ->
    Z.t ->
    Sc_rollup_inbox_message_repr.serialized option Lwt.t

  val form_history_proof :
    History.t -> t -> (History.t * history_proof) tzresult Lwt.t

  val take_snapshot : current_level:Raw_level_repr.t -> t -> history_proof

  type inclusion_proof

  val inclusion_proof_encoding : inclusion_proof Data_encoding.t

  val pp_inclusion_proof : Format.formatter -> inclusion_proof -> unit

  val number_of_proof_steps : inclusion_proof -> int

  val verify_inclusion_proof :
    inclusion_proof -> history_proof -> history_proof -> bool

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
    history_proof ->
    Raw_level_repr.t * Z.t ->
    (proof * Sc_rollup_PVM_sig.inbox_message option) tzresult Lwt.t

  val empty : Sc_rollup_repr.t -> Raw_level_repr.t -> t Lwt.t

  module Internal_for_tests : sig
    val produce_inclusion_proof :
      History.t ->
      history_proof ->
      history_proof ->
      inclusion_proof option tzresult

    val serialized_proof_of_string : string -> serialized_proof
  end
end

module type P = sig
  type t

  type tree

  type proof

  val proof_encoding : proof Data_encoding.t

  val proof_before : proof -> Hash.t

  val verify_proof :
    proof -> (tree -> (tree * 'a) Lwt.t) -> (tree * 'a) option Lwt.t

  val produce_proof :
    t -> tree -> (tree -> (tree * 'a) Lwt.t) -> (proof * 'a) option Lwt.t
end

module Make_hashing_scheme (P : P) :
  Merkelized_operations with type tree = P.tree = struct
  type tree = P.tree

  let add_message inbox payload level_messages =
    let open Lwt_syntax in
    let message_index = inbox.message_counter in
    let message_counter = Z.succ message_index in
    let level_messages =
      Level_messages_inbox.add_message level_messages message_index payload
    in
    let nb_messages_in_commitment_period =
      Int64.succ inbox.nb_messages_in_commitment_period
    in
    let inbox =
      {
        starting_level_of_current_commitment_period =
          inbox.starting_level_of_current_commitment_period;
        current_level_hash = inbox.current_level_hash;
        rollup = inbox.rollup;
        level = inbox.level;
        old_levels_messages = inbox.old_levels_messages;
        message_counter;
        nb_messages_in_commitment_period;
      }
    in
    return (level_messages, inbox)

  let get_message_payload messages message_counter =
    Level_messages_inbox.get_message_payload messages message_counter

  (** [no_history] creates an empty history with [capacity] set to
      zero---this makes the [remember] function a no-op. We want this
      behaviour in the protocol because we don't want to store
      previous levels of the inbox. *)
  let no_history = History.empty ~capacity:0L

  let take_snapshot ~current_level inbox =
    let prev_cell = inbox.old_levels_messages in
    if Raw_level_repr.(inbox.level < current_level) then
      (* If the level of the inbox is lower than the current level, there
         is no new messages in the inbox for the current level. It is then safe
         to take a snapshot of the actual inbox. *)
      let prev_cell_ptr = hash_skip_list_cell prev_cell in
      Skip_list.next ~prev_cell ~prev_cell_ptr (current_level_hash inbox)
    else
      (* If there is a level tree for the [current_level] in the inbox, we need
         to ignore this new level as it is not finished yet (regarding the
         block's completion). We take the inbox's current predecessor instead.
      *)
      prev_cell

  let form_history_proof history inbox =
    let open Lwt_tzresult_syntax in
    let prev_cell = inbox.old_levels_messages in
    let prev_cell_ptr = hash_skip_list_cell prev_cell in
    let*? history = History.remember prev_cell_ptr prev_cell history in
    let cell =
      Skip_list.next ~prev_cell ~prev_cell_ptr (current_level_hash inbox)
    in
    return (history, cell)

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
  let archive_if_needed history inbox new_level messages =
    let open Lwt_result_syntax in
    if Raw_level_repr.(inbox.level = new_level) then
      match messages with
      | Some messages -> return (history, inbox, messages)
      | None ->
          let messages = Level_messages_inbox.empty new_level in
          return (history, inbox, messages)
    else
      let* history, old_levels_messages = form_history_proof history inbox in
      let messages = Level_messages_inbox.empty new_level in
      let inbox =
        {
          starting_level_of_current_commitment_period =
            inbox.starting_level_of_current_commitment_period;
          current_level_hash = inbox.current_level_hash;
          rollup = inbox.rollup;
          nb_messages_in_commitment_period =
            inbox.nb_messages_in_commitment_period;
          old_levels_messages;
          level = new_level;
          message_counter = Z.zero;
        }
      in
      return (history, inbox, messages)

  let add_messages history inbox level payloads messages =
    let open Lwt_tzresult_syntax in
    let* () =
      fail_when
        (match payloads with [] -> true | _ -> false)
        Tried_to_add_zero_messages
    in
    let* () =
      fail_when
        Raw_level_repr.(level < inbox.level)
        (Invalid_level_add_messages level)
    in
    let* history, inbox, messages =
      archive_if_needed history inbox level messages
    in
    let*! messages, inbox =
      List.fold_left_s
        (fun (level_messages, inbox) payload ->
          add_message inbox payload level_messages)
        (messages, inbox)
        payloads
    in
    let current_level_hash () = Level_messages_inbox.hash messages in
    return (messages, history, {inbox with current_level_hash})

  let add_messages_no_history inbox level payloads messages =
    let open Lwt_tzresult_syntax in
    let+ messages, _, inbox =
      add_messages no_history inbox level payloads messages
    in
    (messages, inbox)

  (* An [inclusion_proof] is a path in the Merkelized skip list
     showing that a given inbox history is a prefix of another one.
     This path has a size logarithmic in the difference between the
     levels of the two inboxes.

     [Irmin.Proof.{tree_proof, stream_proof}] could not be reused here
     because there is no obvious encoding of sequences in these data
     structures with the same guarantee about the size of proofs. *)
  type inclusion_proof = history_proof list

  let inclusion_proof_encoding =
    let open Data_encoding in
    list history_proof_encoding

  let pp_inclusion_proof fmt proof =
    Format.pp_print_list pp_history_proof fmt proof

  let number_of_proof_steps proof = List.length proof

  let lift_ptr_path deref ptr_path =
    let rec aux accu = function
      | [] -> Some (List.rev accu)
      | x :: xs -> Option.bind (deref x) @@ fun c -> aux (c :: accu) xs
    in
    aux [] ptr_path

  let verify_inclusion_proof proof a b =
    let assoc = List.map (fun c -> (hash_skip_list_cell c, c)) proof in
    let path = List.split assoc |> fst in
    let deref =
      let open Hash.Map in
      let map = of_seq (List.to_seq assoc) in
      fun ptr -> find_opt ptr map
    in
    let cell_ptr = hash_skip_list_cell b in
    let target_ptr = hash_skip_list_cell a in
    Skip_list.valid_back_path
      ~equal_ptr:Hash.equal
      ~deref
      ~cell_ptr
      ~target_ptr
      path

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
        level : history_proof;
        inc : inclusion_proof;
        message_proof : P.proof;
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
        upper : history_proof;
        inc : inclusion_proof;
        lower_message_proof : P.proof;
        upper_message_proof : P.proof;
        upper_level : Raw_level_repr.t;
      }

  let pp_proof fmt proof =
    match proof with
    | Single_level {level; _} ->
        let hash = Skip_list.content level in
        Format.fprintf fmt "Single_level inbox proof at %a" Hash.pp hash
    | Level_crossing {lower; upper; upper_level; _} ->
        let lower_hash = Skip_list.content lower in
        let upper_hash = Skip_list.content upper in
        Format.fprintf
          fmt
          "Level_crossing inbox proof between %a and %a (upper_level %a)"
          Hash.pp
          lower_hash
          Hash.pp
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
          (obj3
             (req "level" history_proof_encoding)
             (req "inclusion_proof" inclusion_proof_encoding)
             (req "message_proof" P.proof_encoding))
          (function
            | Single_level {level; inc; message_proof} ->
                Some (level, inc, message_proof)
            | _ -> None)
          (fun (level, inc, message_proof) ->
            Single_level {level; inc; message_proof});
        case
          ~title:"Level_crossing"
          (Tag 1)
          (obj6
             (req "lower" history_proof_encoding)
             (req "upper" history_proof_encoding)
             (req "inclusion_proof" inclusion_proof_encoding)
             (req "lower_message_proof" P.proof_encoding)
             (req "upper_message_proof" P.proof_encoding)
             (req "upper_level" Raw_level_repr.encoding))
          (function
            | Level_crossing
                {
                  lower;
                  upper;
                  inc;
                  lower_message_proof;
                  upper_message_proof;
                  upper_level;
                } ->
                Some
                  ( lower,
                    upper,
                    inc,
                    lower_message_proof,
                    upper_message_proof,
                    upper_level )
            | _ -> None)
          (fun ( lower,
                 upper,
                 inc,
                 lower_message_proof,
                 upper_message_proof,
                 upper_level ) ->
            Level_crossing
              {
                lower;
                upper;
                inc;
                lower_message_proof;
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
      | Single_level {inc; level; _} ->
          verify_inclusion_proof inc level snapshot
      | Level_crossing {inc; lower; upper; _} -> (
          let prev_cell = Skip_list.back_pointer upper 0 in
          match prev_cell with
          | None -> false
          | Some p ->
              verify_inclusion_proof inc upper snapshot
              && Hash.equal p (hash_skip_list_cell lower)))
      "invalid inclusions"

  (** Utility function that handles all the verification needed for a
      particular message proof at a particular level. It calls
      [P.verify_proof], but also checks the proof has the correct
      [P.proof_before] hash and the [level] stored inside the tree is
      the expected one. *)
  let check_message_proof _message_proof _level_hash (_l, _n) label =
    proof_error (Format.sprintf "message_proof is invalid (%s)" label)

  let verify_proof (l, n) snapshot proof =
    assert (Z.(geq n zero)) ;
    let open Lwt_tzresult_syntax in
    let* () = check_inclusions proof snapshot in
    match proof with
    | Single_level p -> (
        let level_hash = Skip_list.content p.level in
        let* payload_opt =
          check_message_proof p.message_proof level_hash (l, n) "single level"
        in
        match payload_opt with
        | None ->
            if equal_history_proof snapshot p.level then return None
            else proof_error "payload is None but proof.level not top level"
        | Some payload ->
            return
            @@ Some
                 Sc_rollup_PVM_sig.
                   {inbox_level = l; message_counter = n; payload})
    | Level_crossing p -> (
        let lower_level_hash = Skip_list.content p.lower in
        let* should_be_none =
          check_message_proof
            p.lower_message_proof
            lower_level_hash
            (l, n)
            "lower"
        in
        let* () =
          match should_be_none with
          | None -> return ()
          | Some _ -> proof_error "more messages to read in lower level"
        in
        let upper_level_hash = Skip_list.content p.upper in
        let* payload_opt =
          check_message_proof
            p.upper_message_proof
            upper_level_hash
            (p.upper_level, Z.zero)
            "upper"
        in
        match payload_opt with
        | None ->
            (* [check_inclusions] checks at least two important properties:
               1. [p.lower_level] is different from [p.upper_level]
               2. [p.upper_level] is included in the snapshot

               If [p.upper_level] is included in the snapshot, the level was
               created by the protocol. If the protocol created a level tree
               at [p.upper_level] it *must* contain at least one message.
               So, if [p.upper_level] exists, at the index [Z.zero] (fetched
               here), a payload *must* exist.

               This code is then dead as long as we store only the nonempty
               inboxes.
            *)
            fail (Empty_upper_level p.upper_level)
        | Some payload ->
            return
            @@ Some
                 Sc_rollup_PVM_sig.
                   {
                     inbox_level = p.upper_level;
                     message_counter = Z.zero;
                     payload;
                   })

  let produce_proof _history _inbox (_l, _n) =
    proof_error "Can't produce proof yet"

  let empty rollup level =
    let open Lwt_syntax in
    assert (Raw_level_repr.(level <> Raw_level_repr.root)) ;
    let pre_genesis_level = Raw_level_repr.root in
    let initial_messages = Level_messages_inbox.empty pre_genesis_level in
    let initial_hash = Level_messages_inbox.hash initial_messages in
    return
      {
        rollup;
        level;
        message_counter = Z.zero;
        nb_messages_in_commitment_period = 0L;
        starting_level_of_current_commitment_period = level;
        current_level_hash = (fun () -> initial_hash);
        old_levels_messages = Skip_list.genesis initial_hash;
      }

  module Internal_for_tests = struct
    let produce_inclusion_proof history a b =
      let open Tzresult_syntax in
      let cell_ptr = hash_skip_list_cell b in
      let target_index = Skip_list.index a in
      let* history = History.remember cell_ptr b history in
      let deref ptr = History.find ptr history in
      Skip_list.back_path ~deref ~cell_ptr ~target_index
      |> Option.map (lift_ptr_path deref)
      |> Option.join |> return

    let serialized_proof_of_string x = Bytes.of_string x
  end
end

include (
  Make_hashing_scheme (struct
    type t = Context.t

    type tree = Context.tree

    type proof = Context.Proof.tree Context.Proof.t

    let proof_encoding = Context.Proof_encoding.V1.Tree32.tree_proof_encoding

    let proof_before proof =
      match proof.Context.Proof.before with
      | `Value hash | `Node hash -> Hash.of_context_hash hash

    let verify_proof p f =
      Lwt.map Result.to_option (Context.verify_tree_proof p f)

    let produce_proof _ _ _ =
      (* We cannot produce a proof without full inbox_context *)
      Lwt.return None
  end) :
    Merkelized_operations with type tree = Context.tree)

type inbox = t
