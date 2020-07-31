(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

(** Double endorsement evidence operation may happen when an endorser
    endorsed two different blocks on the same level. *)

open Protocol
open Alpha_context

(****************************************************************)
(*                  Utility functions                           *)
(****************************************************************)

let get_first_different_baker baker bakers =
  List.find
    (fun baker' -> Signature.Public_key_hash.( <> ) baker baker')
    bakers

let get_first_different_bakers ctxt =
  Context.get_bakers ctxt
  >|=? fun bakers ->
  let baker_1 = List.hd bakers in
  get_first_different_baker baker_1 (List.tl bakers)
  |> fun baker_2 -> (baker_1, baker_2)

let get_first_different_endorsers ctxt =
  Context.get_endorsers ctxt
  >|=? fun endorsers ->
  let endorser_1 = List.hd endorsers in
  let endorser_2 = List.hd (List.tl endorsers) in
  (endorser_1, endorser_2)

let block_fork b =
  get_first_different_bakers (B b)
  >>=? fun (baker_1, baker_2) ->
  Block.bake ~policy:(By_account baker_1) b
  >>=? fun blk_a ->
  Block.bake ~policy:(By_account baker_2) b >|=? fun blk_b -> (blk_a, blk_b)

(****************************************************************)
(*                        Tests                                 *)
(****************************************************************)

(** Simple scenario where two endorsements are made from the same
    delegate and exposed by a double_endorsement operation. Also verify
    that punishment is operated. *)
let valid_double_endorsement_evidence () =
  Context.init 2
  >>=? fun (b, _) ->
  block_fork b
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (delegate, _slots) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Block.bake ~operations:[Operation.pack endorsement_a] blk_a
  >>=? fun blk_a ->
  (* Block.bake ~operations:[endorsement_b] blk_b >>=? fun _ -> *)
  Op.double_endorsement (B blk_a) endorsement_a endorsement_b
  |> fun operation ->
  (* Bake with someone different than the bad endorser *)
  Context.get_bakers (B blk_a)
  >>=? fun bakers ->
  get_first_different_baker delegate bakers
  |> fun baker ->
  Block.bake ~policy:(By_account baker) ~operation blk_a
  >>=? fun blk ->
  (* Check that the frozen deposit, the fees and rewards are removed *)
  iter_s
    (fun kind ->
      let contract = Alpha_context.Contract.implicit_contract delegate in
      Assert.balance_is ~loc:__LOC__ (B blk) contract ~kind Tez.zero)
    [Deposit; Fees; Rewards]

(****************************************************************)
(*  The following test scenarios are supposed to raise errors.  *)
(****************************************************************)

(** Check that an invalid double endorsement operation that exposes a valid
    endorsement fails. *)
let invalid_double_endorsement () =
  Context.init 10
  >>=? fun (b, _) ->
  Block.bake b
  >>=? fun b ->
  Op.endorsement (B b) ()
  >>=? fun endorsement ->
  Block.bake ~operation:(Operation.pack endorsement) b
  >>=? fun b ->
  Op.double_endorsement (B b) endorsement endorsement
  |> fun operation ->
  Block.bake ~operation b
  >>= fun res ->
  Assert.proto_error ~loc:__LOC__ res (function
      | Cheating_proofs.Invalid_double_endorsement_evidence _ ->
          true
      | _ ->
          false)

(** Check that a double endorsement added at the same time as a double
    endorsement operation fails. *)
let too_early_double_endorsement_evidence () =
  Context.init 2
  >>=? fun (b, _) ->
  block_fork b
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (delegate, _slots) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Op.double_endorsement (B b) endorsement_a endorsement_b
  |> fun operation ->
  Block.bake ~operation b
  >>= fun res ->
  Assert.proto_error ~loc:__LOC__ res (function
      | Cheating_proofs.Too_early_evidence _ ->
          true
      | _ ->
          false)

(** Check that after [preserved_cycles + 1], it is not possible
    to create a double_endorsement anymore. *)
let too_late_double_endorsement_evidence () =
  Context.init 2
  >>=? fun (b, _) ->
  Context.get_constants (B b)
  >>=? fun Constants.{parametric = {preserved_cycles; _}; _} ->
  block_fork b
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (delegate, _slots) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  fold_left_s
    (fun blk _ -> Block.bake_until_cycle_end blk)
    blk_a
    (1 -- (preserved_cycles + 1))
  >>=? fun blk ->
  Op.double_endorsement (B blk) endorsement_a endorsement_b
  |> fun operation ->
  Block.bake ~operation blk
  >>= fun res ->
  Assert.proto_error ~loc:__LOC__ res (function
      | Cheating_proofs.Outdated_evidence _ ->
          true
      | _ ->
          false)

(** Check that an invalid double endorsement evidence that expose two
    endorsements made by two different endorsers fails. *)
let different_delegates () =
  Context.init 2
  >>=? fun (b, _) ->
  Block.bake b
  >>=? fun b ->
  block_fork b
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (endorser_a, _a_slots) ->
  get_first_different_endorsers (B blk_b)
  >>=? fun (endorser_b1c, endorser_b2c) ->
  let endorser_b =
    if Signature.Public_key_hash.( = ) endorser_a endorser_b1c.delegate then
      endorser_b2c.delegate
    else endorser_b1c.delegate
  in
  Op.endorsement ~delegate:endorser_a (B blk_a) ()
  >>=? fun e_a ->
  Op.endorsement ~delegate:endorser_b (B blk_b) ()
  >>=? fun e_b ->
  Block.bake ~operation:(Operation.pack e_b) blk_b
  >>=? fun _ ->
  Op.double_endorsement (B blk_b) e_a e_b
  |> fun operation ->
  Block.bake ~operation blk_b
  >>= fun res ->
  Assert.proto_error ~loc:__LOC__ res (function
      | Cheating_proofs.Inconsistent_evidence _ ->
          true
      | _ ->
          false)

(** Check that a double endorsement evidence that exposes a ill-formed
    endorsement fails. *)
let wrong_delegate () =
  Context.init ~endorsers_per_block:1 2
  >>=? fun (b, contracts) ->
  Error_monad.map_s (Context.Contract.manager (B b)) contracts
  >>=? fun accounts ->
  let pkh1 = (List.nth accounts 0).Account.pkh in
  let pkh2 = (List.nth accounts 1).Account.pkh in
  block_fork b
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (endorser_a, _a_slots) ->
  Op.endorsement ~delegate:endorser_a (B blk_a) ()
  >>=? fun endorsement_a ->
  Context.get_endorser (B blk_b)
  >>=? fun (endorser_b, _b_slots) ->
  let delegate =
    if Signature.Public_key_hash.equal pkh1 endorser_b then pkh2 else pkh1
  in
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Op.double_endorsement (B blk_b) endorsement_a endorsement_b
  |> fun operation ->
  Block.bake ~operation blk_b
  >>= fun e ->
  Assert.proto_error ~loc:__LOC__ e (function
      | Baking.Unexpected_endorsement ->
          true
      | _ ->
          false)

(** inject proof twice in two different cycle *)
let double_injection_double_endorsement_evidence () =
  Context.init 2
  >>=? fun (blk, _contracts) ->
  block_fork blk
  >>=? fun (blk_a, blk_b) ->
  Context.get_endorser (B blk_a)
  >>=? fun (delegate, _slots) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Block.bake ~operations:[Operation.pack endorsement_a] blk_a
  >>=? fun blk_a ->
  Op.double_endorsement (B blk_a) endorsement_a endorsement_b
  |> fun evidence ->
  Block.bake ~operation:evidence blk_a
  >>=? fun blk ->
  Block.bake_until_cycle_end blk
  >>=? fun blk ->
  Block.bake ~operation:evidence blk
  >>= fun e ->
  Assert.proto_error ~loc:__LOC__ e (function
      | Apply.Double_injection_of_evidence ->
          true
      | _ ->
          false)

(** Previously unrequired evidence can be re-injected and slash the baker *)
let unrequired_evidence_injected () =
  Context.init 2
  >>=? fun (blk, _contracts) ->
  Context.get_endorser (B blk)
  >>=? fun (delegate, _slots) ->
  block_fork blk
  >>=? fun (blk_a, blk_b) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Op.double_endorsement (B blk) endorsement_a endorsement_b
  |> fun evidence ->
  Block.bake blk
  >>=? fun blk ->
  block_fork blk
  >>=? fun (blk_2_a, blk_2_b) ->
  Op.endorsement ~delegate (B blk_2_a) ()
  >>=? fun endorsement_2_a ->
  Op.endorsement ~delegate (B blk_2_b) ()
  >>=? fun endorsement_2_b ->
  Op.double_endorsement (B blk) endorsement_2_a endorsement_2_b
  |> fun evidence_2 ->
  Block.bake ~policy:(By_account delegate) blk
  >>=? fun blk ->
  Block.bake ~policy:(Excluding [delegate]) ~operation:evidence blk
  >>=? fun blk ->
  Block.bake ~policy:(Excluding [delegate]) ~operation:evidence_2 blk
  >>= fun e ->
  Assert.proto_error ~loc:__LOC__ e (function
      | Apply.Unrequired_evidence ->
          true
      | _ ->
          false)
  >>=? fun () ->
  Block.bake ~policy:(By_account delegate) blk
  >>=? fun blk ->
  Block.bake ~policy:(Excluding [delegate]) ~operation:evidence_2 blk
  >>=? fun _blk -> return_unit

let assert_proof_exists ~loc ?(exists = true) cheat_level delegate blk =
  Context.Delegate.info (B blk) delegate
  >>=? fun delegate_info ->
  let proof_exists =
    Raw_level.LSet.mem cheat_level delegate_info.proof_levels
  in
  Assert.equal_bool ~loc proof_exists exists

(** Outdated proof is deleted from storage *)
let outdated_proof_has_been_cleaned () =
  Context.init 2
  >>=? fun (blk, _contracts) ->
  Context.get_constants (B blk)
  >>=? fun Constants.{parametric = {preserved_cycles; blocks_per_cycle; _}; _} ->
  block_fork blk
  >>=? fun (blk_a, blk_b) ->
  Context.get_level (B blk_a)
  >>?= fun cheat_level ->
  Context.get_endorser (B blk_a)
  >>=? fun (delegate, _slots) ->
  Op.endorsement ~delegate (B blk_a) ()
  >>=? fun endorsement_a ->
  Op.endorsement ~delegate (B blk_b) ()
  >>=? fun endorsement_b ->
  Op.double_endorsement (B blk_a) endorsement_a endorsement_b
  |> fun evidence ->
  Block.bake_until_n_cycle_end preserved_cycles blk_a
  >>=? fun blk ->
  Block.bake_n (Int32.to_int blocks_per_cycle - 2) blk
  >>=? fun blk ->
  Block.bake ~policy:(Excluding [delegate]) ~operation:evidence blk
  >>=? fun blk ->
  assert_proof_exists ~loc:__LOC__ cheat_level delegate blk
  >>=? fun () ->
  Block.bake blk
  >>=? fun blk ->
  Block.bake ~operation:evidence blk
  >>= fun res ->
  Assert.proto_error ~loc:__LOC__ res (function
      | Cheating_proofs.Outdated_evidence _ ->
          true
      | _ ->
          false)
  >>=? fun () ->
  (* proof storage is cleaned at the end of cycle *)
  (* proof storage is cleaned at the end of cycles *)
  Block.bake_n (Int32.to_int blocks_per_cycle - 2) blk
  >>=? fun blk ->
  assert_proof_exists ~loc:__LOC__ cheat_level delegate blk
  >>=? fun () ->
  Block.bake blk
  >>=? fun blk ->
  assert_proof_exists ~loc:__LOC__ ~exists:false cheat_level delegate blk

let tests =
  [ Test.tztest
      "valid double endorsement evidence"
      `Quick
      valid_double_endorsement_evidence;
    Test.tztest
      "invalid double endorsement evidence"
      `Quick
      invalid_double_endorsement;
    Test.tztest
      "too early double endorsement evidence"
      `Quick
      too_early_double_endorsement_evidence;
    Test.tztest
      "too late double endorsement evidence"
      `Quick
      too_late_double_endorsement_evidence;
    Test.tztest "different delegates" `Quick different_delegates;
    Test.tztest "wrong delegate" `Quick wrong_delegate;
    Test.tztest
      "reject double injection of an evidence."
      `Quick
      double_injection_double_endorsement_evidence;
    Test.tztest
      "inject previously unrequired evidence"
      `Quick
      unrequired_evidence_injected;
    Test.tztest
      "outdated proof has been cleaned from storage"
      `Quick
      outdated_proof_has_been_cleaned ]
