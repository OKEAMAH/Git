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

(** Helpers built upon the Sc_rollup_node and Sc_rollup_client *)

open Sc_rollup_helpers

let pvm_kind = "wasm_2_0_0"

let kernel_inputs_path = "tezt/tests/evm_kernel_inputs"

type full_evm_setup = {
  node : Node.t;
  client : Client.t;
  sc_rollup_node : Sc_rollup_node.t;
  sc_rollup_client : Sc_rollup_client.t;
  sc_rollup_address : string;
  originator_key : string;
  rollup_operator_key : string;
  evm_proxy_server : Evm_proxy_server.t;
}

let hex_256_of n = Printf.sprintf "%064x" n

let no_0x s =
  if String.starts_with ~prefix:"0x" s then String.sub s 2 (String.length s - 2)
  else s

let evm_proxy_server_version proxy_server =
  let endpoint = Evm_proxy_server.endpoint proxy_server in
  let get_version_url = endpoint ^ "/version" in
  RPC.Curl.get get_version_url

let get_transaction_count proxy_server address =
  let parameters : JSON.u = `A [`String address; `String "latest"] in
  let* transaction_count =
    Evm_proxy_server.call_evm_rpc
      proxy_server
      ~method_:"eth_getTransactionCount"
      ~parameters
  in
  return JSON.(transaction_count |-> "result" |> as_int64)

let get_transaction_status ~endpoint ~tx =
  if tx == "" then failwith "no transaction hash, it probably failed." ;
  let* receipt = Eth_cli.get_receipt ~endpoint ~tx in
  return JSON.(receipt |-> "status" |> as_bool)

let check_tx_succeeded ~endpoint ~tx =
  if tx == "" then failwith "no transaction hash, it probably failed." ;
  let* status = get_transaction_status ~endpoint ~tx in
  Check.(is_true status) ~error_msg:"Expected transaction to succeed." ;
  unit

let check_tx_failed ~endpoint ~tx =
  if tx == "" then failwith "no transaction hash, it probably failed." ;
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
    ~key:(Printf.sprintf "/eth_accounts/%s/storage/%064x" (no_0x address) nth)

let check_str_in_storage ~evm_setup ~address ~nth ~expected =
  let*! value = get_value_in_storage evm_setup.sc_rollup_client address nth in
  Check.((value = Some expected) (option string))
    ~error_msg:"Unexpected value in storage, should be %R, but got %L" ;
  unit

let check_nb_in_storage ~evm_setup ~address ~nth ~expected =
  let* () =
    check_str_in_storage
      ~evm_setup
      ~address
      ~nth
      ~expected:(hex_256_of expected)
  in
  unit

let get_storage_size sc_rollup_client ~address =
  let*! storage =
    Sc_rollup_client.inspect_durable_state_value
      ~hooks
      sc_rollup_client
      ~pvm_kind
      ~operation:Sc_rollup_client.Subkeys
      ~key:(Printf.sprintf "/eth_accounts/%s/storage" (no_0x address))
  in
  return (List.length storage)

let next_evm_level ~sc_rollup_node ~node ~client =
  let* () = Client.bake_for_and_wait client in
  Sc_rollup_node.wait_for_level
    ~timeout:30.
    sc_rollup_node
    (Node.get_level node)

let wait_for_application ~sc_rollup_node ~node ~client apply () =
  let* start_level = Client.level client in
  let max_iteration = 10 in
  let tx_hash = apply () in
  let rec loop () =
    let* () = Lwt_unix.sleep 5. in
    let* new_level = next_evm_level ~sc_rollup_node ~node ~client in
    if start_level + max_iteration < new_level then
      Test.fail
        "Baked more than %d blocks and the operation's application is still \
         pending"
        max_iteration ;
    if Lwt.state tx_hash = Lwt.Sleep then loop () else unit
  in
  (* Using [Lwt.both] ensures that any exception thrown in [tx_hash] will be
     thrown by [Lwt.both] as well. *)
  let* res, () = Lwt.both tx_hash (loop ()) in
  return res

let setup_evm_kernel ?(originator_key = Constant.bootstrap1.public_key_hash)
    ?(rollup_operator_key = Constant.bootstrap1.public_key_hash) protocol =
  let* node, client = setup_l1 protocol in
  let sc_rollup_node =
    Sc_rollup_node.create
      ~protocol
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
      "evm_kernel"
  in
  let* sc_rollup_address =
    originate_sc_rollup
      ~kind:pvm_kind
      ~boot_sector
      ~parameters_ty:"pair string (ticket string)"
      ~src:originator_key
      client
  in
  let* () = Sc_rollup_node.run sc_rollup_node sc_rollup_address [] in
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
    }

type contract = {label : string; abi : string; bin : string}

let deploy ~contract ~sender full_evm_setup =
  let {node; client; sc_rollup_node; evm_proxy_server; _} = full_evm_setup in
  let evm_proxy_server_endpoint = Evm_proxy_server.endpoint evm_proxy_server in
  let* () = Eth_cli.add_abi ~label:contract.label ~abi:contract.abi () in
  let send_deploy =
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
