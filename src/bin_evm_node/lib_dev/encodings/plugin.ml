(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

let block_to_string bytes =
  let decoded = Ethereum_types.block_from_rlp bytes in
  Data_encoding.Json.(
    construct Ethereum_types.block_encoding decoded |> to_string)

let transaction_receipt_to_string bytes =
  let block_hash =
    Ethereum_types.block_hash_of_string
      "d28d009fef5019bd9b353d7d9d881bde4870d3c5e418b1faf05fd9f7540994d8"
  in
  let decoded = Ethereum_types.transaction_object_from_rlp block_hash bytes in
  Data_encoding.Json.(
    construct Ethereum_types.transaction_object_encoding decoded |> to_string)

let transaction_object_to_string bytes =
  let block_hash =
    Ethereum_types.block_hash_of_string
      "d28d009fef5019bd9b353d7d9d881bde4870d3c5e418b1faf05fd9f7540994d8"
  in
  let decoded = Ethereum_types.transaction_object_from_rlp block_hash bytes in
  Data_encoding.Json.(
    construct Ethereum_types.transaction_object_encoding decoded |> to_string)

let () =
  Octez_smart_rollup_wasm_debugger_plugin.Encodings.register
    "evm.block"
    block_to_string ;
  Octez_smart_rollup_wasm_debugger_plugin.Encodings.register
    "evm.transaction_object"
    transaction_object_to_string ;
  Octez_smart_rollup_wasm_debugger_plugin.Encodings.register
    "evm.transaction_receipt"
    transaction_receipt_to_string
