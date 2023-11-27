(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2023 Nomadic Labs <contact@nomadic-labs.com>           *)
(*                                                                           *)
(*****************************************************************************)

(** Non-negative 64-bit integer. *)

type t = private Int64.t

type uint63 := t

(** {!Compare.Int64} *)
module Cmp : Compare.S with type t = t

include module type of Cmp with type t := t

val uint8_encoding : t Data_encoding.t

val uint16_encoding : t Data_encoding.t

val uint30_encoding : t Data_encoding.t

val int64_encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

val zero : t

val one : t

val two : t

val five : t

val nine : t

val nineteen : t

val fifty : t

val one_hundred : t

val two_hundred_fifty_seven : t

val five_hundred : t

val ten_thousand : t

val one_million : t

val one_billion : t

val max_uint30 : t

val max_int : t

module Div_safe : sig
  (** Positive 64-bit integer. *)
  type nonrec t = private t

  val of_int64 : int64 -> t option

  val of_int : int -> t option

  val of_z : Z.t -> t option

  val to_int : t -> int

  val two : t

  val three : t

  val twenty_five : t

  val sixty : t

  val one_hundred : t

  val two_hundred_fifty_six : t

  val one_thousand : t

  val seven_thousand : t

  val one_million : t

  val one_billion : t

  val max_int : t

  val uint8_encoding : t Data_encoding.t

  val uint30_encoding : t Data_encoding.t

  val add : t -> uint63 -> t option

  val sub : t -> uint63 -> t option

  module With_exceptions : sig
    val of_int64 : Int64.t -> t

    val of_int : int -> t
  end
end

val to_int : t -> int

val to_int32 : t -> Int32.t option

val to_z : t -> Z.t

val of_int : int -> t option

val of_int32 : Int32.t -> t option

val of_int64 : int64 -> t option

val of_z : Z.t -> t option

val of_list_length : 'a list -> t

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

  val of_int32 : Int32.t -> t

  val of_z : Z.t -> t

  val succ : t -> Div_safe.t

  val add : t -> t -> t

  val mul : t -> t -> t
end
