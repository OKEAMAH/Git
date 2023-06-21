(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Epoxy_tx.Tx_rollup
open Plompiler
open Plonk_test.Helpers

module RandomTx (L : LIB) = struct
  open Plonk_test.Helpers.Utils (L)

  open Helpers.V (L)

  open V (L)

  module HashPV = Plompiler.Anemoi128
  module SchnorrPV = Plompiler.Schnorr (HashPV)
  module Schnorr = SchnorrPV.P
  module T = Types.P

  let sks : Schnorr.sk array =
    Array.init Constants.max_nb_accounts (fun _ ->
        Mec.Curve.Jubjub.AffineEdwards.Scalar.random ())

  let pks = Array.map Schnorr.neuterize sks

  let init_state = P.random_state sks ()

  let r, state = P.generate_transaction ~sks init_state

  let () =
    (* let tx = match r.tx with Transfer tx -> tx | _ -> assert false in *)
    (* let src =
         (Z.to_int @@ P.coerce tx.payload.msg.src) / Constants.max_nb_tickets
       in
       let dst =
         (Z.to_int @@ P.coerce tx.payload.msg.dst) / Constants.max_nb_tickets
       in *)
    (* Printf.printf "\nsrc: %d, dst: %d\n" src dst ; *)
    let open T in
    let _acc_string i s =
      let acc =
        Option.map (fun (x, _, _) -> x) @@ T.IMap.find_opt i s.accounts
      in
      match acc with
      | None -> "none"
      | Some acc -> Format.asprintf "%a" T.pp_account acc
    in
    let diff = P.compute_diff init_state state in
    (* Printf.printf
       "diff indices: [%s]\n"
       (String.concat ","
       @@ List.map (fun (i, _) -> string_of_int i)
       @@ IMap.bindings diff.accounts) ; *)
    let new_state = P.apply_diff init_state diff in
    (* let src_acc_string = acc_string src init_state in
       let dst_acc_string = acc_string dst init_state in
       Printf.printf "Before:\nsrc: %s\n dst: %s\n" src_acc_string dst_acc_string ;
       let src_acc_string = acc_string src diff in
       let dst_acc_string = acc_string dst diff in
       Printf.printf "Diff:\nsrc: %s\n dst: %s\n" src_acc_string dst_acc_string ;
       let src_acc_string = acc_string src state in
       let dst_acc_string = acc_string dst state in
       Printf.printf "After:\nsrc: %s\n dst: %s\n" src_acc_string dst_acc_string ;
       let src_acc_string = acc_string src new_state in
       let dst_acc_string = acc_string dst new_state in
       Printf.printf "Applied:\nsrc: %s\n dst: %s\n" src_acc_string dst_acc_string ; *)
    assert (P.state_scalar state = P.state_scalar new_state)

  let tests =
    [
      test
        ~valid:true
        ~name:"RandomTx.make_rollup"
        (circuit_op r init_state state);
    ]
end

let tests =
  [
    Alcotest.test_case "RandomTx" `Quick (to_test (module RandomTx : Test));
    (* Alcotest.test_case
       "RandomTx plonk"
       `Slow
       (to_test ~plonk:(module Plonk.Main_protocol) (module RandomTx : Test)); *)
  ]
