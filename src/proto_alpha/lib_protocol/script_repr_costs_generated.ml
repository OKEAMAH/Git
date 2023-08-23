(* Do not edit this file manually.
   This file was automatically generated from benchmark models
   If you wish to update a function in this file,
   a. update the corresponding model, or
   b. move the function to another module and edit it there. *)

[@@@warning "-33"]

module S = Saturation_repr
open S.Syntax

(* model encoding/DECODING_MICHELINE *)
(* fun size1 ->
     fun size2 ->
       fun size3 -> ((60. * size1) + (10. * size2)) + (10. * size3) *)
let cost_DECODING_MICHELINE size1 size2 size3 =
  (size1 * S.safe_int 60) + (size2 * S.safe_int 10) + (size3 * S.safe_int 10)

(* model encoding/DECODING_MICHELINE_bytes *)
(* fun size -> 20. * size *)
let cost_DECODING_MICHELINE_bytes size = size * S.safe_int 20

(* model encoding/ENCODING_MICHELINE *)
(* fun size1 ->
     fun size2 ->
       fun size3 -> ((100. * size1) + (25. * size2)) + (10. * size3) *)
let cost_ENCODING_MICHELINE size1 size2 size3 =
  (size1 * S.safe_int 100) + (size2 * S.safe_int 25) + (size3 * S.safe_int 10)

(* model encoding/ENCODING_MICHELINE_bytes *)
(* fun size -> 33. * size *)
let cost_ENCODING_MICHELINE_bytes size = size * S.safe_int 33

(* model micheline/strip_locations_micheline *)
(* fun size -> 51. * size *)
let cost_strip_locations_micheline size =
  let size = S.safe_int size in
  size * S.safe_int 51

(* model script_repr/MICHELINE_NODES *)
(* fun size -> 0. + (6.4928521501 * size) *)
let cost_MICHELINE_NODES size =
  let size = S.safe_int size in
  (size lsr 1) + (size * S.safe_int 6)

(* model script_repr/strip_annotations *)
(* fun size -> 51. * size *)
let cost_strip_annotations size =
  let size = S.safe_int size in
  size * S.safe_int 51
