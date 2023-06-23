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

let f_not_in_table = !![0; 3; 4; 6]

let f_size = Array.length f

let test_correctness () =
  let prv, vrf = Plonk.Cq.setup srs f_size table in
  let transcript = Bytes.empty in
  let proof, prv_transcript = Plonk.Cq.prove prv transcript f in
  let vrf, vrf_transcript = Plonk.Cq.verify vrf transcript proof in
  assert vrf ;
  assert (Bytes.equal prv_transcript vrf_transcript)

let test_negative () =
  let prv, vrf = Plonk.Cq.setup srs f_size table in
  let transcript = Bytes.empty in
  try
    let proof, _ = Plonk.Cq.prove prv transcript f_not_in_table in
    let vrf, _ = Plonk.Cq.verify vrf transcript proof in
    assert (not vrf)
  with Plonk.Cq.Entry_not_in_table -> ()

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Correctness", test_correctness); ("Negative", test_negative)]
