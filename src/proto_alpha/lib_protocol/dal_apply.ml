(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* Every function of this file should check the feature flag. *)

open Alpha_context
open Dal_errors

let assert_dal_feature_enabled ctxt =
  let open Constants in
  let Parametric.{dal = {feature_enable; _}; _} = parametric ctxt in
  error_unless Compare.Bool.(feature_enable = true) Dal_feature_disabled

let only_if_dal_feature_enabled ctxt ~default f =
  let open Constants in
  let Parametric.{dal = {feature_enable; _}; _} = parametric ctxt in
  if feature_enable then f ctxt else default ctxt

let slot_of_int_e ~number_of_slots n =
  let open Result_syntax in
  match Dal.Slot_index.of_int_opt ~number_of_slots n with
  | None ->
      tzfail
      @@ Dal_errors.Dal_slot_index_above_hard_limit
           {given = n; limit = number_of_slots - 1}
  | Some slot_index -> return slot_index

(* Use this function to select the pkh used in the DAL committee. As long as an
   epoch does not span across multiple cycles, we could use as well the pkh of
   the consensus key. *)
let pkh_of_consensus_key (consensus_key : Consensus_key.pk) =
  consensus_key.delegate

let validate_attestation ctxt get_consensus_key op =
  let open Lwt_result_syntax in
  let*? () = assert_dal_feature_enabled ctxt in
  (* DAL/TODO: https://gitlab.com/tezos/tezos/-/issues/4462
     Reconsider the ordering of checks. *)
  let Dal.Attestation.{attestation; level = given; slot = _} = op in
  let number_of_slots = Dal.number_of_slots ctxt in
  let*? max_index = number_of_slots - 1 |> slot_of_int_e ~number_of_slots in
  let maximum_size = Dal.Attestation.expected_size_in_bits ~max_index in
  let size = Dal.Attestation.occupied_size_in_bits attestation in
  let*? () =
    error_unless
      Compare.Int.(size <= maximum_size)
      (Dal_attestation_size_limit_exceeded {maximum_size; got = size})
  in
  let current = Level.(current ctxt).level in
  let*? expected =
    match Raw_level.pred current with
    | None -> error Dal_unexpected_attestation_at_root_level
    | Some level -> Result_syntax.return level
  in
  let delta_levels = Raw_level.diff expected given in
  let*? () =
    error_when
      Compare.Int32.(delta_levels > 0l)
      (Dal_operation_for_old_level {expected; given})
  in
  let*? () =
    error_when
      Compare.Int32.(delta_levels < 0l)
      (Dal_operation_for_future_level {expected; given})
  in
  let* consensus_key = get_consensus_key () in
  let attester = pkh_of_consensus_key consensus_key in
  let*? () =
    error_when
      (Option.is_none @@ Dal.Attestation.shards_of_attester ctxt ~attester)
      (Dal_data_availibility_attester_not_in_committee
         {attester; level = expected})
  in
  return consensus_key

let apply_attestation ctxt consensus_key op =
  let open Result_syntax in
  let* () = assert_dal_feature_enabled ctxt in
  let Dal.Attestation.{attestation; level; _} = op in
  let attester = pkh_of_consensus_key consensus_key in
  match Dal.Attestation.shards_of_attester ctxt ~attester with
  | None ->
      (* This should not happen: operation validation should have failed. *)
      error (Dal_data_availibility_attester_not_in_committee {attester; level})
  | Some shards ->
      return (Dal.Attestation.record_attested_shards ctxt attestation shards)

(* This function should fail if we don't want the operation to be
   propagated over the L1 gossip network. Because this is a manager
   operation, there are already checks to ensure the source of
   operation has enough fees. Among the various checks, there are
   checks that cannot fail unless the source of the operation is
   malicious (or if there is a bug). In that case, it is better to
   ensure fees will be taken. *)
let validate_publish_slot_header ctxt _operation =
  assert_dal_feature_enabled ctxt

let apply_publish_slot_header ctxt operation =
  let open Result_syntax in
  let* ctxt = Gas.consume ctxt Dal_costs.cost_Dal_publish_slot_header in
  let number_of_slots = Dal.number_of_slots ctxt in
  let* cryptobox = Dal.make ctxt in
  let current_level = (Level.current ctxt).level in
  let* slot_header =
    Dal.Operations.Publish_slot_header.slot_header
      ~cryptobox
      ~number_of_slots
      ~current_level
      operation
  in
  let* ctxt = Dal.Slot.register_slot_header ctxt slot_header in
  return (ctxt, slot_header)

let finalisation ctxt =
  let open Lwt_result_syntax in
  only_if_dal_feature_enabled
    ctxt
    ~default:(fun ctxt -> return (ctxt, None))
    (fun ctxt ->
      let*! ctxt = Dal.Slot.finalize_current_slot_headers ctxt in
      (* The fact that slots confirmation is done at finalization is very
         important for the assumptions made by the Dal refutation game. In fact:
         - {!Dal.Slot.finalize_current_slot_headers} updates the Dal skip list
         at block finalization, by inserting newly confirmed slots;
         - {!Sc_rollup.Game.initial}, called when applying a manager operation
         that starts a refutation game, makes a snapshot of the Dal skip list
         to use it as a reference if the refutation proof involves a Dal input.

         If confirmed Dal slots are inserted into the skip list during operations
         application, adapting how refutation games are made might be needed
         to e.g.,
         - use the same snapshotted skip list as a reference by L1 and rollup-node;
         - disallow proofs involving pages of slots that have been confirmed at the
           level where the game started.
      *)
      let+ ctxt, attestation = Dal.Slot.finalize_pending_slot_headers ctxt in
      (ctxt, Some attestation))

let compute_committee ctxt level =
  let open Lwt_result_syntax in
  let*? () = assert_dal_feature_enabled ctxt in
  let blocks_per_epoch = (Constants.parametric ctxt).dal.blocks_per_epoch in
  let first_level_in_epoch =
    match
      Level.sub
        ctxt
        level
        (Int32.to_int @@ Int32.rem level.Level.cycle_position blocks_per_epoch)
    with
    | Some v -> v
    | None ->
        (* unreachable, because level.level >= level.cycle_position >=
           (level.cycle_position mod blocks_per_epoch) *)
        assert false
  in
  let pkh_from_tenderbake_slot slot =
    let+ ctxt, consensus_key =
      Stake_distribution.slot_owner ctxt first_level_in_epoch slot
    in
    (ctxt, pkh_of_consensus_key consensus_key)
  in
  (* This committee is cached because it is the one we will use
     for the validation of the DAL attestations. *)
  Alpha_context.Dal.Attestation.compute_committee ctxt pkh_from_tenderbake_slot

let initialisation ctxt ~level =
  let open Lwt_result_syntax in
  only_if_dal_feature_enabled
    ctxt
    ~default:(fun ctxt -> return ctxt)
    (fun ctxt ->
      let+ committee = compute_committee ctxt level in
      Alpha_context.Dal.Attestation.init_committee ctxt committee)
