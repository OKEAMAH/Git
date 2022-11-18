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
   is decomposed into sublists of messages, one for each Tezos level greater
   than the level where SCORU is activated.

   This module is designed to:

   1. provide a space-efficient representation for proofs of inbox
      inclusions (only for inboxes obtained at the end of block
      validation) ;

   2. offer an efficient function to add a new batch of messages in the
      inbox at the current level.

   To solve (1), we use a proof tree H which is implemented by a merkelized skip
   list allowing for compact inclusion proofs (See {!skip_list_repr.ml}).

   To solve (2), we maintain a separate proof tree C witnessing the
   contents of messages of the current level.

   The protocol maintains the hashes of the head of H, and the root hash of C.

   The rollup node needs to maintain a full representation for C and a
   partial representation for H back to the level of the LCC.

*)
type error += Invalid_level_add_messages of Raw_level_repr.t

type error += Inbox_proof_error of string

type error += Tried_to_add_zero_messages

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
    (fun () -> Tried_to_add_zero_messages)

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

module V1 = struct
  type level_proof = {hash : Hash.t; level : Raw_level_repr.t}

  let level_proof_encoding =
    let open Data_encoding in
    conv
      (fun {hash; level} -> (hash, level))
      (fun (hash, level) -> {hash; level})
      (obj2 (req "hash" Hash.encoding) (req "level" Raw_level_repr.encoding))

  let equal_level_proof {hash; level} level_proof_2 =
    Hash.equal hash level_proof_2.hash
    && Raw_level_repr.equal level level_proof_2.level

  type history_proof = (level_proof, Hash.t) Skip_list.cell

  let hash_history_proof cell =
    let {hash; level} = Skip_list.content cell in
    let back_pointers_hashes = Skip_list.back_pointers cell in
    Hash.to_bytes hash
    :: (Raw_level_repr.to_int32 level |> Int32.to_string |> Bytes.of_string)
    :: List.map Hash.to_bytes back_pointers_hashes
    |> Hash.hash_bytes

  let equal_history_proof = Skip_list.equal Hash.equal equal_level_proof

  let history_proof_encoding : history_proof Data_encoding.t =
    Skip_list.encoding Hash.encoding level_proof_encoding

  let pp_level_proof fmt {hash; level} =
    Format.fprintf
      fmt
      "hash: %a@,level: %a"
      Hash.pp
      hash
      Raw_level_repr.pp
      level

  let pp_history_proof fmt history_proof =
    (Skip_list.pp ~pp_content:pp_level_proof ~pp_ptr:Hash.pp) fmt history_proof

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
   - [level] : the inbox level ;
   - [message_counter] : the number of messages in the [level]'s inbox ;
     the number of messages that have not been consumed by a commitment cementing ;
   - [nb_messages_in_commitment_period] :
     the number of messages during the commitment period ;
   - [current_level_proof] : the [current_level] and its root hash ;
   - [old_levels_messages] : a witness of the inbox history.

   When new messages are appended to the current level inbox, the
   metadata stored in the context may be related to an older level.
   In that situation, an archival process is applied to the metadata.
   This process saves the [current_level_proof] in the
   [old_levels_messages] and empties [current_level]. It then
   initialises a new level tree for the new messages---note that any
   intermediate levels are simply skipped. See
   {!Make_hashing_scheme.archive_if_needed} for details.

  *)
  type t = {
    level : Raw_level_repr.t;
    nb_messages_in_commitment_period : int64;
    message_counter : Z.t;
    (* Lazy to avoid hashing O(n^2) time in [add_messages] *)
    current_level_proof : unit -> level_proof;
    old_levels_messages : history_proof;
  }

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3978

     The number of messages during commitment period is broken with the
     unique inbox. *)

  let equal inbox1 inbox2 =
    (* To be robust to addition of fields in [t]. *)
    let {
      level;
      nb_messages_in_commitment_period;
      message_counter;
      current_level_proof;
      old_levels_messages;
    } =
      inbox1
    in
    Raw_level_repr.equal level inbox2.level
    && Compare.Int64.(
         equal
           nb_messages_in_commitment_period
           inbox2.nb_messages_in_commitment_period)
    && Z.equal message_counter inbox2.message_counter
    && equal_level_proof
         (current_level_proof ())
         (inbox2.current_level_proof ())
    && equal_history_proof old_levels_messages inbox2.old_levels_messages

  let pp fmt
      {
        level;
        nb_messages_in_commitment_period;
        message_counter;
        current_level_proof;
        old_levels_messages;
      } =
    Format.fprintf
      fmt
      "@[<hov 2>{ level = %a@;\
       current messages hash  = %a@;\
       nb_messages_in_commitment_period = %s@;\
       message_counter = %a@;\
       old_levels_messages = %a@;\
       }@]"
      Raw_level_repr.pp
      level
      pp_level_proof
      (current_level_proof ())
      (Int64.to_string nb_messages_in_commitment_period)
      Z.pp_print
      message_counter
      pp_history_proof
      old_levels_messages

  let inbox_level inbox = inbox.level

  let inbox_message_counter inbox = inbox.message_counter

  let old_levels_messages inbox = inbox.old_levels_messages

  let current_level_proof inbox = inbox.current_level_proof ()

  let encoding =
    Data_encoding.(
      conv
        (fun {
               message_counter;
               nb_messages_in_commitment_period;
               level;
               current_level_proof;
               old_levels_messages;
             } ->
          ( message_counter,
            nb_messages_in_commitment_period,
            level,
            current_level_proof (),
            old_levels_messages ))
        (fun ( message_counter,
               nb_messages_in_commitment_period,
               level,
               current_level_proof,
               old_levels_messages ) ->
          {
            message_counter;
            nb_messages_in_commitment_period;
            level;
            current_level_proof = (fun () -> current_level_proof);
            old_levels_messages;
          })
        (obj5
           (req "message_counter" n)
           (req "nb_messages_in_commitment_period" int64)
           (req "level" Raw_level_repr.encoding)
           (req "current_level_proof" level_proof_encoding)
           (req "old_levels_messages" history_proof_encoding)))

  let number_of_messages_during_commitment_period inbox =
    inbox.nb_messages_in_commitment_period
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

let key_of_message ix =
  ["message"; Data_encoding.Binary.to_string_exn Data_encoding.n ix]

let number_of_messages_key = ["number_of_messages"]

type serialized_proof = Bytestring.t

let serialized_proof_encoding = Data_encoding.bytestring

module type Merkelized_operations = sig
  type inbox_context

  type tree

  val hash_level_tree : tree -> Hash.t

  val new_level_tree : inbox_context -> tree Lwt.t

  val add_messages :
    inbox_context ->
    History.t ->
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    tree option ->
    (tree * History.t * t) tzresult Lwt.t

  val add_messages_no_history :
    inbox_context ->
    t ->
    Raw_level_repr.t ->
    Sc_rollup_inbox_message_repr.serialized list ->
    tree option ->
    (tree * t) tzresult Lwt.t

  val get_message_payload :
    tree -> Z.t -> Sc_rollup_inbox_message_repr.serialized option Lwt.t

  val form_history_proof :
    inbox_context ->
    History.t ->
    t ->
    tree option ->
    (History.t * history_proof) tzresult Lwt.t

  val take_snapshot : t -> history_proof

  type inclusion_proof

  val inclusion_proof_encoding : inclusion_proof Data_encoding.t

  val pp_inclusion_proof : Format.formatter -> inclusion_proof -> unit

  val number_of_proof_steps : inclusion_proof -> int

  val verify_inclusion_proof :
    inclusion_proof -> history_proof -> history_proof tzresult

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
    inbox_context ->
    History.t ->
    history_proof ->
    Raw_level_repr.t * Z.t ->
    (proof * Sc_rollup_PVM_sig.inbox_message option) tzresult Lwt.t

  val empty : inbox_context -> Raw_level_repr.t -> t Lwt.t

  module Internal_for_tests : sig
    val eq_tree : tree -> tree -> bool

    val produce_inclusion_proof :
      History.t ->
      history_proof ->
      history_proof ->
      inclusion_proof option tzresult

    val serialized_proof_of_string : string -> serialized_proof

    val inbox_message_counter : t -> Z.t
  end
end

module type P = sig
  module Tree : Context.TREE with type key = string list and type value = bytes

  type t = Tree.t

  type tree = Tree.tree

  val commit_tree : Tree.t -> string list -> Tree.tree -> unit Lwt.t

  val lookup_tree : Tree.t -> Hash.t -> tree option Lwt.t

  type proof

  val proof_encoding : proof Data_encoding.t

  val proof_before : proof -> Hash.t

  val verify_proof :
    proof -> (tree -> (tree * 'a) Lwt.t) -> (tree * 'a) option Lwt.t

  val produce_proof :
    Tree.t -> tree -> (tree -> (tree * 'a) Lwt.t) -> (proof * 'a) option Lwt.t
end

module Make_hashing_scheme (P : P) :
  Merkelized_operations with type tree = P.tree and type inbox_context = P.t =
struct
  module Tree = P.Tree

  type inbox_context = P.t

  type tree = P.tree

  let hash_level_tree level_tree = Hash.of_context_hash (Tree.hash level_tree)

  let set_number_of_messages tree number_of_messages =
    let number_of_messages_bytes =
      Data_encoding.Binary.to_bytes_exn Data_encoding.n number_of_messages
    in
    Tree.add tree number_of_messages_key number_of_messages_bytes

  (** Initialise the merkle tree for a new level in the inbox. *)
  let new_level_tree ctxt =
    let tree = Tree.empty ctxt in
    set_number_of_messages tree Z.zero

  let add_message inbox payload level_tree =
    let open Lwt_result_syntax in
    let message_index = inbox.message_counter in
    let message_counter = Z.succ message_index in
    let*! level_tree =
      Tree.add
        level_tree
        (key_of_message message_index)
        (Bytestring.to_bytes
           (payload : Sc_rollup_inbox_message_repr.serialized :> Bytestring.t))
    in
    let*! level_tree = set_number_of_messages level_tree message_counter in
    let nb_messages_in_commitment_period =
      Int64.succ inbox.nb_messages_in_commitment_period
    in
    let inbox =
      {
        current_level_proof = inbox.current_level_proof;
        level = inbox.level;
        old_levels_messages = inbox.old_levels_messages;
        message_counter;
        nb_messages_in_commitment_period;
      }
    in
    return (level_tree, inbox)

  let get_message_payload level_tree message_index =
    let open Lwt_syntax in
    let key = key_of_message message_index in
    let* bytes = Tree.(find level_tree key) in
    return
    @@ Option.map
         (fun bs ->
           Sc_rollup_inbox_message_repr.unsafe_of_string
             (Bytestring.of_bytes bs))
         bytes

  (** [no_history] creates an empty history with [capacity] set to
      zero---this makes the [remember] function a no-op. We want this
      behaviour in the protocol because we don't want to store
      previous levels of the inbox. *)
  let no_history = History.empty ~capacity:0L

  let take_snapshot inbox = inbox.old_levels_messages

  let key_of_level level =
    let level_bytes =
      Data_encoding.Binary.to_bytes_exn Raw_level_repr.encoding level
    in
    Bytes.to_string level_bytes

  let commit_tree ctxt tree inbox_level =
    let key = [key_of_level inbox_level] in
    P.commit_tree ctxt key tree

  let form_history_proof ctxt history inbox level_tree =
    let open Lwt_result_syntax in
    let*! () =
      let*! tree =
        match level_tree with
        | Some tree -> Lwt.return tree
        | None -> new_level_tree ctxt
      in
      commit_tree ctxt tree inbox.level
    in
    let prev_cell = inbox.old_levels_messages in
    let prev_cell_ptr = hash_history_proof prev_cell in
    let*? history = History.remember prev_cell_ptr prev_cell history in
    let level_proof = current_level_proof inbox in
    let cell = Skip_list.next ~prev_cell ~prev_cell_ptr level_proof in
    return (history, cell)

  (** [archive_if_needed ctxt history inbox new_level level_tree]
      is responsible for ensuring that the {!add_messages} function
      below has a correctly set-up [level_tree] to which to add the
      messages. If [new_level] is a higher level than the current inbox,
      we create a new inbox level tree at that level in which to start
      adding messages, and archive the earlier levels depending on the
      [history] parameter's [capacity]. If [level_tree] is [None] (this
      happens when the inbox is first created) we similarly create a new
      empty level tree.

      This function and {!form_history_proof} are the only places we
      begin new level trees. *)
  let archive_if_needed ctxt history inbox new_level level_tree =
    let open Lwt_result_syntax in
    if Raw_level_repr.(inbox.level = new_level) then
      match level_tree with
      | Some tree -> return (history, inbox, tree)
      | None ->
          let*! tree = new_level_tree ctxt in
          return (history, inbox, tree)
    else
      let* history, old_levels_messages =
        form_history_proof ctxt history inbox level_tree
      in
      let*! tree = new_level_tree ctxt in
      let inbox =
        {
          current_level_proof = inbox.current_level_proof;
          nb_messages_in_commitment_period =
            inbox.nb_messages_in_commitment_period;
          old_levels_messages;
          level = new_level;
          message_counter = Z.zero;
        }
      in
      return (history, inbox, tree)

  let add_messages ctxt history inbox level payloads level_tree =
    let open Lwt_result_syntax in
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
    let* history, inbox, level_tree =
      archive_if_needed ctxt history inbox level level_tree
    in
    let* level_tree, inbox =
      List.fold_left_es
        (fun (level_tree, inbox) payload ->
          add_message inbox payload level_tree)
        (level_tree, inbox)
        payloads
    in
    let current_level_proof () =
      let hash = hash_level_tree level_tree in
      {hash; level}
    in
    return (level_tree, history, {inbox with current_level_proof})

  let add_messages_no_history ctxt inbox level payloads level_tree =
    let open Lwt_result_syntax in
    let+ level_tree, _, inbox =
      add_messages ctxt no_history inbox level payloads level_tree
    in
    (level_tree, inbox)

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

  let verify_inclusion_proof inclusion_proof snapshot_history_proof =
    let open Result_syntax in
    let rec aux (hash_map, ptr_list) = function
      | [] -> error (Inbox_proof_error "inclusion proof is empty")
      | [target] ->
          let target_ptr = hash_history_proof target in
          let hash_map = Hash.Map.add target_ptr target hash_map in
          let ptr_list = target_ptr :: ptr_list in
          ok (hash_map, List.rev ptr_list, target, target_ptr)
      | history_proof :: tail ->
          let ptr = hash_history_proof history_proof in
          aux (Hash.Map.add ptr history_proof hash_map, ptr :: ptr_list) tail
    in
    let* hash_map, ptr_list, target, target_ptr =
      aux (Hash.Map.empty, []) inclusion_proof
    in
    let deref ptr = Hash.Map.find ptr hash_map in
    let cell_ptr = hash_history_proof snapshot_history_proof in
    let* () =
      error_unless
        (Skip_list.valid_back_path
           ~equal_ptr:Hash.equal
           ~deref
           ~cell_ptr
           ~target_ptr
           ptr_list)
        (Inbox_proof_error "invalid inclusion proof")
    in
    return target

  type proof =
    (* See the main docstring for this type (in the mli file) for
       definitions of the three proof parameters [starting_point],
       [message] and [snapshot]. In the below we deconstruct
       [starting_point] into [(l, n)] where [l] is a level and [n] is a
       message index.

       In a [Single_level] proof, [history_proof] is the skip list cell for the
       level [l], [inc] is an inclusion proof of [history_proof] into [snapshot]
       and [message_proof] is a tree proof showing that

         [exists level_tree .
              (hash_level_tree level_tree = level.content)
          AND (get_messages_payload n level_tree = (_, message))]

       Note: in the case that [message] is [None] this shows that there's no
       value at the index [n]; in this case we also must check that
       [history_proof] equals [snapshot] (otherwise, we'd need a [Next_level]
       proof instead. *)
    | Single_level of {inc : inclusion_proof; message_proof : P.proof}
    (* See the main docstring for this type (in the mli file) for
       definitions of the three proof parameters [starting_point],
       [message] and [snapshot]. In the below we deconstruct
       [starting_point] as [(l, n)] where [l] is a level and [n] is a
       message index.

       In a [Next_level] proof, [lower_history_proof] is the skip list cell for
       the level [l], [inc] is an inclusion proof of [lower_history_proof] into
       [snapshot] and [lower_message_proof] is a tree proof showing that there
       is no message at [(l, n)] with [lower_message_proof].

       The first message to read at the next level of [l] is the
       first input [Start_of_level].
    *)
    | Next_level of {lower_message_proof : P.proof; inc : inclusion_proof}

  let pp_proof fmt proof =
    match proof with
    | Single_level _ -> Format.fprintf fmt "Single_level inbox proof"
    | Next_level _ -> Format.fprintf fmt "Next_level inbox proof"

  let proof_encoding =
    let open Data_encoding in
    union
      ~tag_size:`Uint8
      [
        case
          ~title:"Single_level"
          (Tag 0)
          (obj2
             (req "inclusion_proof" inclusion_proof_encoding)
             (req "message_proof" P.proof_encoding))
          (function
            | Single_level {inc; message_proof} -> Some (inc, message_proof)
            | _ -> None)
          (fun (inc, message_proof) -> Single_level {inc; message_proof});
        case
          ~title:"Next_level"
          (Tag 1)
          (obj2
             (req "lower_message_proof" P.proof_encoding)
             (req "inclusion_proof" inclusion_proof_encoding))
          (function
            | Next_level {lower_message_proof; inc} ->
                Some (lower_message_proof, inc)
            | _ -> None)
          (fun (lower_message_proof, inc) ->
            Next_level {lower_message_proof; inc});
      ]

  let of_serialized_proof (p : Bytestring.t) =
    Data_encoding.Binary.of_string_opt proof_encoding (p :> string)

  let to_serialized_proof p =
    Data_encoding.Binary.to_string_exn proof_encoding p |> Bytestring.of_string

  let proof_error reason =
    let open Lwt_result_syntax in
    tzfail (Inbox_proof_error reason)

  let check p reason = unless p (fun () -> proof_error reason)

  (** To construct or verify a tree proof we need a function of type

      [tree -> (tree, result) Lwt.t]

      where [result] is some data extracted from the tree that we care about
      proving. [payload_and_message_tree n] is such a function, used for checking
      the message at a particular index, [n].

      For this function, the [result] is

      [payload : Sc_rollup_inbox_message_repr.serialized option]

      where [payload] is [None] if there was no message at the index. *)
  let payload_and_message_tree n tree =
    let open Lwt_syntax in
    let* payload = get_message_payload tree n in
    return (tree, payload)

  (** Utility function that handles all the verification needed for a
      particular message proof at a particular level. It calls
      [P.verify_proof], but also checks the proof has the correct
      [P.proof_before] hash. *)
  let check_message_proof message_proof level_hash n label =
    let open Lwt_result_syntax in
    let* () =
      check
        (Hash.equal level_hash (P.proof_before message_proof))
        (Format.sprintf "message_proof (%s) does not match history" label)
    in
    let*! result = P.verify_proof message_proof (payload_and_message_tree n) in
    match result with
    | None -> proof_error (Format.sprintf "message_proof is invalid (%s)" label)
    | Some (_, payload_opt) -> return payload_opt

  let verify_proof (l, n) snapshot proof =
    assert (Z.(geq n zero)) ;
    let open Lwt_result_syntax in
    match proof with
    | Single_level {inc; message_proof} -> (
        let*? history_proof = verify_inclusion_proof inc snapshot in
        let level_proof = Skip_list.content history_proof in
        let* payload_opt =
          check_message_proof message_proof level_proof.hash n "single level"
        in
        match payload_opt with
        | None ->
            if equal_history_proof snapshot history_proof then return_none
            else proof_error "payload is None but proof.level not top level"
        | Some payload ->
            return_some
              Sc_rollup_PVM_sig.{inbox_level = l; message_counter = n; payload})
    | Next_level {inc; lower_message_proof} -> (
        let*? lower_history_proof = verify_inclusion_proof inc snapshot in
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/3975
           We could prove that the last message to read is SOL, and is
           before [n]. *)
        let lower_level_proof = Skip_list.content lower_history_proof in
        let* should_be_none =
          check_message_proof
            lower_message_proof
            lower_level_proof.hash
            n
            "lower"
        in
        match should_be_none with
        | None ->
            let*? payload =
              Sc_rollup_inbox_message_repr.(serialize (Internal Start_of_level))
            in
            let inbox_level = Raw_level_repr.succ l in
            let message_counter = Z.zero in
            return_some
              Sc_rollup_PVM_sig.{inbox_level; message_counter; payload}
        | Some _ -> proof_error "more messages to read in current level")

  (** Utility function; we convert all our calls to be consistent with
      [Lwt_result_syntax]. *)
  let option_to_result e lwt_opt =
    let open Lwt_syntax in
    let* opt = lwt_opt in
    match opt with None -> proof_error e | Some x -> return (ok x)

  let produce_proof ctxt history inbox (l, n) =
    let open Lwt_result_syntax in
    let deref ptr = History.find ptr history in
    let compare {hash = _; level} = Raw_level_repr.compare level l in
    let result = Skip_list.search ~deref ~compare ~cell:inbox in
    let* inc, history_proof =
      match result with
      | Skip_list.{rev_path; last_cell = Found history_proof} ->
          return (List.rev rev_path, history_proof)
      | {last_cell = Nearest _; _}
      | {last_cell = No_exact_or_lower_ptr; _}
      | {last_cell = Deref_returned_none; _} ->
          (* We are only interested to the result where [search] than a
             path to the cell we were looking for. All the other cases
             should be considered as an error. *)
          proof_error
            (Format.asprintf
               "Skip_list.search failed to find a valid path: %a"
               (Skip_list.pp_search_result ~pp_cell:pp_history_proof)
               result)
    in
    let* level_tree =
      option_to_result
        "could not find level_tree in the inbox_context"
        (P.lookup_tree ctxt (Skip_list.content history_proof).hash)
    in
    let* message_proof, payload_opt =
      option_to_result
        "failed to produce message proof for level_tree"
        (P.produce_proof ctxt level_tree (payload_and_message_tree n))
    in
    match payload_opt with
    | Some payload ->
        return
          ( Single_level {inc; message_proof},
            Some
              Sc_rollup_PVM_sig.{inbox_level = l; message_counter = n; payload}
          )
    | None ->
        if equal_history_proof inbox history_proof then
          return (Single_level {inc; message_proof}, None)
        else
          let lower_message_proof = message_proof in
          let* input_given =
            let inbox_level = Raw_level_repr.succ l in
            let message_counter = Z.zero in
            let*? payload =
              Sc_rollup_inbox_message_repr.(serialize (Internal Start_of_level))
            in
            return_some
              Sc_rollup_PVM_sig.{inbox_level; message_counter; payload}
          in
          return (Next_level {inc; lower_message_proof}, input_given)

  let empty context level =
    let open Lwt_syntax in
    let pre_genesis_level = Raw_level_repr.root in
    let* initial_level = new_level_tree context in
    let* () = commit_tree context initial_level pre_genesis_level in
    let initial_level_proof =
      let hash = hash_level_tree initial_level in
      {hash; level = pre_genesis_level}
    in
    return
      {
        level;
        message_counter = Z.zero;
        nb_messages_in_commitment_period = 0L;
        current_level_proof = (fun () -> initial_level_proof);
        old_levels_messages = Skip_list.genesis initial_level_proof;
      }

  module Internal_for_tests = struct
    let eq_tree = Tree.equal

    let produce_inclusion_proof history a b =
      let open Result_syntax in
      let cell_ptr = hash_history_proof b in
      let target_index = Skip_list.index a in
      let* history = History.remember cell_ptr b history in
      let deref ptr = History.find ptr history in
      Skip_list.back_path ~deref ~cell_ptr ~target_index
      |> Option.map (lift_ptr_path deref)
      |> Option.join |> return

    let serialized_proof_of_string x = Bytestring.of_string x

    let inbox_message_counter = inbox_message_counter
  end
end

include (
  Make_hashing_scheme (struct
    module Tree = struct
      include Context.Tree

      type t = Context.t

      type tree = Context.tree

      type value = bytes

      type key = string list
    end

    type t = Context.t

    type tree = Context.tree

    let commit_tree _ctxt _key _tree =
      (* This is a no-op in the protocol inbox implementation *)
      Lwt.return ()

    let lookup_tree _ctxt _hash =
      (* We cannot find the tree without a full inbox_context *)
      Lwt.return None

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
    Merkelized_operations
      with type tree = Context.tree
       and type inbox_context = Context.t)

type inbox = t
