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
open Vector_commitment.Verkle

let test_create_diff log_size =
  let t1 = Unix.gettimeofday () in
  let _diff = create_diff (1 lsl log_size) in
  let t2 = Unix.gettimeofday () in
  Printf.printf "\n log_size = %i ; time = %f \n" log_size (t2 -. t1)

let test_bench_create_diff () =
  for i = 12 to 20 do
    test_create_diff i
  done

let test_correctness () =
  let fd = "test_vc" in
  let snd_lvl = generate_snd_lvl () in
  let () = commit_storage fd snd_lvl in

  let diff = create_uniform_diff (1 lsl 14) in
  let t1 = Unix.gettimeofday () in
  let () = update_commit fd diff in
  let t2 = Unix.gettimeofday () in
  Printf.printf "\n time = %f \n" (t2 -. t1) ;
  let root = read_root fd in

  update_storage diff snd_lvl ;
  let root_new, _ = commit snd_lvl in
  assert (Bls12_381.G1.eq root root_new)

let test_bench_uniform log_size =
  let fd = "test_vc_bench" in
  let diff = create_uniform_diff (1 lsl log_size) in
  let t1 = Unix.gettimeofday () in
  let () = update_commit fd diff in
  let t2 = Unix.gettimeofday () in
  Printf.printf "\n UNIFORM log_size = %d ; time = %f \n" log_size (t2 -. t1)

let test_bench log_size =
  let fd = "test_vc_bench" in
  let diff = create_diff (1 lsl log_size) in
  let t1 = Unix.gettimeofday () in
  let () = update_commit fd diff in
  let t2 = Unix.gettimeofday () in
  Printf.printf "\n RANDOM log_size = %d ; time = %f \n" log_size (t2 -. t1)

let test_bench_update () =
  (*   for _i = 1 to 5 do *)
  (*     test_bench 18 ; *)
  (*     test_bench_uniform 18 *)
  (*   done *)
  for i = 16 to 18 do
    test_bench i
  done

let prepare_bench () =
  let fd = "test_vc_bench" in
  let snd_lvl = generate_snd_lvl () in
  let () = commit_storage fd snd_lvl in
  ()

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [
      (*       ("Bench create diff", test_bench_create_diff) *)
      (*       ("Verkle_correctness", test_correctness) *)
      ("Verkle_bench_update", test_bench_update);
      (*       ("Verkle_prepare", prepare_bench); *)
    ]
