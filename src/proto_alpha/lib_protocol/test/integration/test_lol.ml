(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

(** Testing
    -------
    Component:    Lol
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/integration/main.exe \
                   -- --file test_lol.ml
    Subject:      Lol
*)

let test_lol () =
  let open Lwt_result_syntax in
  let* block, _baker = Context.init1 () in
  let* block = Block.bake block in
  let* block = Block.bake block in
  let (_ : Block.t) = block in
  return_unit

let tests = [Tztest.tztest "Test lol" `Quick test_lol]

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("lol", tests)] |> Lwt_main.run
