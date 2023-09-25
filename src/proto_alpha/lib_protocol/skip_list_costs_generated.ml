(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model skip_list/hash_cell *)
(* fun size -> 250. + (57. * size) *)
let cost_hash_cell size =
  let v0 = size in
  S.safe_int 250 + (v0 * S.safe_int 57)

(* model skip_list/next *)
(* fun size -> 19.2125537461 * (log2 (1 + size)) *)
let cost_next size =
  let v0 = log2 (S.safe_int 1 + size) in
  (v0 lsr 1) + (v0 * S.safe_int 19)
