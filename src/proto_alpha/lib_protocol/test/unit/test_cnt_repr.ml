(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
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
    Component:    Contract_repr
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                  -- --file test_cnt_repr.ml
    Dependencies: contract_hash.ml
    Subject:      Testing the internal protocol counter. 
*)

open Protocol

(* open Storage_functors *)
module A = Alpha_context

let create () =
  let open Lwt_result_syntax in
  let account = Account.new_account () in
  let bootstrap_account = Account.make_bootstrap_account account in
  let* alpha_ctxt = Block.alpha_context [bootstrap_account] in
  return @@ A.Internal_for_tests.to_raw alpha_ctxt

let test_cnt_init () =
  let open Lwt_result_wrap_syntax in
  let* ctxt = create () in

  let*@ counter = Cnt_storage.current ctxt in
  Assert.equal_int32 ~loc:__LOC__ counter 0l

let test_cnt_increase () =
  let open Lwt_result_wrap_syntax in
  let* ctxt = create () in
  let*@ ctxt = Cnt_storage.increase ctxt in
  let*@ counter = Cnt_storage.current ctxt in
  let* () = Assert.equal_int32 ~loc:__LOC__ counter 1l in
  let*@ ctxt = Cnt_storage.increase ctxt in
  let*@ counter = Cnt_storage.current ctxt in
  let* () = Assert.equal_int32 ~loc:__LOC__ counter 2l in
  let*@ ctxt = Cnt_storage.increase ctxt in
  let*@ counter = Cnt_storage.current ctxt in
  Assert.equal_int32 ~loc:__LOC__ counter 3l

let tests =
  [
    Tztest.tztest "Test counter init for internal count" `Quick test_cnt_init;
    Tztest.tztest
      "Test counter increase for internal count"
      `Quick
      test_cnt_increase;
  ]

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("Cnt_storage.ml", tests)]
  |> Lwt_main.run
