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

(** The state of a transaction rollup is a set of variables that are
    expected to vary in time. More precisely, the state comprises

    {ul {li A [cost_per_byte] rate, that is expected to be at least as
            expensive as the [cost_per_byte] constant of the protocol,
            but can be increased if the transaction rollup is crowded.}} *)
type t = {cost_per_byte : Tez_repr.t}

val encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

(** [update_cost_per_byte ctxt ~cost_per_byte ~tx_rollup_cost_per_byte
    ~final_size ~hard_limit] computes a new cost per byte based on the
    ratio of the [hard_limit] maximum amount of byte an inbox can use
    and the [final_size] amount of bytes it uses at the end of the
    construction of a Tezos block. The [tx_rollup_cost_per_byte] value
    computed by this function is always greater than the
    [cost_per_byte] protocol constant.

    More precisely, [cost_per_byte] has to be equal to the protocol
    parameter of the same name.

    In a nutshell, if the ratio is lesser than 80%, the cost per byte
    is reduced. If the ratios is somewhere between 80% and 90%, the
    cost per byte remains constant. If the ratio is greater than 90%,
    then the cost per byte is increased.

    The rationale behind this mechanics is to reduce the activity of a
    rollup in case it becomes too intense. *)
val update_cost_per_byte :
  cost_per_byte:Tez_repr.t ->
  tx_rollup_cost_per_byte:Tez_repr.t ->
  final_size:int ->
  hard_limit:int ->
  Tez_repr.t
