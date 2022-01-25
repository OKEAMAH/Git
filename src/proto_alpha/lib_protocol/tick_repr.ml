type t = int

let encoding = Data_encoding.int16

let pp ppf tick = Format.fprintf ppf "%d" tick

let make x =
  assert (Compare.Int.(x >= 0)) ;
  x

let next = succ

let distance tick1 tick2 = abs (tick1 - tick2)

let ( = ) = Compare.Int.( = )

module Map = Map.Make (Compare.Int)
