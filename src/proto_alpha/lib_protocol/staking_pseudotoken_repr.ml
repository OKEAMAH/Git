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

(* A pseudotoken is not a Tez but it behaves similarly so let's reuse its operations. *)

include Tez_repr

let to_int64 = to_mutez

type error += Overflow

let () =
  let open Data_encoding in
  register_error_kind
    `Temporary
    ~id:"staking_pseudotoken_overflow"
    ~title:"Overflowing pseudotoken conversion"
    ~pp:(fun ppf () -> Format.fprintf ppf "Overflowing pseudotoken conversion")
    ~description:
      "Pseudotokens are non-negative int64 numbers, a conversion to \
       pseudotoken outside the representible range was attempted."
    unit
    (function Overflow -> Some () | _ -> None)
    (fun () -> Overflow)

let of_int64 x =
  if Compare.Int64.(x < 0L) then error Overflow else ok @@ of_mutez_exn x

let of_z x =
  let open Result_syntax in
  record_trace Overflow
  @@ let* x = Z_result.to_int64 x in
     of_int64 x

let to_z x = Z.of_int64 (to_int64 x)
