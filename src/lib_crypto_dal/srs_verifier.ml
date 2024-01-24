(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Kzg.Bls

module Parameters_bounds_for_tests = struct
  (* The following bounds are chosen to fit the invariants of [ensure_validity] *)

  (* The maximum value for the slot size is chosen to trigger
     cases where some domain sizes for the FFT are not powers
     of two.*)
  let max_slot_size_log2 = 13

  let max_redundancy_factor_log2 = 4

  (* The difference between slot size & page size ; also the minimal bound of
     the number of shards.
     To keep shard length < max_polynomial_length, we need to set nb_shard
     strictly greater (-> +1) than redundancy_factor *)
  let size_offset_log2 = max_redundancy_factor_log2 + 1

  (* The pages must be strictly smaller than the slot, and the difference of
     their length must be greater than the number of shards. *)
  let max_page_size_log2 = max_slot_size_log2 - size_offset_log2

  let max_srs_size = 1 lsl (max_slot_size_log2 + 1)

  (* The set of parameters maximizing the SRS length, and which
     is in the codomain of [generate_parameters]. *)
  let max_parameters : Dal_config.parameters =
    {
      (* The +1 is here to ensure that the SRS will be large enough for the
         erasure polynomial *)
      slot_size = 1 lsl max_slot_size_log2;
      page_size = 1 lsl max_page_size_log2;
      redundancy_factor = 1 lsl max_redundancy_factor_log2;
      number_of_shards = 1;
    }
end

(* Number of bytes fitting in a Scalar.t. Since scalars are integer modulo
   r~2^255, we restrict ourselves to 248-bit integers (31 bytes). *)
let scalar_bytes_amount = Scalar.size_in_bytes - 1

(* The page size is a power of two and thus not a multiple of [scalar_bytes_amount],
   hence the + 1 to account for the remainder of the division. *)
let page_length ~page_size = Int.div page_size scalar_bytes_amount + 1

(* for a given [size] (in bytes), return the length of the corresponding
   domain *)
let domain_length ~size =
  let length = page_length ~page_size:size in
  let length_domain, _, _ = Kzg.Utils.FFT.select_fft_domain length in
  length_domain

(* [slot_as_polynomial_length ~slot_size ~page_size] returns the length of the
   polynomial of maximal degree representing a slot of size [slot_size] with
   [slot_size / page_size] pages. The returned length thus depends on the number
   of pages. *)
let slot_as_polynomial_length ~slot_size ~page_size =
  let page_length_domain = domain_length ~size:page_size in
  slot_size / page_size * page_length_domain

let fake_srs =
  let length = Parameters_bounds_for_tests.max_srs_size in
  let secret =
    Scalar.of_string
      "20812168509434597367146703229805575690060615791308155437936410982393987532344"
  in
  let srs_g1 = Srs_g1.generate_insecure length secret in
  let srs_g2 = Srs_g2.generate_insecure length secret in
  (srs_g1, srs_g2)
