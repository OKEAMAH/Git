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

type t = {fees_per_byte : Tez_repr.t}

let initial_state = {fees_per_byte = Tez_repr.zero}

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {fees_per_byte} -> fees_per_byte)
    (fun fees_per_byte ->
      assert (Tez_repr.(zero <= fees_per_byte)) ;
      {fees_per_byte})
    (obj1 (req "fees_per_byte" Tez_repr.encoding))

let pp fmt {fees_per_byte} =
  Format.fprintf fmt "Tx_rollup: fees_per_byte = %a" Tez_repr.pp fees_per_byte

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2338
   To get a smoother variation of fees, that is more resistant to
   spurious pikes of data, we will use EMA.

   The type [t] probably needs to be updated accordingly. *)
let update_fees_per_byte : t -> final_size:int -> hard_limit:int -> t =
 fun ({fees_per_byte} as state) ~final_size ~hard_limit ->
  let computation =
    let open Compare.Int in
    let percentage = final_size * 100 / hard_limit in
    if 90 < percentage then
      (* If the fees were null before, we bootstrap the increase with
         a small, fix value of 100 mutez. *)
      if Tez_repr.(fees_per_byte = zero) then ok @@ Tez_repr.of_mutez_exn 100L
      else
        Tez_repr.(
          fees_per_byte *? 105L >>? fun x ->
          x /? 100L >>? fun x -> x +? one_mutez)
    else if 80 < percentage && percentage <= 90 then ok fees_per_byte
    else
      Tez_repr.(
        fees_per_byte *? 95L >>? fun x ->
        x /? 100L >>? fun x -> x +? one_mutez)
  in
  (* In the (very unlikely) event of an overflow, we keep the fees
     constant. *)
  match computation with
  | Ok fees_per_byte -> {fees_per_byte}
  | Error _ -> state

let fees {fees_per_byte} size = Tez_repr.(fees_per_byte *? Int64.of_int size)

module Internal_for_tests = struct
  let initial_state_with_fees_per_byte : Tez_repr.t -> t =
   fun fees_per_byte -> {fees_per_byte}
end
