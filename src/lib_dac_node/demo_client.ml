(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 Trili Tech, <contact@trili.tech>                  *)
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

let payload_from_file filename =
  let open Lwt_result_syntax in
  let*! raw_payload = Lwt_utils_unix.read_file filename in
  let items = String.split ' ' raw_payload in
  let payload =
    Hex.show @@ Hex.of_string
    @@ Data_encoding.(Binary.to_string_exn (list string) items)
  in
  return payload

let send_payload host port hex_payload =
  let open Lwt_result_syntax in
  let payload = Hex.to_bytes_exn @@ `Hex hex_payload in
  let coordinator_cctxt =
    Dac_node_client.make_unix_cctxt ~scheme:"http" ~host ~port
  in
  let* hash =
    Dac_node_client.V0.Coordinator.post_preimage coordinator_cctxt ~payload
  in
  let (`Hex hex_hash) = Dac_plugin.raw_hash_to_hex hash in
  return @@ hex_hash

let hash_rpc_arg =
  let construct hash = Hex.show @@ Dac_plugin.raw_hash_to_hex hash in
  let destruct hex =
    let hex = `Hex hex in
    match Hex.to_bytes hex |> Option.map Dac_plugin.raw_hash_of_bytes with
    | None -> Error "Cannot parse reveal hash"
    | Some reveal_hash -> Ok reveal_hash
  in
  Tezos_rpc.Arg.make
    ~descr:"A reveal hash"
    ~name:"reveal_hash"
    ~destruct
    ~construct
    ()

let get_certificate host port root_hash =
  let open Lwt_result_syntax in
  let root_page_hash =
    Hex.to_bytes_exn (`Hex root_hash) |> Dac_plugin.raw_hash_of_bytes
  in
  let coordinator_cctxt =
    Dac_node_client.make_unix_cctxt ~scheme:"http" ~host ~port
  in
  let* certificate =
    Dac_node_client.V0.get_serialized_certificate
      coordinator_cctxt
      ~root_page_hash
  in
  match certificate with
  | None -> failwith "Could not retrieve certificate"
  | Some certificate -> return @@ Hex.show @@ Hex.of_string certificate
