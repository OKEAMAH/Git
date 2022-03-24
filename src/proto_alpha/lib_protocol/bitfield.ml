(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type t = Z.t

type error += Invalid_input of int

let encoding = Data_encoding.z

let empty = Z.zero

let mem field pos =
  error_when Compare.Int.(pos < 0) (Invalid_input pos) >>? fun () ->
  let mask = Z.logand field Z.(shift_left one pos) in
  ok @@ Compare.Z.(mask <> Z.zero)

let add field pos =
  error_when Compare.Int.(pos < 0) (Invalid_input pos) >>? fun () ->
  ok @@ Z.logor field Z.(shift_left one pos)

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"bitfield_invalid_input"
    ~title:"Invalid bitfield’s input"
    ~description:"Bitfields does not accept negative inputs"
    (obj1 (req "input" int31))
    (function Invalid_input i -> Some i | _ -> None)
    (fun i -> Invalid_input i)
