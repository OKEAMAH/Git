(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Protocol.Apply_results
open Tezos_shell_services
open Protocol_client_context
open Protocol.Alpha_context

(* TODO/TORU: don't reapply whole inbox on update *)
let interp_messages ctxt messages cumulated_size =
  let open Lwt_syntax in
  let+ (ctxt, _ctxt_hash, rev_contents) =
    List.fold_left_s
      (fun (ctxt, ctxt_hash, acc) message ->
        let+ apply_res = Apply.apply_message ctxt message in
        let (ctxt, ctxt_hash, result) =
          match apply_res with
          | Ok (ctxt, result) ->
              (* The message was successfully interpreted but the status in
                 [result] may indicate that the application failed. The context
                 may have been modified with e.g. updated counters. *)
              (ctxt, Context.hash ctxt, Inbox.Interpreted result)
          | Error err ->
              (* The message was discarded before attempting to interpret it. The
                 context is not modified. For instance if a batch is unparsable,
                 or the BLS signature is incorrect, or a counter is wrong, etc. *)
              (ctxt, ctxt_hash, Inbox.Discarded err)
        in
        let inbox_message = {Inbox.message; result; context_hash = ctxt_hash} in
        (ctxt, ctxt_hash, inbox_message :: acc))
      (ctxt, Context.hash ctxt, [])
      messages
  in
  let contents = List.rev rev_contents in
  let inbox = Inbox.{contents; cumulated_size} in
  (ctxt, inbox)

let compute_messages block_info rollup_id =
  let managed_operation =
    List.nth_opt
      block_info.Alpha_block_services.operations
      State.rollup_operation_index
  in
  let get_message :
      type kind.
      kind contents ->
      kind contents_result ->
      (Tx_rollup_message.t * int) option =
   fun op result ->
    match (op, result) with
    | ( Manager_operation
          {
            operation =
              Tx_rollup_submit_batch {tx_rollup; content; burn_limit = _};
            _;
          },
        Manager_operation_result
          {operation_result = Applied (Tx_rollup_submit_batch_result _); _} )
      when Tx_rollup.equal rollup_id tx_rollup ->
        (* Batch message *)
        Some (Tx_rollup_message.make_batch content)
    | ( Manager_operation
          {
            operation =
              Transaction
                {amount; parameters; destination = Tx_rollup dst; entrypoint};
            _;
          },
        Manager_operation_result
          {operation_result = Applied (Transaction_result _); _} )
      when Tx_rollup.equal dst rollup_id
           && Entrypoint.(entrypoint = Tx_rollup.deposit_entrypoint) ->
        (* Deposit *)
        (* TODO/TORU *)
        ignore (amount, parameters) ;
        assert false
    | (_, _) -> None
  in
  let rec get_related_messages :
      type kind.
      Tx_rollup_message.t list ->
      int ->
      kind contents_and_result_list ->
      Tx_rollup_message.t list * int =
   fun acc cumulated_size -> function
    | Single_and_result (op, result) -> (
        match get_message op result with
        | None -> (List.rev acc, cumulated_size)
        | Some (message, size) ->
            (List.rev (message :: acc), cumulated_size + size))
    | Cons_and_result (op, result, rest) ->
        let (acc, cumulated_size) =
          match get_message op result with
          | None -> (acc, cumulated_size)
          | Some (message, size) -> (message :: acc, cumulated_size + size)
        in
        get_related_messages acc cumulated_size rest
  in
  let finalize_receipt (acc, cumulated_size) operation =
    match Alpha_block_services.(operation.protocol_data, operation.receipt) with
    | ( Operation_data {contents = operation_contents; _},
        Some (Operation_metadata {contents = result_contents}) ) -> (
        match kind_equal_list operation_contents result_contents with
        | Some Eq ->
            let operation_and_result =
              pack_contents_list operation_contents result_contents
            in
            get_related_messages acc cumulated_size operation_and_result
        | None -> (acc, cumulated_size))
    | (_, Some No_operation_metadata) | (_, None) -> (acc, cumulated_size)
  in
  match managed_operation with
  | None -> ([], 0)
  | Some managed_operations ->
      List.fold_left finalize_receipt ([], 0) managed_operations

let process_messages_and_inboxes (state : State.t) ~predecessor_context_hash
    block_info rollup_id =
  let open Lwt_result_syntax in
  let current_hash = block_info.Alpha_block_services.hash in
  (* let predecessor_hash = block_info.header.shell.predecessor in
   * let*! predecessor_context_hash = State.context_hash state predecessor_hash in *)
  let*! predecessor_context =
    match predecessor_context_hash with
    | None ->
        (* Rollup Genesis *)
        Lwt.return (Context.empty state.context_index)
    | Some context_hash ->
        (* Known predecessor *)
        (* TODO/TORU: don't checkout from disk unless reorg *)
        Context.checkout_exn state.context_index context_hash
  in
  let (messages, cumulated_size) =
    extract_messages_from_block block_info rollup_id
  in
  let*! () = Event.(emit messages_application) (List.length messages) in
  let*! (context, inbox) =
    interp_messages predecessor_context messages cumulated_size
  in
  let* () = State.save_inbox state current_hash inbox in
  let*! context_hash = Context.commit context in
  let*! () =
    Event.(emit inbox_stored)
      (current_hash, inbox.contents, inbox.cumulated_size, context_hash)
  in
  let* () = State.save_context_hash state current_hash context_hash in
  return_unit

let rec process_hash cctxt state rollup_genesis current_hash rollup_id =
  let open Lwt_result_syntax in
  let chain = cctxt#chain in
  let block = `Hash (current_hash, 0) in
  let* block_info = Alpha_block_services.info cctxt ~chain ~block () in
  process_block cctxt state rollup_genesis block_info rollup_id

and process_block cctxt state rollup_genesis block_info rollup_id =
  let open Lwt_result_syntax in
  let current_hash = block_info.hash in
  let predecessor_hash = block_info.header.shell.predecessor in
  (* TODO/TORU: What if rollup_genesis is on another branch, i.e. in a reorg? *)
  if Block_hash.equal rollup_genesis current_hash then return_unit
  else
    let*! context_hash = State.context_hash state current_hash in
    match context_hash with
    | Some _ ->
        (* Already processed *)
        let*! () = Event.(emit block_already_seen) current_hash in
        return_unit
    | None ->
        let*! predecessor_context_hash =
          State.block_already_seen state predecessor_hash
        in
        let* () =
          match predecessor_context_hash with
          | None ->
              let*! () =
                Event.(emit processing_block_predecessor) predecessor_hash
              in
              process_hash cctxt state rollup_genesis predecessor_hash rollup_id
          | Some _ ->
              (* Predecessor known *)
              return_unit
        in
        let*! () =
          Event.(emit processing_block) (current_hash, predecessor_hash)
        in
        let* () =
          process_messages_and_inboxes
            state
            ~predecessor_context_hash
            block_info
            rollup_id
        in
        let* () = State.set_new_head state current_hash in
        let*! () = Event.(emit new_tezos_head) current_hash in
        let*! () = Event.(emit block_processed) current_hash in
        return_unit

let process_inboxes cctxt state rollup_genesis current_hash rollup_id =
  let open Lwt_result_syntax in
  let*! () = Event.(emit new_block) current_hash in
  let* () = process_hash cctxt state rollup_genesis current_hash rollup_id in
  return_unit

let main_exit_callback state data_dir exit_status =
  let open Lwt_syntax in
  let* () = Stores.close data_dir in
  let* () = Context.close state.State.context_index in
  let* () = Event.(emit node_is_shutting_down) exit_status in
  Tezos_base_unix.Internal_event_unix.close ()

let rec connect ~delay cctxt =
  let open Lwt_syntax in
  let* res = Monitor_services.heads cctxt cctxt#chain in
  match res with
  | Ok (stream, stopper) -> Error_monad.return (stream, stopper)
  | Error _ ->
      let* () = Event.(emit cannot_connect) delay in
      let* () = Lwt_unix.sleep delay in
      connect ~delay cctxt

let valid_history_mode = function
  | History_mode.Archive | History_mode.Full _ -> true
  | _ -> false

let run ~data_dir cctxt =
  let open Lwt_result_syntax in
  let*! () = Event.(emit starting_node) () in
  let* ({data_dir; rollup_id; rollup_genesis; reconnection_delay; _} as
       configuration) =
    Configuration.load ~data_dir
  in
  let* state =
    State.init ~data_dir ~context:cctxt ~rollup:rollup_id ~rollup_genesis
  in
  let* _rpc_server = RPC.start configuration state in
  let _ =
    (* Register cleaner callback *)
    Lwt_exit.register_clean_up_callback
      ~loc:__LOC__
      (main_exit_callback state configuration.data_dir)
  in
  let* (_, _, _, history_mode) = Chain_services.checkpoint cctxt () in
  let* () =
    fail_unless
      (valid_history_mode history_mode)
      (Error.Tx_rollup_invalid_history_mode history_mode)
  in
  let rec loop () =
    let* () =
      Lwt.catch
        (fun () ->
          let* (block_stream, interupt) =
            connect ~delay:reconnection_delay cctxt
          in
          let*! () =
            Lwt_stream.iter_s
              (fun (current_hash, _header) ->
                let*! r =
                  process_inboxes
                    cctxt
                    state
                    rollup_genesis
                    current_hash
                    rollup_id
                in
                match r with
                | Ok () -> Lwt.return ()
                | Error e ->
                    Format.eprintf "%a@." pp_print_trace e ;
                    let () = interupt () in
                    Lwt.return ())
              block_stream
          in
          let*! () = Event.(emit connection_lost) () in
          loop ())
        fail_with_exn
    in
    Lwt_utils.never_ending ()
  in
  loop ()
