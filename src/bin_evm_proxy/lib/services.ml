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

open Tezos_rpc
open Rpc_encodings

let version_service =
  Service.get_service
    ~description:"version"
    ~query:Query.empty
    ~output:Data_encoding.string
    Path.(root / "version")

let client_version =
  Format.sprintf
    "%s/%s-%s/%s/ocamlc.%s"
    "octez-evm-proxy-server"
    (Tezos_version.Version.to_string
       Tezos_version_value.Current_git_info.version)
    Tezos_version_value.Current_git_info.abbreviated_commit_hash
    Stdlib.Sys.os_type
    Stdlib.Sys.ocaml_version

let version dir =
  Directory.register0 dir version_service (fun () () ->
      Lwt.return_ok client_version)

(* The proxy server can either take a single request or multiple requests at
   once. *)
type 'a batchable = Singleton of 'a | Batch of 'a list

let batchable_encoding kind =
  Data_encoding.(
    union
      [
        case
          ~title:"singleton"
          (Tag 0)
          kind
          (function Singleton i -> Some i | _ -> None)
          (fun i -> Singleton i);
        case
          ~title:"batch"
          (Tag 1)
          (list kind)
          (function Batch i -> Some i | _ -> None)
          (fun i -> Batch i);
      ])

type 'a failable = Valid of 'a | Invalid of Data_encoding.json

let failable_encoding input_encoding =
  Data_encoding.(
    union
      [
        case
          ~title:"valid"
          (Tag 0)
          input_encoding
          (function Valid (input, id) -> Some (input, id) | _ -> None)
          (fun (input, id) -> Valid (input, id));
        case
          ~title:"invalid"
          (Tag 1)
          json
          (function Invalid json -> Some json | _ -> None)
          (fun json -> Invalid json);
      ])

let dispatch_service =
  Service.post_service
    ~query:Query.empty
      (* The service decodes a JSON and not a specific encoding. Decoding and
         error handling is up to the service implementation. *)
    ~input:Data_encoding.json
    ~output:
      (batchable_encoding
         (JSONRPC.response_encoding Output.encoding Error.data_encoding))
    Path.(root)

let get_block ~full_transaction_object block_param
    (module Rollup_node_rpc : Rollup_node.S) =
  match block_param with
  | Ethereum_types.(Hash_param (Block_height n)) ->
      Rollup_node_rpc.nth_block ~full_transaction_object n
  | Latest | Earliest | Pending ->
      Rollup_node_rpc.current_block ~full_transaction_object

let rpc_fail err id = JSONRPC.{value = Error (Error.rpc_error_of_kind err); id}

let dispatch_input
    ((module Rollup_node_rpc : Rollup_node.S), smart_rollup_address) (input, id)
    =
  let open Lwt_result_syntax in
  let return value = return JSONRPC.{value = Ok value; id} in
  match input with
  | Accounts.Input _ -> return (Accounts.Output [])
  | Network_id.Input _ ->
      let* (Qty chain_id) = Rollup_node_rpc.chain_id () in
      let net_version = Z.to_string chain_id in
      return (Network_id.Output net_version)
  | Chain_id.Input _ ->
      let* chain_id = Rollup_node_rpc.chain_id () in
      return (Chain_id.Output chain_id)
  | Get_balance.Input (Some (address, _block_param)) ->
      let* balance = Rollup_node_rpc.balance address in
      return (Get_balance.Output balance)
  | Block_number.Input _ ->
      let* block_number = Rollup_node_rpc.current_block_number () in
      return (Block_number.Output block_number)
  | Get_block_by_number.Input (Some (block_param, full_transaction_object)) ->
      let* block =
        get_block ~full_transaction_object block_param (module Rollup_node_rpc)
      in
      return (Get_block_by_number.Output block)
  | Get_block_by_number.Input None ->
      return
        (Get_block_by_number.Output Mockup.(block (TxHash [transaction_hash])))
  | Get_block_by_hash.Input _ ->
      return
        (Get_block_by_hash.Output Mockup.(block (TxHash [transaction_hash])))
  | Get_code.Input (Some (address, _)) ->
      let* code = Rollup_node_rpc.code address in
      return (Get_code.Output code)
  | Gas_price.Input _ -> return (Gas_price.Output Mockup.gas_price)
  | Get_transaction_count.Input (Some (address, _)) ->
      let* nonce = Rollup_node_rpc.nonce address in
      return (Get_transaction_count.Output nonce)
  | Get_transaction_receipt.Input (Some tx_hash) ->
      let* receipt = Rollup_node_rpc.transaction_receipt tx_hash in
      return (Get_transaction_receipt.Output receipt)
  | Get_transaction_by_hash.Input (Some tx_hash) ->
      let* transaction_object = Rollup_node_rpc.transaction_object tx_hash in
      return (Get_transaction_by_hash.Output transaction_object)
  | Send_raw_transaction.Input (Some tx_raw) ->
      let* tx_hash =
        Rollup_node_rpc.inject_raw_transaction ~smart_rollup_address tx_raw
      in
      return (Send_raw_transaction.Output tx_hash)
  | Send_transaction.Input _ ->
      return (Send_transaction.Output Mockup.transaction_hash)
  | Eth_call.Input _ -> return (Eth_call.Output Mockup.call)
  | Get_estimate_gas.Input _ ->
      return (Get_estimate_gas.Output Mockup.gas_price)
  | Txpool_content.Input _ ->
      let* txpool = Rollup_node_rpc.txpool () in
      return (Txpool_content.Output txpool)
  | Web3_clientVersion.Input _ ->
      return (Web3_clientVersion.Output client_version)
  | _ ->
      Lwt.return_ok
        (rpc_fail
           (Error.Invalid_method_parameters
              ("", Data_encoding.Json.construct Input.encoding (input, id)))
           id)

let rpc_id fields =
  match List.assoc_opt ~equal:String.equal "id" fields with
  | None -> None
  | Some id -> (
      try Some (Data_encoding.Json.destruct JSONRPC.id_repr_encoding id)
      with _ -> None)

let is_method_implemented m =
  List.exists (fun (module M : METHOD) -> M.method_ = m) methods

(* If the method is known but still cannot be decoded, this implies that the
   parameters are invalid. *)
let if_field_method_exists meth fields json =
  match meth with
  | `String m when is_method_implemented m -> (
      match List.assoc_opt ~equal:String.equal "params" fields with
      | Some input -> rpc_fail (Error.Invalid_method_parameters (m, input))
      | _ -> rpc_fail (Error.Invalid_request json))
  | `String m -> rpc_fail (Error.Method_not_found m)
  | _ -> rpc_fail (Error.Invalid_request json)

(* Check the only fields are the one from JSONRPC specification, and returns the
   method name. *)
let check_fields_and_return_method fields =
  if
    List.for_all
      (function
        | "jsonrpc", version -> version = `String JSONRPC.version
        | "method", _ | "params", _ | "id", _ -> true
        | _ -> false)
      fields
  then List.assoc_opt ~equal:String.equal "method" fields
  else None

(* [on_invalid_input json] is used when decoding fails and attempts to find the
   most precise error:
   - If the JSON is not an object then the request is invalid.
   - If the JSON does not have exclusively the JSONRPC specified fields then the
   request is invalid.
   - If the method is not in the list of known methods, then the method is not
   implemented.
   - Otherwise this implies the parameters for the given method are invalid.
*)
let on_invalid_input json =
  match json with
  | `O fields -> (
      let id = rpc_id fields in
      match check_fields_and_return_method fields with
      | Some meth -> if_field_method_exists meth fields json id
      | _ -> rpc_fail (Error.Invalid_request json) id)
  | _ -> rpc_fail (Error.Invalid_request json) None

let dispatch_failable_input ctx = function
  | Valid input -> dispatch_input ctx input
  | Invalid json -> Lwt.return_ok (on_invalid_input json)

let dispatch ctx dir =
  Directory.register0 dir dispatch_service (fun () input ->
      let decode_and_dispatch json =
        Data_encoding.Json.destruct Input.encoding json |> dispatch_input ctx
      in
      let open Lwt_result_syntax in
      match input with
      | `O _ ->
          let+ output = decode_and_dispatch input in
          Singleton output
      | `A inputs ->
          let+ outputs = List.map_es decode_and_dispatch inputs in
          Batch outputs
      | _ -> return (Singleton (rpc_fail (Error.Invalid_request input) None)))

let directory (rollup_node_config : (module Rollup_node.S) * string) =
  Directory.empty |> version |> dispatch rollup_node_config
