(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

open Protocol.Alpha_context
module Reveal_hash = Protocol.Sc_rollup_reveal_hash

type error += Wrong_hash of {found : Reveal_hash.t; expected : Reveal_hash.t}

let () =
  Sc_rollup_node_errors.register_error_kind
    ~id:"sc_rollup.node.wrong_hash_of_reveal_preimage"
    ~title:"Hash of reveal preimage is not correct"
    ~description:"Hash of reveal preimage is not correct."
    ~pp:(fun ppf (found, expected) ->
      Format.fprintf
        ppf
        "The hash of reveal preimage is %a while a value of %a is expected"
        Reveal_hash.pp
        found
        Reveal_hash.pp
        expected)
    `Permanent
    Data_encoding.(
      obj2
        (req "found" Reveal_hash.encoding)
        (req "expected" Reveal_hash.encoding))
    (function
      | Wrong_hash {found; expected} -> Some (found, expected) | _ -> None)
    (fun (found, expected) -> Wrong_hash {found; expected})

type source = String of string | File of string

let file_contents filename =
  let open Lwt_result_syntax in
  Lwt.catch
    (fun () ->
      let*! contents = Lwt_utils_unix.read_file filename in
      return contents)
    (fun _ ->
      tzfail @@ Sc_rollup_node_errors.Could_not_open_preimage_file filename)

let path data_dir pvm_name hash =
  let hash = Protocol.Sc_rollup_reveal_hash.to_hex hash in
  Filename.(concat (concat data_dir pvm_name) hash)

let proto_hash_to_dac_hash ((module Plugin) : Dac_plugin.t) proto_reveal_hash =
  proto_reveal_hash
  |> Data_encoding.Binary.to_bytes_exn Protocol.Sc_rollup_reveal_hash.encoding
  |> Data_encoding.Binary.of_bytes_exn Plugin.encoding

let get ~data_dir ~pvm_kind ~hash =
  let open Lwt_result_syntax in
  let filename =
    path data_dir (Octez_smart_rollup.Kind.to_string pvm_kind) hash
  in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/5296
     Use DAC observer client when [filename] doesn't exist. *)
  let* contents = file_contents filename in
  let*? () =
    let contents_hash =
      Reveal_hash.hash_string ~scheme:Reveal_hash.Blake2B [contents]
    in
    error_unless
      (Reveal_hash.equal contents_hash hash)
      (Wrong_hash {found = contents_hash; expected = hash})
  in
  let* _encoded =
    (* Check that the reveal input can be encoded within the bounds enforced by
       the protocol. *)
    trace Sc_rollup_node_errors.Could_not_encode_raw_data
    @@ protect
    @@ fun () ->
    Data_encoding.Binary.to_bytes_exn
      Sc_rollup.input_encoding
      (Reveal (Raw_data contents))
    |> return
  in
  return contents

let proto_hash_to_dac_hash proto_reveal_hash =
  let dac_plugin =
    WithExceptions.Option.get ~loc:__LOC__ @@ Dac_plugin.get Protocol.hash
  in
  proto_hash_to_dac_hash dac_plugin proto_reveal_hash
