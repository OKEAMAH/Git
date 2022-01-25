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

(** The state of a transaction rollup is a set of variables that vary
    in time, as the rollup progresses. *)
type t

(** The initial value of a transaction rollup state, after its origination. *)
val initial_state : t

val encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

(** [update_fees_per_byte state ~final_size ~hard_limit] updates the
    fees to be paid for each byte submitted to a transaction rollup
    inbox, based on the ratio of the [hard_limit] maximum amount of
    byte an inbox can use and the [final_size] amount of bytes it uses
    at the end of the construction of a Tezos block.

    In a nutshell, if the ratio is lesser than 80%, the cost per byte
    is reduced. If the ratios is somewhere between 80% and 90%, the
    fees per byte remains constant. If the ratio is greater than 90%,
    then the fees per byte is increased.

    The rationale behind this mechanics is to reduce the activity of a
    transaction rollup in case it becomes too intense. *)
val update_fees_per_byte : t -> final_size:int -> hard_limit:int -> t

(** [fees state size] computes the fees to be paid to submit [size]
    bytes in the inbox of the transactional rollup. *)
val fees : t -> int -> Tez_repr.t tzresult

module Internal_for_tests : sig
  (** [initial_state_with_fees_per_byte fees] returns [initial_state], but
      wherein it costs [fees] per byte to add a message to an inbox. *)
  val initial_state_with_fees_per_byte : Tez_repr.t -> t
end
