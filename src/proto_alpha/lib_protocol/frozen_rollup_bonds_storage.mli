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

(** This module manages frozen rollups deposits (here called bonds). These
    bonds are part of the stake of the contract making the deposit. *)

(** This error is raised when [spend_only_call_from_token] is called with an
    amount that is less than the deposit associated to the given contract and
    rollup bond id.*)
type error +=
  | (* `Permanent *)
      Frozen_rollup_bonds_must_be_spent_at_once of
      Contract_repr.t * Rollup_bond_id_repr.t

(** [has_frozen_bonds ctxt contract] returns true iff there are frozen bonds
    associated to [contract]. *)
val has_frozen_bonds : Raw_context.t -> Contract_repr.t -> bool tzresult Lwt.t

(** [allocated ctxt contract bond_id] returns a new context because of an access
    to carbonated data, and a boolean that is [true] iff there is a bond
    associated to [contract] and [bond_id]. *)
val allocated :
  Raw_context.t ->
  Contract_repr.t ->
  Rollup_bond_id_repr.t ->
  (Raw_context.t * bool) tzresult Lwt.t

(** [find ctxt contract bond_id] returns a new context because of an access
    to carbonated data, and the bond associated to [contract] and [bond_id] if
    there is one, or [None] if there is none. *)
val find :
  Raw_context.t ->
  Contract_repr.t ->
  Rollup_bond_id_repr.t ->
  (Raw_context.t * Tez_repr.t option) tzresult Lwt.t

(** [spend ctxt contract bond_id amount] withdraws the given [amount] from
    the value of the bond associated to [contract] and [bond_id].

    Fails when there is no bond for [contract] and [bond_id].

    @raise a [Frozen_rollup_bonds_must_be_spent_at_once (contract, bond_id)]
    error when the amount is different from the bond associated to [contract]
    and [bond_id].
 *)
val spend_only_call_from_token :
  Raw_context.t ->
  Contract_repr.t ->
  Rollup_bond_id_repr.t ->
  Tez_repr.t ->
  Raw_context.t tzresult Lwt.t

(** [credit ctxt contract bond_id amount] adds the given [amount] to the bond
    associated to [contract] and [bond_id]. If no bond exists, one whose value
    is [amount] is created.

    Fails when [(find ctxt contract bond_id) + amount > Int64.max_int]. *)
val credit_only_call_from_token :
  Raw_context.t ->
  Contract_repr.t ->
  Rollup_bond_id_repr.t ->
  Tez_repr.t ->
  Raw_context.t tzresult Lwt.t

(** [total ctxt contract] returns the total amount of bonds associated to
    [contract]. *)
val total : Raw_context.t -> Contract_repr.t -> Tez_repr.t tzresult Lwt.t
