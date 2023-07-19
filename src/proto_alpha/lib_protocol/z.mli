(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

type t = Compare.Z.t

type non_zero = private t

val make_non_zero_exn : t -> non_zero

exception Overflow

val zero : t

val one : t

val two : non_zero

val of_int : int -> t

val of_int32 : int32 -> t

val of_int64 : int64 -> t

val of_string : string -> t tzresult

val succ : t -> t

val pred : t -> t

val abs : t -> t

val neg : t -> t

val add : t -> t -> t

val sub : t -> t -> t

val mul : t -> t -> t

val div : t -> non_zero -> t

val div_result : t -> t -> t tzresult

val rem : t -> non_zero -> t

val ediv_rem : t -> t -> (t * t) tzresult

val logand : t -> t -> t

val logor : t -> t -> t

val logxor : t -> t -> t

val lognot : t -> t

val shift_left : t -> int -> t

val shift_right : t -> int -> t

val numbits : t -> int

val testbit : t -> int -> bool

val to_int : t -> int tzresult

val to_int_exn : t -> int

val to_int32 : t -> int32 tzresult

val to_int64 : t -> int64

val to_string : t -> string

val fits_int : t -> bool

val fits_int32 : t -> bool

val fits_int64 : t -> bool

val pp_print : Format.formatter -> t -> unit

val compare : t -> t -> int

val equal : t -> t -> bool

val leq : t -> t -> bool

val geq : t -> t -> bool

val lt : t -> t -> bool

val gt : t -> t -> bool

val min : t -> t -> t

val max : t -> t -> t

val sqrt : t -> t

val log2 : t -> int

val log2up : t -> int

val size : t -> int

val to_bits : t -> string

val of_bits : string -> t
