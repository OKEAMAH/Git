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

let submit_transaction ?timeout client tx_data =
  Grpc_client.call ?timeout ~rpc:submit_transactions_rpc client tx_data
