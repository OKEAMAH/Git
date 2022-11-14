(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

open Sc_rollup_errors
module Store = Storage.Sc_rollup
module Commitment = Sc_rollup_commitment_repr
module Commitment_hash = Commitment.Hash

(** [address_from_nonce ctxt nonce] produces an address completely determined by
    an operation hash and an origination counter, and accounts for gas spent. *)
let address_from_nonce ctxt nonce =
  let open Tzresult_syntax in
  let* ctxt =
    Raw_context.consume_gas ctxt Sc_rollup_costs.Constants.cost_serialize_nonce
  in
  match Data_encoding.Binary.to_bytes_opt Origination_nonce.encoding nonce with
  | None -> error Sc_rollup_address_generation
  | Some nonce_bytes ->
      let bytes_len = Bytes.length nonce_bytes in
      let+ ctxt =
        Raw_context.consume_gas
          ctxt
          (Sc_rollup_costs.cost_hash_bytes ~bytes_len)
      in
      (ctxt, Sc_rollup_repr.Address.hash_bytes [nonce_bytes])

let originate ctxt ~kind ~boot_sector ~parameters_ty ~genesis_commitment =
  let open Lwt_tzresult_syntax in
  let*? ctxt, genesis_commitment_hash =
    Sc_rollup_commitment_storage.hash ctxt genesis_commitment
  in
  let*? ctxt, nonce = Raw_context.increment_origination_nonce ctxt in
  let*? ctxt, address = address_from_nonce ctxt nonce in
  let* ctxt, pvm_kind_size, _kind_existed =
    Store.PVM_kind.add ctxt address kind
  in
  let origination_level = (Raw_context.current_level ctxt).level in
  let* ctxt, genesis_info_size, _info_existed =
    Store.Genesis_info.add
      ctxt
      address
      {commitment_hash = genesis_commitment_hash; level = origination_level}
  in
  let* ctxt, boot_sector_size, _sector_existed =
    Store.Boot_sector.add ctxt address boot_sector
  in
  let* ctxt, param_ty_size_diff, _added =
    Store.Parameters_type.add ctxt address parameters_ty
  in
  let* ctxt, lcc_size_diff =
    Store.Last_cemented_commitment.init ctxt address genesis_commitment_hash
  in
  let* ctxt, commitment_size_diff, _was_bound =
    Store.Commitments.add
      (ctxt, address)
      genesis_commitment_hash
      genesis_commitment
  in
  (* This store [Store.Commitment_added] is going to be used to look this
     bootstrap commitment. This commitment is added here so the
     [sc_rollup_state_storage.deallocate] function does not have to handle a
     edge case. *)
  let* ctxt, commitment_added_size_diff, _commitment_existed =
    Store.Commitment_added.add
      (ctxt, address)
      genesis_commitment_hash
      origination_level
  in
  (* This store [Store.Commitment_added] is going to be used to look this
     bootstrap commitment. This commitment is added here so the
     [sc_rollup_state_storage.deallocate] function does not have to handle a
     edge case.

     There is no staker for the genesis_commitment. *)
  let* ctxt, commitment_staker_count_size_diff, _commitment_staker_existed =
    Store.Commitment_stake_count.add
      (ctxt, address)
      genesis_commitment_hash
      Int32.zero
  in
  let* ctxt, stakers_size_diff = Store.Staker_count.init ctxt address 0l in
  let addresses_size = 2 * Sc_rollup_repr.Address.size in
  let stored_kind_size = 2 (* because tag_size of kind encoding is 16bits. *) in
  let origination_size = Constants_storage.sc_rollup_origination_size ctxt in
  let size =
    Z.of_int
      (origination_size + stored_kind_size + boot_sector_size + addresses_size
     + lcc_size_diff + commitment_size_diff + commitment_added_size_diff
     + commitment_staker_count_size_diff + stakers_size_diff
     + param_ty_size_diff + pvm_kind_size + genesis_info_size)
  in
  return (address, size, genesis_commitment_hash, ctxt)

let kind ctxt address =
  let open Lwt_tzresult_syntax in
  let* ctxt, kind_opt = Store.PVM_kind.find ctxt address in
  match kind_opt with
  | Some k -> return (ctxt, k)
  | None -> fail (Sc_rollup_errors.Sc_rollup_does_not_exist address)

let list_unaccounted ctxt =
  let open Lwt_syntax in
  let+ res = Store.PVM_kind.keys_unaccounted ctxt in
  Result.return res

let genesis_info ctxt rollup =
  let open Lwt_tzresult_syntax in
  let* ctxt, genesis_info = Store.Genesis_info.find ctxt rollup in
  match genesis_info with
  | None -> fail (Sc_rollup_does_not_exist rollup)
  | Some genesis_info -> return (ctxt, genesis_info)

let get_metadata ctxt rollup =
  let open Lwt_tzresult_syntax in
  let* ctxt, genesis_info = genesis_info ctxt rollup in

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3997
     - We should search for the parameters at level [genesis_info.level] in the
       parameters skip list (see task 2 of issue above);
     - The current implementation becomes incorrect (we cannot refute metadata) as
     soon as L1 paramteters change.
        - Should we temporarily save the L1 parameters in genesis_info at each
          Scoru origination?, or
        - Do not merge this MR in master, until the MR about task 2 is merged? *)
  let parametric = Constants_storage.parametric ctxt in
  let*? parametric_constants = Constants_parametric_repr.serialize parametric in
  let metadata : Sc_rollup_metadata_repr.t =
    {
      address = rollup;
      origination_level = genesis_info.level;
      parametric_constants;
    }
  in
  return (ctxt, metadata)

let get_boot_sector ctxt rollup =
  let open Lwt_tzresult_syntax in
  let* ctxt, boot_sector = Storage.Sc_rollup.Boot_sector.find ctxt rollup in
  match boot_sector with
  | None -> fail (Sc_rollup_does_not_exist rollup)
  | Some boot_sector -> return (ctxt, boot_sector)

let parameters_type ctxt rollup =
  let open Lwt_result_syntax in
  let+ ctxt, res = Store.Parameters_type.find ctxt rollup in
  (res, ctxt)
