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

type error += Overflow | Division_by_zero | Invalid_argument of string

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"z_overflow"
    ~title:"Z conversion overflow"
    ~description:"An overflow occured while converting a large integer"
    unit
    (function Overflow -> Some () | _ -> None)
    (fun () -> Overflow) ;
  register_error_kind
    `Permanent
    ~id:"z_division_by_zero"
    ~title:"Z division by zero"
    ~description:"A division by zero was attempted on large integers"
    unit
    (function Division_by_zero -> Some () | _ -> None)
    (fun () -> Division_by_zero) ;
  register_error_kind
    `Permanent
    ~id:"z_invalid_argument"
    ~title:"Invalid argument in Zarith"
    ~description:
      "A function from the Zarith library received an invalid argument"
    ~pp:(fun ppf s ->
      Format.fprintf
        ppf
        "Invalid argument while calling a function from the Zarith library: %s."
        s)
    (obj1 (req "message" (string Plain)))
    (function Invalid_argument s -> Some s | _ -> None)
    (fun s -> Invalid_argument s)

let map_overflow f =
  match f () with Ok x -> Ok x | Error Z.Errors.Overflow -> error Overflow

let map_division_by_zero f =
  match f () with
  | Ok x -> Ok x
  | Error Z.Errors.Division_by_zero -> error Division_by_zero

let map_invalid_argument f =
  match f () with
  | Ok x -> Ok x
  | Error (Z.Errors.Invalid_argument err) -> error (Invalid_argument err)

let to_int z = map_overflow (fun () -> Z.to_int z)

let to_int32 z = map_overflow (fun () -> Z.to_int32 z)

let to_int64 z = map_overflow (fun () -> Z.to_int64 z)

let testbit a b = map_invalid_argument (fun () -> Z.testbit a b)

let div a b = map_division_by_zero (fun () -> Z.div a b)

let div2 a =
  match Z.div a (Z.of_int 2) with
  | Ok res -> res
  | Error Z.Errors.Division_by_zero -> assert false

let div100 a =
  match Z.div a (Z.of_int 100) with
  | Ok res -> res
  | Error Z.Errors.Division_by_zero -> assert false

let div20 a =
  match Z.div a (Z.of_int 20) with
  | Ok res -> res
  | Error Z.Errors.Division_by_zero -> assert false

let rem a b = map_division_by_zero (fun () -> Z.rem a b)

let of_string s = map_invalid_argument (fun () -> Z.of_string s)
