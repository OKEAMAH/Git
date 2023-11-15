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
open Vector_commitment.Merkle

let test_update_one () =
  let fd = "test_mt" in
  let fd2 = "test_mt2" in
  let leaves = generate_leaves () in
  (* let leaves =
       Kzg.Bls.Scalar.[|of_string "1" |> to_bytes; of_string "2" |> to_bytes ; of_string "3" |> to_bytes; of_string "4" |> to_bytes|]
     in *)
  (* Array.iteri
     (fun k i -> Printf.printf "\nl[%d] : %s" k Hex.(show (of_bytes i)))
     leaves ; *)
  commit_storage fd leaves ;
  Printf.printf "\ninitial storage\n" ;
  print_storage fd ;
  (* let root_before = read_root fd in *)
  let index, value =
    (Random.int Parameters.nb_cells, Kzg.Bls.Scalar.(random () |> to_bytes))
    (* (0, Kzg.Bls.Scalar.(of_string "5" |> to_bytes)) *)
  in
  update_one fd index value ;
  Printf.printf "\nafter update_one\n" ;
  print_storage fd ;
  let root_after_update_one = read_root fd in
  leaves.(index) <- value ;
  (* Array.iteri
     (fun k i -> Printf.printf "\nl[%d] : %s" k Hex.(show (of_bytes i)))
     leaves ; *)
  commit_storage fd2 leaves ;
  Printf.printf "\nafter commit\n" ;
  print_storage fd2 ;
  let root_after_commit_storage = read_root fd2 in
  (* Printf.printf "\nroot_before : %s" Hex.(show (of_bytes root_before)) ;
     Printf.printf "\nroot_afteru : %s" Hex.(show (of_bytes root_after_update_one)) ; *)
  (* Printf.printf
     "\nroot_afterc : %s\n"
     Hex.(show (of_bytes root_after_commit_storage)) ; *)
  assert (Bytes.equal root_after_update_one root_after_commit_storage)

let test_update update_size () =
  assert (update_size <= Parameters.log_nb_cells) ;
  let fd = "test_mt" in
  let fd2 = "test_mt2" in
  let leaves = generate_leaves () in
  commit_storage fd leaves ;
  (* Printf.printf "\ninitial storage\n" ;
     print_storage fd ; *)
  let update = create_diff (1 lsl update_size) in
  update_commit fd update ;
  (* Printf.printf "\nafter update_one\n" ;
     print_storage fd ; *)
  let root_after_update_one = read_root fd in
  update_leaves leaves update ;
  commit_storage fd2 leaves ;
  (* Printf.printf "\nafter commit\n" ;
     print_storage fd2 ; *)
  let root_after_commit_storage = read_root fd2 in
  assert (Bytes.equal root_after_update_one root_after_commit_storage)

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [
      (* ("Merkle update one", test_update_one) ; *)
      ("Merkle update", test_update 2);
    ]
