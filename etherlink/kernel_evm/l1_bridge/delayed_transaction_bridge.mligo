(* SPDX-CopyrightText Marigold <contact@marigold.dev> *)
#include "./ticket_type.mligo"
#include "./evm_type.mligo"

type storage = {
  admin: address
}

type transaction = {
  chunked_tx: bytes;
  evm_address: address;
}

type parameter =
  | Send of transaction
  | Deposit

type return = operation list * storage

let send_transaction ({chunked_tx; evm_address}: transaction) (storage: storage) : return = 
    // Check that one tez has been sent
    let fees = Tezos.get_amount () in
    if fees <> 1tez then 
      failwith "Not enough tez to include the transaction in the delayed inbox" 
    else
    
    // Craft an internal inbox message that respect the EVM rollup type
    // and put the payload in the bytes field.
    let evm_rollup : evm contract =
      Option.unopt ((Tezos.get_contract_opt evm_address) : evm contract option)
    in
    // Send the tx_raw to the kernel
    [Tezos.transaction (Other chunked_tx) 0mutez evm_rollup], storage

let withdraw_tez (storage: storage) : return = 
  // Check if the sender is the admin
  if Tezos.get_sender () <> storage.admin then
    failwith "Unauthorized address"
  else
  let admin = Tezos.get_contract storage.admin in
  // Withdraw all the balance of the smart contract
  let amount = Tezos.get_balance () in
  [Tezos.transaction () amount admin], storage

let main (parameter : parameter) (storage : storage) : return = 
  match parameter with
  | Send transaction -> send_transaction transaction storage
  | Deposit -> withdraw_tez storage

