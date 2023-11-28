(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** A value between 0 and 100_00. *)
type t = private Uint63.t

val zero : t

val five_percent : t

val twenty_percent : t

val seventy_percent : t

val one_hundred_percent : t

val to_int32 : t -> Int32.t

val to_z : t -> Z.t

val encoding : t Data_encoding.t

module Saturating : sig
  val sub : t -> t -> t
end

module With_exceptions : sig
  val of_int : int -> t

  val of_int32 : Int32.t -> t
end
