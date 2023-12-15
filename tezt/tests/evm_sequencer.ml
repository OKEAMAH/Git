(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

open Sc_rollup_helpers

let delayed_path () =
  Base.(
    project_root
    // "etherlink/kernel_evm/l1_bridge/delayed_transaction_bridge.tz")

let evm_type =
  "or (or (pair bytes (ticket (pair nat (option bytes)))) bytes) bytes"

type l1_contracts = {delayed_transaction_bridge : string}

type sequencer_setup = {
  node : Node.t;
  sc_rollup_node : Sc_rollup_node.t;
  client : Client.t;
  sc_rollup_address : string;
  evm_node : Evm_node.t;
  l1_contracts : l1_contracts;
}

(** [next_evm_level ~sc_rollup_node ~node ~client] moves [sc_rollup_node] to
    the [node]'s next level. *)
let next_evm_level ~sc_rollup_node ~node ~client =
  let* () = Client.bake_for_and_wait client in
  let* level = Node.get_level node in
  Sc_rollup_node.wait_for_level ~timeout:30. sc_rollup_node level

let setup_l1_contracts client =
  (* Originates the delayed transaction bridge. *)
  let* delayed_transaction_bridge =
    Client.originate_contract
      ~alias:"evm-seq-delayed-bridge"
      ~amount:Tez.zero
      ~src:Constant.bootstrap1.public_key_hash
      ~init:(sf "%S" Constant.bootstrap1.public_key_hash)
      ~prg:(delayed_path ())
      ~burn_cap:Tez.one
      client
  in
  let* () = Client.bake_for_and_wait client in

  return {delayed_transaction_bridge}

let setup_sequencer ?(bootstrap_accounts = Eth_account.bootstrap_accounts)
    protocol =
  let* node, client = setup_l1 protocol in
  let* l1_contracts = setup_l1_contracts client in
  let sc_rollup_node =
    Sc_rollup_node.create Observer node ~base_dir:(Client.base_dir client)
  in
  let preimages_dir = Sc_rollup_node.data_dir sc_rollup_node // "wasm_2_0_0" in
  let config =
    Configuration.make_config
      ~bootstrap_accounts
      ~sequencer:true
      ~delayed_bridge:l1_contracts.delayed_transaction_bridge
      ()
  in
  let* {output; _} =
    prepare_installer_kernel
      ~base_installee:"./"
      ~preimages_dir
      ?config
      "evm_kernel"
  in
  let* sc_rollup_address =
    originate_sc_rollup
      ~kind:"wasm_2_0_0"
      ~boot_sector:("file:" ^ output)
      ~parameters_ty:evm_type
      client
  in
  let* () =
    Sc_rollup_node.run sc_rollup_node sc_rollup_address ["--log-kernel-debug"]
  in
  let mode =
    Evm_node.Sequencer {kernel = output; preimage_dir = preimages_dir}
  in
  let* evm_node =
    Evm_node.init ~mode (Sc_rollup_node.endpoint sc_rollup_node)
  in
  return
    {node; client; evm_node; l1_contracts; sc_rollup_address; sc_rollup_node}

let send_raw_transaction_to_delayed_inbox ~sc_rollup_node ~node ~client
    ~l1_contracts ~sc_rollup_address raw_tx =
  let {delayed_transaction_bridge; _} = l1_contracts in

  let hash =
    `Hex raw_tx |> Hex.to_bytes |> Tezos_crypto.Hacl.Hash.Keccak_256.digest
    |> Hex.of_bytes |> Hex.show
  in
  let bytes = sf {|0x00%s%s|} hash raw_tx in
  let* () =
    Client.transfer
      ~entrypoint:"default"
      ~arg:(sf {|(Right (Pair %s "%s"))|} bytes sc_rollup_address)
      ~amount:Tez.one
      ~giver:Constant.bootstrap2.public_key_hash
        (*We don't care who send the transaction*)
      ~receiver:delayed_transaction_bridge
      ~burn_cap:Tez.one
      client
  in
  let* () = Client.bake_for_and_wait client in
  let* _ = next_evm_level ~sc_rollup_node ~node ~client in
  Lwt.return hash

let test_persistent_state =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "sequencer"]
    ~title:"Sequencer state is persistent across runs"
  @@ fun protocol ->
  let* {evm_node; _} = setup_sequencer protocol in
  (* Sleep to let the sequencer produce some blocks. *)
  let* () = Lwt_unix.sleep 20. in
  (* Ask for the current block. *)
  let* block_number = Rpc.block_number evm_node in
  Check.is_true
    ~__LOC__
    (block_number > 0l)
    ~error_msg:"The sequencer should have produced a block" ;
  (* Terminate the sequencer. *)
  let* () = Evm_node.terminate evm_node in
  (* Restart it. *)
  let* () = Evm_node.run evm_node in
  (* Assert the block number is at least [block_number]. Asserting
     that the block number is exactly the same as {!block_number} can
     be flaky if a block is produced between the restart and the
     RPC. *)
  let* new_block_number = Rpc.block_number evm_node in
  Check.is_true
    ~__LOC__
    (new_block_number >= block_number)
    ~error_msg:"The sequencer should have produced a block" ;
  unit

let test_send_transaction_to_delayed_inbox =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "sequencer"; "delayed_inbox"]
    ~title:"Send a transaction to the delayed inbox"
  @@ fun protocol ->
  (* Start the evm node *)
  let* {client; node; l1_contracts; sc_rollup_address; sc_rollup_node; _} =
    setup_sequencer protocol
  in
  let raw_transfer =
    "f86d80843b9aca00825b0494b53dc01974176e5dff2298c5a94343c2585e3c54880de0b6b3a764000080820a96a07a3109107c6bd1d555ce70d6253056bc18996d4aff4d4ea43ff175353f49b2e3a05f9ec9764dc4a3c3ab444debe2c3384070de9014d44732162bb33ee04da187ef"
  in
  let* hash =
    send_raw_transaction_to_delayed_inbox
      ~sc_rollup_node
      ~client
      ~l1_contracts
      ~sc_rollup_address
      ~node
      raw_transfer
  in
  let* delayed_transactions_hashes =
    Sc_rollup_node.RPC.call sc_rollup_node
    @@ Sc_rollup_rpc.get_global_block_durable_state_value
         ~pvm_kind:"wasm_2_0_0"
         ~operation:Sc_rollup_rpc.Subkeys
         ~key:"/delayed-inbox"
         ()
  in
  Check.(list_mem string hash delayed_transactions_hashes)
    ~error_msg:"hash %L should be present in the delayed inbox %R" ;
  unit

let register ~protocols =
  test_persistent_state protocols ;
  test_send_transaction_to_delayed_inbox protocols
