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

(* This module is taken from lib_plonk/test/helpers.ml but modified for VC functions. *)
module Time = struct
  type data = {n : int; sum : float; sum_squares : float; last : float}

  let str_time = ref ""

  let zero_data = {n = 0; sum = 0.; sum_squares = 0.; last = 0.}

  let apply_update = ref zero_data

  let reset () = apply_update := zero_data

  let update data time =
    let sum = time +. !data.sum in
    let sum_squares = (time *. time) +. !data.sum_squares in
    data := {n = !data.n + 1; sum; sum_squares; last = time}

  let mean data = !data.sum /. float_of_int !data.n

  let var data =
    let m = mean data in
    (!data.sum_squares /. float_of_int !data.n) -. (m *. m)

  let std data = sqrt (var data)

  let string_of_time t =
    if t > 60. then Printf.sprintf "%3.2f m " (t /. 60.)
    else if t > 1. then Printf.sprintf "%3.2f s " t
    else if t > 0.001 then Printf.sprintf "%3.2f ms" (t *. 1_000.)
    else Printf.sprintf "%3.0f µs" (t *. 1_000_000.)

  let time description f =
    Gc.full_major () ;
    let start = Unix.gettimeofday () in
    let res = f () in
    let stop = Unix.gettimeofday () in
    let d = stop -. start in
    let () =
      match description with "apply_update" -> update apply_update d | _ -> ()
    in
    let t_str = string_of_time d in
    Printf.printf "%-8s: Time: %8s \n%!" description t_str ;
    res

  let reset_str () = str_time := ""

  let update_str ?header () =
    let header =
      match header with None -> "" | Some header -> header ^ "\n"
    in
    str_time := !str_time ^ Printf.sprintf "%s%f\n" header !apply_update.last

  let print_time_in_file file =
    let oc = open_out file in
    Printf.fprintf oc "%s" !str_time ;
    close_out oc

  let rec repeat n f () =
    if n > 0 then (
      f () ;
      repeat (n - 1) f ())

  let bench_test_function ~nb_rep func () =
    reset () ;
    repeat nb_rep func () ;
    assert (nb_rep = !apply_update.n) ;
    Printf.printf
      "\nTimes over %d repetitions (95%% confidence interval):\n\n"
      nb_rep ;
    let pp = string_of_time in
    let z = 1.96 in
    Printf.printf
      "  Apply_update : %s ± %s\n"
      (pp (mean apply_update))
      (pp (z *. std apply_update)) ;
    Printf.printf "\n"

  let time_if_verbose verbose description f =
    if verbose then time description f else f ()
end

module Make_VC_test
    (Make_VC : Vector_commitment.Vector_commitment_sig.Make_Vector_commitment) =
struct
  module Params_FC = struct
    let log_nb_cells = 4
  end

  module VC = Make_VC (Params_FC)

  let test_correctness () =
    (* Parameters for functional correctness tests *)
    let open VC in
    let open VC.Internal_test in
    let file_name = "test_vc" in
    let leaves = generate_leaves () in
    let () = create_tree ~file_name leaves in

    let diff = generate_update ~size:(1 lsl 2) in
    (*     let t1 = Unix.gettimeofday () in *)
    let () = apply_update ~file_name diff in
    (*     let t2 = Unix.gettimeofday () in *)
    (*     Printf.printf "\n time = %f \n" (t2 -. t1) ; *)
    let root = read_root ~file_name in
    apply_update_leaves leaves diff ;
    let tree_memory = create_tree_memory leaves in
    let root_new = read_root_memory tree_memory in
    Unix.unlink file_name ;
    assert (equal_root root root_new)

  let prepare_bench log_nb_bits () =
    let module Params_FC = struct
      let log_nb_cells = log_nb_bits
    end in
    let module VC = Make_VC (Params_FC) in
    let open VC in
    let file_name = "test_vc_bench" in
    let leaves = generate_leaves () in
    let () = create_tree ~file_name leaves in
    ()

  let test_bench log_nb_bits log_size_update =
    let module Params_FC = struct
      let log_nb_cells = log_nb_bits
    end in
    let module VC = Make_VC (Params_FC) in
    let open VC in
    let file_name = "test_vc_bench" in
    let diff = generate_update ~size:(1 lsl log_size_update) in
    let () =
      Time.bench_test_function
        ~nb_rep:10
        (fun () ->
          Time.time "apply_update" (fun () -> apply_update ~file_name diff))
        ()
    in
    Printf.printf "-----------------------------"

  let test_bench_update () =
    for i = 5 to 8 do
      test_bench 10 i
    done

  let tests =
    List.map
      (fun (name, f) -> Alcotest.test_case name `Quick f)
      [
        (* ("VC_correctness", test_correctness) ; *)
        (*         ("VC_prepare", prepare_bench 10); *)
        ("VC_bench", test_bench_update);
      ]
end
