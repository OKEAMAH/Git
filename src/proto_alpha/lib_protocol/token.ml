(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2021 Nomadic Labs <contact@nomadic-labs.com>           *)
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

(** [remove_contract_stake ctxt contract amount] calls
    [Stake_storage.remove_stake ctxt delegate amount] if [contract] has a
    [delegate]. Otherwise this function does nothing. *)
let remove_contract_stake ctxt contract amount =
  Contract_delegate_storage.find ctxt contract >>=? function
  | None -> return ctxt
  | Some delegate -> Stake_storage.remove_stake ctxt delegate amount

(** [add_contract_stake ctxt contract amount] calls
    [Stake_storage.add_stake ctxt delegate amount] if [contract] has a
    [delegate]. Otherwise this function does nothing. *)
let add_contract_stake ctxt contract amount =
  Contract_delegate_storage.find ctxt contract >>=? function
  | None -> return ctxt
  | Some delegate -> Stake_storage.add_stake ctxt delegate amount

type delegate = [`Contract of Contract_repr.t]

type delegator = [`Contract of Contract_repr.t]

let contract_of_delegator = function `Contract c -> c

let pkh_of_delegate = function `Contract c -> Contract_repr.is_implicit c

let contract_of_pkh pkh = `Contract (Contract_repr.implicit_contract pkh)

let get_contract_delegate ctxt delegator =
  Contract_delegate_storage.find ctxt (contract_of_delegator delegator)
  >>=? function
  | None -> return_none
  | Some pkh -> return_some (contract_of_pkh pkh)

let delegates_to c delegator delegate =
  get_contract_delegate c delegator >>=? fun del ->
  match del with
  | None -> return_false
  | Some (`Contract contract) ->
      return (Contract_repr.equal contract (contract_of_delegator delegate))

let delegates_to_self c delegator = delegates_to c delegator delegator

let init_delegate ctxt delegator (delegate : delegate) =
  let delegator = contract_of_delegator delegator in
  match pkh_of_delegate delegate with
  | Some pkh ->
      Contract_storage.get_balance_and_frozen_bonds ctxt delegator
      >>=? fun balance ->
      Contract_delegate_storage.init ctxt delegator pkh >>=? fun ctxt ->
      Stake_storage.add_stake ctxt pkh balance
  | None -> return ctxt

let update_delegate ctxt delegator delegate =
  let delegator = contract_of_delegator delegator in
  match pkh_of_delegate delegate with
  | Some pkh ->
      Contract_storage.get_balance_and_frozen_bonds ctxt delegator
      >>=? fun balance_and_frozen_bonds ->
      remove_contract_stake ctxt delegator balance_and_frozen_bonds
      >>=? fun ctxt ->
      Contract_delegate_storage.delete ctxt delegator >>=? fun ctxt ->
      Contract_delegate_storage.set ctxt delegator pkh >>=? fun ctxt ->
      add_contract_stake ctxt delegator balance_and_frozen_bonds
  | None -> return ctxt

let delete_delegate ctxt delegator =
  let delegator = contract_of_delegator delegator in
  Contract_storage.get_balance_and_frozen_bonds ctxt delegator
  >>=? fun balance_and_frozen_bonds ->
  remove_contract_stake ctxt delegator balance_and_frozen_bonds >>=? fun ctxt ->
  Contract_delegate_storage.delete ctxt delegator

let staking_balance ctxt = function
  | `Contract del -> (
      match Contract_repr.is_implicit del with
      | Some pkh -> Stake_storage.get_staking_balance ctxt pkh
      | None -> return Tez_repr.zero)

type container =
  [ `Contract of Contract_repr.t
  | `Collected_commitments of Blinded_public_key_hash.t
  | `Frozen_deposits of Signature.Public_key_hash.t
  | `Block_fees
  | `Frozen_bonds of Contract_repr.t * Bond_id_repr.t ]

type infinite_source =
  [ `Invoice
  | `Bootstrap
  | `Initial_commitments
  | `Revelation_rewards
  | `Double_signing_evidence_rewards
  | `Endorsing_rewards
  | `Baking_rewards
  | `Baking_bonuses
  | `Minted
  | `Liquidity_baking_subsidies
  | `Tx_rollup_rejection_rewards ]

type source = [infinite_source | container]

type infinite_sink =
  [ `Storage_fees
  | `Double_signing_punishments
  | `Lost_endorsing_rewards of Signature.Public_key_hash.t * bool * bool
  | `Tx_rollup_rejection_punishments
  | `Burned ]

type sink = [infinite_sink | container]

let allocated ctxt stored =
  match stored with
  | `Contract contract ->
      Contract_storage.allocated ctxt contract >|=? fun allocated ->
      (ctxt, allocated)
  | `Collected_commitments bpkh ->
      Commitment_storage.exists ctxt bpkh >|= ok >|=? fun allocated ->
      (ctxt, allocated)
  | `Frozen_deposits delegate ->
      let contract = Contract_repr.implicit_contract delegate in
      Frozen_deposits_storage.allocated ctxt contract >|= fun allocated ->
      ok (ctxt, allocated)
  | `Block_fees -> return (ctxt, true)
  | `Frozen_bonds (contract, bond_id) ->
      Contract_storage.bond_allocated ctxt contract bond_id

let balance ctxt stored =
  match stored with
  | `Contract contract ->
      Contract_storage.get_balance ctxt contract >|=? fun balance ->
      (ctxt, balance)
  | `Collected_commitments bpkh ->
      Commitment_storage.committed_amount ctxt bpkh >|=? fun balance ->
      (ctxt, balance)
  | `Frozen_deposits delegate ->
      let contract = Contract_repr.implicit_contract delegate in
      Frozen_deposits_storage.find ctxt contract >|=? fun frozen_deposits ->
      let balance =
        match frozen_deposits with
        | None -> Tez_repr.zero
        | Some frozen_deposits -> frozen_deposits.current_amount
      in
      (ctxt, balance)
  | `Block_fees -> return (ctxt, Raw_context.get_collected_fees ctxt)
  | `Frozen_bonds (contract, bond_id) ->
      Contract_storage.find_bond ctxt contract bond_id
      >|=? fun (ctxt, balance_opt) ->
      (ctxt, Option.value ~default:Tez_repr.zero balance_opt)

let credit ctxt dest amount origin =
  let open Receipt_repr in
  (match dest with
  | #infinite_sink as infinite_sink ->
      let sink =
        match infinite_sink with
        | `Storage_fees -> Storage_fees
        | `Double_signing_punishments -> Double_signing_punishments
        | `Lost_endorsing_rewards (d, p, r) -> Lost_endorsing_rewards (d, p, r)
        | `Tx_rollup_rejection_punishments -> Tx_rollup_rejection_punishments
        | `Burned -> Burned
      in
      return (ctxt, sink)
  | #container as container -> (
      match container with
      | `Contract dest ->
          Contract_storage.credit_only_call_from_token ctxt dest amount
          >|=? fun ctxt -> (ctxt, Contract dest)
      | `Collected_commitments bpkh ->
          Commitment_storage.increase_commitment_only_call_from_token
            ctxt
            bpkh
            amount
          >|=? fun ctxt -> (ctxt, Commitments bpkh)
      | `Frozen_deposits delegate as dest ->
          allocated ctxt dest >>=? fun (ctxt, allocated) ->
          (if not allocated then Frozen_deposits_storage.init ctxt delegate
          else return ctxt)
          >>=? fun ctxt ->
          Frozen_deposits_storage.credit_only_call_from_token
            ctxt
            delegate
            amount
          >|=? fun ctxt -> (ctxt, Deposits delegate)
      | `Block_fees ->
          Raw_context.credit_collected_fees_only_call_from_token ctxt amount
          >>?= fun ctxt -> return (ctxt, Block_fees)
      | `Frozen_bonds (contract, bond_id) ->
          Contract_storage.credit_bond_only_call_from_token
            ctxt
            contract
            bond_id
            amount
          >>=? fun ctxt -> return (ctxt, Frozen_bonds (contract, bond_id))))
  >|=? fun (ctxt, balance) -> (ctxt, (balance, Credited amount, origin))

let spend ctxt src amount origin =
  let open Receipt_repr in
  (match src with
  | #infinite_source as infinite_source ->
      let src =
        match infinite_source with
        | `Bootstrap -> Bootstrap
        | `Invoice -> Invoice
        | `Initial_commitments -> Initial_commitments
        | `Minted -> Minted
        | `Liquidity_baking_subsidies -> Liquidity_baking_subsidies
        | `Revelation_rewards -> Nonce_revelation_rewards
        | `Double_signing_evidence_rewards -> Double_signing_evidence_rewards
        | `Endorsing_rewards -> Endorsing_rewards
        | `Baking_rewards -> Baking_rewards
        | `Baking_bonuses -> Baking_bonuses
        | `Tx_rollup_rejection_rewards -> Tx_rollup_rejection_rewards
      in
      return (ctxt, src)
  | #container as container -> (
      match container with
      | `Contract src ->
          Contract_delegate_storage.find ctxt src >>=? fun delegate ->
          Contract_storage.spend_only_call_from_token ctxt src delegate amount
          >>=? fun ctxt ->
          Contract_storage.allocated ctxt src >>=? fun allocated ->
          (if allocated then return ctxt
          else Contract_delegate_storage.delete ctxt src)
          >|=? fun ctxt -> (ctxt, Contract src)
      | `Collected_commitments bpkh ->
          Commitment_storage.decrease_commitment_only_call_from_token
            ctxt
            bpkh
            amount
          >>=? fun ctxt -> return (ctxt, Commitments bpkh)
      | `Frozen_deposits delegate ->
          Frozen_deposits_storage.spend_only_call_from_token
            ctxt
            delegate
            amount
          >|=? fun ctxt -> (ctxt, Deposits delegate)
      | `Block_fees ->
          Raw_context.spend_collected_fees_only_call_from_token ctxt amount
          >>?= fun ctxt -> return (ctxt, Block_fees)
      | `Frozen_bonds (contract, bond_id) ->
          Contract_storage.spend_bond_only_call_from_token
            ctxt
            contract
            bond_id
            amount
          >>=? fun ctxt -> return (ctxt, Frozen_bonds (contract, bond_id))))
  >|=? fun (ctxt, balance) -> (ctxt, (balance, Debited amount, origin))

(* stake diff calculation *)
(* [stake_removes] is a map associated to the delegatees for which
   at least a delegator has spended tez in a transfer_n, the total
   amount spended by its delegatees in this transfer_n.*)

module StMap = Map.Make (struct
  type t = Contract_repr.t

  let compare = Contract_repr.compare
end)

(* [collect_delegate_stake_mvt amount del dsdiff] ensures that only
   one stake decreasement will be performed per delegatee during a
   transfer_n.

   It collects by source an [amount], checks if it already knows [del]
   and adds [amount] to the stake to remove for [del] in this
   transfer.

   When [del] does not already appear in [dsdiff], [del] is added
   associated to [amount]. *)
let collect_delegate_stake_mvt amount del dsdiff =
  match StMap.find del dsdiff with
  | None -> return (StMap.add del amount dsdiff)
  | Some old_amount ->
      Tez_repr.(old_amount +? amount) >>?= fun new_amount ->
      return (StMap.add del new_amount dsdiff)

(* [update_staking_balances del_cred amount_cred dsdiff ctxt] ensures
   that only one staking movement is performed per delegatee during a
   transfer_n. It computes for each delegatee implies in a transfer_n
   the unique staking movement to performed.

   From a [stake_removes] map [dsdiff] and a context [ctxt] computes a
   new context such as only one staking movement is performed for the
   [delegatee]'s in [dsdiff] and [del_cred].

   For any [del] in [dsdiff], [del] is not [del_cred], it removes
   [dsdiff del] from [del] staking balance.

   When [del_cred] is not in [dsdiff], [cred_amount] is added to its
   staking amount. Otherwise, either:
   - [cred_amount] = [dsdiff del_cred] and no updates is performed, or
   - [cred_amount] > [dsdiff del_cred] and the diff is added to
     [del_cred]'s staking_balance, or
   - [cred_amount] > [dsdiff del_cred] and the diff is removed to
     [del_cred]'s staking_balance. *)

let update_staking_balances del_cred amount_cred dsdiff pre_ctxt =
  let cmp d1 d2 =
    match d1 with Some d1 -> Contract_repr.(d1 = d2) | None -> false
  in
  StMap.fold_es
    (fun del amount_spend (ctxt, found) ->
      match Contract_repr.is_implicit del with
      | None -> return (ctxt, found)
      | Some del_pkh ->
          if cmp del_cred del then
            (if Tez_repr.(amount_spend = amount_cred) then return ctxt
            else if Tez_repr.(amount_spend > amount_cred) then
              Tez_repr.(amount_spend -? amount_cred) >>?= fun new_amount ->
              Stake_storage.remove_stake ctxt del_pkh new_amount
            else
              Tez_repr.(amount_cred -? amount_spend) >>?= fun new_amount ->
              Stake_storage.add_stake ctxt del_pkh new_amount)
            >>=? fun ctxt -> return (ctxt, true)
          else
            Stake_storage.remove_stake ctxt del_pkh amount_spend
            >>=? fun ctxt -> return (ctxt, found))
    dsdiff
    (pre_ctxt, false)
  >>=? fun (ctxt, found) ->
  if found then return ctxt
  else
    match del_cred with
    | None -> return ctxt
    | Some del_cred -> (
        match Contract_repr.is_implicit del_cred with
        | None -> return ctxt
        | Some del_pkh -> Stake_storage.add_stake ctxt del_pkh amount_cred)

let delegate_of ctxt std =
  match std with
  | `Contract src | `Frozen_bonds (src, _) -> (
      Contract_delegate_storage.find ctxt src >>=? function
      | None -> return_none
      | Some del -> return_some (Contract_repr.implicit_contract del))
  | `Frozen_deposits delegate -> (
      Contract_delegate_storage.find
        ctxt
        (Contract_repr.implicit_contract delegate)
      >>=? function
      | None -> return_none
      | Some del -> return_some (Contract_repr.implicit_contract del))
  | `Block_fees | `Collected_commitments _ | #source | #sink -> return_none

let transfer_n ?(origin = Receipt_repr.Block_application) ctxt src dest =
  let sources = List.filter (fun (_, am) -> Tez_repr.(am <> zero)) src in
  match sources with
  | [] ->
      (* Avoid accessing context data when there is nothing to transfer. *)
      return (ctxt, [])
  | _ :: _ ->
      (* Withdraw from sources and compute of the stake decreasements by
         delegatee. *)
      List.fold_left_es
        (fun ((ctxt, total, debit_logs), dsdiff) (source, amount) ->
          spend ctxt source amount origin >>=? fun (ctxt, debit_log) ->
          Tez_repr.(amount +? total) >>?= fun total ->
          delegate_of ctxt source >>=? fun del ->
          (match del with
          | None -> return dsdiff
          | Some del -> collect_delegate_stake_mvt amount del dsdiff)
          >>=? fun dsdiff ->
          return ((ctxt, total, debit_log :: debit_logs), dsdiff))
        ((ctxt, Tez_repr.zero, []), StMap.empty)
        sources
      >>=? fun ((ctxt, amount, debit_logs), dsdiff) ->
      credit ctxt dest amount origin >>=? fun (ctxt, credit_log) ->
      (* Deallocate implicit contracts with no stake. This must be done after
         spending and crediting. If done in between then a transfer of all the
         balance from (`Contract c) to (`Frozen_bonds (c,_)) would leave the
         contract c unallocated. *)
      List.fold_left_es
        (fun ctxt (source, _amount) ->
          match source with
          | `Contract contract | `Frozen_bonds (contract, _) ->
              Contract_storage.ensure_deallocated_if_empty ctxt contract
          | #source -> return ctxt)
        ctxt
        sources
      >>=? fun ctxt ->
      (* Make a unique staking movement by delegatee implies in this transfer_n.*)
      delegate_of ctxt dest >>=? fun del ->
      update_staking_balances del amount dsdiff ctxt >>=? fun ctxt ->
      (* Make sure the order of balance updates is : debit logs in the order of
         of the parameter [src], and then the credit log. *)
      let balance_updates = List.rev (credit_log :: debit_logs) in
      return (ctxt, balance_updates)

let transfer ?(origin = Receipt_repr.Block_application) ctxt src dest amount =
  transfer_n ~origin ctxt [(src, amount)] dest
