(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Protocol
open Alpha_context
open Test_tez

let tez_testable = Alcotest.testable Tez.pp Tez.( = )

let check_tx_rollup_exists ctxt tx_rollup =
  Context.Tx_rollup.state ctxt tx_rollup >>= function
  | Ok _ -> Lwt.return true
  | Error _ -> Lwt.return false

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
  Context.Tx_rollup.state (I i) tx_rollup >>=? fun _ ->
  cost_per_byte *? Int64.of_int tx_rollup_origination_size
  >>?= fun tx_rollup_origination_burn ->
  Assert.balance_was_debited
    ~loc:__LOC__
    (I i)
    contract
    balance
    tx_rollup_origination_burn

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
  Context.Tx_rollup.state (I i) txo1 >>=? fun _ ->
  Context.Tx_rollup.state (I i) txo2 >>=? fun _ -> return_unit

(** Check that the cost per byte per inbox rate is updated correctly *)
let test_cost_per_byte_update () =
  let cost_per_byte = Tez.of_mutez_exn 250L in
  let test ~tx_rollup_cost_per_byte ~final_size ~hard_limit ~result ~message =
    let result = Tez.of_mutez_exn result in
    let tx_rollup_cost_per_byte = Tez.of_mutez_exn tx_rollup_cost_per_byte in
    let new_cost_per_byte =
      Alpha_context.Tx_rollup.Internal_for_tests.update_cost_per_byte
        ~cost_per_byte
        ~tx_rollup_cost_per_byte
        ~final_size
        ~hard_limit
    in
    Alcotest.check tez_testable message result new_cost_per_byte
  in

  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_100
    ~result:1_000L
    ~message:"Cost per byte should remain constant" ;
  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_000
    ~result:1_051L
    ~message:"Cost per byte should increase" ;
  test
    ~tx_rollup_cost_per_byte:1_000L
    ~final_size:1_000
    ~hard_limit:1_500
    ~result:951L
    ~message:"Cost per byte should decrease" ;

  test
    ~tx_rollup_cost_per_byte:(cost_per_byte |> Tez.to_mutez)
    ~final_size:1_000
    ~hard_limit:1_500
    ~result:(cost_per_byte |> Tez.to_mutez)
    ~message:"Cost per byte never decreased under the [cost_per_byte] constant" ;

  return ()

(** [originate ()] originate a tx_rollup and returns the context, two tz1
    accounts and the tx_rollup address  *)
let originate () =
  (* We don't want reward to interferes with balance computation *)
  Context.init
    ~consensus_threshold:0
    ~tx_rollup_enable:true
    ~endorsing_reward_per_slot:Tez.zero
    ~baking_reward_bonus_per_slot:Tez.zero
    ~baking_reward_fixed_portion:Tez.zero
    2
  >>=? fun (b, contracts) ->
  let account1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0
  in
  let account2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1
  in
  Op.tx_rollup_origination (B b) account1 >>=? fun (operation, tx_rollup) ->
  Block.bake ~operation b >>=? fun b -> return (b, account1, account2, tx_rollup)

(** [test_add_batch] originate a tx rollup and fill one of its inbox
    with an arbitrary batch of data. *)
let test_add_batch () =
  originate () >>=? fun (b, contract, _contract2, tx_rollup) ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  let contents_size = 5 in
  let contents = String.make contents_size 'c' in
  Op.tx_rollup_submit_batch (B b) contract tx_rollup contents
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {content; cumulated_size} ->
  let length = List.length content in
  Alcotest.(check int "Expect an inbox with a single item" 1 length) ;
  Alcotest.(check int "Expect cumulated size" contents_size cumulated_size) ;
  Test_tez.(tx_rollup_cost_per_byte *? Int64.of_int contents_size)
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost

(** [test_add_two_batches] originate a tx rollup and add two arbitrary
    batches to one of its inboxes. Ensure that their order is
    correct. *)
let test_add_two_batches () =
  originate () >>=? fun (b, contract, _contract2, tx_rollup) ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  let contents_size1 = 5 in
  let contents1 = String.make contents_size1 'c' in
  Op.tx_rollup_submit_batch (B b) contract tx_rollup contents1 >>=? fun op1 ->
  Context.Contract.counter (B b) contract >>=? fun counter ->
  let contents_size2 = 6 in
  let contents2 = String.make contents_size2 'd' in
  Op.tx_rollup_submit_batch
    ~counter:Z.(add counter (of_int 1))
    (B b)
    contract
    tx_rollup
    contents2
  >>=? fun op2 ->
  Block.bake ~operations:[op1; op2] b >>=? fun b ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {content; cumulated_size} ->
  let length = List.length content in
  let expected_cumulated_size = contents_size1 + contents_size2 in

  Alcotest.(check int "Expect an inbox with two items" 2 length) ;
  Alcotest.(
    check int "Expect cumulated size" expected_cumulated_size cumulated_size) ;

  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {content; _} ->
  Alcotest.(check int "Expect an inbox with two items" 2 (List.length content)) ;
  let first = List.nth content 0 in
  let _ =
    match first with
    | Some (Batch content) ->
        Alcotest.(
          check
            string
            "Expected first transaction to be first"
            content
            contents1)
    | _ -> Alcotest.fail "Fist element of inbox does not contains a batch"
  in

  let second = List.nth content 1 in
  let _ =
    match second with
    | Some (Batch content) ->
        Alcotest.(
          check
            string
            "Expected second transaction to be second"
            content
            contents2)
    | _ -> Alcotest.fail "Second element of inbox does not contains a batch"
  in
  Test_tez.(
    tx_rollup_cost_per_byte *? (Int64.of_int @@ expected_cumulated_size))
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost
  >>=? fun () -> return ()

(* TODO: Refactor that to submit as many operation as necessary to
   exceed the size limit

   let wrap e = Lwt.return (Environment.wrap_tzresult e)

   (** Try to add a transaction which goes over the gas limit. *)
   let test_too_big () =
   originate () >>=? fun (i, contract, tx_rollup, _cost_per_byte) ->
   Context.Contract.balance (I i) contract >>=? fun balance ->
   let contents = Bytes.make 5 'c' in
   let gas_limit = Gas_limit_repr.Arith.integral_of_int_exn 1_040_000 in
   Op.tx_rollup_submit_batch (I i) contract tx_rollup contents gas_limit
   >>=? fun op ->
   Incremental.add_operation i op >>=? fun i ->
   let contents2 = Bytes.make 6 'd' in
   let gas_limit2 = Gas_limit_repr.Arith.integral_of_int_exn 10_000_000 in
   Op.tx_rollup_submit_batch (I i) contract tx_rollup contents2 gas_limit2
   >>=? fun op ->
   let res = Incremental.add_operation i op in
   let f res =
    Lwt.return
      (match res with
      | Error
          (Environment.Ecoproto_error
             (Tx_rollup_inbox_storage.Tx_rollup_gas_limit_reached _)
          :: _) ->
          Ok i
      | Ok _ | Error _ -> assert false)
   in
   Lwt.bind res f >>=? fun i ->
   Lwt.bind (Tx_rollup_inbox.get (Incremental.alpha_ctxt i) tx_rollup) wrap
   >>=? fun {length; allocated_gas} ->
   Alcotest.(check int32 "Expect an inbox with one item" 1l length) ;
   Alcotest.check
    gas_limit_testable
    "Expect allocated gas"
    gas_limit
    allocated_gas ;
   Context.Tx_rollup.state (I i) tx_rollup >>=? fun {l2_gas_rate} ->
   Test_tez.(l2_gas_rate *? (Int64.of_int @@ Saturation_repr.to_int gas_limit))
   >>?= fun cost ->
   Assert.balance_was_debited ~loc:__LOC__ (I i) contract balance cost
   >>=? fun () ->
   ignore i ;

   return ()
*)

(** Test that block finalization changes gas rates *)
let test_finalization () =
  originate () >>=? fun (b, contract, _contract2, tx_rollup) ->
  Context.get_constants (B b)
  >>=? fun {
             parametric = {cost_per_byte; tx_rollup_hard_size_limit_per_inbox; _};
             _;
           } ->
  Context.Contract.balance (B b) contract >>=? fun balance ->
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = tx_rollup_cost_per_byte} ->
  Alcotest.check
    tez_testable
    "Check initial cost per byte"
    cost_per_byte
    tx_rollup_cost_per_byte ;

  let contents_size = 5 in
  let contents = String.make contents_size 'c' in
  Op.tx_rollup_submit_batch (B b) contract tx_rollup contents
  >>=? fun operation ->
  Block.bake ~operation b >>=? fun b ->
  Test_tez.(tx_rollup_cost_per_byte *? Int64.of_int contents_size)
  >>?= fun cost ->
  Assert.balance_was_debited ~loc:__LOC__ (B b) contract balance cost
  >>=? fun () ->
  Context.Tx_rollup.inbox (B b) tx_rollup >>=? fun {content; cumulated_size} ->
  let length = List.length content in
  (* Check the content of the inbox *)
  Alcotest.(check int "Expect an inbox with a single item" 1 length) ;
  Alcotest.(check int "Expect cumulated_size" contents_size cumulated_size) ;
  (* Check the new cost_per_byte rate *)
  Context.Tx_rollup.state (B b) tx_rollup
  >>=? fun {cost_per_byte = new_tx_rollup_cost_per_byte} ->
  Alcotest.check
    tez_testable
    "Check that cost per byte has changed"
    (Alpha_context.Tx_rollup.Internal_for_tests.update_cost_per_byte
       ~cost_per_byte
       ~tx_rollup_cost_per_byte
       ~final_size:cumulated_size
       ~hard_limit:tx_rollup_hard_size_limit_per_inbox)
    new_tx_rollup_cost_per_byte
  |> return

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
    Tztest.tztest
      "check the function that updates the cost per byte rate per inbox"
      `Quick
      test_cost_per_byte_update;
    Tztest.tztest "add one batch to a rollup" `Quick test_add_batch;
    Tztest.tztest "add two batches to a rollup" `Quick test_add_two_batches;
    (* Tztest.tztest "Try to add a too-big transaction" `Quick test_too_big; *)
    Tztest.tztest "Test finalization" `Quick test_finalization;
  ]
