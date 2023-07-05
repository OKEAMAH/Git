(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

open Protocol
open Alpha_context
open Octez_smart_rollup_node_alpha
open Kernel_durable

type t = {
  current_block_diff : Delayed_inbox.Pointer.t;
  simulation_ctxt : Simulation.t;
}

module type Messages_encoder = sig
  type signer_ctxt

  val encode_sequence :
    signer_ctxt ->
    nonce:int32 ->
    prefix:int32 ->
    suffix:int32 ->
    Sc_rollup.Inbox_message.serialized list ->
    string tzresult Lwt.t
end

module type S = sig
  type signer_ctxt

  val init_ctxt :
    signer_ctxt ->
    Node_context.ro ->
    Delayed_inbox.queue_slice ->
    Layer1.head ->
    t tzresult Lwt.t

  val new_block :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Delayed_inbox.queue_slice ->
    t tzresult Lwt.t

  val append_messages :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Sc_rollup.Inbox_message.serialized list ->
    t tzresult Lwt.t
end

let simulate node_ctxt simulation_ctxt
    (messages : Sc_rollup.Inbox_message.serialized list) =
  let open Lwt_result_syntax in
  let node_ctxt =
    Node_context.
      {node_ctxt with kernel_debug_logger = Event.simulation_kernel_debug}
  in
  let+ simulation_ctxt, _ticks =
    Simulation.simulate_messages
      node_ctxt
      ~prepend_meta_messages:false
      simulation_ctxt
      messages
  in
  simulation_ctxt

let ensure_diff_is_valid (current_diff : Delayed_inbox.Pointer.t option)
    (new_diff : Delayed_inbox.queue_slice) =
  let open Lwt_result_syntax in
  (* TODO make sure it refers to the sequence [SoL, IpL, m1, m2, ... EoL] *)
  let* () =
    fail_unless
      Compare.Int32.(Delayed_inbox.Pointer.size new_diff.pointer >= 3l)
      (Exn
         (Failure "Block diff has to include at least SoL, IpL and EoL messages"))
  in
  match current_diff with
  | None ->
      fail_unless
        Compare.Int32.(new_diff.pointer.head = 0l)
        (Exn
           (Failure
              "First block's messages have to be the first in the delayed \
               inbox queue"))
  | Some current_diff ->
      fail_unless
        (Delayed_inbox.Pointer.is_adjacent current_diff new_diff.pointer)
        (Exn
           (Failure
              "Two consecutive blocks' message have to be adjacent in the \
               delayed inbox queue"))

module Make (Enc : Messages_encoder) = struct
  let new_block_impl ?current_block_diff signer_ctxt node_ctxt ~sim_ctxt
      ~new_block_diff =
    let open Lwt_result_syntax in
    let* () = ensure_diff_is_valid current_block_diff new_block_diff in
    (* If we already started a first block, we have to close it up with EoL,
       which is supposed to be on the head of the queue. *)
    let need_consume_previous_eol = Option.is_some current_block_diff in
    (* First, supply all of the diff messages,
       which will be added to the delayed inbox. *)
    let* populated_delayed_inbox_ctxt =
      simulate node_ctxt sim_ctxt new_block_diff.elements
    in
    let diff_size =
      Kernel_durable.Delayed_inbox.Pointer.size new_block_diff.pointer
    in
    let to_consume =
      if need_consume_previous_eol then
        (* In this case delayed inbox looks like:
           EoL[from previous level], SoL[new level], IpL[new level], ..., EoL[new_level].
           We need to consume first EoL and not consume last EoL,
           what brings us to diff_size elements to consume.
        *) diff_size
      else
        (* In this case, it's our first block, hence, no EoL from previous level *)
        Int32.pred diff_size
    in
    (* TODO: fetch optimistic nonce *)
    let* consume_inbox_sequence =
      Enc.encode_sequence signer_ctxt ~nonce:0l ~prefix:to_consume ~suffix:0l []
    in
    let*? wrapping_sequence_external =
      Environment.wrap_tzresult
      @@ Sc_rollup.Inbox_message.(serialize @@ External consume_inbox_sequence)
    in
    let* consumed_delayed_inbox_ctxt =
      simulate
        node_ctxt
        populated_delayed_inbox_ctxt
        [wrapping_sequence_external]
    in
    return
      {
        current_block_diff = new_block_diff.pointer;
        simulation_ctxt = consumed_delayed_inbox_ctxt;
      }

  let init_ctxt signer_ctxt node_ctxt first_block block_head =
    let open Lwt_result_syntax in
    (* TODO remove it *)
    let* block_head = Node_context.get_predecessor node_ctxt block_head in
    let* sim_ctxt =
      Simulation.init_simulation_ctxt ~reveal_map:None node_ctxt block_head
    in
    new_block_impl signer_ctxt node_ctxt ~sim_ctxt ~new_block_diff:first_block

  let new_block signer_ctxt node_ctxt sim_state block_delayed_inbox_diff =
    new_block_impl
      signer_ctxt
      node_ctxt
      ~current_block_diff:sim_state.current_block_diff
      ~sim_ctxt:sim_state.simulation_ctxt
      ~new_block_diff:block_delayed_inbox_diff

  let append_messages signer_ctxt node_ctxt sim_state
      external_serialized_messages =
    let open Lwt_result_syntax in
    (* TODO explain this part *)
    (* TODO fetch nonce from simulation durable storage *)
    let* encoded_wrapping_sequence =
      Enc.encode_sequence
        signer_ctxt
        ~nonce:0l
        ~prefix:0l
        ~suffix:0l
        external_serialized_messages
    in
    let*? wrapping_sequence_external =
      Environment.wrap_tzresult
      @@ Sc_rollup.Inbox_message.(
           serialize @@ External encoded_wrapping_sequence)
    in
    let+ new_simulation_ctxt =
      simulate node_ctxt sim_state.simulation_ctxt [wrapping_sequence_external]
    in
    {sim_state with simulation_ctxt = new_simulation_ctxt}
end
