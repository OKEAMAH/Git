(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

include Tezos_protocol_environment_alpha.Z

type error += Invalid_string of string

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"z.invalid_string"
    ~title:"Invalid string notation for an arbitrary-precision number"
    ~pp:(fun ppf s ->
      Format.fprintf
        ppf
        "String %S is not a valid notation for an arbitrary-precision integer"
        s)
    ~description:
      "During a conversion from string to Z, an invalid string was given as \
       argument"
    (obj1 (req "string" (string Plain)))
    (function Invalid_string s -> Some s | _ -> None)
    (fun s -> Invalid_string s)

let of_string s =
  try ok (of_string s) with Invalid_argument _ -> error @@ Invalid_string s

type non_zero = t

let make_non_zero_exn x =
  if Compare.Z.(x = zero) then raise Division_by_zero else x
