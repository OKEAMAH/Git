(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
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

(** Mocked values used until we can retrieve the specific values from an EVM kernel. *)

open Ethereum_types

let return = Lwt_result_syntax.return

module Conv = struct
  let pow_18 = String.make 18 '0'

  (** WEI is the smallest denomination of ether.
        1 ETH = 1,000,000,000,000,000,000 WEI (10^18). *)
  let to_wei x = Z.of_string @@ Int.to_string x ^ pow_18
end

let hash_f = hash_of_string

let qty_f = quantity_of_z

(* Default chain_id for ethereum custom networks with Ganache. *)
let chain_id () = return (qty_f (Z.of_int 1337))

let kernel_version () = return "MOCKUP_KERNEL_VERSION"

let net_version = chain_id

let block_height_counter = ref 0

let block_height () = block_height_of_z @@ Z.of_int !block_height_counter

let balance = qty_f @@ Conv.to_wei 1000

let code _ =
  hash_f
    "0x608060405234801561001057600080fd5b5061017f806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c80634e70b1dc1461004657806360fe47b1146100645780636d4ce63c14610080575b600080fd5b61004e61009e565b60405161005b91906100d0565b60405180910390f35b61007e6004803603810190610079919061011c565b6100a4565b005b6100886100ae565b60405161009591906100d0565b60405180910390f35b60005481565b8060008190555050565b60008054905090565b6000819050919050565b6100ca816100b7565b82525050565b60006020820190506100e560008301846100c1565b92915050565b600080fd5b6100f9816100b7565b811461010457600080fd5b50565b600081359050610116816100f0565b92915050565b600060208284031215610132576101316100eb565b5b600061014084828501610107565b9150509291505056fea2646970667358221220ec57e49a647342208a1f5c9b1f2049bf1a27f02e19940819f38929bf67670a5964736f6c63430008120033"
  |> Lwt_result_syntax.return

(* Gas limit must be at least 21000 *)
let gas_price = qty_f @@ Z.of_int 21000

let transaction_counter = ref 0

let transaction_count () = qty_f @@ Z.of_int !transaction_counter

(* Transaction's hash must be an alphanumeric 66 utf8 byte
   hex (chars: a-fA-F) string *)
let transaction_hash =
  hash_f @@ "0xf837c23ac7150b486be21fc00e3e2ad118e12bec1e2bca401b999f544eabc402"

let block_hash =
  Block_hash "d28d009fef5019bd9b353d7d9d881bde4870d3c5e418b1faf05fd9f7540994d8"

let block transactions =
  {
    number = Some (block_height ());
    hash = Some block_hash;
    parent = Block_hash (String.make 64 'a');
    nonce = hash_f @@ String.make 16 'a';
    sha3Uncles = hash_f @@ String.make 64 'a';
    logsBloom = Some (hash_f @@ String.make 512 'a');
    transactionRoot = hash_f @@ String.make 64 'a';
    stateRoot = hash_f @@ String.make 64 'a';
    receiptRoot = hash_f @@ String.make 64 'a';
    miner = hash_f @@ String.make 40 'b';
    difficulty = qty_f Z.one;
    totalDifficulty = qty_f Z.one;
    extraData = "";
    size = qty_f @@ Z.of_int 12345;
    gasLimit = qty_f @@ Z.of_int 1111111;
    gasUsed = qty_f Z.zero;
    timestamp = qty_f Z.zero;
    transactions;
    uncles = [];
  }

let bootstrap_address =
  address_of_string "0x6F4d14B90C48bEFb49CA3fe6663dEC70731A8bC7"

let bootstrap_address2 =
  address_of_string "0xA5A5bf58c7Dc91cBE5005A7E5c6314998Eda479E"

let transaction_receipt () =
  {
    transactionHash = transaction_hash;
    transactionIndex = qty_f Z.zero;
    blockHash = block_hash;
    blockNumber = qty_f @@ Z.of_int !block_height_counter;
    from = bootstrap_address;
    to_ = Some bootstrap_address2;
    contractAddress =
      Some (address_of_string "0x6ce4d79d4e77402e1ef3417fdda433aa744c6e1c");
    cumulativeGasUsed = gas_price;
    effectiveGasPrice = gas_price;
    gasUsed = gas_price;
    logs = [];
    logsBloom = hash_f @@ String.make 512 'a';
    type_ = qty_f Z.zero;
    status = qty_f Z.one;
  }

let transaction_object =
  {
    blockHash = Some block_hash;
    blockNumber = Some (qty_f @@ Z.of_int 42);
    from = address_of_string "0x6F4d14B90C48bEFb49CA3fe6663dEC70731A8bC7";
    gas = qty_f Z.zero;
    gasPrice = qty_f Z.zero;
    hash = transaction_hash;
    input = empty_hash;
    nonce = qty_f Z.zero;
    to_ = Some (address_of_string "0xA5A5bf58c7Dc91cBE5005A7E5c6314998Eda479E");
    transactionIndex = qty_f Z.zero;
    value = qty_f Z.zero;
    v = qty_f Z.zero;
    r = hash_f @@ "00";
    s = hash_f @@ "00";
  }

let simulate_call _ = Lwt_result_syntax.return (hash_of_string "0x000102030405")

let estimate_gas _ = Lwt_result_syntax.return gas_price

let smart_rollup_address = return "foo"

let balance _addr = return balance

let nonce _addr = return (transaction_count ())

let inject_raw_transaction ~smart_rollup_address:_ _tx =
  incr block_height_counter ;
  incr transaction_counter ;
  return transaction_hash

let current_block ~full_transaction_object =
  let txs =
    if full_transaction_object then TxFull [transaction_object]
    else TxHash [transaction_hash]
  in
  return (block txs)

let current_block_number () = return (block_height ())

let nth_block ~full_transaction_object _n =
  let tx =
    if full_transaction_object then TxFull [transaction_object]
    else TxHash [transaction_hash]
  in
  return (block tx)

let transaction_receipt _tx_hash = return (Some (transaction_receipt ()))

let transaction_object _tx_hash = return (Some transaction_object)

let tx_pending =
  {
    blockHash = None;
    blockNumber = None;
    from = bootstrap_address;
    gas = qty_f Z.zero;
    gasPrice = qty_f Z.zero;
    hash =
      Hash "af953a2d01f55cfe080c0c94150a60105e8ac3d51153058a1f03dd239dd08586";
    input = empty_hash;
    nonce = qty_f Z.zero;
    to_ = Some bootstrap_address2;
    transactionIndex = qty_f Z.zero;
    value = qty_f Z.zero;
    v = qty_f Z.zero;
    r = hash_f @@ "00";
    s = hash_f @@ "00";
  }

let tx_queued =
  {
    blockHash = None;
    blockNumber = None;
    from = bootstrap_address2;
    gas = qty_f Z.zero;
    gasPrice = qty_f Z.zero;
    hash =
      Hash "af953a2d01f55cfe080c0c94150a60105e8ac3d51153058a1f03dd239dd08588";
    input = empty_hash;
    nonce = qty_f Z.zero;
    to_ = Some bootstrap_address;
    transactionIndex = qty_f Z.zero;
    value = qty_f Z.zero;
    v = qty_f Z.zero;
    r = hash_f @@ "00";
    s = hash_f @@ "00";
  }

let txpool _ =
  return
    {
      pending =
        AddressMap.add
          bootstrap_address
          (NonceMap.add Z.zero tx_pending NonceMap.empty)
          AddressMap.empty;
      queued =
        AddressMap.add
          bootstrap_address2
          (NonceMap.add Z.zero tx_queued NonceMap.empty)
          AddressMap.empty;
    }
