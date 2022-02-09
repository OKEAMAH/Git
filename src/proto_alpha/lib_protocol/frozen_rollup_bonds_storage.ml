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

(** This module encapsulates the following storage maps:
    - [Storage.Contract.Frozen_rollup_bonds]
    - [Storage.Contract.Total_rollup_bonds]

   This module enforces the following invariants:
    - [ (Frozen_rollup_bonds.mem x) <-> (Total_rollup_bonds.mem x) ]
    - [ Total_rollup_bonds.find x ] = sum of all bond values in
      [ Frozen_rollup_bonds.bindings x ]. *)

open Storage.Contract

type error +=
  | Frozen_rollup_bonds_must_be_spent_at_once of
      Contract_repr.t * Rollup_bond_id_repr.t

let () =
  register_error_kind
    `Permanent
    ~id:"frozen_rollup_bonds.must_be_spent_at_once"
    ~title:"Partial spending of rollup bonds"
    ~description:"Frozen rollup bonds must be spent at once."
    ~pp:(fun ppf (contract, bond_id) ->
      Format.fprintf
        ppf
        "The frozen funds for contract (%a) and rollup bond (%a) are not \
         allowed to be partially withdrawn. The amount withdrawn must be equal \
         to the entire deposit for the said bond."
        Contract_repr.pp
        contract
        Rollup_bond_id_repr.pp
        bond_id)
    Data_encoding.(
      obj2
        (req "contract" Contract_repr.encoding)
        (req "bond_id" Rollup_bond_id_repr.encoding))
    (function
      | Frozen_rollup_bonds_must_be_spent_at_once (c, b) -> Some (c, b)
      | _ -> None)
    (fun (c, b) -> Frozen_rollup_bonds_must_be_spent_at_once (c, b))

let has_frozen_bonds ctxt contract = Total_rollup_bonds.mem ctxt contract >|= ok

let allocated ctxt contract bond_id =
  Frozen_rollup_bonds.mem (ctxt, contract) bond_id >|= ok

let find ctxt contract bond_id =
  Frozen_rollup_bonds.find (ctxt, contract) bond_id

(** PRE : amount > 0, fullfilled by unique caller [Token.transfer]. *)
let spend_only_call_from_token ctxt contract bond_id amount =
  Frozen_rollup_bonds.get (ctxt, contract) bond_id >>=? fun frozen_bonds ->
  error_when
    Tez_repr.(frozen_bonds <> amount)
    (Frozen_rollup_bonds_must_be_spent_at_once (contract, bond_id))
  >>?= fun () ->
  Frozen_rollup_bonds.remove_existing (ctxt, contract) bond_id >>=? fun ctxt ->
  Total_rollup_bonds.get ctxt contract >>=? fun total ->
  Tez_repr.(total -? amount) >>?= fun new_total ->
  if Tez_repr.(new_total = zero) then
    Total_rollup_bonds.remove_existing ctxt contract
  else Total_rollup_bonds.update ctxt contract new_total

(** PRE : [amount > 0], fullfilled by unique caller [Token.transfer].*)
let credit_only_call_from_token ctxt contract bond_id amount =
  (Frozen_rollup_bonds.find (ctxt, contract) bond_id >>=? function
   | None -> Frozen_rollup_bonds.init (ctxt, contract) bond_id amount
   | Some frozen_bonds ->
       Tez_repr.(frozen_bonds +? amount) >>?= fun new_amount ->
       Frozen_rollup_bonds.update (ctxt, contract) bond_id new_amount)
  >>=? fun ctxt ->
  Total_rollup_bonds.find ctxt contract >>=? function
  | None -> Total_rollup_bonds.init ctxt contract amount
  | Some total ->
      Tez_repr.(total +? amount) >>?= fun new_total ->
      Total_rollup_bonds.update ctxt contract new_total
