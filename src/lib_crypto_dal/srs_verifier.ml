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

(* Bounds (in log₂)
   1 <= redundancy<= 4
   7 <= page size + (redundancy + 1) <= slot size <= 20
   5 <= page size <= slot size - (redundancy + 1) <= 18 - 5 = 13
   2 <= redundancy + 1 <= nb shards <= slot size - page size <= 15
   we call range the number of logs to go through
   we call offset the index to start (included)
*)
type range = {
  redundancy_range : int;
  redundancy_offset : int;
  slot_range : int;
  slot_offset : int;
  page_range : int;
  page_offset : int;
}

let small_params_for_tests =
  {
    redundancy_range = 4;
    redundancy_offset = 1;
    slot_range = 6;
    slot_offset = 8;
    page_range = 3;
    page_offset = 5;
  }

let generate_poly_lengths p =
  let page_srs =
    let values =
      List.init p.page_range (fun i ->
          domain_length ~size:(1 lsl (i + p.page_offset)))
    in
    values
  in
  let commitment_srs =
    List.init p.slot_range (fun slot_size ->
        let slot_size = slot_size + p.slot_offset in
        List.init p.redundancy_range (fun redundancy ->
            let redundancy = redundancy + p.redundancy_offset in
            let page_range =
              max 0 (slot_size - (redundancy + 1) - p.page_offset + 1)
            in
            List.init page_range (fun page_size ->
                let page_size = page_size + p.page_offset in
                Parameters_bounds_for_tests.max_srs_size
                - slot_as_polynomial_length
                    ~page_size:(1 lsl page_size)
                    ~slot_size:(1 lsl slot_size))))
    |> List.concat |> List.concat
  in
  let shard_srs =
    List.init p.slot_range (fun slot_size ->
        let slot_size = slot_size + p.slot_offset in
        List.init p.redundancy_range (fun redundancy ->
            let redundancy = redundancy + p.redundancy_offset in
            let page_range =
              max 0 (slot_size - (redundancy + 1) - p.page_offset + 1)
            in
            List.init page_range (fun page_size ->
                let page_size = page_size + p.page_offset in
                let shard_range = max 0 (slot_size - page_size + 1) in
                let shard_offset = redundancy + 1 in
                List.init shard_range (fun nb_shards ->
                    let nb_shards = nb_shards + shard_offset in
                    redundancy
                    * slot_as_polynomial_length
                        ~page_size:(1 lsl page_size)
                        ~slot_size:(1 lsl slot_size)
                    / nb_shards))))
    |> List.concat |> List.concat |> List.concat
  in
  List.sort_uniq Int.compare (page_srs @ commitment_srs @ shard_srs)

let print_verifier_srs () =
  let srs_g1, srs_g2 = fake_srs in
  let srs2 =
    List.map
      (fun i ->
        let g2 =
          Srs_g2.get srs_g2 i |> G2.to_compressed_bytes |> Hex.of_bytes
          |> Hex.show
        in
        Printf.sprintf "(%d, \"%s\")" i g2)
      (generate_poly_lengths small_params_for_tests)
  in
  let srs1 =
    List.init (1 lsl 8) (fun i ->
        Printf.sprintf
          "\"%s\""
          (Srs_g1.get srs_g1 i |> G1.to_compressed_bytes |> Hex.of_bytes
         |> Hex.show))
  in
  Printf.printf
    "\n\nlet srs_g1 = [|\n  %s\n|] |> read_srs_g1"
    (String.concat " ;\n  " @@ srs1) ;
  Printf.printf
    "\n\nlet srs_g2 = [\n  %s\n] |> read_srs_g2"
    (String.concat " ;\n  " @@ srs2)

let read_srs_g1 srs1 =
  let srs1 =
    Array.map
      (fun s -> Hex.to_bytes_exn (`Hex s) |> G1.of_compressed_bytes_exn)
      srs1
  in
  Srs_g1.of_array srs1

let read_srs_g2 srs2 =
  List.map
    (fun (i, s) -> (i, Hex.to_bytes_exn (`Hex s) |> G2.of_compressed_bytes_exn))
    srs2
