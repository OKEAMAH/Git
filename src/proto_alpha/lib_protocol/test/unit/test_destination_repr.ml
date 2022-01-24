(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

(** Testing
    -------
    Component:    Destination_repr
    Invocation:   dune exec -- ./src/proto_alpha/lib_protocol/test/unit/main.exe \
                  test Destination_repr
    Subject:      To test the encoding of [Destination_repr] and assert it is
                  compatible with [Contract_repr.encoding].
*)

open Protocol
open Tztest

let ( !! ) = function Ok x -> x | Error _ -> raise (Invalid_argument "( !! )")

(* The following addresses have been extracted from TzKT. *)

let null_address = "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"

let liquidity_baking_dex = "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5"

let assert_compat contract destination =
  match destination with
  | Destination_repr.Contract contract'
    when Contract_repr.equal contract contract' ->
      ()
  | _ -> raise (Invalid_argument "assert_compat")

(** [test_decoding_json_compat str] decodes [str] as both a [Destination_repr.t]
    and [Contract_repr.t], and checks the two are equal. *)
let test_decoding_json_compat str () =
  let json =
    !!(Data_encoding.Json.from_string @@ Format.sprintf {|"%s"|} str)
  in
  let contract =
    Data_encoding.Json.(destruct Protocol.Contract_repr.encoding json)
  in
  let destination =
    Data_encoding.Json.(destruct Protocol.Destination_repr.encoding json)
  in

  assert_compat contract destination ;

  return_unit

(** [test_encode_contract_decode_destination str] interprets [str] as
    a [Contract_repr.t], encodes it in a bytes array, then decodes it
    as a [Destination_repr.t]. The resulting destination should be
    equal to the initial contract. *)
let test_encode_contract_decode_destination str () =
  let contract = !!(Contract_repr.of_b58check str) in
  let bytes =
    Data_encoding.Binary.to_bytes_exn Contract_repr.encoding contract
  in
  let destination =
    Data_encoding.Binary.of_bytes_exn Destination_repr.encoding bytes
  in

  assert_compat contract destination ;

  return_unit

(** [test_encode_destination_decode_contract str] interprets [str] as
    a [Destination_repr.t], encodes it in a bytes array, then decodes
    it as a [Contract_repr.t]. The resulting contract should be equal
    to the initial destination. *)
let test_encode_destination_decode_contract str () =
  let destination = !!(Destination_repr.of_b58check str) in
  let bytes =
    Data_encoding.Binary.to_bytes_exn Destination_repr.encoding destination
  in
  let contract =
    Data_encoding.Binary.of_bytes_exn Contract_repr.encoding bytes
  in

  assert_compat contract destination ;

  return_unit

let tests =
  [
    tztest "Json decoding compat implicit contract (null address)" `Quick
    @@ test_decoding_json_compat null_address;
    tztest "Json decoding compat smart contract (liquidity baking dex)" `Quick
    @@ test_decoding_json_compat liquidity_baking_dex;
    tztest "Binary Contract_repr to Destination_repr (null address)" `Quick
    @@ test_encode_contract_decode_destination null_address;
    tztest
      "Binary Contract_repr to Destination_repr (liquidity baking dex)"
      `Quick
    @@ test_encode_contract_decode_destination liquidity_baking_dex;
    tztest "Binary Destination_repr to Contract_repr (null address)" `Quick
    @@ test_encode_destination_decode_contract null_address;
    tztest
      "Binary Contract_repr to Destination_repr (liquidity baking dex)"
      `Quick
    @@ test_encode_destination_decode_contract liquidity_baking_dex;
  ]
