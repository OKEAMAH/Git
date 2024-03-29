(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model cache/CACHE_UPDATE *)
(* fun size -> max 10 (600. + (43. * (log2 (1 + size)))) *)
let cost_CACHE_UPDATE size =
  let size = S.safe_int size in
  (log2 (size + S.safe_int 1) * S.safe_int 43) + S.safe_int 600
