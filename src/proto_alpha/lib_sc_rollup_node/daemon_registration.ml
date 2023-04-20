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

module Protocol_daemon : Protocol_daemon_sig.S = struct
  module Node_context = struct
    include Node_context

    let last_processed_block node_ctxt =
      let open Lwt_result_syntax in
      let+ l2_block = last_processed_head_opt node_ctxt in
      let open Option_syntax in
      let+ {header = {block_hash; level; _}; _} = l2_block in
      (block_hash, Protocol.Alpha_context.Raw_level.to_int32 level)
  end

  module RPC_server = RPC_server

  let process_block (node_ctxt : _ Node_context.t) (hash, header) =
    let head = Layer1.{hash; level = header.Block_header.level} in
    Daemon.process_block node_ctxt head

  let on_layer_1_head_extra (_node_ctxt : _ Node_context.t) (hash, header) =
    let open Lwt_result_syntax in
    let head = Layer1.{hash; level = header.Block_header.level} in
    let* () = Publisher.publish_commitments () in
    let* () = Publisher.cement_commitments () in
    let* () = Refutation_coordinator.process head in
    let* () = Batcher.batch () in
    let* () = Batcher.new_head head in
    let*! () = Injector.inject (* ~header *) () in
    return_unit

  let enter_degraded_mode = Daemon.enter_degraded_mode

  let degraded_mode_on_block (hash, header) =
    let head = Layer1.{hash; level = header.Block_header.level} in
    Daemon.degraded_mode_on_block head

  let start_workers (configuration : Configuration.t)
      (node_ctxt : _ Node_context.t) =
    let open Lwt_result_syntax in
    let signers =
      Configuration.Operator_purpose_map.bindings node_ctxt.operators
      |> List.fold_left
           (fun acc (purpose, operator) ->
             let purposes =
               match Signature.Public_key_hash.Map.find operator acc with
               | None -> [purpose]
               | Some ps -> purpose :: ps
             in
             Signature.Public_key_hash.Map.add operator purposes acc)
           Signature.Public_key_hash.Map.empty
      |> Signature.Public_key_hash.Map.bindings
      |> List.map (fun (operator, purposes) ->
             let strategy =
               match purposes with
               | [Configuration.Add_messages] -> `Delay_block 0.5
               | _ -> `Each_block
             in
             (operator, strategy, purposes))
    in
    let* () = Publisher.init node_ctxt in
    let* () = Refutation_coordinator.init node_ctxt in
    let* () =
      Injector.init
        node_ctxt.cctxt
        (Node_context.readonly node_ctxt)
        ~data_dir:node_ctxt.data_dir
        ~signers
        ~retention_period:configuration.injector.retention_period
        ~allowed_attempts:configuration.injector.attempts
    in
    let* () =
      match
        Configuration.Operator_purpose_map.find Add_messages node_ctxt.operators
      with
      | None -> return_unit
      | Some signer -> Batcher.init configuration.batcher ~signer node_ctxt
    in
    return_unit

  let stop_workers node_ctxt =
    let open Lwt_result_syntax in
    let message = node_ctxt.Node_context.cctxt#message in
    let*! () = message "Shutting down Injector@." in
    let*! () = Injector.shutdown () in
    let*! () = message "Shutting down Batcher@." in
    let*! () = Batcher.shutdown () in
    let*! () = message "Shutting down Commitment Publisher@." in
    let*! () = Publisher.shutdown () in
    let*! () = message "Shutting down Refutation Coordinator@." in
    let*! () = Refutation_coordinator.shutdown () in
    return_unit
end

let () = Protocol_daemons.register Protocol.hash (module Protocol_daemon)
