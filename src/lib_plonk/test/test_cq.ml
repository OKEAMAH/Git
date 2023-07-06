(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

let ( !! ) = Plonk_test.Cases.( !! )

let srs = fst Plonk_test.Helpers.srs

let table = !![0; 2; 4; 6; 8; 10; 12; 14; 16; 18; 20; 22; 24; 26; 28; 30]

let f = !![0; 2; 2; 0]

let f_not_in_table = !![0; 3; 2; 0]

let wire_size = Array.length f

let test_correctness () =
  let prv, vrf = Plonk.Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  let proof, prv_transcript = Plonk.Cq.prove prv transcript f in
  let vrf, vrf_transcript = Plonk.Cq.verify vrf transcript proof in
  assert vrf ;
  assert (Bytes.equal prv_transcript vrf_transcript)

let test_not_in_table () =
  let prv, _ = Plonk.Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  try
    let _ = Plonk.Cq.prove prv transcript f_not_in_table in
    failwith
      "Test_cq.test_not_in_table : proof generation was supposed to fail."
  with Plonk.Cq.Entry_not_in_table -> ()

let test_wrong_proof () =
  let module Cq = Plonk.Cq.Internal in
  let prv, vrf = Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  let proof_f, _ = Cq.prove prv transcript f in
  let wrong_proof =
    let f =
      Plonk.Bls.(
        Evaluations.(
          interpolation_fft
            (Domain.build wire_size)
            (of_array (wire_size - 1, f_not_in_table))))
    in
    Cq.{proof_f with cm_f = Plonk.Utils.commit1 prv.srs1 f}
  in
  assert (not (fst @@ Cq.verify vrf transcript wrong_proof))

let bench_pippenger () =
  let nb_rep = 1000 in
  let open Plonk.Bls in
  let srs, _ =
    let open Octez_bls12_381_polynomial.Bls12_381_polynomial in
    Srs.generate_insecure 8 0
  in
  let _srs = Srs_g1.to_array srs in
  let _srs_affine = G1.to_affine_array _srs in
  let f_poly =
    Poly.of_coefficients
      (List.init (Srs_g1.size srs) (fun i ->
           let rec s () =
             let x = Scalar.random () in
             if String.length (Scalar.to_string x) < 60 then s () else x
           in
           (s (), i)))
  in
  let f = Poly.to_dense_coefficients f_poly in

  let f_srs () =
    let _ = Srs_g1.pippenger srs f_poly in
    ()
  in
  let f_g1 () =
    let _ = G1.pippenger _srs f in
    ()
  in
  let f_g1_affine () =
    let _ = G1.pippenger_with_affine_array _srs_affine f in
    ()
  in
  let f_g1_affine_with_conv () =
    let _ = G1.pippenger_with_affine_array (G1.to_affine_array _srs) f in
    ()
  in

  let srs = Plonk_test.Helpers.Time.bench ~nb_rep f_srs () in
  let g1 = Plonk_test.Helpers.Time.bench ~nb_rep f_g1 () in
  let affine = Plonk_test.Helpers.Time.bench ~nb_rep f_g1_affine () in
  let affine_conv =
    Plonk_test.Helpers.Time.bench ~nb_rep f_g1_affine_with_conv ()
  in

  let n = float_of_int nb_rep in

  Printf.printf "\n\nSRS pippe : %f s — mean : %f s." srs (srs /. n) ;
  Printf.printf "\nPippenger : %f s — mean : %f s." g1 (g1 /. n) ;
  Printf.printf "\nWith affi : %f s — mean : %f s." affine (affine /. n) ;
  Printf.printf
    "\nAf w conv : %f s — mean : %f s."
    affine_conv
    (affine_conv /. n) ;
  Printf.printf "\n\n" ;
  ()

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [
      (* ("Correctness", test_correctness); *)
      (* ("Not in table", test_not_in_table); *)
      (* ("Fake proof", test_wrong_proof); *)
      ("Bench pippenger", bench_pippenger);
    ]
