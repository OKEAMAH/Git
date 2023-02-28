(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

type error += Negative_payload_size

(* A random character in the range 'a..z' *)
let rand_chr () = Char.chr (97 + Random.int 26)

type t = {payload : bytes; root_hash : Dac_plugin.hash; description : string}

let payload_encoding ((module Plugin) : Dac_plugin.t) =
  let of_hex_exn h =
    Option.value_f (Plugin.of_hex h) ~default:(fun _ -> assert false)
  in
  let hash_hex_encoding =
    Data_encoding.(conv Plugin.to_hex of_hex_exn (string' Plain))
  in
  Data_encoding.(
    conv
      (fun {payload; root_hash; description} ->
        (payload, root_hash, description))
      (fun (payload, root_hash, description) ->
        {payload; root_hash; description})
    @@ obj3
         (req "payload" @@ bytes' Hex)
         (req "root_hash" @@ hash_hex_encoding)
         (req "description" @@ string' Plain))

let generate directory filename size =
  let open Lwt_result_syntax in
  let filename = filename ^ ".json" in
  let protocol_hash =
    Protocol_hash.of_b58check_exn
      "ProtoALphaALphaALphaALphaALphaALphaALphaALphaDdp3zK"
  in
  let* plugin =
    match Dac_plugin.get protocol_hash with
    | None -> failwith "Could not resolve plugin"
    | Some plugin -> return plugin
  in
  let fake_store = Page_store.Fake.init () in
  let path = Filename.concat directory filename in
  let size_in_bytes = size * 1024 * 1024 in
  let*? seq =
    Seq.init
      ~when_negative_length:[Negative_payload_size]
      size_in_bytes
      (fun _ -> rand_chr ())
  in
  let payload = Bytes.of_seq seq in
  let* root_hash =
    Pages_encoding.Merkle_tree.V0.Fake.serialize_payload
      plugin
      ~page_store:fake_store
      payload
  in
  let description = "Sample_payload: " ^ Int.to_string size ^ " MB" in
  let t = {payload; root_hash; description} in
  let encoding = payload_encoding plugin in
  let*! res =
    Lwt_utils_unix.with_open_out path @@ fun chan ->
    let json = Data_encoding.Json.construct encoding t in
    let content = Data_encoding.Json.to_string json in
    Lwt_utils_unix.write_string chan content
  in
  match res with Ok x -> return x | Error _e -> failwith "Cannot save payload"
