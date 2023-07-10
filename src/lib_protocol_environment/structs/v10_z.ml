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

include Z

module Errors = struct
  type overflow =
    | Overflow
        (** Raised by conversion functions when the value cannot be represented in
    the destination type.
*)

  type division_by_zero =
    | Division_by_zero
        (** Raised by division and remainder functions when the divisor is zero.
*)

  type invalid_arg =
    | Invalid_argument of string
        (** Raised by of_string when the argument is not a syntactically correct
    representation of an integer.
*)
end

let catch_overflow f = try Ok (f ()) with Overflow -> Error Errors.Overflow

let catch_division_by_zero f =
  try Ok (f ()) with Division_by_zero -> Error Errors.Division_by_zero

let catch_invalid_argument f =
  try Ok (f ())
  with Invalid_argument err -> Error (Errors.Invalid_argument err)

let div a b = catch_division_by_zero (fun () -> div a b)

let rem a b = catch_division_by_zero (fun () -> rem a b)

let div_rem a b = catch_division_by_zero (fun () -> div_rem a b)

let cdiv a b = catch_division_by_zero (fun () -> cdiv a b)

let fdiv a b = catch_division_by_zero (fun () -> fdiv a b)

let ediv_rem a b = catch_division_by_zero (fun () -> ediv_rem a b)

let ediv a b = catch_division_by_zero (fun () -> ediv a b)

let erem a b = catch_division_by_zero (fun () -> erem a b)

let divexact a b = catch_division_by_zero (fun () -> divexact a b)

let of_float x = catch_overflow (fun () -> of_float x)

let to_int x = catch_overflow (fun () -> to_int x)

let to_int32 x = catch_overflow (fun () -> to_int32 x)

let to_int64 x = catch_overflow (fun () -> to_int64 x)

let to_nativeint x = catch_overflow (fun () -> to_nativeint x)

let popcount x = catch_overflow (fun () -> popcount x)

let hamdist x y = catch_overflow (fun () -> hamdist x y)

let of_string x = catch_invalid_argument (fun () -> of_string x)

let testbit a b = catch_invalid_argument (fun () -> testbit a b)
