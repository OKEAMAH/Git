(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

type t = {cost_per_byte : Tez_repr.t}

let encoding =
  let open Data_encoding in
  conv
    (fun {cost_per_byte} -> cost_per_byte)
    (fun cost_per_byte -> {cost_per_byte})
    (obj1 (req "cost_per_byte" Tez_repr.encoding))

let pp fmt {cost_per_byte} =
  Format.fprintf fmt "cost_per_byte: %a" Tez_repr.pp cost_per_byte

let update_cost_per_byte :
    cost_per_byte:Tez_repr.t ->
    tx_rollup_cost_per_byte:Tez_repr.t ->
    final_size:int ->
    hard_limit:int ->
    Tez_repr.t =
 fun ~cost_per_byte ~tx_rollup_cost_per_byte ~final_size ~hard_limit ->
  let computation =
    let open Compare.Int in
    (* This cannot overflow because [hard_limit] is small enough, and
       [final_size] is lesser than [hard_limit]. *)
    let percentage = final_size * 100 / hard_limit in
    if 90 < percentage then
      Tez_repr.(
        tx_rollup_cost_per_byte *? 105L >>? fun x ->
        x /? 100L >>? fun x -> x +? one_mutez)
    else if 80 < percentage && percentage <= 90 then ok tx_rollup_cost_per_byte
    else
      Tez_repr.(
        tx_rollup_cost_per_byte *? 95L >>? fun x ->
        x /? 100L >>? fun x -> x +? one_mutez)
  in
  match computation with
  | Ok x -> Tez_repr.max cost_per_byte x
  | Error _ -> cost_per_byte
