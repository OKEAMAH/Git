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

let lot_of_gas =
  Protocol.Alpha_context.Gas.Arith.integral_of_int_exn 1_000_000_000

let check_tx_rollup_exists ctxt tx_rollup =
  Context.Tx_rollup.state ctxt tx_rollup >|=? Option.is_some

(** [test_disable_feature_flag] try to originate a tx rollup with the feature
    flag is deactivated and check it fails *)
let test_disable_feature_flag () =
  Context.init 1 >>=? fun (b, contracts) ->
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

(** [test_origination] originate a tx rollup and check that it burns the
    correct amount of the origination source contract. *)
let test_origination () =
  Context.init ~tx_rollup_enable:true 1 >>=? fun (b, contracts) ->
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

(** [test_two_origination] originate two tx rollups in the same operation and
    check that each has a different address. *)
let test_two_origination () =
  Context.init ~tx_rollup_enable:true 1 >>=? fun (b, contracts) ->
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

  let check_counter ctxt name description account value =
    let open Syntax in
    let* (res, _) = Counter.get ctxt account in
    Alcotest.(
      check
        int64
        (Format.sprintf "counter for %s (%s)" name description)
        res
        value) ;
    return ()

  let check_balance ctxt name_account name_ticket description account
      ticket_hash value =
    let open Syntax in
    let* (res, _) = Ticket_ledger.get ctxt ticket_hash account in
    Alcotest.(
      check
        int64
        (Format.sprintf
           "balance for %s of %s (%s)"
           name_account
           name_ticket
           description)
        res
        value) ;
    return ()

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
    let amount = 100L in
    (* 1. test [Counter] *)
    let* () = check_counter ctxt "account_pk" "initial" account_pk 0L in
    let* ctxt = Counter.set ctxt account_pk 1L in
    let* () = check_counter ctxt "account_pk" "after set" account_pk 1L in
    (* 2. test [Ticket_ledger] *)
    let* ctxt = Ticket_ledger.set ctxt ticket_hash account_pk amount in
    let* () =
      check_balance
        ctxt
        "account_pk"
        "ticket1"
        "after set"
        account_pk
        ticket_hash
        amount
    in

    return ()

  (** Check a valid deposit has the expected effect on the storage. *)
  let test_tx_rollup_apply_deposit () =
    let open Syntax in
    with_initial_setup [[]] @@ fun ctxt accounts ->
    let (_, pk1, _) = nth_exn accounts 0 in
    let ticket_hash = ticket1 in
    let deposit = {destination = pk1; ticket_hash; amount = 50L} in
    let* ctxt = Apply.apply_deposit ctxt deposit in

    let* () =
      check_balance ctxt "pk1" "ticket1" "after apply" pk1 ticket_hash 50L
    in

    return ()

  (** Check a valid transfer has the expected effect on the
      storage. *)
  let test_tx_rollup_apply_single_operation () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; []] @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let (_, account2_pk, _) = nth_exn accounts 1 in
    let ticket_hash = nth_exn hashes1 0 in

    let content1 : operation_content =
      Transfer {destination = account2_pk; ticket_hash; amount = 32L}
    in
    let transfer1 : operation =
      {signer = account1_pk; counter = 0L; content = content1}
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1]
    in

    assert (status = Success) ;

    let* () =
      check_counter ctxt "account1_pk" "after operation" account1_pk 1L
    in

    let* () =
      check_balance
        ctxt
        "account1_pk"
        "ticket1"
        "after operation"
        account1_pk
        ticket_hash
        68L
    in

    return ()

  (** Check a transfer to self leaves the balance unchanged. *)
  let test_tx_rollup_apply_self_transfer () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]] @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let ticket_hash = nth_exn hashes1 0 in

    let content1 : operation_content =
      Transfer {destination = account1_pk; ticket_hash; amount = 30L}
    in
    let transfer1 : operation =
      {signer = account1_pk; counter = 0L; content = content1}
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1]
    in

    assert (status = Success) ;

    let* () =
      check_counter ctxt "account1_pk" "after operation" account1_pk 1L
    in

    let* () =
      check_balance
        ctxt
        "account1_pk"
        "ticket1"
        "after operation"
        account1_pk
        ticket_hash
        100L
    in

    return ()

  (** Check a transfer with a negative amount raises an error. *)
  let test_tx_rollup_apply_negative_transfer () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]] @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let ticket_hash = nth_exn hashes1 0 in

    let content1 : operation_content =
      Transfer {destination = account1_pk; ticket_hash; amount = -30L}
    in
    let transfer1 : operation =
      {signer = account1_pk; counter = 0L; content = content1}
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1]
    in

    assert (status = Failure {index = 0; reason = Invalid_transfer}) ;

    let* () =
      check_counter ctxt "account1_pk" "after operation" account1_pk 1L
    in

    let* () =
      check_balance
        ctxt
        "account1_pk"
        "ticket1"
        "after operation"
        account1_pk
        ticket_hash
        100L
    in

    return ()

  (** Check a transfer triggering an integer overflow raises an
      error. *)
  let test_tx_rollup_apply_overflow_transfer () =
    let open Syntax in
    with_initial_setup [[(ticket1, 1L)]; [(ticket1, Int64.max_int)]]
    @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let (_, account2_pk, _) = nth_exn accounts 1 in
    let ticket_hash = nth_exn hashes1 0 in

    let content1 : operation_content =
      Transfer {destination = account2_pk; ticket_hash; amount = 1L}
    in
    let transfer1 : operation =
      {signer = account1_pk; counter = 0L; content = content1}
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1]
    in

    assert (
      status
      = Failure
          {
            index = 0;
            reason = Balance_overflow {account = account2_pk; ticket_hash};
          }) ;

    let* () =
      check_counter ctxt "account1_pk" "after operation" account1_pk 1L
    in

    let* () =
      check_balance
        ctxt
        "account1_pk"
        "ticket1"
        "after operation"
        account1_pk
        ticket_hash
        1L
    in

    let* () =
      check_balance
        ctxt
        "account1_pk"
        "ticket1"
        "after operation"
        account2_pk
        ticket_hash
        Int64.max_int
    in

    return ()

  (** Check a deposit triggering an integer overflow raises an
      error. *)
  let test_tx_rollup_apply_overflow_deposit () =
    let open Syntax in
    with_initial_setup [[(ticket1, Int64.max_int)]] @@ fun ctxt accounts ->
    let (_, account1_pk, hashes1) = nth_exn accounts 0 in
    let ticket_hash = nth_exn hashes1 0 in

    catch
      (Apply.apply_deposit
         ctxt
         {destination = account1_pk; ticket_hash; amount = 1L})
      (fun _ -> assert false)
      (function Balance_overflow _ -> return () | _ -> assert false)

  (** Check a transaction with two valid transfers has the expected
      effect on the storage. *)
  let test_tx_rollup_apply_correct_trade () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 15L};
      }
    in

    let* (status, ctxt) =
      Apply.Internal_for_tests.apply_transaction ctxt [transfer1; transfer2]
    in

    assert (status = Success) ;

    let* () = check_counter ctxt "pk1" "after operation" pk1 1L in
    let* () = check_counter ctxt "pk2" "after operation" pk2 1L in

    let* () =
      check_balance ctxt "pk1" "ticket1" "after operation" pk1 hash1 70L
    in
    let* () =
      check_balance ctxt "pk1" "ticket2" "after operation" pk1 hash2 15L
    in
    let* () =
      check_balance ctxt "pk2" "ticket1" "after operation" pk2 hash1 30L
    in
    let* () =
      check_balance ctxt "pk2" "ticket2" "after operation" pk2 hash2 35L
    in

    return ()

  (** Check a transaction with a valid transfer and an invalid one has
      the expected effect on the storage. The balances should be left
      unchanged, but the counters of the related accounts are
      incremented. *)
  let test_tx_rollup_apply_wrong_counter () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        (* wrong counter *)
        counter = 1L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 20L};
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
              Counter_mismatch {account = pk2; requested = 1L; actual = 0L};
          }) ;

    let* () =
      check_counter ctxt "pk1" "should be unchanged after operation" pk1 0L
    in
    let* () =
      check_counter ctxt "pk2" "should be unchanged after operation" pk2 0L
    in

    let* () =
      check_balance
        ctxt
        "pk1"
        "ticket1"
        "should be unchanged after operation"
        pk1
        hash1
        100L
    in
    let* () =
      check_balance
        ctxt
        "pk1"
        "ticket2"
        "should be unchanged after operation"
        pk1
        hash2
        0L
    in
    let* () =
      check_balance
        ctxt
        "pk2"
        "ticket1"
        "should be unchanged after operation"
        pk2
        hash1
        0L
    in
    let* () =
      check_balance
        ctxt
        "pk2"
        "ticket2"
        "should be unchanged after operation"
        pk2
        hash2
        50L
    in

    return ()

  (** Check a transfer with an amount too high raises an error. *)
  let test_tx_rollup_apply_low_balance () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (_, pk1, hashes1) = nth_exn accounts 0 in
    let (_, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 55L};
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
                  requested = 55L;
                  actual = 50L;
                };
          }) ;

    let* () = check_counter ctxt "pk1" "after operation" pk1 1L in
    let* () = check_counter ctxt "pk2" "after operation" pk2 1L in

    let* () =
      check_balance
        ctxt
        "pk1"
        "ticket1"
        "should be unchanged after operation"
        pk1
        hash1
        100L
    in
    let* () =
      check_balance
        ctxt
        "pk1"
        "ticket2"
        "should be unchanged after operation"
        pk1
        hash2
        0L
    in
    let* () =
      check_balance
        ctxt
        "pk2"
        "ticket1"
        "should be unchanged after operation"
        pk2
        hash1
        0L
    in
    let* () =
      check_balance
        ctxt
        "pk2"
        "ticket2"
        "should be unchanged after operation"
        pk2
        hash2
        50L
    in

    return ()

  (** Check a valid batch has the expected effects on the storage. *)
  let test_tx_rollup_apply_correct_batch () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 20L};
      }
    in

    let transaction = [transfer1; transfer2] in
    let signature = sign_ops [sk1; sk2] transaction in

    let batch : transactions_batch = batch [transaction] signature lot_of_gas in

    let* (_, _, ctxt) = Apply.apply_transactions_batch ctxt batch in

    let* () = check_counter ctxt "pk1" "after operation" pk1 1L in
    let* () = check_counter ctxt "pk2" "after operation" pk2 1L in

    let* () =
      check_balance ctxt "pk1" "ticket1" "after operation" pk1 hash1 70L
    in
    let* () =
      check_balance ctxt "pk1" "ticket2" "after operation" pk1 hash2 20L
    in
    let* () =
      check_balance ctxt "pk2" "ticket1" "after operation" pk2 hash1 30L
    in
    let* () =
      check_balance ctxt "pk2" "ticket2" "after operation" pk2 hash2 30L
    in

    return ()

  (** Check a valid batch with several transactions has the expected
      effects on the storage. *)
  let test_tx_rollup_apply_correct_batch_with_several_transactions () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 20L};
      }
    in
    let ol2 = [transfer2] in
    let signatures2 = sign_ops [sk2] ol2 in

    let batch : transactions_batch =
      batch [ol1; ol2] (signatures1 @ signatures2) lot_of_gas
    in

    let* (status, _, ctxt) = Apply.apply_transactions_batch ctxt batch in

    (match status with [(_, Success); (_, Success)] -> () | _ -> assert false) ;

    let* () = check_counter ctxt "pk1" "after operation" pk1 1L in
    let* () = check_counter ctxt "pk2" "after operation" pk2 1L in

    let* () =
      check_balance ctxt "pk1" "ticket1" "after operation" pk1 hash1 70L
    in
    let* () =
      check_balance ctxt "pk1" "ticket2" "after operation" pk1 hash2 20L
    in
    let* () =
      check_balance ctxt "pk2" "ticket1" "after operation" pk2 hash1 30L
    in
    let* () =
      check_balance ctxt "pk2" "ticket2" "after operation" pk2 hash2 30L
    in

    return ()

  (** Check a valid batch with several transactions from the same
      accounts has the expected effects on the storage. In particular,
      the counter should be updated only once per transaction. *)
  let test_tx_rollup_apply_correct_batch_with_several_transactions_from_same_account
      () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (_sk2, pk2, _hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in

    let transfer2 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 20L};
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

    let* () = check_counter ctxt "pk1" "after operation" pk1 1L in
    let* () = check_counter ctxt "pk2" "after operation" pk2 0L in

    let* () =
      check_balance ctxt "pk1" "ticket1" "remaining balance" pk1 hash1 50L
    in
    let* () =
      check_balance ctxt "pk2" "ticket1" "transfered balance" pk2 hash1 50L
    in

    return ()

  (** Check the submission of a batch with an invalid signature raises
      an error. *)
  let test_tx_rollup_apply_correct_batch_wrong_signature () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 20L};
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

  (** Check the submission of a batch with an incorrect allocated
      batch raises an error. *)
  let test_tx_rollup_apply_batch_not_enough_gas () =
    let open Syntax in
    with_initial_setup [[(ticket1, 100L)]; [(ticket2, 50L)]]
    @@ fun ctxt accounts ->
    let (sk1, pk1, hashes1) = nth_exn accounts 0 in
    let (sk2, pk2, hashes2) = nth_exn accounts 1 in
    let hash1 = nth_exn hashes1 0 in
    let hash2 = nth_exn hashes2 0 in

    let transfer1 : operation =
      {
        signer = pk1;
        counter = 0L;
        content =
          Transfer {destination = pk2; ticket_hash = hash1; amount = 30L};
      }
    in
    let ol1 = [transfer1] in
    let signatures1 = sign_ops [sk1] ol1 in

    let transfer2 : operation =
      {
        signer = pk2;
        counter = 0L;
        content =
          Transfer {destination = pk1; ticket_hash = hash2; amount = 20L};
      }
    in
    let ol2 = [transfer2] in
    let signatures2 = sign_ops [sk2] ol2 in

    (* First, we run the batch one time with enough gas, to get the
       necessary amount in return. *)
    let batch1 : transactions_batch =
      batch [ol1; ol2] (signatures1 @ signatures2) lot_of_gas
    in

    let* (_, necessary_gas, _) = Apply.apply_transactions_batch ctxt batch1 in

    (* Then, we replay, but with less gas *)
    let allocated_gas =
      Saturation_repr.sub necessary_gas (Saturation_repr.safe_int 100)
    in

    let batch2 : transactions_batch =
      batch [ol1; ol2] (signatures1 @ signatures2) allocated_gas
    in

    let* () =
      catch
        (Apply.apply_transactions_batch ctxt batch2)
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
      Tztest.tztest (storage_name ^ ": test rollup apply self transfer") `Quick
      @@ to_lwt test_tx_rollup_apply_self_transfer;
      Tztest.tztest
        (storage_name ^ ": test rollup apply negative transfer")
        `Quick
      @@ to_lwt test_tx_rollup_apply_negative_transfer;
      Tztest.tztest
        (storage_name ^ ": test rollup apply overflow transfer")
        `Quick
      @@ to_lwt test_tx_rollup_apply_overflow_transfer;
      Tztest.tztest
        (storage_name ^ ": test rollup apply overflow deposit")
        `Quick
      @@ to_lwt test_tx_rollup_apply_overflow_deposit;
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
