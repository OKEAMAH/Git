(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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
    Component:    Protocol Library
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/pbt/test_tx_rollup_l2_withdraw_storage.exe
    Subject:      Tx rollup l2 withdraw storage
*)

open Lib_test.Qcheck2_helpers

open Protocol.Tx_rollup_withdraw_repr.Withdrawal_accounting

let gen_ofs = QCheck2.Gen.int_bound (64 * 10)

let gen_storage = QCheck2.Gen.(list int64)

let test_get_set (c, ofs) =
  List.for_all
    (fun ofs' ->
      let res =
        let open Tzresult_syntax in
        let* c' = set c ofs in
        let* v = get c ofs' in
        let* v' = get c' ofs' in
        return (if ofs = ofs' then v' = true else v = v')
      in
      match res with
      | Error e ->
          Alcotest.failf
            "Unexpected error: %a"
            Protocol.Environment.Error_monad.pp_trace
            e
      | Ok res -> res)
    (0 -- 63)

let () =
  let qcheck_wrap = qcheck_wrap ~rand:(Random.State.make_self_init ()) in
  Alcotest.run
    "bits"
    [
      ( "quantity",
        qcheck_wrap
          [
            QCheck2.Test.make
              ~print:(fun (storage, ofs) ->
                Format.asprintf
                  "([%a], %d)"
                  (Format.pp_print_list
                     ~pp_sep:Format.pp_print_cut
                     (fun fmt x -> Format.fprintf fmt "%s" (Int64.to_string x)))
                  storage
                  ofs)
              ~name:"get set"
              QCheck2.Gen.(pair gen_storage gen_ofs)
              test_get_set;
          ] );
    ]
