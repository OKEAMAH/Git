(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

let address_size = 20

module L2_address =
  Blake2B.Make
    (Base58)
    (struct
      let name = "Tx_rollup_l2_address"

      let title =
        "The hash of a BLS public key used to identify a L2 ticket holders"

      let b58check_prefix = "\001\127\181\224" (* tru2(37) *)

      let size = Some address_size
    end)

let () = Base58.check_encoded_prefix L2_address.b58check_encoding "tru2" 37

type address = L2_address.t

let address_encoding = L2_address.encoding

let pp_address = L2_address.pp

let address_to_b58check = L2_address.to_b58check

let address_of_b58check_opt = L2_address.of_b58check_opt

let address_of_b58check_exn = L2_address.of_b58check_exn

let address_of_bytes_exn = L2_address.of_bytes_exn

let address_of_bytes_opt = L2_address.of_bytes_opt

let compare_address = L2_address.compare

let of_bls_pk : Bls_signature.pk -> address =
 fun pk -> L2_address.hash_bytes [Bls_signature.pk_to_bytes pk]

type t = Full of address | Indexed of int32

let encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        (Tag 0)
        ~title:"Full"
        address_encoding
        (function Full a -> Some a | _ -> None)
        (function a -> Full a);
      case
        (Tag 1)
        ~title:"Indexed"
        int32
        (function Indexed i -> Some i | _ -> None)
        (function i -> Indexed i);
    ]

let pp fmt = function
  | Full a -> pp_address fmt a
  | Indexed i -> Format.fprintf fmt "#%ld" i

let in_memory_size : t -> Cache_memory_helpers.sint =
  let open Cache_memory_helpers in
  function
  | Indexed _ -> header_size +! word_size +! int32_size
  | Full _ -> header_size +! word_size +! string_size_gen address_size

let compare x y =
  match (x, y) with
  | (Indexed x, Indexed y) -> Int32.compare x y
  | (Full x, Full y) -> compare_address x y
  | (Indexed _, Full _) -> -1
  | (Full _, Indexed _) -> 1

let size = function Indexed _ -> 4 | Full _ -> address_size
