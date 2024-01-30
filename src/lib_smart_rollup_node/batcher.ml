(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Batcher_worker_types
module Message_queue = Hash_queue.Make (L2_message.Hash) (L2_message)

module Batcher_events = Batcher_events.Declare (struct
  let worker_name = "batcher"
end)

module L2_batched_message = struct
  type t = {content : string; l1_hash : Injector.Inj_operation.hash}
end

module Batched_messages = Hash_queue.Make (L2_message.Hash) (L2_batched_message)

module Int_cache =
  Aches_lwt.Lache.Make_result
    (Aches.Rache.Transfer
       (Aches.Rache.LRU)
       (struct
         include Int

         let hash x = x
       end))

type status = Pending_batch | Batched of Injector.Inj_operation.hash

type last_seen_head = {block_hash : Block_hash.t; level : int32}

type state = {
  config : Configuration.t;
  messages : Message_queue.t;
  batched : Batched_messages.t;
  mutable plugin : (module Protocol_plugin_sig.S);
  mutable last_seen_head : last_seen_head option;
  mutable stop : unit -> unit Lwt.t;
}

let message_size s =
  (* Encoded as length of s on 4 bytes + s *)
  4 + String.length s

let inject_batch state (l2_messages : L2_message.t list) =
  let open Lwt_result_syntax in
  let messages = List.map L2_message.content l2_messages in
  let operation = L1_operation.Add_messages {messages} in
  let* l1_hash =
    Injector.check_and_add_pending_operation state.config.mode operation
  in
  let+ l1_hash =
    match l1_hash with
    | Some l1_hash -> return l1_hash
    | None ->
        let op = Injector.Inj_operation.make operation in
        return op.hash
  in
  List.iter
    (fun msg ->
      let content = L2_message.content msg in
      let hash = L2_message.hash msg in
      Batched_messages.replace state.batched hash {content; l1_hash})
    l2_messages

let inject_batches state = List.iter_es (inject_batch state)

let max_batch_size {config; plugin; _} =
  let module Plugin = (val plugin) in
  Option.value
    config.batcher.max_batch_size
    ~default:Plugin.Batcher_constants.protocol_max_batch_size

let get_batches state ~only_full =
  let ( current_rev_batch,
        current_batch_size,
        current_batch_elements,
        full_batches ) =
    Message_queue.fold
      (fun msg_hash
           message
           ( current_rev_batch,
             current_batch_size,
             current_batch_elements,
             full_batches ) ->
        let size = message_size (L2_message.content message) in
        let new_batch_size = current_batch_size + size in
        let new_batch_elements = current_batch_elements + 1 in
        if
          new_batch_size <= max_batch_size state
          && new_batch_elements <= state.config.batcher.max_batch_elements
        then
          (* We can add the message to the current batch because we are still
             within the bounds. *)
          ( (msg_hash, message) :: current_rev_batch,
            new_batch_size,
            new_batch_elements,
            full_batches )
        else
          (* The batch augmented with the message would be too big but it is
             below the limit without it. We finalize the current batch and
             create a new one for the message. NOTE: Messages in the queue are
             always < [state.conf.max_batch_size] because {!on_register} only
             accepts those. *)
          let batch = List.rev current_rev_batch in
          ([(msg_hash, message)], size, 1, batch :: full_batches))
      state.messages
      ([], 0, 0, [])
  in
  let batches =
    if
      (not only_full)
      || current_batch_size >= state.config.batcher.min_batch_size
         && current_batch_elements >= state.config.batcher.min_batch_elements
    then
      (* We have enough to make a batch with the last non-full batch. *)
      List.rev current_rev_batch :: full_batches
    else full_batches
  in
  List.fold_left
    (fun (batches, to_remove) -> function
      | [] -> (batches, to_remove)
      | batch ->
          let msg_hashes, batch = List.split batch in
          let to_remove = List.rev_append msg_hashes to_remove in
          (batch :: batches, to_remove))
    ([], [])
    batches

let produce_batches state ~only_full =
  let open Lwt_result_syntax in
  let batches, to_remove = get_batches state ~only_full in
  match batches with
  | [] -> return_unit
  | _ ->
      let* () = inject_batches state batches in
      let*! () =
        Batcher_events.(emit batched)
          (List.length batches, List.length to_remove)
      in
      List.iter
        (fun tr_hash -> Message_queue.remove state.messages tr_hash)
        to_remove ;
      return_unit

let on_register state (messages : string list) =
  let open Lwt_result_syntax in
  let module Plugin = (val state.plugin) in
  let max_size_msg =
    min
      (Plugin.Batcher_constants.message_size_limit
     + 4 (* We add 4 because [message_size] adds 4. *))
      (max_batch_size state)
  in
  let*? messages =
    List.mapi_e
      (fun i message ->
        if message_size message > max_size_msg then
          error_with "Message %d is too large (max size is %d)" i max_size_msg
        else Ok (L2_message.make message))
      messages
  in
  let*! () = Batcher_events.(emit queue) (List.length messages) in
  let hashes =
    List.map
      (fun message ->
        let msg_hash = L2_message.hash message in
        Message_queue.replace state.messages msg_hash message ;
        msg_hash)
      messages
  in
  let+ () = produce_batches state ~only_full:true in
  hashes

let on_new_head state = produce_batches state ~only_full:false

let init_batcher_state plugin config =
  {
    config;
    messages = Message_queue.create 100_000 (* ~ 400MB *);
    batched = Batched_messages.create 100_000 (* ~ 400MB *);
    plugin;
    last_seen_head = None;
    stop = (fun () -> Lwt.return_unit);
  }

module Types = struct
  type nonrec state = state

  type parameters = {
    config : Configuration.t;
    plugin : (module Protocol_plugin_sig.S);
  }
end

module Name = struct
  (* We only have a single batcher in the node *)
  type t = unit

  let encoding = Data_encoding.unit

  let base = Batcher_events.Worker.section @ ["worker"]

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
        protect @@ fun () -> on_register state messages
    | Request.Produce_batches -> protect @@ fun () -> on_new_head state

  type launch_error = error trace

  let on_launch _w () Types.{config; plugin} =
    let open Lwt_result_syntax in
    let state = init_batcher_state plugin config in
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
    | Request.Produce_batches -> emit_and_return_errors errs

  let on_completion _w r _ st =
    match Request.view r with
    | Request.View (Register _ | Produce_batches) ->
        Batcher_events.(emit Worker.request_completed_debug) (Request.view r, st)

  let on_no_request _ = Lwt.return_unit

  let on_close _w = Lwt.return_unit
end

let table = Worker.create_table Queue

let worker_promise, worker_waker = Lwt.task ()

let check_batcher_config (module Plugin : Protocol_plugin_sig.S)
    Configuration.{max_batch_size; _} =
  match max_batch_size with
  | Some m when m > Plugin.Batcher_constants.protocol_max_batch_size ->
      error_with
        "batcher.max_batch_size must be smaller than %d"
        Plugin.Batcher_constants.protocol_max_batch_size
  | _ -> Ok ()

let start plugin config =
  let open Lwt_result_syntax in
  let+ worker = Worker.launch table () {config; plugin} (module Handlers) in
  Lwt.wakeup worker_waker worker

let start_in_mode mode =
  let open Configuration in
  match mode with
  | Batcher | Operator -> true
  | Observer | Accuser | Bailout | Maintenance -> false
  | Custom ops -> purpose_matches_mode (Custom ops) Batching

let init plugin (config : Configuration.t) =
  let open Lwt_result_syntax in
  match Lwt.state worker_promise with
  | Lwt.Return _ ->
      (* Worker already started, nothing to do. *)
      return_unit
  | Lwt.Fail exn ->
      (* Worker crashed, not recoverable. *)
      fail [Rollup_node_errors.No_batcher; Exn exn]
  | Lwt.Sleep ->
      (* Never started, start it. *)
      if start_in_mode config.mode then start plugin config else return_unit

(* This is a batcher worker for a single scoru *)
let worker =
  lazy
    (match Lwt.state worker_promise with
    | Lwt.Return worker -> Ok worker
    | Lwt.Fail exn -> Error (Error_monad.error_of_exn exn)
    | Lwt.Sleep -> Error Rollup_node_errors.No_batcher)

let active () =
  match Lwt.state worker_promise with
  | Lwt.Return _ -> true
  | Lwt.Fail _ | Lwt.Sleep -> false

let find_message hash =
  let open Result_syntax in
  let+ w = Result.map_error TzTrace.make (Lazy.force worker) in
  let state = Worker.state w in
  Message_queue.find_opt state.messages hash

let get_queue () =
  let open Result_syntax in
  let+ w = Result.map_error TzTrace.make (Lazy.force worker) in
  let state = Worker.state w in
  Message_queue.bindings state.messages

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
  let* w = lwt_map_error TzTrace.make (Lwt.return (Lazy.force worker)) in
  Worker.Queue.push_request_and_wait w (Request.Register messages)
  |> handle_request_error

let produce_batches () =
  let open Lwt_result_syntax in
  match Lazy.force worker with
  | Error Rollup_node_errors.No_batcher ->
      (* There is no batcher, nothing to do *)
      return_unit
  | Error e -> tzfail e
  | Ok w ->
      Worker.Queue.push_request_and_wait w Request.Produce_batches
      |> handle_request_error

let shutdown () =
  let open Lwt_syntax in
  match Lazy.force worker with
  | Error _ ->
      (* There is no batcher, nothing to do *)
      return_unit
  | Ok w ->
      let state = Worker.state w in
      let* () = state.stop () in
      Worker.shutdown w

let message_status state msg_hash =
  let open Result_syntax in
  match Message_queue.find_opt state.messages msg_hash with
  | Some msg ->
      return (Some (L2_message.content msg), Rollup_node_services.Pending_batch)
  | None -> (
      match Batched_messages.find_opt state.batched msg_hash with
      | None -> return (None, Rollup_node_services.Unknown)
      | Some {content = msg; l1_hash} -> (
          let return status = return (Some msg, status) in
          match Injector.operation_status l1_hash with
          | None -> return Rollup_node_services.Unknown
          | Some (Pending op) ->
              return (Rollup_node_services.Pending_injection op)
          | Some (Injected {op; oph; op_index}) ->
              return
                (Rollup_node_services.Injected
                   {op = op.operation; oph; op_index})
          | Some (Included {op; oph; op_index; l1_block; l1_level}) ->
              let* w = Result.map_error TzTrace.make (Lazy.force worker) in
              let state = Worker.state w in
              let finalized =
                match state.last_seen_head with
                | None -> false
                | Some {level; _} -> level >= Int32.add l1_level 2l
              in
              let cemented =
                (* Default value, cementation status is not known by
                   autonomous batcher *)
                false
              in
              return
                (Rollup_node_services.Included
                   {
                     op = op.operation;
                     oph;
                     op_index;
                     l1_block;
                     l1_level;
                     finalized;
                     cemented;
                   })))

let message_status msg_hash =
  let open Result_syntax in
  let* w = Result.map_error TzTrace.make (Lazy.force worker) in
  let state = Worker.state w in
  message_status state msg_hash

module RPC_directory = struct
  module Local_directory = Rpc_directory_helpers.Make_directory (struct
    include Rollup_node_services.Local

    type context = unit

    type subcontext = unit

    let context_of_prefix () () = Lwt_result.return ()
  end)

  let () =
    Local_directory.register0 Rollup_node_services.Local.injection
    @@ fun _node_ctxt () messages -> register_messages messages

  let () =
    Local_directory.register0 Rollup_node_services.Local.batcher_queue
    @@ fun _node_ctxt () () ->
    let open Lwt_result_syntax in
    let*? queue = get_queue () in
    return queue

  let () =
    Local_directory.register1 Rollup_node_services.Local.batcher_message
    @@ fun () hash () () -> message_status hash |> Lwt.return
end

let rpc_directory = RPC_directory.Local_directory.build_directory ()

(** Retrieve next protocol of a block with a small cache from protocol levels to
    protocol hashes. *)
let next_protocol_of_block =
  let proto_levels_cache = Int_cache.create 7 in
  fun (cctxt : Client_context.full) (block_hash, (block_header : Block_header.t))
      ->
    let open Lwt_result_syntax in
    let proto_level = block_header.shell.proto_level in
    Int_cache.bind_or_put
      proto_levels_cache
      proto_level
      (fun _proto_level ->
        let+ protos =
          Tezos_shell_services.Shell_services.Blocks.protocols
            cctxt
            ~chain:cctxt#chain
            ~block:(`Hash (block_hash, 0))
            ()
        in
        protos.next_protocol)
      Lwt.return

let update_plugin state protocol =
  let open Result_syntax in
  let+ plugin = Protocol_plugins.proto_plugin_for_protocol protocol in
  state.plugin <- plugin

let rec monitor_l1_chain l1_ctxt cctxt state =
  let open Lwt_result_syntax in
  let*! res =
    Layer_1.iter_heads l1_ctxt @@ fun (head_hash, header) ->
    let head = {block_hash = head_hash; level = header.shell.level} in
    let* next_protocol = next_protocol_of_block cctxt (head_hash, header) in
    let*? () = update_plugin state next_protocol in
    (* Produces batches on level change *)
    let* () =
      match state.last_seen_head with
      | Some {level = last_level; _} when last_level >= header.shell.level ->
          return_unit
      | _ -> produce_batches ()
    in
    state.last_seen_head <- Some head ;
    let*! () = Injector.inject ~header:header.shell () in
    return_unit
  in
  (* Ignore errors *)
  let*! () =
    match res with
    | Error error ->
        Internal_event.Simple.emit Batcher_events.monitoring_error error
    | Ok () -> Lwt.return_unit
  in
  monitor_l1_chain l1_ctxt cctxt state

module Autonomous = struct
  let run ~data_dir config cctxt =
    let open Lwt_result_syntax in
    let*? plugin =
      Protocol_plugins.(proto_plugin_for_protocol @@ last_registered ())
    in
    let*? () = check_batcher_config plugin config.Configuration.batcher in
    let*? signers =
      match Purpose.find_operator Batching config.operators with
      | None -> error_with "No signers configured for batcher"
      | Some (Multiple []) -> error_with "No signers configured for batcher"
      | Some (Multiple pkhs) ->
          (* For the batcher we delay of 0.5 sec to allow more
             operations to get in. *)
          Ok
            [
              (pkhs, `Delay_block 0.5, Purpose.operation_kind (Purpose Batching));
            ]
    in
    let (module Plugin) = plugin in
    let* constants = Plugin.Layer1_helpers.retrieve_constants cctxt in
    let* () =
      Injector.init
        cctxt
        ~reconnection_delay:config.reconnection_delay
        {
          cctxt = (cctxt :> Client_context.full);
          fee_parameters = config.fee_parameters;
          minimal_block_delay = constants.minimal_block_delay;
          delay_increment_per_round = constants.delay_increment_per_round;
        }
        ~data_dir
        ~signers
        ~retention_period:config.injector.retention_period
        ~allowed_attempts:config.injector.attempts
    in
    let*! l1_ctxt =
      Layer_1.start
        ~name:"batcher"
        ~reconnection_delay:config.reconnection_delay
        cctxt
    in
    let* worker = Worker.launch table () {config; plugin} (module Handlers) in
    let state = Worker.state worker in
    Lwt.wakeup worker_waker worker ;
    let* rpc_server = Rpc_server.start config rpc_directory in
    let*! () =
      Event.node_is_ready ~rpc_addr:config.rpc_addr ~rpc_port:config.rpc_port
    in
    let monitoring_promise = monitor_l1_chain l1_ctxt cctxt state in
    state.stop <-
      (fun () ->
        let*! () = Rpc_server.shutdown rpc_server in
        let*! () =
          Injector.shutdown ~tags:(Purpose.operation_kind (Purpose Batching)) ()
        in
        Lwt.cancel monitoring_promise ;
        let*! () = Layer_1.shutdown l1_ctxt in
        Lwt.return_unit) ;
    Lwt_utils.never_ending ()
end
