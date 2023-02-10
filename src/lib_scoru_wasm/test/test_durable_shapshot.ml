(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech  <contact@trili.tech>                        *)
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

(** Testing
    -------
    Component:    Lib_scoru_wasm durable
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "^Durable snapshot$"
    Subject:      Tests for the tezos-scoru-wasm durable snapshotting
*)

open QCheck
open Tztest
open Encodings_util
open Durable_snapshot_util
open Durable_stresstest_generator
open Probability_helpers
open Durable_input_generator

module Paired_runners = struct
  module Inp_gen = Make_default_input_generator (Snapshot)

  (* Gen_f needed to overcome a compile error which occurs when
     Durable_operation_generator (Paired_durable) is inplaced directly in
     module Generator = ...
  *)
  module Generator_f = Durable_operation_generator (Paired_durable)
  module Generator = Generator_f.Make_probabilistic_generator (Inp_gen)

  (* Create new tree with passed list of key values *)
  let initialize_tree (keys, values) =
    let open Lwt_syntax in
    let open Tezos_scoru_wasm_durable_snapshot in
    let kv = WithExceptions.List.combine ~loc:__LOC__ keys values in
    (* 20% of all keys go to readonly subpath *)
    let ro_ops = Int.(div (List.length kv) 5) in
    let ro_values, w_values = List.split_n ro_ops kv in
    let ro_values =
      List.mapi
        (fun i (k, v) -> if i < ro_ops then ("/readonly" ^ k, v) else (k, v))
        ro_values
    in
    let* init_tezos_durable =
      Lwt.map Durable.of_storage_exn @@ Wasm_utils.make_durable w_values
    in
    (* Add RO keys in the tree *)
    let* init_tezos_durable =
      Lwt_list.fold_left_s
        (fun dur (k, v) ->
          Durable.set_value_exn
            ~edit_readonly:true
            dur
            (Durable.key_of_string_exn k)
            v)
        init_tezos_durable
        ro_values
    in
    let* init_tree = empty_tree () in
    Tree_encoding_runner.encode
      Tezos_scoru_wasm_durable_snapshot.Durable.encoding
      init_tezos_durable
      init_tree

  let gen_stress_main_impl ~(rounds : int) ~(initial_tree_size : int) :
      unit Generator.Gen_lwt.t =
    let open Generator.Gen_lwt_syntax in
    let open Monads_util.Monad_ops (Generator.Gen_lwt) in
    (* Insert initial values *)
    let key_gen =
      gen_arbitrary_path
        ~max_len:Default_key_generator_params.max_key_length
        ~max_segments_num:20
        (Gen.oneofl Default_key_generator_params.key_alphabet)
    in
    let*? keys = Gen.list_size (Gen.return initial_tree_size) key_gen in
    let*? values =
      Gen.list_size
        (Gen.return initial_tree_size)
        (Gen.string_size ~gen:Gen.char (Gen.int_bound 2048))
    in
    let*! init_tree = initialize_tree (keys, values) in
    (* Initialise input generator context *)
    let*! init_snaphot =
      Tree_encoding_runner.decode Snapshot.encoding init_tree
    in
    let* _, ops_distr = Gen_lwt.get_state in
    let* () = Gen_lwt.set_state (init_snaphot, ops_distr) in

    (* Decode initial paired durable *)
    let*! init_paired_durable =
      Tree_encoding_runner.decode Paired_durable.encoding init_tree
    in
    let* _final_dur =
      iter_n init_paired_durable rounds ~f:(fun dur ->
          let* new_snapshot, new_current = Generator.apply_op dur in
          (* Update input generator context for next round of generation *)
          let* _, ops_distr = Gen_lwt.get_state in
          let+ () = Gen_lwt.set_state (new_snapshot, ops_distr) in
          (new_snapshot, new_current))
    in
    (* Paired_durable.print_collected_statistic () ; *)
    (* assert (1 != 1) ; *)
    Generator.Gen_lwt.return ()

  (* rounds - number of operations to be generated in a stress-test *)
  let gen_stress ~(rounds : int) ~(initial_tree_size : int)
      ~(operations_distribution : operations_distribution) : unit Gen.t =
   fun g ->
    Lwt_main.run
    @@
    let open Lwt_syntax in
    (* This empty tree won't be used in the gen_stress_main_impl *)
    let* empt = empty_tree () in
    let* init_snaphot = Tree_encoding_runner.decode Snapshot.encoding empt in
    Lwt.map fst
    @@ gen_stress_main_impl
         ~rounds
         ~initial_tree_size
         g
         (init_snaphot, operations_distribution)

  let run_scenario (scenario : Paired_durable.t -> 'a Lwt.t) : 'a Lwt.t =
    let open Lwt_syntax in
    let* tree = empty_tree () in
    let* durable = Tree_encoding_runner.decode Paired_durable.encoding tree in
    (* Check pre-conditions:
       max key length is the same for both implementations.
       Perhaps this will be evaluated when the module initialises
    *)
    let _max_key_len = Paired_durable.max_key_length in
    let* result = scenario durable in
    let* final_state_eq = Durables_equality.eq (fst durable) (snd durable) in
    let* snapshot_str = Durables_equality.to_string_a (fst durable) in
    let+ current_str = Durables_equality.to_string_b (snd durable) in
    (* Just in case check testing states *)
    Assert.assert_true
      (Format.asprintf
         "Final durable states diverged: snapshot = %s vs current = %s"
         snapshot_str
         current_str)
      final_state_eq ;
    result
end

module Runners = Paired_runners

let assert_exception exected_ex run =
  let open Lwt_syntax in
  Lwt.catch
    (fun () ->
      let+ _ = run () in
      assert false)
    (fun caught_exn ->
      match caught_exn with
      | e when e = exected_ex -> Lwt.return_unit
      | x -> raise x)

(* Actual tests *)
let test_several_operations () =
  Runners.run_scenario @@ fun durable ->
  let open Lwt_syntax in
  let key1 = Paired_durable.key_of_string_exn "/durable/value/to/write1" in
  let key2 = Paired_durable.key_of_string_exn "/durable/value/to2/write2" in
  let* durable = Paired_durable.write_value_exn durable key1 0L "hello" in
  let* durable = Paired_durable.write_value_exn durable key2 0L "world" in
  let* res_hello = Paired_durable.read_value_exn durable key1 0L 5L in
  Assert.String.equal ~loc:__LOC__ "hello" res_hello ;
  let* res_still_hello = Paired_durable.read_value_exn durable key1 0L 10L in
  Assert.String.equal ~loc:__LOC__ "hello" res_still_hello ;
  let key_prefix = Paired_durable.key_of_string_exn "/durable/value" in
  let* durable = Paired_durable.delete durable key_prefix in
  let* () =
    assert_exception Tezos_scoru_wasm_durable_snapshot.Durable.Value_not_found
    @@ fun () -> Paired_durable.read_value_exn durable key1 0L 5L
  in
  return_ok_unit

let stress_test_desceding2000_3000 =
  make
  @@ Runners.gen_stress
       ~rounds:3000
       ~initial_tree_size:2000
       ~operations_distribution:
         (Distributions.desceding_distribution_l
            Durable_operation.all_operations)

let stress_test_uniform2000_10000 =
  make
  @@ Runners.gen_stress
       ~rounds:10000
       ~initial_tree_size:2000
       ~operations_distribution:
         (Distributions.uniform_distribution_l Durable_operation.all_operations)

let stress_strcture_ops =
  make
  @@ Runners.gen_stress
       ~rounds:3000
       ~initial_tree_size:2000
       ~operations_distribution:
         (Distributions.uniform_distribution_l
            Durable_operation.(
              List.concat
                [
                  structure_modification_operations;
                  structure_inspection_operations;
                ]))

let stress_each_op () =
  let initial_tree_size = 1000 in
  let rounds = 2000 in
  let test_case x =
    make
    @@ Runners.gen_stress ~rounds ~initial_tree_size ~operations_distribution:x
  in
  List.mapi
    (fun i op ->
      tztest_qcheck
        ~count:1
        ~name:
          (Format.asprintf
             "Stress-test operation %a, initial tree size %d and rounds %d"
             Durable_operation.pp_some_op
             op
             initial_tree_size
             rounds)
        (test_case @@ Distributions.one_of_n i Durable_operation.all_operations)
        (fun _ -> Lwt.return (Ok ())))
    Durable_operation.all_operations

let tests : unit Alcotest_lwt.test_case trace =
  List.append
    [
      tztest "Do several operations on durable" `Quick test_several_operations;
      tztest_qcheck
        ~count:1
        ~name:"All operations: initial tree size is 2000, rounds are 3000"
        stress_test_desceding2000_3000
        (fun _ -> Lwt.return (Ok ()));
      tztest_qcheck
        ~count:1
        ~name:"All operations: initial tree size is 2000, rounds are 10000"
        stress_test_uniform2000_10000
        (fun _ -> Lwt.return (Ok ()));
      tztest_qcheck
        ~count:1
        ~name:
          "Structural modifications: initial tree size is 2000, rounds are 3000"
        stress_strcture_ops
        (fun _ -> Lwt.return (Ok ()));
    ]
    (stress_each_op ())
