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

(** This module groups everything related to delegate registration.
    For the invariants maintained, see the submodule {!Contract}.

    It also groups "trivial" getters/setters related to delegates.

    It is responsible for maintaining the following tables:
    - {!Storage.Contract.Frozen_deposits_limit}
    - {!Storage.Delegates}
*)

type error += (* `Temporary *) Not_registered of Signature.Public_key_hash.t

(** Has a delegate been registered in the delegate table? *)
val registered : Raw_context.t -> Signature.Public_key_hash.t -> bool Lwt.t

(** Check that a given implicit account is a registered delegate. *)
val check_registered :
  Raw_context.t -> Signature.Public_key_hash.t -> unit tzresult Lwt.t

(** Iterate on all registered delegates. *)
val fold :
  Raw_context.t ->
  order:[`Sorted | `Undefined] ->
  init:'a ->
  f:(Signature.Public_key_hash.t -> 'a -> 'a Lwt.t) ->
  'a Lwt.t

(** List all registered delegates. *)
val list : Raw_context.t -> Signature.Public_key_hash.t list Lwt.t

val frozen_deposits_limit :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Tez_repr.t option tzresult Lwt.t

val set_frozen_deposits_limit :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Tez_repr.t option ->
  Raw_context.t Lwt.t

(** Returns a delegate's frozen deposits, both the current amount and
   the initial freezed amount.

    A delegate's frozen balance is only composed of frozen deposits;
    rewards and fees are not frozen, but simply credited at the right
    moment.  *)
val frozen_deposits :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Storage.deposits tzresult Lwt.t

val staking_balance :
  Raw_context.t -> Signature.Public_key_hash.t -> Tez_repr.t tzresult Lwt.t

(** Only use this function for RPCs: this is expensive. *)
val delegated_balance :
  Raw_context.t -> Signature.Public_key_hash.t -> Tez_repr.t tzresult Lwt.t

(** Returns the full 'balance' of the implicit contract associated to
    a given key, i.e. the sum of the spendable balance (given by [balance] or
    [Contract_storage.get_balance]) and of the frozen balance. The frozen
    balance is composed of all frozen bonds associated to the contract (given by
    [Contract_storage.get_frozen_bonds]) and of the frozen deposits (given by
    [frozen_deposits]).

    Only use this function for RPCs: this is expensive. *)
val full_balance :
  Raw_context.t -> Signature.Public_key_hash.t -> Tez_repr.t tzresult Lwt.t

(** This module ensures the following invariants:
    - registered delegates (i.e. those that appear in {!Storage.Delegates}) are
    self-delegated (i.e. {!Contract_delegate_storage.find} [delegate] returns [delegate]),
    - registered delegates have their public keys revealed,
    - registered delegates cannot change their delegation,
    - stake is properly moved when changing delegation.
*)
module Contract : sig
  type error +=
    | (* `Permanent *) Unregistered_delegate of Signature.Public_key_hash.t
    | (* `Temporary *) Active_delegate
    | (* `Permanent *) Empty_delegate_account of Signature.Public_key_hash.t
    | (* `Permanent *) No_deletion of Signature.Public_key_hash.t
    | (* `Temporary *) Current_delegate

  (** [init ctxt contract delegate] registers a delegate when
      creating a contract.

      This functions assumes that [contract] is allocated.
      This function returns an error if [contract] already has a delegate or
      if [delegate] is not a registered delegate. *)
  val init :
    Raw_context.t ->
    Contract_repr.t ->
    Signature.Public_key_hash.t ->
    Raw_context.t tzresult Lwt.t

  (** [set ctxt contract delegate_opt] allows to set the
      delegate of a contract to [delegate] when [delegate_opt = Some delegate]
      or to unset the delegate when [delegate_opt = None].
      When [delegate_opt = Some contract] (aka self-delegation),
      the function also registers the contract as a delegate and
      sets the delegate as {{!module:Delegate_activation_storage}active}.

      It returns an error when trying to set the delegate to an unregistered delegate.
      It returns an error when trying to unset or change the delegate of a registered delegate.
      It returns an error when self-delegating and the delegate is not {{!Contract_storage.allocated}allocated}.
      It returns an error when self-delegating and the delegate is already active. *)
  val set :
    Raw_context.t ->
    Contract_repr.t ->
    Signature.Public_key_hash.t option ->
    Raw_context.t tzresult Lwt.t
end

(** Returns the public key of a registered delegate. Returns the error
   {!Contract.Unregistered_delegate} if the delegate is not registered.  *)
val pubkey :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Signature.Public_key.t tzresult Lwt.t
