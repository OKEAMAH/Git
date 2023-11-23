(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2023 Nomadic Labs <contact@nomadic-labs.com>           *)
(*                                                                           *)
(*****************************************************************************)

(** Non-negative 64-bit integer. *)

type t = private Int64.t

(** {!Compare.Int64} *)
module Cmp : Compare.S with type t = t

include module type of Cmp with type t := t

val encoding : t Data_encoding.t

val uint8_encoding : t Data_encoding.t

val uint16_encoding : t Data_encoding.t

val uint30_encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

val zero : t

val one : t

val two : t

val nine : t

val nineteen : t

val fifty : t

val one_hundred : t

val two_hundred_fifty_seven : t

val ten_thousand : t

val max_int : t

module Div_safe : sig
  (** Positive 64-bit integer. *)
  type nonrec t = private t

  val of_int64 : int64 -> t option

  val of_int : int -> t option

  val two : t

  val sixty : t

  val one_hundred : t

  val one_thousand : t

  val one_million : t

  val max_int : t

  val uint8_encoding : t Data_encoding.t

  module With_exceptions : sig
    val of_int : int -> t
  end
end

val to_int : t -> int

val to_z : t -> Z.t

val of_int : int -> t option

val of_int64 : int64 -> t option

val abs_of_int64 : Int64.t -> [`Pos of t | `Neg of t]

val of_string_opt : string -> t option

val add : t -> t -> t option

val sub : t -> t -> t option

val mul : t -> t -> t option

val div : t -> Div_safe.t -> t

val div_sub : t -> Div_safe.t -> t * t

val rem : t -> Div_safe.t -> t

type rounding := [`Up | `Down]

val mul_percentage : rounding:rounding -> t -> Int_percentage.t -> t

val mul_ratio : rounding:rounding -> t -> num:t -> den:Div_safe.t -> t option

(** Exception-raising, use at top-level only. *)
module With_exceptions : sig
  val of_int64 : Int64.t -> t

  val of_int : int -> t

  val succ : t -> t

  val add : t -> t -> t

  val mul : t -> t -> t
end
