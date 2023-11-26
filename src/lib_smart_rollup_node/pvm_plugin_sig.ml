(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

(** Evaluation state for the PVM.  *)
type ('fuel, 'tree) eval_state = {
  state : 'tree;  (** The actual PVM state. *)
  state_hash : State_hash.t;  (** Hash of [state]. *)
  tick : Z.t;  (** Tick of [state]. *)
  inbox_level : int32;  (** Inbox level in which messages are evaluated. *)
  message_counter_offset : int;
      (** Offset for message index, which corresponds to the number of
            messages of the inbox already evaluated.  *)
  remaining_fuel : 'fuel;
      (** Fuel remaining for the evaluation of the inbox. *)
  remaining_messages : string list;
      (** Messages of the inbox that remain to be evaluated.  *)
}

type ('fuel, 'tree) eval_result = {
  state : ('fuel, 'tree) eval_state;
  num_ticks : Z.t;
  num_messages : int;
}

module type FUELED_PVM = sig
  type fuel

  (** Evaluation result for the PVM which contains the evaluation state and
      additional information.  *)

  (** [eval_block_inbox ~fuel node_ctxt (inbox, messages) state] evaluates the
      [messages] for the [inbox] in the given [state] of the PVM and returns the
      evaluation result containing the new state, the number of messages, the
      inbox level and the remaining fuel. *)
  val eval_block_inbox :
    fuel:fuel ->
    (_, 'repo) Node_context_types.t ->
    Inbox.t * string list ->
    'tree ->
    ((fuel, 'tree) eval_result, 'repo) Node_context_types.delayed_write tzresult
    Lwt.t

  (** [eval_messages ?reveal_map ~fuel node_ctxt ~message_counter_offset state
      inbox_level messages] evaluates the [messages] for inbox level
      [inbox_level] in the given [state] of the PVM and returns the evaluation
      results containing the new state, the remaining fuel, and the number of
      ticks for the evaluation of these messages. If [messages] is empty, the
      PVM progresses until the next input request (within the allocated
      [fuel]). [message_counter_offset] is used when we evaluate partial
      inboxes, such as during simulation. When [reveal_map] is provided, it is
      used as an additional source of data for revelation ticks. *)
  val eval_messages :
    ?reveal_map:string Utils.Reveal_hash_map.t ->
    (_, 'repo) Node_context_types.t ->
    (fuel, 'tree) eval_state ->
    ((fuel, 'tree) eval_result, 'repo) Node_context_types.delayed_write tzresult
    Lwt.t
end

module type S = sig
  val context : (module Context.CONTEXT)

  val witness : ('repo, 'tree) Context.witness

  module Context : Context.CONTEXT

  val get_tick : Kind.t -> Context.tree -> Z.t Lwt.t

  val state_hash : Kind.t -> Context.tree -> State_hash.t Lwt.t

  val initial_state : Kind.t -> Context.tree Lwt.t

  val parse_boot_sector : Kind.t -> string -> string option

  val install_boot_sector :
    Kind.t -> Context.tree -> string -> Context.tree Lwt.t

  val get_status :
    _ Node_context_types.t -> Context.tree -> string tzresult Lwt.t

  val find_whitelist_update_output_index :
    _ Node_context_types.t ->
    Context.tree ->
    outbox_level:int32 ->
    int option Lwt.t

  val produce_serialized_output_proof :
    'repo Node_context_types.rw ->
    'tree ->
    outbox_level:int32 ->
    message_index:int ->
    string tzresult Lwt.t

  val get_current_level : Kind.t -> Context.tree -> int32 option Lwt.t

  val start_of_level_serialized : string

  val end_of_level_serialized : string

  val protocol_migration_serialized : string option

  val info_per_level_serialized :
    predecessor:Block_hash.t -> predecessor_timestamp:Time.Protocol.t -> string

  module Wasm_2_0_0 : sig
    (** [decode_durable_state enc tree] decodes a value using the encoder
        [enc] from the provided [tree] *)
    val decode_durable_state : 'a Tezos_tree_encoding.t -> 'tree -> 'a Lwt.t

    (** [proof_mem_tree t k] is false iff [find_tree k = None].*)
    val proof_mem_tree : 'tree -> string list -> bool Lwt.t

    (** [fold ?depth t root ~order ~init ~f] recursively folds over the trees and
        values of t. The f callbacks are called with a key relative to root. f is
        never called with an empty key for values; i.e., folding over a value is a no-op.

        The depth is 0-indexed. If depth is set (by default it is not), then f is only
        called when the conditions described by the parameter is true:

        - [Eq d] folds over nodes and values of depth exactly d.
        - [Lt d] folds over nodes and values of depth strictly less than d.
        - [Le d] folds over nodes and values of depth less than or equal to d.
        - [Gt d] folds over nodes and values of depth strictly more than d.
        - [Ge d] folds over nodes and values of depth more than or equal to d.

        If order is [`Sorted] (the default), the elements are traversed in lexicographic
        order of their keys. *)
    val proof_fold_tree :
      ?depth:Tezos_context_sigs.Context.depth ->
      'tree ->
      string list ->
      order:[`Sorted | `Undefined] ->
      init:'a ->
      f:(string list -> Context.tree -> 'a -> 'a Lwt.t) ->
      'a Lwt.t
  end

  module Fueled : sig
    module Free : FUELED_PVM with type fuel := Fuel.Free.t

    module Accounted : FUELED_PVM with type fuel := Fuel.Accounted.t
  end
end

type ('repo, 'tree) plugin =
  (module S with type Context.repo = 'repo and type Context.tree = 'tree)

let into (type repo tree) (w : (repo, tree) Context.witness) (module C : S) :
    (module S with type Context.repo = repo and type Context.tree = tree) =
  match Context.try_cast w C.Context.witness with
  | Some Context.Equal -> (module C)
  | None -> assert false
