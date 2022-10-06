(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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
  sc_rollup_node_data_dir : string;
  rpc_addr : string;
  rpc_port : int;
}

let default_data_dir = Filename.concat (Sys.getenv "HOME") ".tezos-dac-node"

let relative_filename data_dir = Filename.concat data_dir "config.json"

let filename config = relative_filename @@ config.data_dir

let default_sc_rollup_node_data_dir =
  Filename.concat (Sys.getenv "HOME") ".tezos-sc-rollup-node"

let default_rpc_addr = "127.0.0.1"

let default_rpc_port = 8832

let encoding =
  Data_encoding.(
    conv
      (fun {data_dir; sc_rollup_node_data_dir; rpc_addr; rpc_port} ->
        (data_dir, sc_rollup_node_data_dir, rpc_addr, rpc_port))
      (fun (data_dir, sc_rollup_node_data_dir, rpc_addr, rpc_port) ->
        {data_dir; sc_rollup_node_data_dir; rpc_addr; rpc_port})
      (obj4
         (dft "data_dir" string default_data_dir)
         (dft "sc_rollup_node_data_dir" string default_sc_rollup_node_data_dir)
         (dft "rpc_addr" string default_rpc_addr)
         (dft "rpc_port" uint16 default_rpc_port)))

let save config =
  let open Lwt_syntax in
  let json = Data_encoding.Json.construct encoding config in
  let* () = Lwt_utils_unix.create_dir config.data_dir in
  Lwt_utils_unix.Json.write_file (filename config) json

let load ~data_dir =
  let open Lwt_result_syntax in
  let+ json = Lwt_utils_unix.Json.read_file (relative_filename data_dir) in
  let config = Data_encoding.Json.destruct encoding json in
  config
