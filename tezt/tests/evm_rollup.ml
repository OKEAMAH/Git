(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

(* Testing
   -------
   Component:    Smart Optimistic Rollups: EVM Kernel
   Requirement:  make -f kernels.mk build
                 npm install eth-cli
   Invocation:   dune exec tezt/tests/main.exe -- --file evm_rollup.ml
*)
open Sc_rollup_helpers

let pvm_kind = "wasm_2_0_0"

let kernel_inputs_path = "tezt/tests/evm_kernel_inputs"

type deposit_addresses = {fa12 : string; bridge : string}

type full_evm_setup = {
  node : Node.t;
  client : Client.t;
  sc_rollup_node : Sc_rollup_node.t;
  sc_rollup_client : Sc_rollup_client.t;
  sc_rollup_address : string;
  originator_key : string;
  rollup_operator_key : string;
  evm_proxy_server : Evm_proxy_server.t;
  endpoint : string;
  deposit_addresses : deposit_addresses option;
}

let hex_256_of n = Printf.sprintf "%064x" n

let evm_proxy_server_version proxy_server =
  let endpoint = Evm_proxy_server.endpoint proxy_server in
  let get_version_url = endpoint ^ "/version" in
  RPC.Curl.get get_version_url

let get_transaction_status ~endpoint ~tx =
  let* receipt = Eth_cli.get_receipt ~endpoint ~tx in
  match receipt with
  | None -> failwith "no transaction receipt, it probably isn't mined yet."
  | Some r -> return r.status

let check_tx_succeeded ~endpoint ~tx =
  let* status = get_transaction_status ~endpoint ~tx in
  Check.(is_true status) ~error_msg:"Expected transaction to succeed." ;
  unit

let check_tx_failed ~endpoint ~tx =
  let* status = get_transaction_status ~endpoint ~tx in
  Check.(is_false status) ~error_msg:"Expected transaction to fail." ;
  unit

(** [get_value_in_storage client addr nth] fetch the [nth] value in the storage
    of account [addr]  *)
let get_value_in_storage sc_rollup_client address nth =
  Sc_rollup_client.inspect_durable_state_value
    ~hooks
    sc_rollup_client
    ~pvm_kind
    ~operation:Sc_rollup_client.Value
    ~key:(Durable_storage_path.storage address ~key:(hex_256_of nth) ())

let check_str_in_storage ~evm_setup ~address ~nth ~expected =
  let*! value = get_value_in_storage evm_setup.sc_rollup_client address nth in
  Check.((value = Some expected) (option string))
    ~error_msg:"Unexpected value in storage, should be %R, but got %L" ;
  unit

let check_nb_in_storage ~evm_setup ~address ~nth ~expected =
  check_str_in_storage ~evm_setup ~address ~nth ~expected:(hex_256_of expected)

let get_storage_size sc_rollup_client ~address =
  let*! storage =
    Sc_rollup_client.inspect_durable_state_value
      ~hooks
      sc_rollup_client
      ~pvm_kind
      ~operation:Sc_rollup_client.Subkeys
      ~key:(Durable_storage_path.storage address ())
  in
  return (List.length storage)

let check_storage_size sc_rollup_client ~address size =
  (* check storage size *)
  let* storage_size = get_storage_size sc_rollup_client ~address in
  Check.((storage_size = size) int)
    ~error_msg:"Unexpected storage size, should be %R, but is %L" ;
  unit

(** [next_evm_level ~sc_rollup_node ~node ~client] moves [sc_rollup_node] to
    the [node]'s next level. *)
let next_evm_level ~sc_rollup_node ~node ~client =
  let* () = Client.bake_for_and_wait client in
  Sc_rollup_node.wait_for_level
    ~timeout:30.
    sc_rollup_node
    (Node.get_level node)

(** [wait_for_transaction_receipt ~evm_proxy_server ~transaction_hash] takes an
    transaction_hash and returns only when the receipt is non null, or [count]
    blocks have passed and the receipt is still not available. *)
let wait_for_transaction_receipt ?(count = 3) ~evm_proxy_server
    ~transaction_hash () =
  let rec loop count =
    let* () = Lwt_unix.sleep 5. in
    let* receipt =
      Evm_proxy_server.(
        call_evm_rpc
          evm_proxy_server
          {
            method_ = "eth_getTransactionReceipt";
            parameters = `A [`String transaction_hash];
          })
    in
    if receipt |> Evm_proxy_server.extract_result |> JSON.is_null then
      if count > 0 then loop (count - 1)
      else Test.fail "Transaction still hasn't been included"
    else
      receipt |> Evm_proxy_server.extract_result
      |> Transaction.transaction_receipt_of_json |> return
  in
  loop count

let wait_for_application ~sc_rollup_node ~node ~client apply () =
  let* start_level = Client.level client in
  let max_iteration = 10 in
  let application_result = apply () in
  let rec loop () =
    let* () = Lwt_unix.sleep 5. in
    let* new_level = next_evm_level ~sc_rollup_node ~node ~client in
    if start_level + max_iteration < new_level then
      Test.fail
        "Baked more than %d blocks and the operation's application is still \
         pending"
        max_iteration ;
    if Lwt.state application_result = Lwt.Sleep then loop () else unit
  in
  (* Using [Lwt.both] ensures that any exception thrown in [tx_hash] will be
     thrown by [Lwt.both] as well. *)
  let* result, () = Lwt.both application_result (loop ()) in
  return result

let send_and_wait_until_tx_mined ~sc_rollup_node ~node ~client
    ~source_private_key ~to_public_key ~value ~evm_proxy_server_endpoint ?data
    () =
  let send =
    Eth_cli.transaction_send
      ~source_private_key
      ~to_public_key
      ~value
      ~endpoint:evm_proxy_server_endpoint
      ?data
  in
  wait_for_application ~sc_rollup_node ~node ~client send ()

let send_n_transactions ~sc_rollup_node ~node ~client ~evm_proxy_server txs =
  let requests =
    List.map
      (fun tx ->
        Evm_proxy_server.
          {method_ = "eth_sendRawTransaction"; parameters = `A [`String tx]})
      txs
  in
  let* hashes = Evm_proxy_server.batch_evm_rpc evm_proxy_server requests in
  let first_hash =
    hashes |> JSON.as_list |> List.hd |> Evm_proxy_server.extract_result
    |> JSON.as_string
  in
  (* Let's wait until one of the transactions is injected into a block, and
      test this block contains the `n` transactions as expected. *)
  let* receipt =
    wait_for_application
      ~sc_rollup_node
      ~node
      ~client
      (wait_for_transaction_receipt
         ~evm_proxy_server
         ~transaction_hash:first_hash)
      ()
  in
  return (requests, receipt)

let setup_deposit_contracts ~admin client protocol =
  (* Originates a FA1.2 token. *)
  let fa12_script = Fa12.fa12_reference in
  let* _fa12_alias, fa12_address =
    Fa12.originate_fa12
      ~src:Constant.bootstrap1.public_key_hash
      ~admin
      ~fa12_script
      client
      protocol
  in
  let* () = Client.bake_for_and_wait client in

  (* Mint some tokens for the admin. *)
  let* () =
    Fa12.mint
      ~admin
      ~mint:(Tez.of_int 100)
      ~dest:admin
      ~fa12_address
      ~fa12_script
      client
  in
  let* () = Client.bake_for_and_wait client in

  (* Originates the bridge. *)
  let prg = Base.(project_root // "src/kernel_evm/l1_bridge/evm_bridge.tz") in
  let* bridge_address =
    Client.originate_contract
      ~alias:"evm-bridge"
      ~amount:Tez.zero
      ~src:Constant.bootstrap1.public_key_hash
      ~init:
        (sf {|(Pair (Pair "%s" "%s") None)|} admin.public_key_hash fa12_address)
      ~prg
      ~burn_cap:Tez.one
      client
  in
  let* () = Client.bake_for_and_wait client in

  return {fa12 = fa12_address; bridge = bridge_address}

let make_config ?bootstrap_accounts ?ticketer ?dictator () =
  let open Sc_rollup_helpers.Installer_kernel_config in
  let ticketer =
    Option.fold
      ~some:(fun ticketer ->
        let value = Hex.(of_string ticketer |> show) in
        let to_ = Durable_storage_path.ticketer in
        [Set {value; to_}])
      ~none:[]
      ticketer
  in
  let bootstrap_accounts =
    Option.fold
      ~some:
        (Array.fold_left
           (fun acc Eth_account.{address; _} ->
             let value =
               Wei.(to_le_bytes @@ of_eth_int 9999) |> Hex.of_bytes |> Hex.show
             in
             let to_ = Durable_storage_path.balance address in
             Set {value; to_} :: acc)
           [])
      ~none:[]
      bootstrap_accounts
  in
  let dictator =
    Option.fold
      ~some:(fun dictator ->
        let to_ = Durable_storage_path.dictator in
        [Set {value = dictator; to_}])
      ~none:[]
      dictator
  in
  match ticketer @ bootstrap_accounts @ dictator with
  | [] -> None
  | res -> Some res

let setup_evm_kernel ?config
    ?(originator_key = Constant.bootstrap1.public_key_hash)
    ?(rollup_operator_key = Constant.bootstrap1.public_key_hash)
    ?(bootstrap_accounts = Eth_account.bootstrap_accounts) ?dictator
    ~deposit_admin protocol =
  let* node, client = setup_l1 protocol in
  let* deposit_addresses =
    match deposit_admin with
    | Some admin ->
        let* res = setup_deposit_contracts ~admin client protocol in
        return (Some res)
    | None -> return None
  in
  (* If a L1 bridge was set up, we make the kernel aware of the address. *)
  let config =
    match config with
    | Some config -> Some config
    | None ->
        let ticketer =
          Option.map (fun {bridge; _} -> bridge) deposit_addresses
        in
        make_config ~bootstrap_accounts ?ticketer ?dictator ()
  in
  let sc_rollup_node =
    Sc_rollup_node.create
      Operator
      node
      ~base_dir:(Client.base_dir client)
      ~default_operator:rollup_operator_key
  in
  (* Start a rollup node *)
  let* boot_sector =
    prepare_installer_kernel
      ~base_installee:"./"
      ~preimages_dir:
        (Filename.concat (Sc_rollup_node.data_dir sc_rollup_node) "wasm_2_0_0")
      ?config
      "evm_kernel"
  in
  let* sc_rollup_address =
    originate_sc_rollup
      ~kind:pvm_kind
      ~boot_sector
      ~parameters_ty:"pair (pair bytes (ticket unit)) (pair nat bytes)"
      ~src:originator_key
      client
  in
  (* Make the L1 bridge aware of the target EVM rollup. *)
  let* () =
    match (deposit_addresses, deposit_admin) with
    | Some {bridge; _}, Some admin ->
        Client.transfer
          ~entrypoint:"set"
          ~arg:(sf {|"%s"|} sc_rollup_address)
          ~amount:Tez.zero
          ~giver:admin.public_key_hash
          ~receiver:bridge
          ~burn_cap:Tez.one
          client
    | _ -> unit
  in
  let* () =
    Sc_rollup_node.run sc_rollup_node sc_rollup_address ["--log-kernel-debug"]
  in
  let sc_rollup_client = Sc_rollup_client.create ~protocol sc_rollup_node in
  (* EVM Kernel installation level. *)
  let* () = Client.bake_for_and_wait client in
  let* _ =
    Sc_rollup_node.wait_for_level
      ~timeout:30.
      sc_rollup_node
      (Node.get_level node)
  in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  return
    {
      node;
      client;
      sc_rollup_node;
      sc_rollup_client;
      sc_rollup_address;
      originator_key;
      rollup_operator_key;
      evm_proxy_server;
      endpoint;
      deposit_addresses;
    }

let setup_past_genesis ?originator_key ?rollup_operator_key ~deposit_admin
    protocol =
  let* ({node; client; sc_rollup_node; _} as full_setup) =
    setup_evm_kernel
      ?originator_key
      ?rollup_operator_key
      ~deposit_admin
      protocol
  in
  (* Force a level to got past the genesis block *)
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  return full_setup

let setup_mockup () =
  let evm_proxy_server = Evm_proxy_server.mockup () in
  let* () = Evm_proxy_server.run evm_proxy_server in
  return evm_proxy_server

type contract = {label : string; abi : string; bin : string}

let deploy ~contract ~sender full_evm_setup =
  let {node; client; sc_rollup_node; evm_proxy_server; _} = full_evm_setup in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* () = Eth_cli.add_abi ~label:contract.label ~abi:contract.abi () in
  let send_deploy () =
    Eth_cli.deploy
      ~source_private_key:sender.Eth_account.private_key
      ~endpoint:evm_proxy_server_endpoint
      ~abi:contract.label
      ~bin:contract.bin
  in
  wait_for_application ~sc_rollup_node ~node ~client send_deploy ()

let send ~sender ~receiver ~value ?data full_evm_setup =
  let {node; client; sc_rollup_node; evm_proxy_server; _} = full_evm_setup in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let send =
    Eth_cli.transaction_send
      ~source_private_key:sender.Eth_account.private_key
      ~to_public_key:receiver.Eth_account.address
      ~value
      ~endpoint:evm_proxy_server_endpoint
      ?data
  in
  wait_for_application ~sc_rollup_node ~node ~client send ()

let send_external_message_and_wait ~sc_rollup_node ~node ~client ~sender
    ~hex_msg =
  let* () =
    Client.Sc_rollup.send_message
      ~src:sender
      ~msg:("hex:[ \"" ^ hex_msg ^ "\" ]")
      client
  in
  let* _ = next_evm_level ~sc_rollup_node ~node ~client in
  unit

let check_block_progression ~sc_rollup_node ~node ~client ~endpoint
    ~expected_block_level =
  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let* block_number = Eth_cli.block_number ~endpoint in
  return
  @@ Check.((block_number = expected_block_level) int)
       ~error_msg:"Unexpected block number, should be %%R, but got %%L"

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
    setup_evm_kernel ~deposit_admin:None protocol
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
  let evm_key = "evm" in
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
      evm_key
      storage_root_keys
      ~error_msg:"Expected %L to be initialized by the EVM kernel.") ;
  unit

let transaction_count_request address =
  Evm_proxy_server.
    {
      method_ = "eth_getTransactionCount";
      parameters = `A [`String address; `String "latest"];
    }

let get_transaction_count proxy_server address =
  let* transaction_count =
    Evm_proxy_server.call_evm_rpc
      proxy_server
      (transaction_count_request address)
  in
  return JSON.(transaction_count |-> "result" |> as_int64)

let test_l2_blocks_progression =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_blocks_progression"]
    ~title:"Check L2 blocks progression"
  @@ fun protocol ->
  let* {node; client; sc_rollup_node; _} =
    setup_evm_kernel ~deposit_admin:None protocol
  in
  let* evm_proxy_server = Evm_proxy_server.init sc_rollup_node in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* () =
    check_block_progression
      ~sc_rollup_node
      ~node
      ~client
      ~endpoint
      ~expected_block_level:1
  in
  let* () =
    check_block_progression
      ~sc_rollup_node
      ~node
      ~client
      ~endpoint
      ~expected_block_level:2
  in
  unit

(** The info for the "storage.sol" contract.
    See [src\kernel_evm\solidity_examples] *)
let simple_storage =
  {
    label = "simpleStorage";
    abi = kernel_inputs_path ^ "/storage_abi.json";
    bin = kernel_inputs_path ^ "/storage.bin";
  }

(** The info for the "erc20tok.sol" contract.
    See [src\kernel_evm\solidity_examples] *)
let erc20 =
  {
    label = "erc20tok";
    abi = kernel_inputs_path ^ "/erc20tok_abi.json";
    bin = kernel_inputs_path ^ "/erc20tok.bin";
  }

(** Test that the contract creation works.  *)
let test_l2_deploy_simple_storage =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_deploy"]
    ~title:"Check L2 contract deployment"
  @@ fun protocol ->
  let* ({sc_rollup_client; evm_proxy_server; _} as full_evm_setup) =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let sender = Eth_account.bootstrap_accounts.(0) in
  let* contract_address, tx =
    deploy ~contract:simple_storage ~sender full_evm_setup
  in
  let address = String.lowercase_ascii contract_address in
  Check.(
    (address = "0xd77420f73b4612a7a99dba8c2afd30a1886b0344")
      string
      ~error_msg:"Expected address to be %R but was %L.") ;

  let* code_in_kernel =
    Evm_proxy_server.fetch_contract_code evm_proxy_server contract_address
  in
  (* The same deployment has been reproduced on the Sepolia testnet, resulting
     on this specific code. *)
  let expected_code =
    "0x608060405234801561001057600080fd5b50600436106100415760003560e01c80634e70b1dc1461004657806360fe47b1146100645780636d4ce63c14610080575b600080fd5b61004e61009e565b60405161005b91906100d0565b60405180910390f35b61007e6004803603810190610079919061011c565b6100a4565b005b6100886100ae565b60405161009591906100d0565b60405180910390f35b60005481565b8060008190555050565b60008054905090565b6000819050919050565b6100ca816100b7565b82525050565b60006020820190506100e560008301846100c1565b92915050565b600080fd5b6100f9816100b7565b811461010457600080fd5b50565b600081359050610116816100f0565b92915050565b600060208284031215610132576101316100eb565b5b600061014084828501610107565b9150509291505056fea2646970667358221220ec57e49a647342208a1f5c9b1f2049bf1a27f02e19940819f38929bf67670a5964736f6c63430008120033"
  in
  Check.((code_in_kernel = expected_code) string)
    ~error_msg:"Unexpected code %L, it should be %R" ;
  (* The transaction was a contract creation, the transaction object
     must not contain the [to] field. *)
  let* tx_object = Eth_cli.transaction_get ~endpoint ~tx_hash:tx in
  (match tx_object with
  | Some tx_object ->
      Check.((tx_object.to_ = None) (option string))
        ~error_msg:
          "The transaction object of a contract creation should not have the \
           [to] field present"
  | None -> Test.fail "The transaction object of %s should be available" tx) ;

  let*! accounts =
    Sc_rollup_client.inspect_durable_state_value
      ~hooks
      sc_rollup_client
      ~pvm_kind
      ~operation:Sc_rollup_client.Subkeys
      ~key:Durable_storage_path.eth_accounts
  in
  (* check tx status*)
  let* () = check_tx_succeeded ~endpoint ~tx in

  (* check contract account was created *)
  Check.(
    list_mem
      string
      (Helpers.normalize contract_address)
      (List.map String.lowercase_ascii accounts)
      ~error_msg:"Expected %L account to be initialized by contract creation.") ;
  unit

let send_call_set_storage_simple contract_address sender n
    {sc_rollup_node; node; client; endpoint; _} =
  let call_set (sender : Eth_account.t) n =
    Eth_cli.contract_send
      ~source_private_key:sender.private_key
      ~endpoint
      ~abi_label:simple_storage.label
      ~address:contract_address
      ~method_call:(Printf.sprintf "set(%d)" n)
  in
  wait_for_application ~sc_rollup_node ~node ~client (call_set sender n) ()

(** Test that a contract can be called,
    and that the call can modify the storage.  *)
let test_l2_call_simple_storage =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_deploy"; "l2_call"]
    ~title:"Check L2 contract call"
  @@ fun protocol ->
  (* setup *)
  let* ({evm_proxy_server; sc_rollup_client; _} as evm_setup) =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let sender = Eth_account.bootstrap_accounts.(0) in

  (* deploy contract *)
  let* address, _tx = deploy ~contract:simple_storage ~sender evm_setup in

  (* set 42 *)
  let* tx = send_call_set_storage_simple address sender 42 evm_setup in

  let* () = check_tx_succeeded ~endpoint ~tx in
  let* () = check_storage_size sc_rollup_client ~address 1 in
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:42 in

  (* set 24 by another user *)
  let* tx =
    send_call_set_storage_simple
      address
      Eth_account.bootstrap_accounts.(1)
      24
      evm_setup
  in

  let* () = check_tx_succeeded ~endpoint ~tx in
  let* () = check_storage_size sc_rollup_client ~address 1 in
  (* value stored has changed *)
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:24 in

  (* set -1 *)
  (* some environments prevent sending a negative value, as the value is
     unsigned (eg remix) but it is actually the expected result *)
  let* tx = send_call_set_storage_simple address sender (-1) evm_setup in

  let* () = check_tx_succeeded ~endpoint ~tx in
  let* () = check_storage_size sc_rollup_client ~address 1 in
  (* value stored has changed *)
  let* () =
    check_str_in_storage
      ~evm_setup
      ~address
      ~nth:0
      ~expected:
        "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
  in
  unit

let test_l2_deploy_erc20 =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "l2_deploy"; "erc20"; "l2_call"]
    ~title:"Check L2 erc20 contract deployment"
  @@ fun protocol ->
  (* setup *)
  let* ({sc_rollup_client; evm_proxy_server; node; client; sc_rollup_node; _} as
       evm_setup) =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let sender = Eth_account.bootstrap_accounts.(0) in
  let player = Eth_account.bootstrap_accounts.(1) in

  (* deploy the contract *)
  let* address, tx = deploy ~contract:erc20 ~sender evm_setup in
  Check.(
    (String.lowercase_ascii address
    = "0xd77420f73b4612a7a99dba8c2afd30a1886b0344")
      string
      ~error_msg:"Expected address to be %R but was %L.") ;

  (* check tx status *)
  let* () = check_tx_succeeded ~endpoint ~tx in

  (* check account was created *)
  let*! accounts =
    Sc_rollup_client.inspect_durable_state_value
      ~hooks
      sc_rollup_client
      ~pvm_kind
      ~operation:Sc_rollup_client.Subkeys
      ~key:Durable_storage_path.eth_accounts
  in
  Check.(
    list_mem
      string
      (Helpers.normalize address)
      (List.map String.lowercase_ascii accounts)
      ~error_msg:"Expected %L account to be initialized by contract creation.") ;

  (* minting / burning *)
  let call_mint (sender : Eth_account.t) n =
    Eth_cli.contract_send
      ~source_private_key:sender.private_key
      ~endpoint
      ~abi_label:erc20.label
      ~address
      ~method_call:(Printf.sprintf "mint(%d)" n)
  in
  let call_burn ?(expect_failure = false) (sender : Eth_account.t) n =
    Eth_cli.contract_send
      ~expect_failure
      ~source_private_key:sender.private_key
      ~endpoint
      ~abi_label:erc20.label
      ~address
      ~method_call:(Printf.sprintf "burn(%d)" n)
  in

  (* sender mints 42 *)
  let* tx =
    wait_for_application ~sc_rollup_node ~node ~client (call_mint sender 42) ()
  in
  let* () = check_tx_succeeded ~endpoint ~tx in

  (* totalSupply is the first value in storage *)
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:42 in

  (* player mints 100 *)
  let* tx =
    wait_for_application ~sc_rollup_node ~node ~client (call_mint player 100) ()
  in
  let* () = check_tx_succeeded ~endpoint ~tx in
  (* totalSupply is the first value in storage *)
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:142 in

  (* sender tries to burn 100, should fail *)
  let* _tx =
    wait_for_application
      ~sc_rollup_node
      ~node
      ~client
      (call_burn ~expect_failure:true sender 100)
      ()
  in
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:142 in

  (* sender tries to burn 42, should succeed *)
  let* tx =
    wait_for_application ~sc_rollup_node ~node ~client (call_burn sender 42) ()
  in
  let* () = check_tx_succeeded ~endpoint ~tx in
  let* () = check_nb_in_storage ~evm_setup ~address ~nth:0 ~expected:100 in
  unit

let transfer ?data protocol =
  let* ({evm_proxy_server; _} as full_evm_setup) =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
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
  (* Perform some sanity checks on the transaction object produced by the
     kernel. *)
  let* tx_object = Eth_cli.transaction_get ~endpoint ~tx_hash:tx in
  let tx_object =
    match tx_object with
    | Some tx_object -> tx_object
    | None -> Test.fail "The transaction object of %s should be available" tx
  in
  Check.((tx_object.from = sender.address) string)
    ~error_msg:"Unexpected transaction's sender" ;
  Check.((tx_object.to_ = Some receiver.address) (option string))
    ~error_msg:"Unexpected transaction's receiver" ;
  Check.((tx_object.value = value) Wei.typ)
    ~error_msg:"Unexpected transaction's value" ;
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

module Test_rpc = struct
  let getBalance =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "get_balance"]
      ~title:"RPC method eth_getBalance"
    @@ fun protocol ->
    let* {evm_proxy_server; _} =
      setup_past_genesis ~deposit_admin:None protocol
    in
    let evm_proxy_server_endpoint =
      Evm_proxy_server.endpoint evm_proxy_server
    in
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

  let getBlockByNumber =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "get_block_by_number"]
      ~title:"RPC method eth_getBlockByNumber"
    @@ fun protocol ->
    let* {evm_proxy_server; _} =
      setup_past_genesis ~deposit_admin:None protocol
    in
    let evm_proxy_server_endpoint =
      Evm_proxy_server.endpoint evm_proxy_server
    in
    let* block =
      Eth_cli.get_block ~block_id:"0" ~endpoint:evm_proxy_server_endpoint
    in
    Check.((block.number = 0l) int32)
      ~error_msg:"Unexpected block number, should be %%R, but got %%L" ;
    unit

  let getTransactionCount =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "get_transaction_count"]
      ~title:"RPC method eth_getTransactionCount"
    @@ fun protocol ->
    let* {evm_proxy_server; _} =
      setup_past_genesis ~deposit_admin:None protocol
    in
    let* transaction_count =
      get_transaction_count
        evm_proxy_server
        Eth_account.bootstrap_accounts.(0).address
    in
    Check.((transaction_count = 0L) int64)
      ~error_msg:"Expected a nonce of %R, but got %L" ;
    unit

  let getTransactionCountBatch =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "get_transaction_count_as_batch"]
      ~title:"RPC method eth_getTransactionCount in batch"
    @@ fun protocol ->
    let* {evm_proxy_server; _} =
      setup_past_genesis ~deposit_admin:None protocol
    in
    let* transaction_count =
      get_transaction_count
        evm_proxy_server
        Eth_account.bootstrap_accounts.(0).address
    in
    let* transaction_count_batch =
      let* transaction_count =
        Evm_proxy_server.batch_evm_rpc
          evm_proxy_server
          [transaction_count_request Eth_account.bootstrap_accounts.(0).address]
      in
      match JSON.as_list transaction_count with
      | [transaction_count] ->
          return JSON.(transaction_count |-> "result" |> as_int64)
      | _ -> Test.fail "Unexpected result from batching one request"
    in
    Check.((transaction_count = transaction_count_batch) int64)
      ~error_msg:
        "Nonce from a single request is %L, but got %R from batching it" ;
    unit

  let batch =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "rpc"; "batch"]
      ~title:"RPC batch requests"
    @@ fun protocol ->
    let* {evm_proxy_server; _} =
      setup_past_genesis ~deposit_admin:None protocol
    in
    let* transaction_count, chain_id =
      let transaction_count =
        transaction_count_request Eth_account.bootstrap_accounts.(0).address
      in
      let chain_id =
        Evm_proxy_server.{method_ = "eth_chainId"; parameters = `Null}
      in
      let* results =
        Evm_proxy_server.batch_evm_rpc
          evm_proxy_server
          [transaction_count; chain_id]
      in
      match JSON.as_list results with
      | [transaction_count; chain_id] ->
          return
            ( JSON.(transaction_count |-> "result" |> as_int64),
              JSON.(chain_id |-> "result" |> as_int64) )
      | _ -> Test.fail "Unexpected result from batching two requests"
    in
    Check.((transaction_count = 0L) int64)
      ~error_msg:"Expected a nonce of %R, but got %L" ;
    (* Default chain id for Ethereum custom networks, not chosen randomly. *)
    let default_chain_id = 1337L in
    Check.((chain_id = default_chain_id) int64)
      ~error_msg:"Expected a chain_id of %R, but got %L" ;
    unit

  let txpool_content =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "txpool_content"]
      ~title:"Check RPC txpool_content is available"
    @@ fun _protocol ->
    let* evm_proxy_server = setup_mockup () in
    (* The content of the txpool is not relevant for now, this test only checks
       the the RPC is correct, i.e. an object containing both the `pending` and
       `queued` fields, containing the correct objects: addresses pointing to a
       mapping of nonces to transactions. *)
    let* _result = Evm_proxy_server.txpool_content evm_proxy_server in
    unit

  let web3_clientVersion =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "client_version"]
      ~title:"Check RPC web3_clientVersion"
    @@ fun _protocol ->
    let* evm_proxy_server = setup_mockup () in
    let* web3_clientVersion =
      Evm_proxy_server.(
        call_evm_rpc
          evm_proxy_server
          {method_ = "web3_clientVersion"; parameters = `A []})
    in
    let* server_version =
      evm_proxy_server_version evm_proxy_server |> Runnable.run
    in
    Check.(
      (JSON.(web3_clientVersion |-> "result" |> as_string)
      = JSON.as_string server_version)
        string)
      ~error_msg:"Expected version %%R, got %%L." ;
    unit

  let estimate_gas =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "estimate_gas"; "simulate"]
      ~title:"Try to estimate gas for contract creation"
      (fun protocol ->
        (* setup *)
        let* {evm_proxy_server; _} =
          setup_past_genesis protocol ~deposit_admin:None
        in
        (* large request *)
        let data = read_file simple_storage.bin in
        let eth_call = [("data", Ezjsonm.encode_string @@ "0x" ^ data)] in
        (* make call to proxy *)
        let* call_result =
          Evm_proxy_server.(
            call_evm_rpc
              evm_proxy_server
              {method_ = "eth_estimateGas"; parameters = `A [`O eth_call]})
        in
        (* Check the RPC returns a `result`. *)
        let r = call_result |> Evm_proxy_server.extract_result in
        Check.((JSON.as_int r = 21123) int)
          ~error_msg:"Expected result greater than %R, but got %L" ;
        unit)

  let estimate_gas_additionnal_field =
    Protocol.register_test
      ~__FILE__
      ~tags:["evm"; "estimate_gas"; "simulate"; "remix"]
      ~title:"eth_estimateGas allows additional fields"
      (fun protocol ->
        (* setup *)
        let* {evm_proxy_server; _} =
          setup_past_genesis protocol ~deposit_admin:None
        in
        (* large request *)
        let data = read_file simple_storage.bin in
        let eth_call =
          [
            ( "from",
              Ezjsonm.encode_string
              @@ "0x6ce4d79d4e77402e1ef3417fdda433aa744c6e1c" );
            ("data", Ezjsonm.encode_string @@ "0x" ^ data);
            ("value", Ezjsonm.encode_string @@ "0x0");
            (* for some reason remix adds the "type" field *)
            ("type", Ezjsonm.encode_string @@ "0x1");
          ]
        in
        (* make call to proxy *)
        let* call_result =
          Evm_proxy_server.(
            call_evm_rpc
              evm_proxy_server
              {method_ = "eth_estimateGas"; parameters = `A [`O eth_call]})
        in
        (* Check the RPC returns a `result`. *)
        let r = call_result |> Evm_proxy_server.extract_result in
        Check.((JSON.as_int r = 21123) int)
          ~error_msg:"Expected result greater than %R, but got %L" ;
        unit)
end

let test_simulate =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "simulate"]
    ~title:"A block can be simulated in the rollup node"
    (fun protocol ->
      let* {evm_proxy_server; sc_rollup_client; _} =
        setup_past_genesis ~deposit_admin:None protocol
      in
      let* json =
        Evm_proxy_server.call_evm_rpc
          evm_proxy_server
          {method_ = "eth_blockNumber"; parameters = `A []}
      in
      let block_number =
        JSON.(json |-> "result" |> as_string |> int_of_string)
      in
      let*! simulation_result =
        Sc_rollup_client.simulate
          ~insight_requests:
            [`Durable_storage_key ["evm"; "blocks"; "current"; "number"]]
          sc_rollup_client
          []
      in
      let simulated_block_number =
        match simulation_result.insights with
        | [insight] ->
            Option.map
              (fun hex -> `Hex hex |> Hex.to_string |> Z.of_bits |> Z.to_int)
              insight
        | _ -> None
      in
      Check.((simulated_block_number = Some (block_number + 1)) (option int))
        ~error_msg:"The simulation should advance one L2 block" ;
      unit)

let test_full_blocks =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "full_blocks"]
    ~title:
      "Check `evm_getBlockByNumber` with full blocks returns the correct \
       informations"
  @@ fun protocol ->
  let* {evm_proxy_server; sc_rollup_node; node; client; _} =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let txs =
    read_file (kernel_inputs_path ^ "/100-inputs-for-proxy")
    |> String.trim |> String.split_on_char '\n'
    |> List.filteri (fun i _ -> i < 5)
  in
  let* _requests, receipt =
    send_n_transactions ~sc_rollup_node ~node ~client ~evm_proxy_server txs
  in
  let* block =
    Evm_proxy_server.(
      call_evm_rpc
        evm_proxy_server
        {
          method_ = "eth_getBlockByNumber";
          parameters =
            `A [`String (Format.sprintf "%#lx" receipt.blockNumber); `Bool true];
        })
  in
  let block = block |> Evm_proxy_server.extract_result |> Block.of_json in
  let block_hash =
    match block.hash with
    | Some hash -> hash
    | None -> Test.fail "Expected a hash for the block"
  in
  let block_number = block.number in
  (match block.Block.transactions with
  | Block.Empty -> Test.fail "Expected a non empty block"
  | Block.Full transactions ->
      List.iteri
        (fun index
             ({blockHash; blockNumber; transactionIndex; _} :
               Transaction.transaction_object) ->
          Check.((block_hash = blockHash) string)
            ~error_msg:
              (sf "The transaction should be in block %%L but found %%R") ;
          Check.((block_number = blockNumber) int32)
            ~error_msg:
              (sf "The transaction should be in block %%L but found %%R") ;
          Check.((Int32.of_int index = transactionIndex) int32)
            ~error_msg:
              (sf "The transaction should be at index %%L but found %%R"))
        transactions
  | Block.Hash _ -> Test.fail "Block is supposed to contain transaction objects") ;
  unit

let test_latest_block =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "blocks"; "latest"]
    ~title:
      "Check `evm_getBlockByNumber` works correctly when asking for the \
       `latest`"
  @@ fun protocol ->
  let* {evm_proxy_server; _} =
    setup_past_genesis ~deposit_admin:None protocol
  in
  (* The first execution of the kernel actually builds two blocks: the genesis
     block and the block for the current inbox. As such, the latest block is
     always of level 1. *)
  let* latest_block =
    Evm_proxy_server.(
      call_evm_rpc
        evm_proxy_server
        {
          method_ = "eth_getBlockByNumber";
          parameters = `A [`String "latest"; `Bool false];
        })
  in
  let latest_block =
    latest_block |> Evm_proxy_server.extract_result |> Block.of_json
  in
  Check.((latest_block.Block.number = 1l) int32)
    ~error_msg:"Expected latest being block number %R, but got %L" ;
  unit

let test_eth_call_nullable_recipient =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "eth_call"; "null"]
    ~title:"Check `eth_call.to` input can be null"
  @@ fun protocol ->
  let* {evm_proxy_server; _} =
    setup_past_genesis ~deposit_admin:None protocol
  in
  let* call_result =
    Evm_proxy_server.(
      call_evm_rpc
        evm_proxy_server
        {
          method_ = "eth_call";
          parameters = `A [`O [("to", `Null)]; `String "latest"];
        })
  in
  (* Check the RPC returns a `result`. *)
  let _result = call_result |> Evm_proxy_server.extract_result in
  unit

let test_inject_100_transactions =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "bigger_blocks"]
    ~title:"Check blocks can contain more than 64 transactions"
  @@ fun protocol ->
  let* {evm_proxy_server; sc_rollup_node; node; client; _} =
    setup_past_genesis ~deposit_admin:None protocol
  in
  (* Retrieves all the messages and prepare them for the current rollup. *)
  let txs =
    read_file (kernel_inputs_path ^ "/100-inputs-for-proxy")
    |> String.trim |> String.split_on_char '\n'
  in
  let* requests, receipt =
    send_n_transactions ~sc_rollup_node ~node ~client ~evm_proxy_server txs
  in
  let* block_with_100tx =
    Evm_proxy_server.(
      call_evm_rpc
        evm_proxy_server
        {
          method_ = "eth_getBlockByNumber";
          parameters =
            `A
              [`String (Format.sprintf "%#lx" receipt.blockNumber); `Bool false];
        })
  in
  let block_with_100tx =
    block_with_100tx |> Evm_proxy_server.extract_result |> Block.of_json
  in
  (match block_with_100tx.Block.transactions with
  | Block.Empty -> Test.fail "Expected a non empty block"
  | Block.Full _ ->
      Test.fail "Block is supposed to contain only transaction hashes"
  | Block.Hash hashes ->
      Check.((List.length hashes = List.length requests) int)
        ~error_msg:"Expected %R transactions in the latest block, got %L") ;

  let* _level = next_evm_level ~sc_rollup_node ~node ~client in
  let* latest_evm_level =
    Evm_proxy_server.(
      call_evm_rpc
        evm_proxy_server
        {method_ = "eth_blockNumber"; parameters = `A []})
  in
  let latest_evm_level =
    latest_evm_level |> Evm_proxy_server.extract_result |> JSON.as_int32
  in
  (* At each loop, the kernel reads the previous block. Until the patch, the
     kernel failed to read the previous block if there was more than 64 hash,
     this test ensures it works by assessing new blocks are produced. *)
  Check.((latest_evm_level >= Int32.succ block_with_100tx.Block.number) int32)
    ~error_msg:
      "Expected a new block after the one with 100 transactions, but level \
       hasn't changed" ;
  unit

let test_eth_call_large =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "eth_call"; "simulate"; "large"]
    ~title:"Try to call with a large amount of data"
    (fun protocol ->
      (* setup *)
      let* {evm_proxy_server; _} =
        setup_past_genesis ~deposit_admin:None protocol
      in
      let sender = Eth_account.bootstrap_accounts.(0) in

      (* large request *)
      let eth_call =
        [
          ("to", Ezjsonm.encode_string sender.address);
          ("data", Ezjsonm.encode_string ("0x" ^ String.make 12_000 'a'));
        ]
      in

      (* make call to proxy *)
      let* call_result =
        Evm_proxy_server.(
          call_evm_rpc
            evm_proxy_server
            {
              method_ = "eth_call";
              parameters = `A [`O eth_call; `String "latest"];
            })
      in

      (* Check the RPC returns a `result`. *)
      let r = call_result |> Evm_proxy_server.extract_result in
      Check.((JSON.as_string r = "0x") string)
        ~error_msg:"Expected result %R, but got %L" ;

      unit)

let test_eth_call_storage_contract_rollup_node =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "eth_call"; "simulate"]
    ~title:"Try to call a view (directly through proxy)"
    (fun protocol ->
      (* setup *)
      let* ({evm_proxy_server; endpoint; _} as evm_setup) =
        setup_past_genesis ~deposit_admin:None protocol
      in

      let sender = Eth_account.bootstrap_accounts.(0) in

      (* deploy contract *)
      let* address, tx = deploy ~contract:simple_storage ~sender evm_setup in
      let* () = check_tx_succeeded ~endpoint ~tx in
      Check.(
        (String.lowercase_ascii address
        = "0xd77420f73b4612a7a99dba8c2afd30a1886b0344")
          string
          ~error_msg:"Expected address to be %R but was %L.") ;

      (* craft request *)
      let data = "0x4e70b1dc" in
      let eth_call =
        [
          ("to", Ezjsonm.encode_string address);
          ("data", Ezjsonm.encode_string data);
        ]
      in

      (* make call to proxy *)
      let* call_result =
        Evm_proxy_server.(
          call_evm_rpc
            evm_proxy_server
            {
              method_ = "eth_call";
              parameters = `A [`O eth_call; `String "latest"];
            })
      in

      let r = call_result |> Evm_proxy_server.extract_result in
      Check.(
        (JSON.as_string r
       = "0x0000000000000000000000000000000000000000000000000000000000000000")
          string)
        ~error_msg:"Expected result %R, but got %L" ;

      let* tx = send_call_set_storage_simple address sender 42 evm_setup in
      let* () = check_tx_succeeded ~endpoint ~tx in

      (* make call to proxy *)
      let* call_result =
        Evm_proxy_server.(
          call_evm_rpc
            evm_proxy_server
            {
              method_ = "eth_call";
              parameters = `A [`O eth_call; `String "latest"];
            })
      in
      let r = call_result |> Evm_proxy_server.extract_result in
      Check.(
        (JSON.as_string r
       = "0x000000000000000000000000000000000000000000000000000000000000002a")
          string)
        ~error_msg:"Expected result %R, but got %L" ;
      unit)

let test_eth_call_storage_contract_proxy =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "simulate"]
    ~title:"Try to call a view (directly through rollup node)"
    (fun protocol ->
      let* ({sc_rollup_client; evm_proxy_server; _} as evm_setup) =
        setup_past_genesis ~deposit_admin:None protocol
      in

      let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
      let sender = Eth_account.bootstrap_accounts.(0) in

      (* deploy contract *)
      let* address, tx = deploy ~contract:simple_storage ~sender evm_setup in
      let* () = check_tx_succeeded ~endpoint ~tx in

      Check.(
        (String.lowercase_ascii address
        = "0xd77420f73b4612a7a99dba8c2afd30a1886b0344")
          string
          ~error_msg:"Expected address to be %R but was %L.") ;

      let*! simulation_result =
        Sc_rollup_client.simulate
          ~insight_requests:
            [
              `Durable_storage_key ["evm"; "simulation_result"];
              `Durable_storage_key ["evm"; "simulation_status"];
            ]
          sc_rollup_client
          [
            Hex.to_string @@ `Hex "ff";
            Hex.to_string
            @@ `Hex
                 "ff01e68094d77420f73b4612a7a99dba8c2afd30a1886b03448857040000000000008080844e70b1dc";
          ]
      in
      let expected_insights =
        [
          Some "0000000000000000000000000000000000000000000000000000000000000000";
          Some "01";
        ]
      in
      Check.(
        (simulation_result.insights = expected_insights) (list @@ option string))
        ~error_msg:"Expected result %R, but got %L" ;
      unit)

let test_eth_call_storage_contract_eth_cli =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "eth_call"; "simulate"]
    ~title:"Try to call a view through an ethereum client"
    (fun protocol ->
      (* setup *)
      let* ({evm_proxy_server; endpoint; sc_rollup_node; client; node; _} as
           evm_setup) =
        setup_past_genesis ~deposit_admin:None protocol
      in

      (* sanity *)
      let* call_result =
        Evm_proxy_server.(
          call_evm_rpc
            evm_proxy_server
            {
              method_ = "eth_call";
              parameters = `A [`O [("to", `Null)]; `String "latest"];
            })
      in
      (* Check the RPC returns a `result`. *)
      let _result = call_result |> Evm_proxy_server.extract_result in

      let sender = Eth_account.bootstrap_accounts.(0) in

      (* deploy contract send send 42 *)
      let* address, _tx = deploy ~contract:simple_storage ~sender evm_setup in
      let* tx = send_call_set_storage_simple address sender 42 evm_setup in
      let* () = check_tx_succeeded ~endpoint ~tx in

      (* make a call to proxy through eth-cli *)
      let call_num =
        Eth_cli.contract_call
          ~endpoint
          ~abi_label:simple_storage.label
          ~address
          ~method_call:"num()"
      in
      let* res =
        wait_for_application ~sc_rollup_node ~node ~client call_num ()
      in

      Check.((String.trim res = "42") string)
        ~error_msg:"Expected result %R, but got %L" ;
      unit)

let test_preinitialized_evm_kernel =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "dictator"; "config"]
    ~title:"Creates a kernel with an initialized dictator key"
  @@ fun protocol ->
  let dictator_key_path = Durable_storage_path.dictator in
  let dictator_key = Eth_account.bootstrap_accounts.(0).address in
  let config =
    Sc_rollup_helpers.Installer_kernel_config.
      [
        Set
          {
            value = Hex.(of_string dictator_key |> show);
            to_ = dictator_key_path;
          };
      ]
  in
  let* {sc_rollup_client; _} =
    setup_evm_kernel ~config ~deposit_admin:None protocol
  in
  let*! found_dictator_key_hex =
    Sc_rollup_client.inspect_durable_state_value
      sc_rollup_client
      ~pvm_kind:"wasm_2_0_0"
      ~operation:Sc_rollup_client.Value
      ~key:dictator_key_path
  in
  let found_dictator_key =
    Option.map
      (fun dictator -> Hex.to_string (`Hex dictator))
      found_dictator_key_hex
  in
  Check.((Some dictator_key = found_dictator_key) (option string))
    ~error_msg:
      (sf "Expected to read %%L as dictator key, but found %%R instead") ;
  unit

let test_deposit_fa12 =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "deposit"]
    ~title:"Deposit FA1.2 token"
  @@ fun protocol ->
  let admin = Constant.bootstrap5 in
  let* {
         client;
         sc_rollup_address;
         deposit_addresses;
         sc_rollup_node;
         node;
         endpoint;
         _;
       } =
    setup_evm_kernel ~deposit_admin:(Some admin) protocol
  in
  let {fa12; bridge} =
    match deposit_addresses with
    | Some x -> x
    | None -> Test.fail ~__LOC__ "The test needs the L1 bridge"
  in

  (* Asserts that L1 bridge targets the EVM rollup. *)
  let* bridge_evm_storage =
    RPC.Client.call client
    @@ RPC.get_chain_block_context_contract_storage ~id:bridge ()
  in
  let bridge_evm_rollup =
    match JSON.encode bridge_evm_storage =~* rex "\"(sr1.+)\"" with
    | Some rollup -> rollup
    | None ->
        Test.fail ~__LOC__ "EVM rollup address not found in bridge contract"
  in
  Check.((sc_rollup_address = bridge_evm_rollup) string)
    ~error_msg:
      (sf
         "The bridge does not target the expected EVM rollup, found %%R \
          expected %%L") ;

  (* Gives enough allowance to the bridge. *)
  let amount_cmutez = 100_000_000 in
  let amount_ctez = 100 in
  let* () =
    Client.from_fa1_2_contract_approve
      ~burn_cap:Tez.one
      ~contract:fa12
      ~as_:admin.public_key_hash
      ~amount:amount_cmutez
      ~from:bridge
      client
  in
  let* () = Client.bake_for_and_wait client in

  (* Deposit tokens to the EVM rollup. *)
  let receiver = "0x119811f34EF4491014Fbc3C969C426d37067D6A4" in
  let* () =
    Client.transfer
      ~entrypoint:"deposit"
      ~arg:(sf {|Pair (Pair %d %s) 1|} amount_cmutez receiver)
      ~amount:Tez.zero
      ~giver:admin.public_key_hash
      ~receiver:bridge
      ~burn_cap:Tez.one
      client
  in
  let* _ = next_evm_level ~sc_rollup_node ~node ~client in

  (* Check the balance in the EVM rollup. *)
  let* balance = Eth_cli.balance ~account:receiver ~endpoint in
  Check.((balance = Wei.of_eth_int amount_ctez) Wei.typ)
    ~error_msg:
      (sf
         "Expected balance of %s should be %%R, but got %%L"
         Eth_account.bootstrap_accounts.(0).address) ;
  unit

let gen_test_kernel_upgrade ?rollup_address ?(should_fail = false) ?(nonce = 2)
    ~base_installee ~installee ?dictator ~private_key protocol =
  let* {
         node;
         client;
         sc_rollup_node;
         sc_rollup_client;
         sc_rollup_address;
         evm_proxy_server;
         _;
       } =
    setup_evm_kernel ?dictator ~deposit_admin:None protocol
  in
  let sc_rollup_address =
    Option.value ~default:sc_rollup_address rollup_address
  in
  let preimages_dir = Sc_rollup_node.data_dir sc_rollup_node // "wasm_2_0_0" in
  let* _, preimage_root_hash_opt =
    Sc_rollup_helpers.prepare_installer_kernel_gen
      ~preimages_dir
      ~base_installee
      ~display_root_hash:true
      installee
  in
  let preimage_root_hash_bytes =
    match preimage_root_hash_opt with
    | Some preimage_root_hash -> Hex.to_string @@ `Hex preimage_root_hash
    | None ->
        failwith
          "Couldn't obtain the root hash of the preimages of the chunked \
           kernel."
  in
  let* rollup_address_bytes =
    let address_opt =
      Tezos_crypto.Hashed.Smart_rollup_address.of_b58check_opt sc_rollup_address
    in
    match address_opt with
    | Some address ->
        return
        @@ Data_encoding.Binary.to_string_exn
             Tezos_crypto.Hashed.Smart_rollup_address.encoding
             address
    | None -> failwith "Unexpected smart rollup address."
  in
  let upgrade_nonce_bytes = Helpers.u16_to_bytes nonce in
  let message_to_sign =
    rollup_address_bytes ^ upgrade_nonce_bytes ^ preimage_root_hash_bytes
  in
  let* secret_key =
    let sk = Hex.to_string (`Hex (Helpers.no_0x private_key)) in
    match
      Data_encoding.Binary.of_string_opt
        Tezos_crypto.Signature.Secp256k1.Secret_key.encoding
        sk
    with
    | Some sk -> return sk
    | None -> failwith "An invalid secret key was provided."
  in
  let signature =
    Data_encoding.Binary.to_string_exn Tezos_crypto.Signature.Secp256k1.encoding
    @@ Tezos_crypto.Signature.Secp256k1.sign_keccak256
         secret_key
         (String.to_bytes message_to_sign)
  in
  let upgrade_tag_bytes = "\003" in
  let full_external_message =
    Hex.show @@ Hex.of_string @@ rollup_address_bytes ^ upgrade_tag_bytes
    ^ upgrade_nonce_bytes ^ preimage_root_hash_bytes ^ signature
  in
  let get_kernel_boot_wasm () =
    let*! kernel_boot_wasm_after_upgrade_opt =
      Sc_rollup_client.inspect_durable_state_value
        sc_rollup_client
        ~pvm_kind:"wasm_2_0_0"
        ~operation:Sc_rollup_client.Value
        ~key:Durable_storage_path.kernel_boot_wasm
    in
    match kernel_boot_wasm_after_upgrade_opt with
    | Some boot_wasm -> return boot_wasm
    | None -> failwith "Kernel `boot.wasm` should be accessible/readable."
  in
  let* expected_kernel_boot_wasm =
    if should_fail then get_kernel_boot_wasm ()
    else
      return @@ Hex.show @@ Hex.of_string
      @@ read_file (project_root // base_installee // (installee ^ ".wasm"))
  in
  let* () =
    send_external_message_and_wait
      ~sc_rollup_node
      ~node
      ~client
      ~sender:Constant.bootstrap1.public_key_hash
      ~hex_msg:full_external_message
  in
  let* kernel_boot_wasm_after_upgrade = get_kernel_boot_wasm () in
  Check.((expected_kernel_boot_wasm = kernel_boot_wasm_after_upgrade) string)
    ~error_msg:(sf "Unexpected `boot.wasm`.") ;
  return (sc_rollup_node, node, client, evm_proxy_server)

let test_kernel_upgrade_to_debug =
  Protocol.register_test
    ~__FILE__
    ~tags:["debug"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade integrity to a debug kernel"
  @@ fun protocol ->
  let base_installee = "src/kernel_evm/kernel/tests/resources" in
  let installee = "debug_kernel" in
  let dictator = Eth_account.bootstrap_accounts.(0) in
  let* _ =
    gen_test_kernel_upgrade
      ~base_installee
      ~installee
      ~dictator:dictator.public_key
      ~private_key:dictator.private_key
      protocol
  in
  unit

let test_kernel_upgrade_evm_to_evm =
  Protocol.register_test
    ~__FILE__
    ~tags:["evm"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade integrity to itself"
  @@ fun protocol ->
  let base_installee = "./" in
  let installee = "evm_kernel" in
  let dictator = Eth_account.bootstrap_accounts.(0) in
  let* sc_rollup_node, node, client, evm_proxy_server =
    gen_test_kernel_upgrade
      ~base_installee
      ~installee
      ~dictator:dictator.public_key
      ~private_key:dictator.private_key
      protocol
  in
  (* We ensure the upgrade went well by checking if the kernel still produces
     blocks. *)
  let endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  check_block_progression
    ~sc_rollup_node
    ~node
    ~client
    ~endpoint
    ~expected_block_level:2

let test_kernel_upgrade_wrong_key =
  Protocol.register_test
    ~__FILE__
    ~tags:["dictator"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade fails with a wrong dictator key"
  @@ fun protocol ->
  let base_installee = "src/kernel_evm/kernel/tests/resources" in
  let installee = "debug_kernel" in
  let dictator = Eth_account.bootstrap_accounts.(0) in
  let* _ =
    gen_test_kernel_upgrade
      ~should_fail:true
      ~base_installee
      ~installee
      ~dictator:dictator.public_key
      ~private_key:Eth_account.bootstrap_accounts.(1).private_key
      protocol
  in
  unit

let test_kernel_upgrade_wrong_nonce =
  Protocol.register_test
    ~__FILE__
    ~tags:["nonce"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade fails with a wrong upgrade nonce"
  @@ fun protocol ->
  let base_installee = "src/kernel_evm/kernel/tests/resources" in
  let installee = "debug_kernel" in
  let dictator = Eth_account.bootstrap_accounts.(0) in
  let* _ =
    gen_test_kernel_upgrade
      ~nonce:3
      ~should_fail:true
      ~base_installee
      ~installee
      ~dictator:dictator.public_key
      ~private_key:dictator.private_key
      protocol
  in
  unit

let test_kernel_upgrade_wrong_rollup_address =
  Protocol.register_test
    ~__FILE__
    ~tags:["address"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade fails with a wrong rollup address"
  @@ fun protocol ->
  let base_installee = "src/kernel_evm/kernel/tests/resources" in
  let installee = "debug_kernel" in
  let dictator = Eth_account.bootstrap_accounts.(0) in
  let* _ =
    gen_test_kernel_upgrade
      ~rollup_address:"sr1T13qeVewVm3tudQb8dwn8qRjptNo7KVkj"
      ~should_fail:true
      ~base_installee
      ~installee
      ~dictator:dictator.public_key
      ~private_key:dictator.private_key
      protocol
  in
  unit

let test_kernel_upgrade_no_dictator =
  Protocol.register_test
    ~__FILE__
    ~tags:["dictator"; "upgrade"]
    ~title:"Ensures EVM kernel's upgrade fails if there is no dictator"
  @@ fun protocol ->
  let base_installee = "src/kernel_evm/kernel/tests/resources" in
  let installee = "debug_kernel" in
  let* _ =
    gen_test_kernel_upgrade
      ~should_fail:true
      ~base_installee
      ~installee
      ~private_key:Eth_account.bootstrap_accounts.(0).private_key
      protocol
  in
  unit

let register_evm_proxy_server ~protocols =
  test_originate_evm_kernel protocols ;
  test_evm_proxy_server_connection protocols ;
  Test_rpc.getBalance protocols ;
  Test_rpc.getBlockByNumber protocols ;
  Test_rpc.getTransactionCount protocols ;
  Test_rpc.getTransactionCountBatch protocols ;
  Test_rpc.batch protocols ;
  Test_rpc.txpool_content protocols ;
  Test_rpc.web3_clientVersion protocols ;
  Test_rpc.estimate_gas protocols ;
  Test_rpc.estimate_gas_additionnal_field protocols ;
  test_l2_blocks_progression protocols ;
  test_l2_transfer protocols ;
  test_chunked_transaction protocols ;
  test_simulate protocols ;
  test_full_blocks protocols ;
  test_latest_block protocols ;
  test_eth_call_nullable_recipient protocols ;
  test_l2_deploy_simple_storage protocols ;
  test_l2_call_simple_storage protocols ;
  test_l2_deploy_erc20 protocols ;
  test_inject_100_transactions protocols ;
  test_eth_call_storage_contract_rollup_node protocols ;
  test_eth_call_storage_contract_proxy protocols ;
  test_eth_call_storage_contract_eth_cli protocols ;
  test_eth_call_large protocols ;
  test_preinitialized_evm_kernel protocols ;
  test_deposit_fa12 protocols ;
  test_kernel_upgrade_to_debug protocols ;
  test_kernel_upgrade_evm_to_evm protocols ;
  test_kernel_upgrade_wrong_key protocols ;
  test_kernel_upgrade_wrong_nonce protocols ;
  test_kernel_upgrade_wrong_rollup_address protocols ;
  test_kernel_upgrade_no_dictator protocols

let register ~protocols = register_evm_proxy_server ~protocols
