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

module Make_VC_test
    (Make_VC : Vector_commitment.Vector_commitment_sig.Make_Vector_commitment) =
struct
  (* Parameters for functional correctness tests *)
  module Params_FC = struct
    let log_nb_leaves = 8
  end

  module VC = Make_VC (Params_FC)
  open VC
  open VC.Internal_test

  let test_correctness () =
    let file_name = "test_vc" in
    let snd_lvl = generate_leaves () in
    let () = create_tree ~file_name snd_lvl in

    let diff = generate_update ~size:(1 lsl 4) in
    (*     let t1 = Unix.gettimeofday () in *)
    let () = apply_update ~file_name diff in
    (*     let t2 = Unix.gettimeofday () in *)
    (*     Printf.printf "\n time = %f \n" (t2 -. t1) ; *)
    let root = read_root ~file_name in
    apply_update_leaves snd_lvl diff ;
    let tree_memory = create_tree_memory snd_lvl in
    let root_new = read_root_memory tree_memory in
    Unix.unlink file_name ;
    assert (equal_root root root_new)

  let tests =
    List.map
      (fun (name, f) -> Alcotest.test_case name `Quick f)
      [("VC_correctness", test_correctness)]
end

(* let prepare_bench () = *)
(*   let file_name = "test_vc_bench" in *)
(*   let snd_lvl = generate_leaves () in *)
(*   let () = commit_storage fd snd_lvl in *)
(*   () *)

(* let test_bench log_size = *)
(*   let fd = "test_vc_bench" in *)
(*   let diff = create_update (1 lsl log_size) in *)
(*   let t1 = Unix.gettimeofday () in *)
(*   let () = update_commit fd diff in *)
(*   let t2 = Unix.gettimeofday () in *)
(*   Printf.printf "\n RANDOM log_size = %d ; time = %f \n" log_size (t2 -. t1) *)

(* let test_bench_update () = *)
(*   (\*   for _i = 1 to 5 do *\) *)
(*   (\*     test_bench 18 ; *\) *)
(*   (\*     test_bench_uniform 18 *\) *)
(*   (\*   done *\) *)
(*   for i = 16 to 18 do *)
(*     test_bench i *)
(*   done *)
