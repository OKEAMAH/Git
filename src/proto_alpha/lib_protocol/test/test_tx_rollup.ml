(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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
    Component:    Rollup layer 1 logic
    Invocation:   dune exec src/proto_alpha/lib_protocol/test/main.exe -- test "^tx rollup$"
    Subject:      Test rollup
*)

open Tx_rollup_helpers
open Protocol
open Alpha_context
open Tx_rollup_l2_operation
open Tx_rollup_l2_apply
open Test_tez

let (ticket1, ticket2) =
  match
    Lwt_main.run
      ( Context.init 1 >>=? fun (blk, _) ->
        Incremental.begin_construction blk >>=? fun incr ->
        let ctxt = Incremental.alpha_ctxt incr in
        let (ticket1, ctxt) = make_key ctxt "first ticket" in
        let (ticket2, ctxt) = make_key ctxt "second ticket" in
        ignore ctxt ;
        return (ticket1, ticket2) )
  with
  | Ok x -> x
  | Error err ->
      Format.printf "%a\n" Error_monad.pp_print_trace err ;
      raise (Invalid_argument "tickets")

let check_tx_rollup_exists ctxt tx_rollup =
  Context.Tx_rollup.state ctxt tx_rollup >|=? Option.is_some

(** [test_disable_feature_flag] Test that by default the tx rollup feature flag
    is correctly deactivated *)
let test_disable_feature_flag () =
  Context.init ~consensus_threshold:0 1 >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op, _tx_rollup) ->
  let expect_failure = function
    | Environment.Ecoproto_error (Apply.Tx_rollup_disabled as e) :: _ ->
        Assert.test_error_encodings e ;
        return_unit
    | _ -> failwith "It should not be possible to send a rollup_operation "
  in
  Incremental.add_operation ~expect_failure i op >>= fun _i -> return_unit

(** [test_origination] Test to originate a tx rollup and check that it burns the
    correct amount of the origination source contract. *)
let test_origination () =
  Context.init ~tx_rollup_enable:true ~consensus_threshold:0 1
  >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Context.get_constants (B b)
  >>=? fun {parametric = {tx_rollup_origination_size; cost_per_byte; _}; _} ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op, tx_rollup) ->
  Incremental.add_operation i op >>=? fun i ->
  check_tx_rollup_exists (I i) tx_rollup >>=? fun exists ->
  if exists then
    cost_per_byte *? Int64.of_int tx_rollup_origination_size
    >>?= fun tx_rollup_origination_burn ->
    Assert.balance_was_debited
      ~loc:__LOC__
      (I i)
      contract
      balance
      tx_rollup_origination_burn
  else failwith "tx rollup was not correctly originated"

(** [test_two_origination] checks that it works to originate two tx rollup are
    in the same operation and that each as a different address. *)
let test_two_origination () =
  Context.init ~tx_rollup_enable:true ~consensus_threshold:0 1
  >>=? fun (b, contracts) ->
  let contract =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  Incremental.begin_construction b >>=? fun i ->
  Op.tx_rollup_origination (I i) contract >>=? fun (op1, _false_tx_rollup1) ->
  (* tx_rollup1 and tx_rollup2 are equal and both are false. The addresses are
     derived from a value called `origination_nonce` that is dependent of the
     tezos operation hash. Also each origination increment this value.

     Here the origination_nonce is wrong because it's not based on the injected
     operation (the combined one. Also the used origination nonce is not
     incremented between _false_tx_rollup1 and _false_tx_rollup2 as the protocol
     do. *)
  Op.tx_rollup_origination (I i) contract >>=? fun (op2, _false_tx_rollup2) ->
  Op.combine_operations ~source:contract (B b) [op1; op2] >>=? fun op ->
  Incremental.add_operation i op >>=? fun i ->
  let nonce =
    Origination_nonce.Internal_for_tests.initial (Operation.hash_packed op)
  in
  let txo1 = Tx_rollup.Internal_for_tests.originated_tx_rollup nonce in
  let nonce = Origination_nonce.Internal_for_tests.incr nonce in
  let txo2 = Tx_rollup.Internal_for_tests.originated_tx_rollup nonce in
  Assert.not_equal
    ~loc:__LOC__
    Tx_rollup.equal
    "Origination of two tx rollups in one operation have different addresses"
    Tx_rollup.pp
    txo1
    txo2
  >>=? fun () ->
  check_tx_rollup_exists (I i) txo1 >>=? fun txo1_exists ->
  Assert.equal_bool ~loc:__LOC__ txo1_exists true >>=? fun () ->
  check_tx_rollup_exists (I i) txo2 >>=? fun txo2_exists ->
  Assert.equal_bool ~loc:__LOC__ txo2_exists true

module L2_test_suite (L2_context : TEST_SUITE_CONTEXT) = struct
  open L2_context
  module Apply = Tx_rollup_l2_apply.Make (L2_context)

  type account = Bls12_381.Signature.sk * Bls12_381.Signature.pk

  let nth_exn l n =
    match List.nth l n with
    | Some x -> x
    | None -> raise (Invalid_argument "nth_exn")

  let with_initial_setup balances k =
    let open Syntax in
    let storage = empty in
    let* (storage, rev_accounts) =
      list_fold_left_m
        (fun (storage, rev_acc) balance ->
          let (sk, pk) = gen_l2_account () in
          let* (storage, rev_hashes) =
            list_fold_left_m
              (fun (storage, rev_acc) (hash, amount) ->
                let* storage = Ticket_ledger.set storage hash pk amount in
                return (storage, hash :: rev_acc))
              (storage, [])
              balance
          in
          return (storage, (sk, pk, List.rev rev_hashes) :: rev_acc))
        (storage, [])
        balances
    in
    k storage (List.rev rev_accounts)

  (** Test the various path of the storage *)
  let test_tx_rollup_storage () =
    let open Syntax in
    let ctxt = empty in
    let (_, account_pk) = gen_l2_account () in
    let ticket_hash = ticket1 in
    let amount = Z.of_int 100 in
    (* 1. test [Counter] *)
    let* (res, ctxt) = Counter.get ctxt account_pk in
    Alcotest.check z_testable "counter initial" Z.zero res ;
    let* ctxt = Counter.set ctxt account_pk Z.one in
    let* (res, ctxt) = Counter.get ctxt account_pk in
    Alcotest.check z_testable "coutner after set" Z.one res ;
    (* 2. test [Ticket_ledger] *)
    let* ctxt = Ticket_ledger.set ctxt ticket_hash account_pk amount in
    let* (res, ctxt) = Ticket_ledger.get ctxt ticket_hash account_pk in
    Alcotest.check z_testable "ledger after set" amount res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_deposit () =
    let open Syntax in
    with_initial_setup [[]] @@ fun ctxt accounts ->
    let (_, pk1, _) = nth_exn accounts 0 in
    let ticket_hash = ticket1 in
    let deposit = {destination = pk1; ticket_hash; amount = Z.of_int 50} in
    let* ctxt = Apply.apply_deposit ctxt deposit in
    let* (res, ctxt) = Ticket_ledger.get ctxt ticket_hash pk1 in

    Alcotest.check z_testable "amount after apply" Z.(of_int 50) res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_single_operation () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; []] @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let (_, account2_pk, _) = nth_exn accounts 1 in
    let ticket_hash = nth_exn hashes1 0 in

    let content1 : operation_content =
      Transfer {destination = account2_pk; ticket_hash; amount = Z.of_int 32}
    in
    let transfer1 : operation =
      {signer = account1_pk; counter = Z.zero; content = content1}
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1]
    in

    assert (status = Success) ;
    let* (res, ctxt) = Counter.get ctxt account1_pk in
    Alcotest.check z_testable "counter after operation" Z.one res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt ticket_hash account1_pk in
    Alcotest.check z_testable "ledger after operation" (Z.of_int 68) res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_correct_trade () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 15};
      }
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1; transfer2]
    in

    assert (status = Success) ;

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "pk1 counter after operation" Z.one res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "pk2 counter after operation" Z.one res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash1 ledger after operation"
      (Z.of_int 70)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash2 ledger after operation"
      (Z.of_int 15)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash1 ledger after operation"
      (Z.of_int 30)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash2 ledger after operation"
      (Z.of_int 35)
      res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_wrong_counter () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.one;
        (* wrong counter *)
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 20};
      }
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1; transfer2]
    in

    assert (
      status
      = Failure
          {
            index = 1;
            reason =
              Counter_mismatch
                {account = pk2; requested = Z.one; actual = Z.zero};
          }) ;

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "counter pk1" Z.zero res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "counter pk2" Z.zero res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check z_testable "ledger pk1 hash1" (Z.of_int 100) res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk1 in
    Alcotest.check z_testable "ledger pk1 hash2" Z.zero res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check z_testable "ledger pk1 hash1" Z.zero res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk2 in
    Alcotest.check z_testable "ledger pk2 hash2" (Z.of_int 50) res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_low_balance () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 55};
      }
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1; transfer2]
    in

    assert (
      status
      = Failure
          {
            index = 1;
            reason =
              Balance_too_low
                {
                  account = pk2;
                  ticket_hash = hash2;
                  requested = Z.of_int 55;
                  actual = Z.of_int 50;
                };
          }) ;

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "pk1 counter after operation" Z.one res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "pk1 counter after operation" Z.one res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash1 ledger after operation"
      (Z.of_int 100)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash2 ledger after operation"
      (Z.of_int 0)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash1 ledger after operation"
      (Z.of_int 0)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash2 ledger after operation"
      (Z.of_int 50)
      res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_correct_batch () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 20};
      }
    in

    let transaction = [transfer1; transfer2] in
    let signature = sign_ops [sk1; sk2] transaction in

    let batch : transactions_batch =
      batch
        [transaction]
        signature
        (Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 1000)
    in

    let* (_, _, ctxt) = Apply.apply_transactions_batch ctxt batch in

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "pk1 counter after operation" Z.one res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "pk2 counter after operation" Z.one res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash1 ledger after operation"
      (Z.of_int 70)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash2 ledger after operation"
      (Z.of_int 20)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash1 ledger after operation"
      (Z.of_int 30)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash2 ledger after operation"
      (Z.of_int 30)
      res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_correct_batch_with_several_transactions () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 20};
      }
    in
    let ol2 = [transfer2] in
    let signatures2 = sign_ops [sk2] ol2 in

    let batch : transactions_batch =
      batch
        [ol1; ol2]
        (signatures1 @ signatures2)
        (Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 500000)
    in

    let* (_, _, ctxt) = Apply.apply_transactions_batch ctxt batch in

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "pk1 counter after operation" Z.one res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "pk2 counter after operation" Z.one res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash1 ledger after operation"
      (Z.of_int 70)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk1 in
    Alcotest.check
      z_testable
      "pk1 hash2 ledger after operation"
      (Z.of_int 20)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash1 ledger after operation"
      (Z.of_int 30)
      res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash2 pk2 in
    Alcotest.check
      z_testable
      "pk2 hash2 ledger after operation"
      (Z.of_int 30)
      res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_correct_batch_with_several_transactions_from_same_account
      () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (_sk2, pk2, _hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in

    let transfer2 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 20};
      }
    in
    let ol = [transfer1; transfer2] in
    let signatures = sign_ops [sk1; sk1] ol in

    let batch : transactions_batch =
      batch
        [ol]
        signatures
        (Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 500000)
    in

    let* (_, _, ctxt) = Apply.apply_transactions_batch ctxt batch in

    let* (res, ctxt) = Counter.get ctxt pk1 in
    Alcotest.check z_testable "counter pk1" (Z.of_int 1) res ;

    let* (res, ctxt) = Counter.get ctxt pk2 in
    Alcotest.check z_testable "counter pk2" Z.zero res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk1 in
    Alcotest.check z_testable "remaining balance h1" (Z.of_int 50) res ;

    let* (res, ctxt) = Ticket_ledger.get ctxt hash1 pk2 in
    Alcotest.check z_testable "transfered balance h1" (Z.of_int 50) res ;

    ignore ctxt ;

    return ()

  let test_tx_rollup_apply_correct_batch_wrong_signature () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 20};
      }
    in
    let ol2 = [transfer2] in
    let signatures2 = sign_ops [sk2] ol2 in

    let batch : transactions_batch =
      batch
        [ol1; ol2]
        (signatures1 @ signatures2)
        (Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 500000)
    in

    let* () =
      catch
        (Apply.apply_transactions_batch
           ctxt
           {batch with aggregated_signatures = Bytes.empty})
        (fun _ -> assert false)
        (function Bad_aggregated_signature -> return () | _ -> assert false)
    in

    return ()

  let test_tx_rollup_apply_batch_not_enough_gas () =
    let open Syntax in
    with_initial_setup [[(ticket1, Z.of_int 100)]; [(ticket2, Z.of_int 50)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk2; ticket_hash = hash1; amount = Z.of_int 30};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = Z.zero;
        content =
          Transfer
            {destination = pk1; ticket_hash = hash2; amount = Z.of_int 20};
      }
    in
    let ol2 = [transfer2] in
    let signatures2 = sign_ops [sk2] ol2 in

    (* We provide enough gas to execute only one [transaction]. *)
    let allocated_gas =
      Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 400
    in

    let batch : transactions_batch =
      batch [ol1; ol2] (signatures1 @ signatures2) allocated_gas
    in

    let* () =
      catch
        (Apply.apply_transactions_batch ctxt batch)
        (fun _ -> assert false)
        (function
          | Tx_rollup_l2_context.Not_enough_gas -> return () | _ -> assert false)
    in

    return ()

  let tests =
    let open Tezos_base_test_helpers in
    [
      Tztest.tztest (storage_name ^ ": basic storage tests") `Quick
      @@ to_lwt test_tx_rollup_storage;
      Tztest.tztest (storage_name ^ ": apply deposit") `Quick
      @@ to_lwt test_tx_rollup_apply_deposit;
      Tztest.tztest
        (storage_name ^ ": test rollup apply single operation")
        `Quick
      @@ to_lwt test_tx_rollup_apply_single_operation;
      Tztest.tztest (storage_name ^ ": test rollup apply correct trade") `Quick
      @@ to_lwt test_tx_rollup_apply_correct_trade;
      Tztest.tztest
        (storage_name ^ ": test rollup apply with low balance")
        `Quick
      @@ to_lwt test_tx_rollup_apply_low_balance;
      Tztest.tztest (storage_name ^ ": test rollup apply wrong counter") `Quick
      @@ to_lwt test_tx_rollup_apply_wrong_counter;
      Tztest.tztest (storage_name ^ ": test rollup apply correct batch") `Quick
      @@ to_lwt test_tx_rollup_apply_correct_batch;
      Tztest.tztest
        (storage_name
       ^ ": test rollup apply correct batch with several operations")
        `Quick
      @@ to_lwt test_tx_rollup_apply_correct_batch_with_several_transactions;
      Tztest.tztest
        (storage_name
       ^ ": test rollup apply correct batch with several operations from the \
          same account")
        `Quick
      @@ to_lwt
           test_tx_rollup_apply_correct_batch_with_several_transactions_from_same_account;
      Tztest.tztest
        (storage_name ^ ": test rollup apply batch with wrong signature")
        `Quick
      @@ to_lwt test_tx_rollup_apply_correct_batch_wrong_signature;
      Tztest.tztest
        (storage_name ^ ": test rollup apply batch with not enough gas")
        `Quick
      @@ to_lwt test_tx_rollup_apply_batch_not_enough_gas;
    ]
end

module Map_test_suite = L2_test_suite (Map_context)

let tests =
  [
    Tztest.tztest
      "check feature flag is disabled"
      `Quick
      test_disable_feature_flag;
    Tztest.tztest "check tx rollup origination and burn" `Quick test_origination;
    Tztest.tztest
      "check two originated tx rollup in one operation have different address"
      `Quick
      test_two_origination;
  ]
  @ Map_test_suite.tests
