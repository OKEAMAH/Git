(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model global_constants_storage/expand_constant_branch *)
(* fun size -> 4095. * size *)
let cost_expand_constant_branch size =
  let size = S.safe_int size in
  size * S.safe_int 4096

(* model global_constants_storage/expand_no_constant_branch *)
(* fun size -> 100. + (4.639474 * (size * (log2 (1 + size)))) *)
let cost_expand_no_constant_branch size =
  let size = S.safe_int size in
  let w3 = log2 (size + S.safe_int 1) * size in
  (w3 * S.safe_int 4) + (w3 lsr 1) + (w3 lsr 2) + S.safe_int 100
