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

(*

   Each time we add a data constructor to [kind], we also need:
   - to extend [all] with this new constructor ;
   - to update [kind_of_string] and [encoding].

*)
type kind = Example_arith

let all = [Example_arith]

let kind_of_string = function "arith" -> Some Example_arith | _ -> None

let example_arith_case =
  Data_encoding.(
    case
      ~title:"Example_arith rollup kind"
      (Tag 0)
      unit
      (function Example_arith -> Some ())
      (fun () -> Example_arith))

let encoding = Data_encoding.union ~tag_size:`Uint16 [example_arith_case]

let example_arith_pvm = (module Sc_rollup_arith : Sc_rollup_repr.PVM.S)

let of_kind = function Example_arith -> example_arith_pvm

let kind_of (module M : Sc_rollup_repr.PVM.S) =
  match kind_of_string M.name with
  | Some k -> k
  | None ->
      failwith
        (Format.sprintf "The module named %s is not in Sc_rollups.all." M.name)

let from ~name = match name with "arith" -> Some example_arith_pvm | _ -> None

let all_names =
  List.map
    (fun k ->
      let (module M : Sc_rollup_repr.PVM.S) = of_kind k in
      M.name)
    all
