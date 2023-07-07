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
module Fueled_pvm = Fueled_pvm.Free

type t = {
  current_block_diff : Delayed_inbox.Pointer.t;
  inbox_level : int32;
  ctxt : Context.ro;
  state : Context.tree;
  tot_messages_consumed : int;
  accumulated_messages : Sc_rollup.Inbox_message.serialized list;
  block_beginning : Context.tree;
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

module Simple = struct
  include Internal_event.Simple

  let section = ["sequencer_node"]

  let simulation_kernel_debug =
    declare_1
      ~section
      ~name:"simulation_kernel_debug"
      ~level:Info
      ~msg:"Simulation debug: {log}"
      ("log", Data_encoding.string)
      ~pp1:Format.pp_print_string
end

let simulation_kernel_debug msg = Simple.(emit simulation_kernel_debug) msg

let init_empty_ctxt node_ctxt (first_block : Delayed_inbox.Pointer.t) =
  let open Lwt_result_syntax in
  let genesis_level = node_ctxt.Node_context.genesis_info.level in
  let* genesis_hash = Node_context.hash_of_level node_ctxt genesis_level in
  let genesis_head = Layer1.{hash = genesis_hash; level = genesis_level} in
  let* ctxt = Node_context.checkout_context node_ctxt genesis_hash in
  let+ ctxt, state = Interpreter.state_of_head node_ctxt ctxt genesis_head in
  {
    ctxt;
    (* It will be incremeneted in new_block_impl straight away *)
    inbox_level = node_ctxt.Node_context.genesis_info.level;
    state;
    current_block_diff = first_block;
    tot_messages_consumed = 0;
    accumulated_messages = [];
    block_beginning = state;
  }

let simulate (node_ctxt : Node_context.ro)
    ({ctxt; inbox_level; accumulated_messages; block_beginning; _} as sim)
    messages =
  let open Lwt_result_syntax in
  let module PVM = (val Pvm.of_kind node_ctxt.kind) in
  let*! block_beginning_hash = PVM.state_hash block_beginning in
  let*! tick = PVM.get_tick block_beginning in
  let accumulated_messages = List.rev_append messages accumulated_messages in
  let*? eol =
    Sc_rollup.Inbox_message.serialize
      (Sc_rollup.Inbox_message.Internal End_of_level)
    |> Environment.wrap_tzresult
  in
  let eval_state =
    Fueled_pvm.
      {
        state = block_beginning;
        state_hash = block_beginning_hash;
        tick;
        inbox_level;
        message_counter_offset = 0;
        remaining_fuel = Fuel.Free.of_ticks 0L;
        remaining_messages =
          List.map Sc_rollup.Inbox_message.unsafe_to_string
          @@ List.rev (eol :: accumulated_messages);
      }
  in
  let node_ctxt =
    Node_context.{node_ctxt with kernel_debug_logger = simulation_kernel_debug}
  in
  let* eval_result = Fueled_pvm.eval_messages node_ctxt eval_state in
  (* Build new state *)
  let Fueled_pvm.{state = {state; _}; _} =
    Delayed_write_monad.ignore eval_result
  in
  let*! ctxt = PVM.State.set ctxt state in
  return {sim with ctxt; state; accumulated_messages}

let ensure_diff_is_valid (current_diff : Delayed_inbox.Pointer.t option)
    (new_diff : Delayed_inbox.queue_slice) =
  let open Lwt_result_syntax in
  let* () =
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
  in
  let open Sc_rollup.Inbox_message in
  let els = new_diff.elements in
  match (els, List.last_opt els) with
  | sol :: ipl :: _, Some eol -> (
      let*? sol_ = Environment.wrap_tzresult @@ deserialize sol in
      let*? ipl_ = Environment.wrap_tzresult @@ deserialize ipl in
      let*? eol_ = Environment.wrap_tzresult @@ deserialize eol in
      match (sol_, ipl_, eol_) with
      | ( Internal Start_of_level,
          Internal (Info_per_level _),
          Internal End_of_level ) ->
          return (List.take_n (List.length els - 1) els, eol)
      | _ ->
          tzfail
            (Exn
               (Failure
                  "Boundaries messages are expected to be SoL, IpL, .. EoL")))
  | _ ->
      tzfail
        (Exn
           (Failure
              "Block diff has to include at least SoL, IpL and EoL messages"))

module Make (Enc : Messages_encoder) = struct
  (* First supply block diff to the sequencer kernel but the last EoL,
     all of them will land in the delayed inbox queue.
     Then suppply Sequence that consumes all those messages from the delayed inbox. *)
  let new_block_impl ?current_block_diff signer_ctxt node_ctxt sim_ctxt
      new_block_diff =
    let open Lwt_result_syntax in
    let* all_but_eol, _eol =
      ensure_diff_is_valid current_block_diff new_block_diff
    in
    (* If we already started a first block, we have to close it up with EoL,
       which is supposed to be on the head of the queue. *)
    let is_first_block = Option.is_none current_block_diff in
    (* First, move sim_ctxt to state where EoL of the current block is supplied.
       To do so we just need to update block beginning state to state as it's basically needed one,
       reset accumulated messages and update current_block_diff *)
    let sim_ctxt =
      {
        sim_ctxt with
        accumulated_messages = [];
        block_beginning = sim_ctxt.state;
        inbox_level = Int32.succ sim_ctxt.inbox_level;
        current_block_diff = new_block_diff.pointer;
      }
    in
    let* populated_delayed_inbox_ctxt =
      simulate node_ctxt sim_ctxt all_but_eol
    in
    let diff_size =
      Kernel_durable.Delayed_inbox.Pointer.size new_block_diff.pointer
    in
    let to_consume =
      if is_first_block then
        (* In this case, it's our first block, hence, no EoL from previous level *)
        Int32.pred diff_size
      else
        (* In this case delayed inbox looks like:
           EoL[from previous level], SoL[new level], IpL[new level], ..., .
           We need to consume first EoL and the rest of the messages,
           what brings us to diff_size elements to consume.
        *) diff_size
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
        consumed_delayed_inbox_ctxt with
        tot_messages_consumed =
          consumed_delayed_inbox_ctxt.tot_messages_consumed
          + Int32.to_int to_consume;
      }

  let init_ctxt signer_ctxt node_ctxt (first_block : Delayed_inbox.queue_slice)
      =
    let open Lwt_result_syntax in
    let* init_ctxt = init_empty_ctxt node_ctxt first_block.pointer in
    new_block_impl signer_ctxt node_ctxt init_ctxt first_block

  let new_block signer_ctxt node_ctxt sim_state block_delayed_inbox_diff =
    new_block_impl
      ~current_block_diff:sim_state.current_block_diff
      signer_ctxt
      node_ctxt
      sim_state
      block_delayed_inbox_diff

  (* Construct Sequence consisting of the passed blocks and passes it to the sequencer kernel *)
  let append_messages signer_ctxt node_ctxt sim_state
      external_serialized_messages =
    let open Lwt_result_syntax in
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
    let+ consumed_ctxt =
      simulate node_ctxt sim_state [wrapping_sequence_external]
    in
    {
      consumed_ctxt with
      tot_messages_consumed =
        consumed_ctxt.tot_messages_consumed
        + List.length external_serialized_messages;
    }
end
