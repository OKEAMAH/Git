(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

include Uint63.Cmp

let zero = Uint63.zero

let five_percent = Uint63.five_hundred

let twenty_percent = Uint63.two_thousand

let seventy_percent = Uint63.seven_thousand

let eighty_percent = Uint63.eight_thousand

let one_hundred_percent = Uint63.ten_thousand

module Div_safe = struct
  type t = Uint63.Div_safe.t

  let one_hundred_percent = Uint63.Div_safe.ten_thousand
end

let of_uint63 i = if Uint63.(i <= one_hundred_percent) then Some i else None

let of_int i = Option.bind (Uint63.of_int i) of_uint63

let of_int32 i = Option.bind (Uint63.of_int32 i) of_uint63

let of_ratio ~rounding ~num ~den =
  Option.bind
    (Uint63.mul_ratio ~rounding one_hundred_percent ~num ~den)
    of_uint63

let to_int32 = Uint63.With_exceptions.to_int32

let to_z = Uint63.to_z

let encoding = Uint63.uint30_encoding

let average ~left_weight a b =
  let weighted_a = Uint63.With_exceptions.mul a left_weight in
  let right_weight =
    Uint63.With_exceptions.sub one_hundred_percent left_weight
  in
  let weighted_b = Uint63.With_exceptions.mul b right_weight in
  let total = Uint63.With_exceptions.add weighted_a weighted_b in
  Uint63.div total Div_safe.one_hundred_percent

module Saturating = struct
  let of_ratio ~rounding ~num ~den =
    of_ratio ~rounding ~num ~den |> Option.value ~default:one_hundred_percent

  let sub a b = Uint63.sub a b |> Option.value ~default:zero
end

module With_exceptions = struct
  let of_int i =
    match of_int i with
    | Some res -> res
    | None -> invalid_arg "Centile_of_percentage.With_exceptions.of_int"

  let of_int32 i =
    match of_int32 i with
    | Some res -> res
    | None -> invalid_arg "Centile_of_percentage.With_exceptions.of_int32"
end
