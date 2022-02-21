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
let messages_to_inbox ctxt messages =
  let open Lwt_result_syntax in
  let+ (ctxt, rev_contents, cumulated_size) =
    List.fold_left_es
      (fun (ctxt, acc, total_size) message ->
        let (batch, size) = Tx_rollup_message.make_batch message in
        let+ ctxt = Apply.apply_batch ctxt batch in
        let context_hash = Context.hash ctxt in
        let inbox_message = {Inbox.message = batch; context_hash} in
        (ctxt, inbox_message :: acc, total_size + size))
      (ctxt, [], 0)
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
  let rec get_related_messages :
      type kind. string list -> kind contents_and_result_list -> string list =
   fun acc -> function
    | Single_and_result
        ( Manager_operation
            {
              operation =
                Tx_rollup_submit_batch {tx_rollup; content; burn_limit = _};
              _;
            },
          Manager_operation_result
            {operation_result = Applied (Tx_rollup_submit_batch_result _); _} )
      when Tx_rollup.equal rollup_id tx_rollup ->
        List.rev (content :: acc)
    | Cons_and_result
        ( Manager_operation
            {
              operation =
                Tx_rollup_submit_batch {tx_rollup; content; burn_limit = _};
              _;
            },
          Manager_operation_result
            {operation_result = Applied (Tx_rollup_submit_batch_result _); _},
          xs )
      when Tx_rollup.equal rollup_id tx_rollup ->
        get_related_messages (content :: acc) xs
    | Single_and_result _ -> List.rev acc
    | Cons_and_result (_, _, xs) -> get_related_messages acc xs
  in
  let finalize_receipt operation =
    match Alpha_block_services.(operation.protocol_data, operation.receipt) with
    | ( Operation_data {contents = operation_contents; _},
        Some (Operation_metadata {contents = result_contents}) ) -> (
        match kind_equal_list operation_contents result_contents with
        | Some Eq ->
            let operation_and_result =
              pack_contents_list operation_contents result_contents
            in
            get_related_messages [] operation_and_result
        | None -> [])
    | (_, Some No_operation_metadata) | (_, None) -> []
  in
  match managed_operation with
  | None -> []
  | Some managed_operations ->
      (* We can use [List.concat_map] because we do not expect many batches per
         rollup and per block. *)
      managed_operations |> List.concat_map finalize_receipt

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
  let messages = compute_messages block_info rollup_id in
  let messages_len = List.length messages in
  let* (context, inbox) = messages_to_inbox predecessor_context messages in
  let*! () = Event.(emit messages_application) messages_len in
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
