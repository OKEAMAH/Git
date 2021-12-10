(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2021 Marigold, <team@marigold.dev>                          *)
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

type t = {
  data_dir : string;
  client_keys : Client_keys.Public_key_hash.t;
  rollup_id : Protocol.Alpha_context.Tx_rollup.t;
  block_hash : Block_hash.t;
  rpc_addr : string;
  rpc_port : int;
}

let default_data_dir =
  let home = Sys.getenv "HOME" and dir = ".tezos-tx-rollup-node" in
  Filename.concat home dir

let default_rpc_addr = "127.0.0.1"

let default_rpc_port = 9999

let default_dormant_mode = false

let project {data_dir; client_keys; rollup_id; block_hash; rpc_addr; rpc_port} =
  (data_dir, client_keys, rollup_id, block_hash, rpc_addr, rpc_port)

let inject (data_dir, client_keys, rollup_id, block_hash, rpc_addr, rpc_port) =
  {data_dir; client_keys; rollup_id; block_hash; rpc_addr; rpc_port}

let encoding_data_dir =
  Data_encoding.dft
    ~description:"Location of the data dir"
    "data-dir"
    Data_encoding.string
    default_data_dir

let encoding_client_keys =
  Data_encoding.req
    ~description:"Client keys"
    "client-keys"
    Client_keys.Public_key_hash.encoding

let encoding_rollup_id =
  Data_encoding.req
    ~description:"Rollup id of the rollup to target"
    "rollup-id"
    Protocol.Alpha_context.Tx_rollup.encoding

let encoding_block_hash =
  Data_encoding.req
    ~description:"Hash of the block wherein the rollup was created"
    "block-hash"
    Block_hash.encoding

let encoding_rpc_addr =
  Data_encoding.dft
    ~description:"RPC address listens by the node"
    "rpc-addr"
    Data_encoding.string
    default_rpc_addr

let encoding_rpc_port =
  Data_encoding.dft
    ~description:"RPC port listens by the node"
    "rpc-port"
    Data_encoding.int16
    default_rpc_port

let encoding =
  let open Data_encoding in
  conv project inject
  @@ obj6
       encoding_data_dir
       encoding_client_keys
       encoding_rollup_id
       encoding_block_hash
       encoding_rpc_addr
       encoding_rpc_port

let get_configuration_filename_from data_dir =
  let filename = "config.json" in
  Filename.concat data_dir filename

let get_configuration_filename configuration =
  get_configuration_filename_from configuration.data_dir

let save configuration =
  let open Lwt_syntax in
  let json = Data_encoding.Json.construct encoding configuration in
  let* () = Lwt_utils_unix.create_dir configuration.data_dir in
  let file = get_configuration_filename configuration in
  Lwt_utils_unix.Json.write_file file json

let load ~data_dir =
  let open Lwt_result_syntax in
  let file = get_configuration_filename_from data_dir in
  let+ json = Lwt_utils_unix.Json.read_file file in
  Data_encoding.Json.destruct encoding json
