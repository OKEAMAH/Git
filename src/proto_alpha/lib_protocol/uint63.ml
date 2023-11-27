(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2023 Nomadic Labs <contact@nomadic-labs.com>           *)
(*                                                                           *)
(*****************************************************************************)

module Cmp = Compare.Int64
include Cmp

type uint63 = t

let zero = Int64.zero

let one = Int64.one

let two = 2L

let five = 5L

let nine = 9L

let nineteen = 19L

let fifty = 50L

let one_hundred = 100L

let two_hundred_fifty_seven = 257L

let ten_thousand = 10_000L

let one_million = 1_000_000L

let one_billion = 1_000_000_000L

let max_uint30 = 1_073_741_824L

let max_int = Int64.max_int

let mk_encoding ~err f g enc =
  let open Data_encoding in
  conv_with_guard
    f
    (fun i -> match g i with None -> Error err | Some i -> Ok i)
    enc

module Div_safe_base : sig
  type nonrec t = private t

  val of_int64 : int64 -> t option

  val of_succ_uint63 : uint63 -> t option

  val add : t -> uint63 -> t option

  module With_exceptions : sig
    val of_int64 : int64 -> t
  end
end = struct
  type nonrec t = t

  let of_int64 i = if i > 0L then Some i else None

  let of_succ_uint63 i = if i < max_int then Some (Int64.succ i) else None

  let add a b =
    let s = Int64.add a b in
    if s < a then None else Some s

  module With_exceptions = struct
    let of_int64 i =
      match of_int64 i with
      | Some res -> res
      | None -> invalid_arg "Uint63.Div_safe.With_exceptions.of_int64"
  end
end

module Div_safe = struct
  module B = Div_safe_base

  type t = B.t

  let of_int64 = B.of_int64

  let of_int i = of_int64 (Int64.of_int i)

  let of_z z = if Z.fits_int64 z then of_int64 (Z.to_int64 z) else None

  let of_int64_exn = B.With_exceptions.of_int64

  let to_int (i : t) = Int64.to_int (i :> Int64.t)

  let two = of_int64_exn 2L

  let three = of_int64_exn 3L

  let twenty_five = of_int64_exn 25L

  let sixty = of_int64_exn 60L

  let one_hundred = of_int64_exn 100L

  let two_hundred_fifty_six = of_int64_exn 256L

  let one_thousand = of_int64_exn 1000L

  let seven_thousand = of_int64_exn 7000L

  let one_million = of_int64_exn 1_000_000L

  let one_billion = of_int64_exn 1_000_000_000L

  let max_int = of_int64_exn Int64.max_int

  let mk_encoding f g enc = mk_encoding ~err:"Positive integer expected" f g enc

  let uint8_encoding = mk_encoding to_int of_int Data_encoding.uint8

  let uint30_encoding = mk_encoding to_int of_int Data_encoding.int31

  let add = B.add

  let sub (a : t) b = of_int64 (Int64.sub (a :> Int64.t) b)

  module With_exceptions = struct
    include B.With_exceptions

    let of_int i =
      match of_int i with
      | Some res -> res
      | None -> invalid_arg "Uint63.Div_safe.With_exceptions.of_int"
  end
end

let to_int = Int64.to_int

let to_int32 (i : t) =
  let i32 = Int64.to_int32 i in
  if i = Int64.of_int32 i32 then Some i32 else None

let to_z = Z.of_int64

let of_int32 i =
  if Compare.Int32.(i >= 0l) then Some (Int64.of_int32 i) else None

let of_int64 i = if i >= 0L then Some i else None

let of_z z = if Z.fits_int64 z then of_int64 (Z.to_int64 z) else None

let abs_of_int64 i = if i >= 0L then `Pos i else `Neg (Int64.neg i)

let of_int i = of_int64 (Int64.of_int i)

let of_list_length l = Int64.of_int (List.length l)

let of_string_opt s =
  let open Option_syntax in
  let* i = Int64.of_string_opt s in
  of_int64 i

let mk_encoding f g enc =
  mk_encoding ~err:"Non-negative integer expected" f g enc

let uint8_encoding = mk_encoding Int64.to_int of_int Data_encoding.uint8

let uint16_encoding = mk_encoding Int64.to_int of_int Data_encoding.uint16

let uint30_encoding = mk_encoding Int64.to_int of_int Data_encoding.int31

let int64_encoding = mk_encoding (fun i -> i) of_int64 Data_encoding.int64

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

  let of_int i =
    match of_int i with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.of_int"

  let of_z z =
    match of_z z with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.of_z"

  let succ a =
    match Div_safe_base.of_succ_uint63 a with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.succ"

  let add a b =
    match add a b with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.add"

  let mul a b =
    match mul a b with
    | Some res -> res
    | None -> invalid_arg "Uint63.With_exceptions.mul"
end
