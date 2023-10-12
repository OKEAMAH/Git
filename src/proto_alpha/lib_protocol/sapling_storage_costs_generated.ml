(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model sapling/SAPLING_APPLY_DIFF *)
(* fun size1 ->
     fun size2 -> max 10 ((1300000. + (5000. * size1)) + (55000. * size2)) *)
let cost_SAPLING_APPLY_DIFF size1 size2 =
  let size1 = S.safe_int size1 in
  let size2 = S.safe_int size2 in
  (size1 * S.safe_int 5120) + (size2 * S.safe_int 55296) + S.safe_int 1300000
