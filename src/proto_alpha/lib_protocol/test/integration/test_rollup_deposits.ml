(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>           *)
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
    Component:  Protocol (token)
    Invocation: dune exec \
                src/proto_alpha/lib_protocol/test/integration/main.exe \
                -- test "^rollup deposits"
    Subject:    Frozen rollup deposits.
*)

open Protocol
open Alpha_context
open Test_tez

let ( >>>=? ) x f = x >|= Environment.wrap_tzresult >>=? f

let big_random_amount () =
  match Tez.of_mutez (Int64.add 1L (Random.int64 10_000L)) with
  | None -> assert false
  | Some x -> x

let small_random_amount () =
  match Tez.of_mutez (Int64.add 1L (Random.int64 1_000L)) with
  | None -> assert false
  | Some x -> x

let very_small_random_amount () =
  match Tez.of_mutez (Int64.add 1L (Random.int64 100L)) with
  | None -> assert false
  | Some x -> x

let nonce_zero =
  Origination_nonce.Internal_for_tests.initial Operation_hash.zero

let mk_tx_rollup ?(nonce = nonce_zero) () =
  ( Tx_rollup.Internal_for_tests.originated_tx_rollup nonce,
    Origination_nonce.Internal_for_tests.incr nonce )

(** Creates a context with a single account. Returns the context and the public
    key hash of the account. *)
let create_context () =
  let accounts = Account.generate_accounts 1 in
  Block.alpha_context accounts >>=? fun ctxt ->
  match accounts with
  | [({pkh; _}, _)] -> return (ctxt, pkh)
  | _ -> (* Exactly one account has been generated. *) assert false

(** Creates a context, a user contract, and a delegate.
    Returns the context, the user contract, the user account, and the
    delegate's pkh. *)
let init_test ~user_is_delegate =
  create_context () >>=? fun (ctxt, _) ->
  let (delegate, delegate_pk, _) = Signature.generate_key () in
  let delegate_contract = Contract.implicit_contract delegate in
  let delegate_account = `Contract (Contract.implicit_contract delegate) in
  let user_contract =
    if user_is_delegate then delegate_contract
    else
      let (user, _, _) = Signature.generate_key () in
      Contract.implicit_contract user
  in
  let user_account = `Contract user_contract in
  (* Allocate contracts for user and delegate. *)
  let user_balance = big_random_amount () in
  Token.transfer ctxt `Minted user_account user_balance >>>=? fun (ctxt, _) ->
  let delegate_balance = big_random_amount () in
  Token.transfer ctxt `Minted delegate_account delegate_balance
  >>>=? fun (ctxt, _) ->
  (* Configure delegate, as a delegate by self-delegation, for which
     revealing its manager key is a prerequisite. *)
  Contract.reveal_manager_key ctxt delegate delegate_pk >>>=? fun ctxt ->
  Delegate.set ctxt delegate_contract (Some delegate) >>>=? fun ctxt ->
  return (ctxt, user_contract, user_account, delegate)

(** Tested scenario :
    1. user contract delegates to 'delegate',
    2. freeze a rollup deposit,
    3. check that staking balance of delegate has not changed,
    4. remove delegation,
    5. check staking balance decreased accordingly,
    6. unfreeze part of the rollup deposit,
    7. check that staking balance is unchanged,
    8. check that user's balance decreased accordingly. *)
let test_delegate_then_freeze_tx_rollup_deposit () =
  init_test ~user_is_delegate:false
  >>=? fun (ctxt, user_contract, user_account, delegate) ->
  (* Fetch user's initial balance before freeze. *)
  Token.balance ctxt user_account >>>=? fun user_balance ->
  (* Let user delegate to "delegate". *)
  Delegate.set ctxt user_contract (Some delegate) >>>=? fun ctxt ->
  (* Fetch staking balance after delegation and before freeze. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance ->
  (* Freeze a tx-rollup deposit. *)
  let (tx_rollup, _) = mk_tx_rollup () in
  let bond_id = Rollup_bond_id.Tx_rollup_bond_id tx_rollup in
  let deposit_amount = small_random_amount () in
  let deposit_account = `Frozen_rollup_bonds (user_contract, bond_id) in
  Token.transfer ctxt user_account deposit_account deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Fetch staking balance after freeze. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance' ->
  (* Ensure staking balance did not change. *)
  Assert.equal_tez ~loc:__LOC__ staking_balance' staking_balance >>=? fun () ->
  (* Remove delegation. *)
  Delegate.set ctxt user_contract None >>>=? fun ctxt ->
  (* Fetch staking balance after delegation removal. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance'' ->
  (* Ensure staking balance decreased by user's initial balance. *)
  Assert.equal_tez
    ~loc:__LOC__
    staking_balance''
    (staking_balance' -! user_balance)
  >>=? fun () ->
  (* Unfreeze the deposit. *)
  Token.transfer ctxt deposit_account user_account deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Fetch staking balance of delegate. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance''' ->
  (* Ensure that staking balance is unchanged. *)
  Assert.equal_tez ~loc:__LOC__ staking_balance''' staking_balance''
  >>=? fun () ->
  (* Fetch user's balance again. *)
  Token.balance ctxt user_account >>>=? fun user_balance' ->
  (* Ensure user's balance decreased. *)
  Assert.equal_tez ~loc:__LOC__ user_balance' user_balance

(** Tested scenario:
    1. freeze a rollup deposit,
    2. user contract delegate to 'delegate',
    3. check that staking balance of delegate has increased as expected,
    4. unfreeze part of the rollup deposit,
    5. check that staking balance has not changed,
    6. remove delegation,
    7. check that staking balance has decreased as expected,
    8. check the the user's balance decreased accordingly. *)
let test_freeze_tx_rollup_deposit_then_delegate () =
  init_test ~user_is_delegate:false
  >>=? fun (ctxt, user_contract, user_account, delegate) ->
  (* Fetch user's initial balance before freeze. *)
  Token.balance ctxt user_account >>>=? fun user_balance ->
  (* Freeze a tx-rollup deposit. *)
  let (tx_rollup, _) = mk_tx_rollup () in
  let bond_id = Rollup_bond_id.Tx_rollup_bond_id tx_rollup in
  let deposit_amount = small_random_amount () in
  let deposit_account = `Frozen_rollup_bonds (user_contract, bond_id) in
  Token.transfer ctxt user_account deposit_account deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Here, user balance has decreased.
     Now, fetch staking balance before delegation and after freeze. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance ->
  (* Let user delegate to "delegate". *)
  Delegate.set ctxt user_contract (Some delegate) >>>=? fun ctxt ->
  (* Fetch staking balance after delegation. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance' ->
  (* ensure staking balance increased by the user's balance. *)
  Assert.equal_tez
    ~loc:__LOC__
    staking_balance'
    (user_balance +! staking_balance)
  >>=? fun () ->
  (* Unfreeze the deposit. *)
  Token.transfer ctxt deposit_account user_account deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Fetch staking balance after unfreeze. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance'' ->
  (* Ensure that staking balance is unchanged. *)
  Assert.equal_tez ~loc:__LOC__ staking_balance'' staking_balance'
  >>=? fun () ->
  (* Remove delegation. *)
  Delegate.set ctxt user_contract None >>>=? fun ctxt ->
  (* Fetch staking balance. *)
  Delegate.staking_balance ctxt delegate >>>=? fun staking_balance''' ->
  (* Check that staking balance has decreased by the user's initial balance. *)
  Assert.equal_tez
    ~loc:__LOC__
    staking_balance'''
    (staking_balance'' -! user_balance)
  >>=? fun () ->
  (* Fetch user's balance. *)
  Token.balance ctxt user_account >>>=? fun user_balance' ->
  (* Ensure user's balance decreased. *)
  Assert.equal_tez ~loc:__LOC__ user_balance' user_balance

(** Tested scenario:
    1. freeze a rollup deposit (with deposit amount = balance),
    2. check that the user contract is still allocated,
    3. punish the user contract,
    4. check that the user contract is unallocated, except if it's a delegate. *)
let test_allocated_when_frozen_deposits_exists ~user_is_delegate () =
  init_test ~user_is_delegate
  >>=? fun (ctxt, user_contract, user_account, _delegate) ->
  (* Fetch user's initial balance before freeze. *)
  Token.balance ctxt user_account >>>=? fun user_balance ->
  Assert.equal_bool ~loc:__LOC__ Tez.(user_balance > zero) true >>=? fun () ->
  (* Freeze a tx-rollup deposit. *)
  let (tx_rollup, _) = mk_tx_rollup () in
  let bond_id = Rollup_bond_id.Tx_rollup_bond_id tx_rollup in
  let deposit_amount = user_balance in
  let deposit_account = `Frozen_rollup_bonds (user_contract, bond_id) in
  Token.transfer ctxt user_account deposit_account deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Check that user contract is still allocated, despite a null balance. *)
  Token.balance ctxt user_account >>>=? fun balance ->
  Assert.equal_tez ~loc:__LOC__ balance Tez.zero >>=? fun () ->
  Token.allocated ctxt user_account >>>=? fun user_allocated ->
  Token.allocated ctxt deposit_account >>>=? fun dep_allocated ->
  Assert.equal_bool ~loc:__LOC__ (user_allocated && dep_allocated) true
  >>=? fun () ->
  (* Punish the user contract. *)
  Token.transfer ctxt deposit_account `Burned deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Check that user and deposit accounts have been unallocated. *)
  Token.allocated ctxt user_account >>>=? fun user_allocated ->
  Token.allocated ctxt deposit_account >>>=? fun dep_allocated ->
  if user_is_delegate then
    Assert.equal_bool ~loc:__LOC__ (user_allocated && not dep_allocated) true
  else Assert.equal_bool ~loc:__LOC__ (user_allocated || dep_allocated) false

(** Tested scenario:
    1. freeze two rollup deposits for the user contract,
    2. check that the stake of the user contract is balance + two deposits,
    3. punish for one of the deposits,
    4. check that the stake of the user contract balance + deposit,
    5. punish for the other deposit,
    6. check that the stake of the user contract is equal to balance. *)
let test_total_stake ~user_is_delegate () =
  init_test ~user_is_delegate
  >>=? fun (ctxt, user_contract, user_account, _delegate) ->
  (* Fetch user's initial balance before freeze. *)
  Token.balance ctxt user_account >>>=? fun user_balance ->
  Assert.equal_bool ~loc:__LOC__ Tez.(user_balance > zero) true >>=? fun () ->
  (* Freeze 2 tx-rollup deposits. *)
  let (tx_rollup, nonce) = mk_tx_rollup () in
  let bond_id1 = Rollup_bond_id.Tx_rollup_bond_id tx_rollup in
  let (tx_rollup, _) = mk_tx_rollup ~nonce () in
  let bond_id2 = Rollup_bond_id.Tx_rollup_bond_id tx_rollup in
  let deposit_amount = small_random_amount () in
  let deposit_account1 = `Frozen_rollup_bonds (user_contract, bond_id1) in
  Token.transfer ctxt user_account deposit_account1 deposit_amount
  >>>=? fun (ctxt, _) ->
  let deposit_account2 = `Frozen_rollup_bonds (user_contract, bond_id2) in
  Token.transfer ctxt user_account deposit_account2 deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Check that the stake of user contract is balance + two deposits. *)
  Contract.stake ctxt user_contract >>>=? fun stake ->
  Token.balance ctxt user_account >>>=? fun balance ->
  Assert.equal_tez ~loc:__LOC__ (stake -! balance) (deposit_amount *! 2L)
  >>=? fun () ->
  (* Punish for one deposit. *)
  Token.transfer ctxt deposit_account2 `Burned deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Check that stake of contract is balance + deposit. *)
  Contract.stake ctxt user_contract >>>=? fun stake ->
  Assert.equal_tez ~loc:__LOC__ (stake -! balance) deposit_amount >>=? fun () ->
  (* Punish for the other deposit. *)
  Token.transfer ctxt deposit_account1 `Burned deposit_amount
  >>>=? fun (ctxt, _) ->
  (* Check that stake of contract is equal to balance. *)
  Contract.stake ctxt user_contract >>>=? fun stake ->
  Assert.equal_tez ~loc:__LOC__ stake balance

let tests =
  Tztest.
    [
      tztest
        "rollup deposits - delegate then freeze"
        `Quick
        test_delegate_then_freeze_tx_rollup_deposit;
      tztest
        "rollup deposits - freeze then delegate"
        `Quick
        test_freeze_tx_rollup_deposit_then_delegate;
      tztest
        "rollup deposits - contract remains allocated, user is not a delegate"
        `Quick
        (test_allocated_when_frozen_deposits_exists ~user_is_delegate:false);
      tztest
        "rollup deposits - contract remains allocated, user is a delegate"
        `Quick
        (test_allocated_when_frozen_deposits_exists ~user_is_delegate:true);
      tztest
        "rollup deposits - total stake, user is not a delegate"
        `Quick
        (test_total_stake ~user_is_delegate:false);
      tztest
        "rollup deposits - total stake, user is a delegate"
        `Quick
        (test_total_stake ~user_is_delegate:true);
    ]
