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

let strip_0x s =
  if String.starts_with ~prefix:"0x" s then
    let n = String.length s in
    String.sub s 2 (n - 2)
  else s

let sign ?log_command ?log_status_on_exit ?log_output ~from_private_key ~to_
    ~value ~data ~nonce ~chainId () =
  let to_hex = Z.format "#x" in
  let gasLimit = to_hex (Z.of_int 21000) in
  let gasPrice = to_hex (Z.of_int 21000) in
  let value = to_hex (Wei.of_wei_z value) in
  let tx_json =
    `O
      [
        ("to", `String to_);
        ("value", `String value);
        ("gasLimit", `String gasLimit);
        ("gasPrice", `String gasPrice);
        ("nonce", `Float (float_of_int nonce));
        ("data", `String data);
        ("chainId", `String chainId);
      ]
  in
  let* output =
    Process.spawn
      ?log_command
      ?log_output
      ?log_status_on_exit
      ~name:"eth-signer"
      "node"
      [
        "tezt/lib_ethereum/signer.js";
        JSON.encode_u tx_json;
        strip_0x from_private_key;
      ]
    |> Process.check_and_read_stdout
  in
  return ("0x" ^ String.trim output)
