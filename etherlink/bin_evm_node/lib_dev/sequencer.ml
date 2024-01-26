(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

module MakeBackend (Ctxt : sig
  val ctxt : Sequencer_context.t

  val secret_key : Signature.secret_key
end) : Services_backend_sig.Backend = struct
  module READER = struct
    let read path =
      let open Lwt_result_syntax in
      let* ctxt = Sequencer_context.sync Ctxt.ctxt in
      let*! evm_state = Sequencer_context.evm_state ctxt in
      let*! res = Sequencer_state.inspect evm_state path in
      return res
  end

  module TxEncoder = struct
    type transactions = {
      raw : string list;
      delayed : Ethereum_types.Delayed_transaction.t list;
    }

    type messages = transactions

    let encode_transactions ~smart_rollup_address:_
        ~(transactions : transactions) =
      let open Result_syntax in
      let delayed_hashes =
        List.map Ethereum_types.Delayed_transaction.hash transactions.delayed
      in
      let hashes =
        List.map
          (fun transaction ->
            let tx_hash_str = Ethereum_types.hash_raw_tx transaction in
            Ethereum_types.(
              Hash Hex.(of_string tx_hash_str |> show |> hex_of_string)))
          transactions.raw
      in
      return (delayed_hashes @ hashes, transactions)
  end

  module Publisher = struct
    type messages = TxEncoder.messages

    let publish_messages ~timestamp ~smart_rollup_address ~messages =
      let open Lwt_result_syntax in
      let* ctxt = Sequencer_context.sync Ctxt.ctxt in
      (* Create the blueprint with the messages. *)
      let blueprint =
        Sequencer_blueprint.create
          ~secret_key:Ctxt.secret_key
          ~timestamp
          ~smart_rollup_address
          ~transactions:messages.TxEncoder.raw
          ~number:ctxt.next_blueprint_number
      in
      (* Apply the blueprint *)
      let* _ctxt = Sequencer_context.apply_blueprint ctxt blueprint in
      return_unit
  end

  module SimulatorBackend = struct
    let simulate_and_read ~input =
      let open Lwt_result_syntax in
      let* ctxt = Sequencer_context.sync Ctxt.ctxt in
      let* raw_insights = Sequencer_context.execute_and_inspect ctxt ~input in
      match Simulation.Encodings.insights_from_list raw_insights with
      | Some i -> return i
      | None -> Error_monad.failwith "Invalid insights format"
  end
end

module Make (Ctxt : sig
  val ctxt : Sequencer_context.t

  val secret_key : Signature.secret_key
end) =
  Services_backend_sig.Make (MakeBackend (Ctxt))
