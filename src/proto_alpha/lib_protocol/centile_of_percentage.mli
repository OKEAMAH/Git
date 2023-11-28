(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** A percentage value with centile precision, represented as an integer
    between 0 and 100_00. *)
type t = private Uint63.t

val zero : t

val five_percent : t

val twenty_percent : t

val seventy_percent : t

val eighty_percent : t

val one_hundred_percent : t

val to_int32 : t -> Int32.t

val to_z : t -> Z.t

val encoding : t Data_encoding.t

(** [average ~left_weight left right] computes
    [left * left_weight + right * (100% - left_weight)]. *)
val average : left_weight:t -> t -> t -> t

module Saturating : sig
  val of_ratio :
    rounding:[`Down | `Up] -> num:Uint63.t -> den:Uint63.Div_safe.t -> t

  val sub : t -> t -> t
end

module With_exceptions : sig
  val of_int : int -> t

  val of_int32 : Int32.t -> t
end
