(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 G.B. Fefe, <gb.fefe@protonmail.com>                    *)
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

type error +=
  | (* `Permanent *) No_deletion of Signature.Public_key_hash.t
  | (* `Temporary *) Active_delegate
  | (* `Temporary *) Current_delegate
  | (* `Permanent *) Empty_delegate_account of Signature.Public_key_hash.t
  | (* `Permanent *) Unregistered_delegate of Signature.Public_key_hash.t

let () =
  register_error_kind
    `Permanent
    ~id:"delegate.no_deletion"
    ~title:"Forbidden delegate deletion"
    ~description:"Tried to unregister a delegate"
    ~pp:(fun ppf delegate ->
      Format.fprintf
        ppf
        "Delegate deletion is forbidden (%a)"
        Signature.Public_key_hash.pp
        delegate)
    Data_encoding.(obj1 (req "delegate" Signature.Public_key_hash.encoding))
    (function No_deletion c -> Some c | _ -> None)
    (fun c -> No_deletion c) ;
  register_error_kind
    `Temporary
    ~id:"delegate.already_active"
    ~title:"Delegate already active"
    ~description:"Useless delegate reactivation"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "The delegate is still active, no need to refresh it")
    Data_encoding.empty
    (function Active_delegate -> Some () | _ -> None)
    (fun () -> Active_delegate) ;
  register_error_kind
    `Temporary
    ~id:"delegate.unchanged"
    ~title:"Unchanged delegated"
    ~description:"Contract already delegated to the given delegate"
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "The contract is already delegated to the same delegate")
    Data_encoding.empty
    (function Current_delegate -> Some () | _ -> None)
    (fun () -> Current_delegate) ;
  register_error_kind
    `Permanent
    ~id:"delegate.empty_delegate_account"
    ~title:"Empty delegate account"
    ~description:"Cannot register a delegate when its implicit account is empty"
    ~pp:(fun ppf delegate ->
      Format.fprintf
        ppf
        "Delegate registration is forbidden when the delegate\n\
        \           implicit account is empty (%a)"
        Signature.Public_key_hash.pp
        delegate)
    Data_encoding.(obj1 (req "delegate" Signature.Public_key_hash.encoding))
    (function Empty_delegate_account c -> Some c | _ -> None)
    (fun c -> Empty_delegate_account c) ;
  (* Unregistered delegate *)
  register_error_kind
    `Permanent
    ~id:"contract.manager.unregistered_delegate"
    ~title:"Unregistered delegate"
    ~description:"A contract cannot be delegated to an unregistered delegate"
    ~pp:(fun ppf k ->
      Format.fprintf
        ppf
        "The provided public key (with hash %a) is not registered as valid \
         delegate key."
        Signature.Public_key_hash.pp
        k)
    Data_encoding.(obj1 (req "hash" Signature.Public_key_hash.encoding))
    (function Unregistered_delegate k -> Some k | _ -> None)
    (fun k -> Unregistered_delegate k)

let set_inactive ctxt delegate =
  Delegate_activation_storage.set_inactive ctxt delegate >>= fun ctxt ->
  Stake_storage.deactivate_only_call_from_delegate_storage ctxt delegate >|= ok

let set_active ctxt delegate =
  Delegate_activation_storage.set_active ctxt delegate
  >>=? fun (ctxt, inactive) ->
  if not inactive then return ctxt
  else Stake_storage.activate_only_call_from_delegate_storage ctxt delegate

let deactivated = Delegate_activation_storage.is_inactive

let init ctxt contract delegate =
  Contract_manager_storage.is_manager_key_revealed ctxt delegate
  >>=? fun known_delegate ->
  error_unless known_delegate (Unregistered_delegate delegate) >>?= fun () ->
  Contract_delegate_storage.registered ctxt delegate >>=? fun is_registered ->
  error_unless is_registered (Unregistered_delegate delegate) >>?= fun () ->
  Contract_delegate_storage.init ctxt contract delegate >>=? fun ctxt ->
  Contract_storage.get_balance_and_frozen_bonds ctxt contract
  >>=? fun balance_and_frozen_bonds ->
  Stake_storage.add_stake ctxt delegate balance_and_frozen_bonds

let set c contract delegate =
  match delegate with
  | None -> (
      (* check if contract is a registered delegate *)
      (match contract with
      | Contract_repr.Implicit pkh ->
          Contract_delegate_storage.registered c pkh >>=? fun is_registered ->
          fail_when is_registered (No_deletion pkh)
      | Originated _ -> return_unit)
      >>=? fun () ->
      Contract_delegate_storage.find c contract >>=? function
      | None -> return c
      | Some delegate ->
          (* Removes the balance of the contract from the delegate *)
          Contract_storage.get_balance_and_frozen_bonds c contract
          >>=? fun balance_and_frozen_bonds ->
          Stake_storage.remove_stake c delegate balance_and_frozen_bonds
          >>=? fun c -> Contract_delegate_storage.delete c contract)
  | Some delegate ->
      Contract_manager_storage.is_manager_key_revealed c delegate
      >>=? fun known_delegate ->
      Contract_delegate_storage.registered c delegate
      >>=? fun registered_delegate ->
      let self_delegation =
        match contract with
        | Implicit pkh -> Signature.Public_key_hash.equal pkh delegate
        | Originated _ -> false
      in
      if (not known_delegate) || not (registered_delegate || self_delegation)
      then fail (Unregistered_delegate delegate)
      else
        Contract_delegate_storage.find c contract >>=? fun current_delegate ->
        (match current_delegate with
        | Some current_delegate
          when Signature.Public_key_hash.equal delegate current_delegate ->
            if self_delegation then
              Delegate_activation_storage.is_inactive c delegate >>=? function
              | true -> return_unit
              | false -> fail Active_delegate
            else fail Current_delegate
        | None | Some _ -> return_unit)
        >>=? fun () ->
        (* check if contract is a registered delegate *)
        (match contract with
        | Contract_repr.Implicit pkh ->
            Contract_delegate_storage.registered c pkh >>=? fun is_registered ->
            (* allow self-delegation to re-activate *)
            if (not self_delegation) && is_registered then
              fail (No_deletion pkh)
            else return_unit
        | Originated _ -> return_unit)
        >>=? fun () ->
        Contract_storage.allocated c contract >>= fun exists ->
        error_when
          (self_delegation && not exists)
          (Empty_delegate_account delegate)
        >>?= fun () ->
        Contract_storage.get_balance_and_frozen_bonds c contract
        >>=? fun balance_and_frozen_bonds ->
        Stake_storage.remove_contract_stake c contract balance_and_frozen_bonds
        >>=? fun c ->
        Contract_delegate_storage.set c contract delegate >>=? fun c ->
        Stake_storage.add_stake c delegate balance_and_frozen_bonds
        >>=? fun c ->
        if self_delegation then
          Storage.Delegates.add c delegate >>= fun c -> set_active c delegate
        else return c

let fold = Storage.Delegates.fold

let list = Storage.Delegates.elements

let frozen_deposits_limit ctxt delegate =
  Storage.Contract.Frozen_deposits_limit.find
    ctxt
    (Contract_repr.Implicit delegate)

let set_frozen_deposits_limit ctxt delegate limit =
  Storage.Contract.Frozen_deposits_limit.add_or_remove
    ctxt
    (Contract_repr.Implicit delegate)
    limit

let frozen_deposits ctxt delegate =
  Frozen_deposits_storage.get ctxt (Contract_repr.Implicit delegate)

let balance ctxt delegate =
  let contract = Contract_repr.Implicit delegate in
  Storage.Contract.Spendable_balance.get ctxt contract

let staking_balance ctxt delegate =
  Contract_delegate_storage.registered ctxt delegate >>=? fun is_registered ->
  if is_registered then Stake_storage.get_staking_balance ctxt delegate
  else return Tez_repr.zero

let full_balance ctxt delegate =
  frozen_deposits ctxt delegate >>=? fun frozen_deposits ->
  let delegate_contract = Contract_repr.Implicit delegate in
  Contract_storage.get_balance_and_frozen_bonds ctxt delegate_contract
  >>=? fun balance_and_frozen_bonds ->
  Lwt.return
    Tez_repr.(frozen_deposits.current_amount +? balance_and_frozen_bonds)

let delegated_balance ctxt delegate =
  staking_balance ctxt delegate >>=? fun staking_balance ->
  full_balance ctxt delegate >>=? fun self_staking_balance ->
  Lwt.return Tez_repr.(staking_balance -? self_staking_balance)

let pubkey ctxt delegate =
  Contract_manager_storage.get_manager_key
    ctxt
    delegate
    ~error:(Unregistered_delegate delegate)
