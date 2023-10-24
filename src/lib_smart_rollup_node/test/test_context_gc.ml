(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

(** Testing
    -------
    Component:    Smart rollup node
    Invocation:   dune exec src/lib_smart_rollup_node/test/main.exe
    Subject:      Test garbage collection for the smart rollup node context
*)

open Store_sigs

let commit_new_state _index context key =
  let open Lwt_syntax in
  let* state = Context.Internal_for_tests.get_a_tree key in
  let* context = Context.PVMState.set context state in
  let* hash = Context.commit context in
  (* let* context = Context.checkout index hash in *)
  (* let context = WithExceptions.Option.get ~loc:__LOC__ context in *)
  Lwt.return (context, hash)

(* Create a mock context, commit 3 states, and trigger garbage collection
 * for the first 2 hashes. Check that the first 2 hashes have been deleted
 * and that the third hash can be retrieved. *)
let test_gc data_dir =
  let open Lwt_result_syntax in
  let* index =
    Context.load
      ~cache_size:Configuration.default_irmin_cache_size
      Read_write
      (Configuration.default_context_dir data_dir)
  in
  let context = Context.empty index in
  let*! context, hash1 = commit_new_state index context "tree1" in
  let*! context, hash2 = commit_new_state index context "tree2" in
  let*! _context, hash3 = commit_new_state index context "tree3" in

  let*! b = Context.checkout index hash1 in
  assert (Option.is_some b) ;
  let*! b = Context.checkout index hash2 in
  assert (Option.is_some b) ;
  let*! b = Context.checkout index hash3 in
  assert (Option.is_some b) ;

  let*! () = Context.gc index hash3 in
  let*! () = Context.wait_gc_completion index in
  assert (Context.is_gc_finished index) ;

  let*! b = Context.checkout index hash1 in
  assert (Option.is_none b) ;
  let*! b = Context.checkout index hash2 in
  assert (Option.is_none b) ;
  let*! b = Context.checkout index hash3 in
  assert (Option.is_some b) ;
  Lwt.return_ok ()

let test_export data_dir =
  let open Lwt_result_syntax in
  let* index =
    Context.load
      ~cache_size:Configuration.default_irmin_cache_size
      Read_write
      (Configuration.default_context_dir data_dir)
  in
  let context = Context.empty index in
  let*! contexts =
    let open Lwt_syntax in
    List.fold_left_s
      (fun acc n ->
        (* List.init_s ~when_negative_length:[] 100 (fun n -> *)
        let context = match acc with [] -> assert false | (c, _) :: _ -> c in
        let+ context, hash =
          commit_new_state index context ("tree" ^ string_of_int n)
        in
        (context, hash) :: acc)
      [(context, Smart_rollup_context_hash.zero)]
      (1 -- 100)
  in
  let contexts =
    match List.rev contexts with [] -> assert false | _ :: r -> r
  in
  let _, last =
    List.last_opt contexts |> WithExceptions.Option.get ~loc:__LOC__
  in
  let path = Filename.concat data_dir "context.dump" in
  let index = Context.index context in
  Log.info "Export context" ;
  let*! () = Context.export index last ~path in
  Log.info "Import context %a" Smart_rollup_context_hash.pp last ;
  let data_dir2 = Filename.concat data_dir "import_test" in
  let*! () = Lwt_utils_unix.create_dir data_dir2 in
  let* context2 =
    Context.load
      ~cache_size:Configuration.default_irmin_cache_size
      Read_write
      (Configuration.default_context_dir data_dir2)
  in
  let* () = Context.import context2 ~path in
  Log.info "Checking context import" ;
  let*! () =
    List.iteri_s
      (fun i (_c, h) ->
        let i = 100 - i in
        Format.eprintf "Checkout %d %a@." i Smart_rollup_context_hash.pp h ;
        let*! c' = Context.checkout context2 h in
        match c' with
        | None ->
            Test.fail
              ~__LOC__
              "Could not checkout %d context %a after import"
              i
              Smart_rollup_context_hash.pp
              h
        | Some c' ->
            let _state' = Context.PVMState.find c' in
            (* let _state = Context.PVMState.find c in *)
            (* assert (state = state') ; *)
            Lwt.return_unit)
      (List.rev contexts)
  in
  return_unit

(* adapted from lib_store/unix/test/test_locator.ml *)
let wrap n f =
  Alcotest_lwt.test_case n `Quick (fun _ () ->
      Lwt_utils_unix.with_tempdir "context_gc_test_" (fun dir ->
          let open Lwt_syntax in
          let* r = f dir in
          match r with
          | Ok () -> Lwt.return_unit
          | Error error ->
              Format.kasprintf Stdlib.failwith "%a" pp_print_trace error))

let tests =
  [wrap "Garbage collection" test_gc; wrap "Context export" test_export]

let () =
  Alcotest_lwt.run ~__FILE__ "lib_smart_rollup_node" [("Context", tests)]
  |> Lwt_main.run
