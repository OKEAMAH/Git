(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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
    Component:  Protocol (delegate_storage)
    Invocation: dune exec \
                src/proto_alpha/lib_protocol/test/integration/consensus/main.exe \
                -- test "^consensus key$"
    Subject:    consistency of the [Drain_delegate] operation
 *)

open Protocol
open Alpha_context

let constants =
  {
    Default_parameters.constants_test with
    endorsing_reward_per_slot = Tez.zero;
    baking_reward_bonus_per_slot = Tez.zero;
    baking_reward_fixed_portion = Tez.zero;
    consensus_threshold = 0;
    origination_size = 0;
  }

(** Checks that staking balance is sum of delegators' stake. *)
let check_delegate_staking_invariant blk delegate_pkh =
  Context.Delegate.staking_balance (B blk) delegate_pkh
  >>=? fun delegate_staking_balance ->
  Context.Delegate.full_balance (B blk) delegate_pkh
  >>=? fun self_staking_balance ->
  Context.Delegate.info (B blk) delegate_pkh >>=? fun delegate_info ->
  let delegate_contract = Contract.Implicit delegate_pkh in
  let delegated_contracts =
    List.filter
      (fun c -> Contract.(c <> delegate_contract))
      delegate_info.delegated_contracts
  in
  List.fold_left_es
    (fun total pkh ->
      Context.Contract.balance_and_frozen_bonds (B blk) pkh
      >>=? fun staking_balance ->
      Lwt.return Tez.(total +? staking_balance) >|= Environment.wrap_tzresult)
    self_staking_balance
    delegated_contracts
  >>=? fun delegators_stake ->
  Assert.equal_tez ~loc:__LOC__ delegate_staking_balance delegators_stake

let update_consensus_key blk delegate public_key =
  let nb_delay_cycles = constants.preserved_cycles + 1 in
  Op.update_consensus_key (B blk) (Contract.Implicit delegate) public_key
  >>=? fun update_ck ->
  Block.bake ~operation:update_ck blk >>=? fun blk' ->
  Block.bake_until_n_cycle_end nb_delay_cycles blk'

let delegate_stake blk source delegate =
  Op.delegation (B blk) (Contract.Implicit source) (Some delegate)
  >>=? fun delegation -> Block.bake ~operation:delegation blk

let transfer_tokens blk source destination amount =
  Op.transaction
    ~force_reveal:true
    (B blk)
    (Contract.Implicit source)
    (Contract.Implicit destination)
    amount
  >>=? fun transfer_op -> Block.bake ~operation:transfer_op blk

let reveal_manager_key blk pk =
  Op.revelation (B blk) pk >>=? fun reveal_op ->
  Block.bake ~operation:reveal_op blk

let drain_delegate ~policy blk ~consensus_key ~delegate ~destination
    expected_final_balance =
  Op.drain_delegate (B blk) ~consensus_key ~delegate ~destination
  >>=? fun drain_del ->
  Block.bake ~policy ~operation:drain_del blk >>=? fun blk' ->
  check_delegate_staking_invariant blk' delegate >>=? fun () ->
  Context.Contract.balance (B blk') (Contract.Implicit delegate)
  >>=? fun final_balance ->
  Assert.equal_tez ~loc:__LOC__ final_balance expected_final_balance

let get_first_2_accounts_contracts (a1, a2) =
  ((a1, Context.Contract.pkh a1), (a2, Context.Contract.pkh a2))

let test_drain_delegate ~exclude_ck ~ck_delegates () =
  Context.init_with_constants2 constants >>=? fun (genesis, contracts) ->
  let (_contract1, account1_pkh), (_contract2, account2_pkh) =
    get_first_2_accounts_contracts contracts
  in
  let consensus_account = Account.new_account () in
  let delegate = account1_pkh in
  let consensus_pk = consensus_account.pk in
  let consensus_pkh = consensus_account.pkh in
  transfer_tokens genesis account2_pkh consensus_pkh Tez.one_mutez
  >>=? fun blk ->
  update_consensus_key blk delegate consensus_pk >>=? fun blk' ->
  let policy, expected_final_balance =
    if exclude_ck then (Block.Excluding [consensus_pkh], Tez.zero)
    else (Block.By_account delegate, Tez.one)
  in
  (if ck_delegates then
   reveal_manager_key blk' consensus_pk >>=? fun blk' ->
   delegate_stake blk' consensus_pkh delegate
  else return blk')
  >>=? fun blk' ->
  drain_delegate
    ~policy
    blk'
    ~consensus_key:consensus_pkh
    ~delegate
    ~destination:consensus_pkh
    expected_final_balance

let tests =
  Tztest.
    [
      tztest
        "test drain delegate excluding ck, ck delegates"
        `Quick
        (test_drain_delegate ~exclude_ck:true ~ck_delegates:true);
      tztest
        "test drain delegate excluding ck, ck does not delegates"
        `Quick
        (test_drain_delegate ~exclude_ck:true ~ck_delegates:false);
      tztest
        "test drain delegate with ck, ck delegates"
        `Quick
        (test_drain_delegate ~exclude_ck:false ~ck_delegates:true);
      tztest
        "test drain delegate with ck, ck does not delegates"
        `Quick
        (test_drain_delegate ~exclude_ck:false ~ck_delegates:false);
    ]
