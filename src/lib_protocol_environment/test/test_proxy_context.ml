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

(** Simple test *)

let c = function None -> None | Some s -> Some (Bytes.to_string s)

(** Restore the context applied until [block2]. It is asserted that
    the following key-values are present:
    - (["version"], ["0.0"])
    - (["a"; "b"], ["Novembre"])
    - [(["a"; "c"], "Juin")]
*)
let test_simple ctxt = 
  Context.find ctxt ["version"] >>= fun version ->
  Assert.equal_string_option ~msg:__LOC__ (c version) (Some "0.0") ;
  Context.find ctxt ["a"; "b"] >>= fun novembre ->
  Assert.equal_string_option (Some "Novembre") (c novembre) ;
  Context.find ctxt ["a"; "c"] >>= fun juin ->
  Assert.equal_string_option ~msg:__LOC__ (Some "Juin") (c juin) ;
  Lwt.return_unit

let test_mem { proxy; memref; _} =
  let open Lwt_syntax in
  (* let proxy_version = Context.find proxy ["version"] in *)
  (* let memref_version = Context.find memref ["version"] in *)
  (* let () = Assert.equal_string_option proxy_version memref_version in *)
  Lwt.return_unit


(******************************************************************************)

let tests =
  [
    ("memops", test_mem);
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
