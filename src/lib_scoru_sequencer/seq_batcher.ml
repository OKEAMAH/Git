(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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
open Octez_smart_rollup_node_alpha.Batcher_worker_types
open Durable_state
module Message_queue = Hash_queue.Make (L2_message.Hash) (L2_message)

let worker_name = "seq_batcher"

module Batcher_events = struct
  include Batcher_events.Declare (struct
    let worker_name = worker_name
  end)

  let batched =
    declare_3
      ~section
      ~name:"batched_sequence"
      ~msg:
        "Batched Sequence consuming messages from delayed inbox queue in range \
         {delayed_inbox_pointer}, and {l2_messages} user messages. Scheduled \
         for injection as {l1_operation_hash}"
      ~level:Notice
      ("delayed_inbox_pointer", Kernel_durable.Delayed_inbox.Pointer.encoding)
      ("l2_messages", Data_encoding.int32)
      ("l1_operation_hash", Injector.Inj_operation.Hash.encoding)

  let optimistic_simulation_advanced =
    declare_3
      ~section
      ~name:"optimistic_simulation_advanced"
      ~msg:
        "Optimistic simulation advanced, {total_consumed} messages are \
         expected to be fed to the user kernel so far. Next message to process \
         has level: {last_level} and index {last_index}"
      ~level:Notice
      ("total_consumed", Data_encoding.int32)
      ("last_level", Data_encoding.int32)
      ("last_index", Data_encoding.int32)

  let emit_optimistic_simulation_advanced (sim_ctxt : Optimistic_simulation.t) =
    (emit optimistic_simulation_advanced)
      ( Int32.of_int sim_ctxt.tot_messages_consumed,
        sim_ctxt.inbox_level,
        Int32.of_int @@ List.length sim_ctxt.accumulated_messages )
end

type state = {
  node_ctxt : Node_context.ro;
  signer : Signature.V0.public_key_hash * Client_keys.sk_uri;
      (* This one is V0 because sequencer kernel doesn't support BLS signatures yet *)
  block_finality : int;
      (** Having block with level X, a block with level X - [block_finality] and less cannot reorg. *)
  mutable last_injected_nonce : int32;
      (** Sequence with [last_injected_nonce] nonce has been scheduled for injection. *)
  mutable new_messages : Sc_rollup.Inbox_message.serialized list;
      (** User messages received from RPC which will be included in the next Sequence *)
  mutable simulation_ctxt : Optimistic_simulation.t option;
}

let encode_sequence state =
  Kernel_message.encode_and_sign_sequence
    (state.node_ctxt.cctxt, snd state.signer)
    state.node_ctxt.rollup_address

module Optimistic_simulation = Optimistic_simulation.Make (struct
  type signer_ctxt = state

  let encode_sequence = encode_sequence
end)

let get_simulation_ctxt_exn state =
  let open Lwt_result_syntax in
  match state.simulation_ctxt with
  | None ->
      failwith "Simulation context of sequencer hasn't been initialized yet"
  | Some opt -> return opt

(** Represents sequence of messages ready to be injected. *)
type sequence_batch = {
  delayed_inbox_pointer : Kernel_durable.Delayed_inbox.Pointer.t;
      (** Delayed inbox range which will be consumed by the sequence *)
  l2_messages : Sc_rollup.Inbox_message.serialized list;
      (** Messages to be sent within the sequence *)
  nonce : int32;
  encoded_sequence : string;  (** Encoded and signed sequence message *)
}

(* Schedule sequencer message for injection, return L1 operation hash. *)
let inject_sequence ~source {encoded_sequence; _} =
  let operation = L1_operation.Add_messages {messages = [encoded_sequence]} in
  Injector.add_pending_operation ~source operation

(* Create Sequence message out of received messages and
   finalized delayed inbox messages. *)
let cut_sequence state =
  let open Lwt_result_syntax in
  let* sim_ctxt = get_simulation_ctxt_exn state in
  (* Assuming at the moment that all the registered messages fit into a single L2 message.
     This logic will be extended later. *)
  let delayed_inbox_pointer = sim_ctxt.current_block_diff in
  let l2_messages = List.rev @@ state.new_messages in
  let delayed_inbox_size =
    Kernel_durable.Delayed_inbox.Pointer.size delayed_inbox_pointer
  in
  let new_nonce = Int32.succ state.last_injected_nonce in
  let+ sequence_signed =
    encode_sequence
      state
      ~nonce:new_nonce
      ~prefix:(Int32.pred delayed_inbox_size)
      ~suffix:1l
      l2_messages
  in
  {
    delayed_inbox_pointer;
    l2_messages;
    nonce = new_nonce;
    encoded_sequence = sequence_signed;
  }

(* This one finalises current Sequence, schedule it for injection
   and update optimistic simulation context with new head *)
let batch_sequence state new_head =
  let open Lwt_result_syntax in
  let* sequence = cut_sequence state in
  let* l1_op_hash =
    inject_sequence
      ~source:(Signature.Of_V0.public_key_hash @@ fst state.signer)
      sequence
  in
  let*! () =
    Batcher_events.(emit batched)
      ( sequence.delayed_inbox_pointer,
        Int32.of_int @@ List.length sequence.l2_messages,
        l1_op_hash )
  in
  let* new_block_delayed_inbox_diff =
    get_delayed_inbox_diff state.node_ctxt new_head
  in
  let* cur_sim_ctxt = get_simulation_ctxt_exn state in
  let* new_sim_ctxt =
    Optimistic_simulation.new_block
      state
      state.node_ctxt
      cur_sim_ctxt
      new_block_delayed_inbox_diff
  in
  state.last_injected_nonce <- sequence.nonce ;
  state.new_messages <- [] ;
  state.simulation_ctxt <- Some new_sim_ctxt ;
  let*! () = Batcher_events.emit_optimistic_simulation_advanced new_sim_ctxt in
  return_unit

(* Maximum size of single L2 message.
   If a L2 message size exceeds it,
   it means we won't be even able to create a Sequence with this message only. *)
let max_single_l2_msg_size =
  Protocol.Constants_repr.sc_rollup_message_size_limit
  - Kernel_message.single_l2_message_overhead
  - 4 (* each L2 message prepended with it size *)

(*** HANDLERS IMPLEMENTATION ***)
let on_register_messages state (messages : string list) =
  let open Lwt_result_syntax in
  let*? messages =
    List.mapi_e
      (fun i message ->
        if String.length message > max_single_l2_msg_size then
          error_with
            "Message %d is too large (max size is %d)"
            i
            max_single_l2_msg_size
        else Ok (L2_message.make message))
      messages
  in
  let*? external_serialized_messages =
    List.map_e
      (fun m ->
        Sc_rollup.Inbox_message.(serialize @@ External (L2_message.content m)))
      messages
    |> Environment.wrap_tzresult
  in
  let* current_simulation_ctxt = get_simulation_ctxt_exn state in
  let* new_sim_ctxt =
    Optimistic_simulation.append_messages
      state
      state.node_ctxt
      current_simulation_ctxt
      external_serialized_messages
  in
  state.new_messages <-
    List.rev_append external_serialized_messages state.new_messages ;
  state.simulation_ctxt <- Some new_sim_ctxt ;
  let*! () = Batcher_events.(emit queue) (List.length messages) in
  let*! () = Batcher_events.emit_optimistic_simulation_advanced new_sim_ctxt in
  return @@ List.map L2_message.hash messages

let on_new_head state (head : Layer1.head) =
  let open Lwt_result_syntax in
  let genesis_level = state.node_ctxt.genesis_info.level in
  let first_block_finalization_level =
    Int32.add (Int32.succ genesis_level) (Int32.of_int state.block_finality)
  in
  if head.level = Int32.succ genesis_level then (
    (* Init simulation context *)
    let* first_delayed_inbox_diff =
      get_delayed_inbox_diff state.node_ctxt head
    in
    let* sim_ctxt =
      Optimistic_simulation.init_ctxt
        state
        state.node_ctxt
        first_delayed_inbox_diff
    in
    state.simulation_ctxt <- Some sim_ctxt ;
    let*! () = Batcher_events.emit_optimistic_simulation_advanced sim_ctxt in
    return_unit)
  else if head.level > first_block_finalization_level then
    batch_sequence state head
  else return_unit

let init_batcher_state node_ctxt ~signer =
  let open Lwt_result_syntax in
  let* _alias, _pk, sk =
    Client_keys.V0.get_key node_ctxt.Node_context.cctxt signer
  in
  return
    {
      node_ctxt;
      signer = (signer, sk);
      (* TODO: restore all the variables below from persistent storage *)
      last_injected_nonce = 0l;
      (* TODO: Make block finality argument of init *)
      block_finality = 0;
      new_messages = [];
      simulation_ctxt = None;
    }

module Types = struct
  type nonrec state = state

  type parameters = {
    node_ctxt : Node_context.ro;
    signer : Signature.public_key_hash;
  }
end

module Name = struct
  (* We only have a single batcher in the node *)
  type t = unit

  let encoding = Data_encoding.unit

  let base = [Protocol.name; "sc_sequencer_node"; worker_name; "worker"]

  let pp _ _ = ()

  let equal () () = true
end

module Worker = Worker.MakeSingle (Name) (Request) (Types)

type worker = Worker.infinite Worker.queue Worker.t

module Handlers = struct
  type self = worker

  let on_request :
      type r request_error.
      worker -> (r, request_error) Request.t -> (r, request_error) result Lwt.t
      =
   fun w request ->
    let state = Worker.state w in
    match request with
    | Request.Register messages ->
        protect @@ fun () -> on_register_messages state messages
    | Request.New_head head -> protect @@ fun () -> on_new_head state head

  type launch_error = error trace

  let on_launch _w () Types.{node_ctxt; signer} =
    let open Lwt_result_syntax in
    let to_v0_exn pkh =
      match
        Signature.V0.Public_key_hash.of_bytes
        @@ Signature.Public_key_hash.to_bytes pkh
      with
      | Error _ ->
          invalid_arg
            "Only Ed25519, Secp256k1, P256 keys are supported as an operator \
             key"
      | Ok x -> x
    in
    let* state = init_batcher_state node_ctxt ~signer:(to_v0_exn signer) in
    return state

  let on_error (type a b) _w st (r : (a, b) Request.t) (errs : b) :
      unit tzresult Lwt.t =
    let open Lwt_result_syntax in
    let request_view = Request.view r in
    let emit_and_return_errors errs =
      let*! () =
        Batcher_events.(emit Worker.request_failed) (request_view, st, errs)
      in
      return_unit
    in
    match r with
    | Request.Register _ -> emit_and_return_errors errs
    | Request.New_head _ -> emit_and_return_errors errs

  let on_completion _w r _ st =
    match Request.view r with
    | Request.View (Register _ | New_head _) ->
        Batcher_events.(emit Worker.request_completed_debug) (Request.view r, st)

  let on_no_request _ = Lwt.return_unit

  let on_close _w = Lwt.return_unit
end

let table = Worker.create_table Queue

let worker_promise, worker_waker = Lwt.task ()

let init _conf ~signer node_ctxt =
  let open Lwt_result_syntax in
  let node_ctxt = Node_context.readonly node_ctxt in
  let+ worker = Worker.launch table () {node_ctxt; signer} (module Handlers) in
  Lwt.wakeup worker_waker worker

(* This is a batcher worker for a single scoru *)
let worker =
  let open Result_syntax in
  lazy
    (match Lwt.state worker_promise with
    | Lwt.Return worker -> return worker
    | Lwt.Fail _ | Lwt.Sleep -> tzfail Sc_rollup_node_errors.No_batcher)

let handle_request_error rq =
  let open Lwt_syntax in
  let* rq in
  match rq with
  | Ok res -> return_ok res
  | Error (Worker.Request_error errs) -> Lwt.return_error errs
  | Error (Closed None) -> Lwt.return_error [Worker_types.Terminated]
  | Error (Closed (Some errs)) -> Lwt.return_error errs
  | Error (Any exn) -> Lwt.return_error [Exn exn]

let register_messages messages =
  let open Lwt_result_syntax in
  let*? w = Lazy.force worker in
  Worker.Queue.push_request_and_wait w (Request.Register messages)
  |> handle_request_error

let new_head b =
  let open Lwt_result_syntax in
  let w = Lazy.force worker in
  match w with
  | Error _ ->
      (* There is no batcher, nothing to do *)
      return_unit
  | Ok w ->
      let*! (_pushed : bool) =
        Worker.Queue.push_request w (Request.New_head b)
      in
      return_unit

let shutdown () =
  let w = Lazy.force worker in
  match w with
  | Error _ ->
      (* There is no batcher, nothing to do *)
      Lwt.return_unit
  | Ok w -> Worker.shutdown w

let get_simulation_state () =
  let open Lwt_result_syntax in
  let*? w = Lazy.force worker in
  let state = Worker.state w in
  let+ sim_ctxt = get_simulation_ctxt_exn state in
  sim_ctxt.state

let get_simulated_state_value key =
  let open Lwt_result_syntax in
  let* sim_state = get_simulation_state () in
  let*! result = lookup_user_kernel sim_state key in
  return result

let get_simulated_state_subkeys key =
  let open Lwt_result_syntax in
  let* sim_state = get_simulation_state () in
  let*! result = list_user_kernel sim_state key in
  return result
