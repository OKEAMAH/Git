(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

(* Testing
   -------
   Component:    Smart Optimistic Rollups: EVM Kernel
   Requirement:  make -f kernels.mk build-kernels
                 npm install eth-cli
   Invocation:   dune exec tezt/tests/main.exe -- --file evm_rollup.ml
*)
open Sc_rollup_helpers
open Evm_rollup_helpers

let test_evm_proxy_server_connection =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"]
    ~title:"EVM proxy server connection"
  @@ fun protocol ->
  let* tezos_node, tezos_client = setup_l1 protocol in
  let* sc_rollup =
    originate_sc_rollup
      ~kind:"wasm_2_0_0"
      ~parameters_ty:"string"
      ~src:Constant.bootstrap1.alias
      tezos_client
  in
  let sc_rollup_node =
    Sc_rollup_node.create
      ~protocol
      Observer
      tezos_node
      ~base_dir:(Client.base_dir tezos_client)
      ~default_operator:Constant.bootstrap1.alias
  in
  let evm_proxy = Evm_proxy_server.create sc_rollup_node in
  (* Tries to start the EVM proxy server without a listening rollup node. *)
  let process = Evm_proxy_server.spawn_run evm_proxy in
  let* () = Process.check ~expect_failure:true process in
  (* Starts the rollup node. *)
  let* _ = Sc_rollup_node.run sc_rollup_node sc_rollup [] in
  (* Starts the EVM proxy server and asks its version. *)
  let* () = Evm_proxy_server.run evm_proxy in
  let*? process = evm_proxy_server_version evm_proxy in
  let* () = Process.check process in
  unit

let test_originate_evm_kernel =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"]
    ~title:"Originate EVM kernel with installer"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; sc_rollup_client; _} =
    setup_evm_kernel protocol
  in
  (* First run of the installed EVM kernel, it will initialize the directory
     "eth_accounts". *)
  let* () = Client.bake_for_and_wait client in
  let first_evm_run_level = Node.get_level node in
  let* level =
    Sc_rollup_node.wait_for_level
      ~timeout:30.
      sc_rollup_node
      first_evm_run_level
  in
  Check.(level = first_evm_run_level)
    Check.int
    ~error_msg:"Current level has moved past first EVM run (%L = %R)" ;
  let eth_accounts_key = "eth_accounts" in
  let*! storage_root_keys =
    Sc_rollup_client.inspect_durable_state_value
      ~hooks
      sc_rollup_client
      ~pvm_kind
      ~operation:Sc_rollup_client.Subkeys
      ~key:""
  in
  Check.(
    list_mem
      string
      eth_accounts_key
      storage_root_keys
      ~error_msg:"Expected %L to be initialized by the EVM kernel.") ;
  unit

let test_rpc_getBalance =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "get_balance"]
    ~title:"RPC method eth_getBalance"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; evm_proxy_server; _} =
    setup_evm_kernel protocol
  in
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* balance =
    Eth_cli.balance
      ~account:Eth_account.bootstrap_accounts.(0).address
      ~endpoint:evm_proxy_server_endpoint
  in
  Check.((balance = Wei.of_eth_int 9999) Wei.typ)
    ~error_msg:
      (sf
         "Expected balance of %s should be %%R, but got %%L"
         Eth_account.bootstrap_accounts.(0).address) ;
  unit

let test_rpc_getBlockByNumber =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "get_block_by_number"]
    ~title:"RPC method eth_getBlockByNumber"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; _} = setup_evm_kernel protocol in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* () = Client.bake_for_and_wait client in
  let first_evm_run_level = Node.get_level node in
  let* _level =
    Sc_rollup_node.wait_for_level
      ~timeout:30.
      sc_rollup_node
      first_evm_run_level
  in
  let* block =
    Eth_cli.get_block ~block_id:"0" ~endpoint:evm_proxy_server_endpoint
  in
  (* For our needs, we just test these two relevant fields for now: *)
  Check.((block.number = 0l) int32)
    ~error_msg:"Unexpected block number, should be %%R, but got %%L" ;
  let expected_transactions =
    Array.(
      map
        (fun accounts -> accounts.Eth_account.genesis_mint_tx)
        Eth_account.bootstrap_accounts
      |> to_list)
  in
  Check.(block.transactions = expected_transactions)
    (Check.list Check.string)
    ~error_msg:"Unexpected list of transactions, should be %%R, but got %%L" ;
  unit

let test_rpc_getTransactionCount =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "get_transaction_count"]
    ~title:"RPC method eth_getTransactionCount"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; _} = setup_evm_kernel protocol in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  (* Force a level to got past the genesis block *)
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let* transaction_count =
    get_transaction_count
      evm_proxy_server
      Eth_account.bootstrap_accounts.(0).address
  in
  Check.((transaction_count = 0L) int64)
    ~error_msg:"Expected a nonce of %R, but got %L" ;
  unit

let test_l2_blocks_progression =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_blocks_progression"]
    ~title:"Check L2 blocks progression"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; _} = setup_evm_kernel protocol in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let check_block_progression ~expected_block_level =
    let* _level = next_evm_level ~sc_rollup_node ~node ~client in
    let* block_number =
      Eth_cli.block_number ~endpoint:evm_proxy_server_endpoint
    in
    return
    @@ Check.((block_number = expected_block_level) int)
         ~error_msg:"Unexpected block number, should be %%R, but got %%L"
  in
  let* () = check_block_progression ~expected_block_level:1 in
  let* () = check_block_progression ~expected_block_level:2 in
  unit

let test_l2_deploy =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_deploy"]
    ~title:"Check L2 contract deployment"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; _} = setup_evm_kernel protocol in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let sender = Eth_account.bootstrap_accounts.(0) in
  let* () =
    Eth_cli.add_abi
      ~label:"simpleStorage"
      ~abi:(kernel_inputs_path ^ "/storage_abi.json")
      ()
  in
  let send_deploy =
    Eth_cli.deploy
      ~source_private_key:sender.private_key
      ~endpoint:evm_proxy_server_endpoint
      ~abi:"simpleStorage"
      ~bin:(kernel_inputs_path ^ "/storage.bin")
  in
  let* _ = wait_for_application ~sc_rollup_node ~node ~client send_deploy () in
  unit

let transfer ?data protocol =
  let* ({node; client; sc_rollup_node; _} as full_evm_setup) =
    setup_evm_kernel protocol
  in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let balance account = Eth_cli.balance ~account ~endpoint in
  let sender, receiver =
    (Eth_account.bootstrap_accounts.(0), Eth_account.bootstrap_accounts.(1))
  in
  let* sender_balance = balance sender.address in
  let* receiver_balance = balance receiver.address in
  let* sender_nonce = get_transaction_count evm_proxy_server sender.address in
  (* We always send less than the balance, to ensure it always works. *)
  let value = Wei.(sender_balance - one) in
  let* tx = send ~sender ~receiver ~value ?data full_evm_setup in
  let* () = check_tx_succeeded ~endpoint ~tx in
  let* new_sender_balance = balance sender.address in
  let* new_receiver_balance = balance receiver.address in
  let* new_sender_nonce =
    get_transaction_count evm_proxy_server sender.address
  in
  Check.(Wei.(new_sender_balance = sender_balance - value) Wei.typ)
    ~error_msg:
      "Unexpected sender balance after transfer, should be %R, but got %L" ;
  Check.(Wei.(new_receiver_balance = receiver_balance + value) Wei.typ)
    ~error_msg:
      "Unexpected receiver balance after transfer, should be %R, but got %L" ;
  Check.((new_sender_nonce = Int64.succ sender_nonce) int64)
    ~error_msg:
      "Unexpected sender nonce after transfer, should be %R, but got %L" ;
  unit

let test_l2_transfer =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_transfer"]
    ~title:"Check L2 transfers are applied"
    transfer

let test_chunked_transaction =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_transfer"; "chunked"]
    ~title:"Check L2 chunked transfers are applied"
  @@ transfer ~data:("0x" ^ String.make 12_000 'a')

let register_evm_proxy_server ~protocols =
  test_originate_evm_kernel protocols ;
  test_evm_proxy_server_connection protocols ;
  test_rpc_getBalance protocols ;
  test_rpc_getBlockByNumber protocols ;
  test_rpc_getTransactionCount protocols ;
  test_l2_blocks_progression protocols ;
  test_l2_transfer protocols ;
  test_chunked_transaction protocols ;
  test_l2_deploy protocols

let register ~protocols = register_evm_proxy_server ~protocols
