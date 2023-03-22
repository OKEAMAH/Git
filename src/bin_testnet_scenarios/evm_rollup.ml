(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

let rec wait_for_eth_funded_key node rollup_node endpoint expected_amount
    account =
  (* Wait for the rollup node to apply the messages from the last block. *)
  let* () = Lwt_unix.sleep 5. in
  let* balance =
    Eth_cli.balance ~account:account.Eth_account.address ~endpoint
  in
  if Wei.Compare.(balance < expected_amount) then (
    Log.info
      "Key %s is underfunded (got %s, expected at least %s)"
      account.Eth_account.address
      Wei.(to_string balance)
      Wei.(to_string expected_amount) ;
    let* level = Node.wait_for_level node (Node.get_level node + 1) in
    let* _ = Sc_rollup_node.wait_for_level rollup_node level in
    wait_for_eth_funded_key node rollup_node endpoint expected_amount account)
  else unit

let setup_evm_rollup ~(testnet : Testnet.t) ~originator_key ~rollup_operator_key
    ?runner ?rollup_node_name ?loser_mode node client =
  let rollup_node =
    Sc_rollup_node.create
      ?runner
      ?name:rollup_node_name
      ~protocol:testnet.protocol
      ~base_dir:(Client.base_dir client)
      ~default_operator:rollup_operator_key
      Operator
      node
  in
  (* Start a rollup node *)
  let* boot_sector =
    Sc_rollup_helpers.prepare_installer_kernel
      ~base_installee:"./"
      ~preimages_dir:
        (Filename.concat (Sc_rollup_node.data_dir rollup_node) "wasm_2_0_0")
      "evm_kernel"
  in
  Log.info "EVM Kernel installer ready." ;
  let* rollup_address =
    Sc_rollup.originate_new_rollup ~boot_sector ~src:originator_key client
  in
  let* _ = Sc_rollup_node.config_init ?loser_mode rollup_node rollup_address in
  Log.info "Starting a smart rollup node to track %s" rollup_address ;
  let* () = Sc_rollup_node.run rollup_node [] in
  let* () = Sc_rollup_node.wait_for_ready rollup_node in
  Log.info "Smart rollup node started." ;
  (* EVM Kernel installation level. *)
  let* _ =
    Sc_rollup_node.wait_for_level ~timeout:30. rollup_node (Node.get_level node)
  in
  let* evm_proxy_server = Evm_proxy_server.init ?runner rollup_node in
  return (rollup_address, rollup_node, evm_proxy_server)

let send_and_wait_until_tx_mined ~rollup_node ~node ~source_private_key
    ~to_public_key ~value ~evm_proxy_server_endpoint =
  let tx_hash =
    Eth_cli.transaction_send
      ~source_private_key
      ~to_public_key
      ~value
      ~endpoint:evm_proxy_server_endpoint
  in
  let next_level =
    let rec go () =
      (* Sleep few seconds to give a better chance to [tx_hash] of being
         choosen and `eth_cli transaction:send` to return. *)
      let* () = Lwt_unix.sleep 5. in
      let* _new_level =
        Sc_rollup_node.wait_for_level
          ~timeout:30.
          rollup_node
          (Node.get_level node)
      in
      go ()
    in
    go ()
  in
  Lwt.choose [tx_hash; next_level]

let eth_transfer ~(testnet : Testnet.t) () =
  (* We expect the operator 11,000 xtz. This is enough to originate a rollup
     (1.68 xtz) and commit (10,000 xtz) and post the messages through the batcher. *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot = Helpers.download testnet.snapshot "snapshot" in
  let* client, node = Helpers.setup_octez_node ~testnet snapshot in
  let* operator = Client.gen_and_show_keys client in
  let* () = Helpers.wait_for_funded_key node client min_balance operator in
  let* _rollup_address, rollup_node, evm_proxy_server =
    setup_evm_rollup
      ~testnet
      ~originator_key:operator.alias
      ~rollup_operator_key:operator.alias
      node
      client
  in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let balance account =
    Eth_cli.balance ~account ~endpoint:evm_proxy_server_endpoint
  in
  let sender, receiver =
    (Eth_account.bootstrap_accounts.(0), Eth_account.bootstrap_accounts.(1))
  in
  let* () =
    wait_for_eth_funded_key
      node
      rollup_node
      evm_proxy_server_endpoint
      (Wei.of_eth_int 9999)
      sender
  in
  let* sender_balance = balance sender.address in
  (* We always send less than the balance, to ensure it always works. *)
  let value = Wei.(sender_balance - one) in
  let* tx_hash =
    send_and_wait_until_tx_mined
      ~rollup_node
      ~node
      ~source_private_key:sender.private_key
      ~to_public_key:receiver.address
      ~value
      ~evm_proxy_server_endpoint
  in
  Log.info "Operation injected and applied in the kernel with hash %s" tx_hash ;
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4929
     Should the scenario checks if the transfer ended with the expected
     result (correct balance for both, updated nonce for the sender)? *)
  unit

let register ~testnet =
  Test.register
    ~__FILE__
    ~title:"Originate an EVM Kernel and make a transfer"
    ~tags:["transfer"]
    (eth_transfer ~testnet)
