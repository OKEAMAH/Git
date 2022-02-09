(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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
    Component:    Protocol Environment
    Invocation:   dune build @src/lib_protocol_environment/runtest
    Dependencies: src/lib_protocol_environment/test/assert.ml
    Subject:      Low-level operations on proxy contexts.
*)

(** Context creation *)

(*
  Genesis -- block2 -- block3a
                  \
                   \-- block3b
*)

let create_block2 ctxt =
  Context.add ctxt ["a"; "b"] (Bytes.of_string "Novembre") >>= fun ctxt ->
  Context.add ctxt ["a"; "c"] (Bytes.of_string "Juin") >>= fun ctxt ->
  Context.add ctxt ["version"] (Bytes.of_string "0.0") >>= fun ctxt ->
  Lwt.return ctxt

let create_block3a ctxt =
  Context.remove ctxt ["a"; "b"] >>= fun ctxt ->
  Context.add ctxt ["a"; "d"] (Bytes.of_string "Mars") >>= fun ctxt ->
  Lwt.return ctxt

let create_block3b ctxt =
  Context.remove ctxt ["a"; "c"] >>= fun ctxt ->
  Context.add ctxt ["a"; "d"] (Bytes.of_string "Février") >>= fun ctxt ->
  Lwt.return ctxt

type t = {
  proxy : Context.t;
  memref : Context.t;
}



let populate_context (ctxt:Context.t) blocks = List.fold_left_s (fun acc f -> f acc) ctxt blocks

let init_contexts (blockfuncs:(Context.t -> Context.t Lwt.t) list) (f:(t -> unit Lwt.t)) _ () : 'a Lwt.t =
  let open Lwt_syntax in

  (* TODO:      Use proxy in delegation mode *)
  let proxy_genesis : Context.t = Proxy_context.empty None in
  let* proxy = populate_context proxy_genesis blockfuncs in

  let memref_genesis : Context.t = Memory_context.empty in
  let* memref = populate_context memref_genesis blockfuncs in

  f { proxy; memref }



let test_cmp msg testfunc val_assert proxy_ctx memref_ctx =
  let open Lwt_syntax in

  (* Assert the value is the one expected *)
  let* proxy_got = testfunc proxy_ctx in
  val_assert proxy_got;

  (* Assert the value from the reference implementation is the same *)
  let* memref_got = testfunc memref_ctx in
  Assert.equal ~msg proxy_got memref_got;
  Lwt.return_unit

(* Test MEM *)
let test_mem { proxy; memref; _} =
  let open Lwt_syntax in

  let testmemfct msg path exp = test_cmp msg (fun ctx -> Context.mem ctx path) (Assert.equal_bool ~msg exp) proxy memref in

  let* () = testmemfct "1st_layer_leaf" ["version"] true in
  let* () = testmemfct "removed_leaf" ["a"; "c"] false in
  let* () = testmemfct "exist_leaf" ["a"; "d"] true in
  let* () = testmemfct "doesnt_exist_leaf" ["a"; "x"] false in

  Lwt.return_unit

(* Test MEM TREE *)
let test_mem_tree { proxy; memref; _} =
  let open Lwt_syntax in

  let testmemtreefct msg path exp =
      test_cmp msg
      (fun ctx -> Context.mem_tree ctx path)
      (Assert.equal_bool ~msg exp)
      proxy memref in

  let* () = testmemtreefct "exist_tree" ["a"] true in
  let* () = testmemtreefct "doesnt_exist_tree" ["b"] false in
  (* let* () = testmemtreefct "is_leaf_not_tree" ["a"; "d"] false in *)

  Lwt.return_unit

(* Test FIND *)
let test_find { proxy; memref; _} =
  let open Lwt_syntax in

  let testfindfct msg path exp =
      test_cmp msg
      (fun ctx -> Context.find ctx path)
      (Assert.equal_bytes_option ~msg exp)
      proxy memref in

  let* () = testfindfct "exist_1stlayer_leaf" ["version"] (Some (Bytes.of_string "0.0")) in
  let* () = testfindfct "exist_leaf" ["a"; "d"] (Some (Bytes.of_string "Février")) in
  let* () = testfindfct "doesnt_exist_leaf" ["a"; "x"] (None) in
  let* () = testfindfct "removed_leaf" ["a"; "c"] (None) in

  Lwt.return_unit

(* Test FIND TREE *)
let test_find_tree { proxy; memref; _} =
  let open Lwt_syntax in

  let testfindtreefct msg path exp =
      test_cmp msg
      (fun ctx -> Context.find ctx path)
      (Assert.equal_bytes_option ~msg exp)
      proxy memref in

  let* () = testfindtreefct "exist_1stlayer_leaf" ["version"] (Some (Bytes.of_string "0.0")) in
  let* () = testfindtreefct "exist_leaf" ["a"; "d"] (Some (Bytes.of_string "Février")) in
  let* () = testfindtreefct "doesnt_exist_leaf" ["a"; "x"] (None) in
  let* () = testfindtreefct "removed_leaf" ["a"; "c"] (None) in

  Lwt.return_unit


(******************************************************************************)

let tests =
  [
    ("mem", test_mem);
    ("memtree", test_mem_tree);
    ("find", test_find);
    ("find_tree", test_find_tree);
  ]

let tests : unit Alcotest_lwt.test_case list =
  List.map
    (fun (n, f) -> Alcotest_lwt.test_case n `Quick (init_contexts [ create_block2; create_block3a; create_block3b ] f))
    tests

let () =
  Alcotest_lwt.run
    "tezos-shell-proxy-context"
    [("proxy_context", tests);]
  |> Lwt_main.run
