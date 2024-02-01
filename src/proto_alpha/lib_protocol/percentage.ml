(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

type t = int

let one = 100

let of_int_guarded i =
  if Compare.Int.(i >= 0 && i <= one) then Ok i
  else Error "Value must be between 0 and 100"

let of_int_bounded i = Compare.Int.(max 0 (min one i))

let encoding =
  let open Data_encoding in
  conv_with_guard (fun i -> i) of_int_guarded uint8

let of_ratio_bounded Ratio_repr.{numerator; denominator} =
  of_int_bounded (one * numerator / denominator)

let to_q x = Q.of_ints x one

let neg p = one - p

let add_bounded p1 p2 = Compare.Int.min one (p1 + p2)

let sub_bounded p1 p2 = Compare.Int.max 0 (p1 - p2)

let p0 = 0

let p5 = 5

let p50 = 50

let p51 = 51

let p100 = one

module Compare = struct
  include Compare.Int
end
