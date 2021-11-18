(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type kind = Hp48

let hp48_case =
  Data_encoding.(
    case
      ~title:"Hp48 rollup kind"
      (Tag 0)
      unit
      (function Hp48 -> Some ())
      (fun () -> Hp48))

let encoding = Data_encoding.union [hp48_case]

let hp48_pvm = (module Sc_rollup_hp48 : Sc_rollup_repr.PVM.S)

let of_kind = function Hp48 -> hp48_pvm

let kind_of (module M : Sc_rollup_repr.PVM.S) =
  match M.name with
  | "hp48" -> Hp48
  | name ->
      failwith
        (Format.sprintf "The module named %s is not in Sc_rollups.all." name)

let all = ["hp48"]

let from ~name = match name with "hp48" -> Some hp48_pvm | _ -> None
