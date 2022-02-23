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

(* TODO/TORU: Move application logic in other module *)

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

(* TODO/TORU return proper errors or option *)
let parse_tx_rollup_l2_address :
    Script.node -> Protocol.Tx_rollup_l2_address.Indexable.value tzresult =
  let open Protocol in
  let open Micheline in
  function
  | Bytes (_loc, bytes) (* As unparsed with [Optimized]. *) -> (
      match Tx_rollup_l2_address.of_bytes_opt bytes with
      | Some txa -> ok (Tx_rollup_l2_address.Indexable.value txa)
      | None -> error_with "Not a valid transaction rollup L2 address")
  | String (_loc, str) (* As unparsed with [Readable]. *) -> (
      match Tx_rollup_l2_address.of_b58check_opt str with
      | Some txa -> ok (Tx_rollup_l2_address.Indexable.value txa)
      | None -> error_with "Not a valid transaction rollup L2 address")
  | _expr -> error_with "Not a valid transaction rollup L2 address"

(* TODO/TORU: return proper errors or option *)
(* TODO/TORU: expose uncarbonated parse_tx_rollup_deposit_parameters in protocol *)
let parse_tx_rollup_deposit_parameters :
    Script.expr -> Tx_rollup.deposit_parameters tzresult =
 fun parameters ->
  let open Micheline in
  let open Protocol in
  (* /!\ This pattern matching needs to remain in sync with the
     Script_ir_translator.parse_tx_rollup_deposit_parameters. *)
  match root parameters with
  | Seq
      ( _,
        [
          Prim
            ( _,
              D_Pair,
              [
                Prim
                  ( _,
                    D_Pair,
                    [ticketer; Prim (_, D_Pair, [contents; amount], _)],
                    _ );
                bls;
              ],
              _ );
          ty;
        ] ) ->
      parse_tx_rollup_l2_address bls >>? fun destination ->
      (match amount with
      | Int (_, v) when Compare.Z.(Z.zero < v && v <= Z.of_int64 Int64.max_int)
        ->
          ok @@ Tx_rollup_l2_qty.of_int64_exn (Z.to_int64 v)
      | Int (_, _) -> error_with "Tx_rollup_invalid_ticket_amount"
      | _expr -> error_with "Invalid deposit")
      >|? fun amount -> Tx_rollup.{ticketer; contents; ty; amount; destination}
  | _expr -> error_with "Invalid deposit"

(* TODO/TORU: return proper errors or option *)
(* TODO/TORU: expose uncarbonated hash_ticket in protocol *)
let hash_ticket tx_rollup ~contents ~ticketer ~ty =
  let open Protocol in
  let open Micheline in
  let hash_of_node node =
    let node = Micheline.strip_locations node in
    match Data_encoding.Binary.to_bytes_opt Script_repr.expr_encoding node with
    | Some bytes ->
        ok
          (Ticket_hash.of_script_expr_hash
          @@ Script_expr_hash.hash_bytes [bytes])
    | None -> error_with "Failed_to_hash_node"
  in
  let make ~ticketer ~ty ~contents ~owner =
    hash_of_node
    @@ Micheline.Seq (Micheline.dummy_location, [ticketer; ty; contents; owner])
  in
  let owner = String (dummy_location, Tx_rollup.to_b58check tx_rollup) in
  make ~ticketer ~ty ~contents ~owner

let extract_messages_from_block block_info rollup_id =
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
                {
                  amount = _;
                  parameters;
                  destination = Tx_rollup dst;
                  entrypoint;
                };
            _;
          },
        Manager_operation_result
          {operation_result = Applied (Transaction_result _); _} )
      when Tx_rollup.equal dst rollup_id
           && Entrypoint.(entrypoint = Tx_rollup.deposit_entrypoint) -> (
        (* Deposit message *)
        match Data_encoding.force_decode parameters with
        | None -> None
        | Some parameters -> (
            match parse_tx_rollup_deposit_parameters parameters with
            | Error _ -> None
            | Ok Tx_rollup.{ticketer; contents; ty; amount; destination} -> (
                match hash_ticket dst ~contents ~ticketer ~ty with
                | Error _ -> None
                | Ok ticket_hash ->
                    Some
                      (Tx_rollup_message.make_deposit
                         destination
                         ticket_hash
                         amount))))
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
