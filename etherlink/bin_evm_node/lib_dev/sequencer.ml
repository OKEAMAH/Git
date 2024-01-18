(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

module MakeBackend (Ctxt : sig
  val ctxt : Sequencer_context.t

  val rollup_node_endpoint : Uri.t

  val secret_key : Signature.secret_key
end) : Services_backend_sig.Backend = struct
  module READER = struct
    let read path =
      let open Lwt_result_syntax in
      let* Sequencer_context.{evm_state; _} =
        Sequencer_context.sync Ctxt.ctxt
      in
      let*! res = Sequencer_state.inspect evm_state path in
      return res
  end

  module TxEncoder = struct
    let encode_transaction ~smart_rollup_address:_ ~transaction =
      let tx_hash_str = Ethereum_types.hash_raw_tx transaction in
      let tx_hash =
        Ethereum_types.(
          Hash Hex.(of_string tx_hash_str |> show |> hex_of_string))
      in
      Result_syntax.return (tx_hash, [transaction])
  end

  module TxPublisher = struct
    let publish_messages ~timestamp ~smart_rollup_address ~messages =
      let open Lwt_result_syntax in
      let* ctxt = Sequencer_context.sync Ctxt.ctxt in
      (* Create the blueprint with the messages. *)
      let (Ethereum_types.(Qty next) as number) = ctxt.next_blueprint_number in
      let inputs =
        Sequencer_blueprint.create
          ~secret_key:Ctxt.secret_key
          ~timestamp
          ~smart_rollup_address
          ~transactions:messages
          ~number
      in
      let* () =
        Rollup_node_services.publish
          ~rollup_node_endpoint:Ctxt.rollup_node_endpoint
          inputs
      in
      ctxt.next_blueprint_number <- Qty (Z.succ next) ;
      (* Execute the blueprint. *)
      let inputs =
        List.map
          (function `External payload -> `Input ("\001" ^ payload))
          inputs
      in
      let* _ctxt = Sequencer_state.execute ~commit:true ctxt inputs in
      return_unit
  end

  module SimulatorBackend = struct
    let simulate_and_read ~input =
      let open Lwt_result_syntax in
      let* ctxt = Sequencer_context.sync Ctxt.ctxt in
      let* raw_insights = Sequencer_state.execute_and_inspect ctxt ~input in
      match Simulation.Encodings.insights_from_list raw_insights with
      | Some i -> return i
      | None -> Error_monad.failwith "Invalid insights format"
  end
end

module Make (Ctxt : sig
  val ctxt : Sequencer_context.t

  val rollup_node_endpoint : Uri.t

  val secret_key : Signature.secret_key
end) =
  Services_backend_sig.Make (MakeBackend (Ctxt))
