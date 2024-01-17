(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 TriliTech    <contact@trili.tech>                      *)
(*                                                                           *)
(*****************************************************************************)

type t = H2_lwt_unix.Client.t

let make address port = Grpc_client.make address port

let submit_transactions_rpc =
  Grpc_client.Rpc.make
    Narwhal.Narwhal.Transactions.submitTransaction
    ~service:"narwhal.Transactions"
    ~method_:"SubmitTransaction"

let monitor_preblocks_rpc =
  Grpc_client.Rpc.make
    Exporter.Exporter.Exporter.export
    ~service:"exporter.Exporter"
    ~method_:"Export"

let submit_transaction ?timeout client tx_data =
  Grpc_client.call ?timeout ~rpc:submit_transactions_rpc client tx_data

let monitor_preblocks client ~since =
  let open Lwt_result_syntax in
  let* Grpc_client.{stream; _} =
    Grpc_client.streamed_call client ~rpc:monitor_preblocks_rpc since
  in
  return
  @@ Lwt_stream.map
       (fun subdag ->
         Result.map
           (fun Exporter.Exporter.SubDag.{payloads; _} ->
             let rev_txs =
               List.fold_left
                 (fun txs batches -> List.append (List.concat batches) txs)
                 []
                 payloads
             in
             List.rev rev_txs)
           subdag)
       stream
