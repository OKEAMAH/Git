(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2023 Nomadic Labs <contact@nomadic-labs.com>           *)
(*                                                                           *)
(*****************************************************************************)

module Cmp = Compare.Int64
include Cmp

let zero = Int64.zero

let one = Int64.one

let two = 2L

let nine = 9L

let nineteen = 19L

let fifty = 50L

let one_hundred = 100L

let two_hundred_fifty_seven = 257L

let ten_thousand = 10_000L

let max_int = Int64.max_int

module Div_safe_base : sig
  type nonrec t = private t

  val of_int64 : int64 -> t option

  module With_exceptions : sig
    val of_int64 : int64 -> t
  end
end = struct
  type nonrec t = t

  let of_int64 i = if i > 0L then Some i else None

  module With_exceptions = struct
    let of_int64 i =
      match of_int64 i with
      | Some res -> res
      | None -> invalid_arg "Uint63.Div_safe.With_exceptions.of_int64"
  end
end

module Div_safe = struct
  include Div_safe_base

  let two = With_exceptions.of_int64 2L

  let sixty = With_exceptions.of_int64 60L

  let one_thousand = With_exceptions.of_int64 1000L

  let one_million = With_exceptions.of_int64 1_000_000L
end

let to_int = Int64.to_int

let to_z = Z.of_int64

let of_int64 i = if i >= 0L then Some i else None

let abs_of_int64 i = if i >= 0L then `Pos i else `Neg (Int64.neg i)

let of_int i = of_int64 (Int64.of_int i)

let of_string_opt s =
  let open Option_syntax in
  let* i = Int64.of_string_opt s in
  of_int64 i

let mk_encoding f g enc =
  let open Data_encoding in
  conv_with_guard
    f
    (fun i ->
      match g i with
      | None -> Error "Non-negative integer expected"
      | Some i -> Ok i)
    enc

let encoding = mk_encoding (fun i -> i) of_int64 Data_encoding.int64

let uint8_encoding = mk_encoding Int64.to_int of_int Data_encoding.uint8

let uint30_encoding = mk_encoding Int64.to_int of_int Data_encoding.int31

let pp fp i = Format.fprintf fp "%Ld" i

let add (a : t) (b : t) =
  let s = Int64.add a b in
  if s < a then None else Some s

let sub (a : t) (b : t) = if a >= b then Some (Int64.sub a b) else None

let div (a : t) (b : Div_safe.t) = Int64.div a (b :> Int64.t)

let div_sub : t -> Div_safe.t -> t * t =
 fun n d ->
  let l = div n d in
  (l, Int64.sub n l)

let rem (a : t) (b : Div_safe.t) = Int64.rem a (b :> Int64.t)

let mul (a : t) (b : t) =
  match Div_safe.of_int64 b with
  | None -> Some 0L
  | Some div_safe_b ->
      if a > div max_int div_safe_b then None else Some (Int64.mul a b)

let z_div ~rounding = match rounding with `Down -> Z.div | `Up -> Z.cdiv

let mul_percentage =
  let z100 = Z.of_int 100 in
  fun ~rounding x (percentage : Int_percentage.t) ->
    (* Guaranteed to produce no errors by the invariants on {!Int_percentage.t}. *)
    Z.(
      to_int64
        (z_div ~rounding (mul (of_int64 x) (of_int (percentage :> int))) z100))

let mul_ratio ~rounding x ~(num : t) ~(den : Div_safe.t) =
  let numerator = Z.(mul (of_int64 x) (of_int64 num)) in
  let denominator = Z.of_int64 (den :> Int64.t) in
  let z = z_div ~rounding numerator denominator in
  if Z.fits_int64 z then Some (Z.to_int64 z) else None

module With_exceptions = struct
  let of_int64 i =
    match of_int64 i with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.of_int64"

  let mul a b =
    match mul a b with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.mul"
end
