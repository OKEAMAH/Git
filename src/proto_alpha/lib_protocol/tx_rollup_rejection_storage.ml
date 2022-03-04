(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Tx_rollup_errors_repr

let prereject :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_rejection_repr.Rejection_hash.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup hash ->
  Tx_rollup_state_storage.get ctxt tx_rollup >>=? fun (ctxt, state) ->
  Lwt.return
  @@ Option.value_e
       ~error:(Error_monad.trace_of_error Prerejection_without_inbox)
  @@ Tx_rollup_state_repr.head_levels state
  >>=? fun (level, _) ->
  Storage.Tx_rollup.Prerejection.mem ctxt hash >>=? fun (ctxt, is_mem) ->
  fail_when is_mem Duplicate_prerejection >>=? fun () ->
  (Storage.Tx_rollup.Prerejection_counter.find ctxt tx_rollup >>=? function
   | (ctxt, None) ->
       Storage.Tx_rollup.Prerejection_counter.init ctxt tx_rollup 1l
       >>=? fun (ctxt, _) -> return (ctxt, 0l)
   | (ctxt, Some counter) ->
       Storage.Tx_rollup.Prerejection_counter.update
         ctxt
         tx_rollup
         (Int32.add counter 1l)
       >>=? fun (ctxt, _) -> return (ctxt, counter))
  >>=? fun (ctxt, counter) ->
  Storage.Tx_rollup.Prerejection.add ctxt hash (tx_rollup, counter)
  >>=? fun (ctxt, _, _) ->
  Storage.Tx_rollup.Prerejections_by_index.add
    ((ctxt, tx_rollup), level)
    counter
    hash
  >|=? fun (ctxt, _, _) -> ctxt

let check_prerejection :
    Raw_context.t ->
    source:Signature.Public_key_hash.t ->
    tx_rollup:Tx_rollup_repr.t ->
    level:Tx_rollup_level_repr.t ->
    message_position:int ->
    proof:Tx_rollup_l2_proof.t ->
    (Raw_context.t * int32) tzresult Lwt.t =
 fun ctxt ~source ~tx_rollup ~level ~message_position ~proof ->
  let prerejection_hash =
    Tx_rollup_rejection_repr.generate_prerejection
      ~source
      ~tx_rollup
      ~level
      ~message_position
      ~proof
  in
  Storage.Tx_rollup.Prerejection.find ctxt prerejection_hash
  >>=? fun (ctxt, prerejection) ->
  match prerejection with
  | Some (expected_rollup, priority)
    when Tx_rollup_repr.(expected_rollup = tx_rollup) ->
      return (ctxt, priority)
  | Some _ | None -> fail Rejection_without_prerejection

let update_accepted_prerejection :
    Raw_context.t ->
    source:Signature.Public_key_hash.t ->
    tx_rollup:Tx_rollup_repr.t ->
    level:Tx_rollup_level_repr.t ->
    commitment:Tx_rollup_commitment_repr.Hash.t ->
    commitment_exists:bool ->
    proof:Tx_rollup_l2_proof.t ->
    priority:int32 ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt
     ~source
     ~tx_rollup
     ~level
     ~commitment
     ~commitment_exists
     ~proof
     ~priority ->
  (Storage.Tx_rollup.Accepted_prerejections.find
     ((ctxt, tx_rollup), level)
     commitment
   >>=? function
   | (ctxt, None) ->
       (* The commitment doesn't exist, it wasn't previously rejected.  So the
          commitment never existed, and this rejection is invalid. *)
       fail_unless commitment_exists Rejection_for_nonexistent_commitment
       >>=? fun () -> return (ctxt, Int32.max_int, proof)
   | (ctxt, Some old) -> return (ctxt, old.priority, old.proof))
  >>=? fun (ctxt, old_priority, old_proof) ->
  fail_unless Tx_rollup_l2_proof.(old_proof = proof) Proof_failed_to_reject
  >>=? fun () ->
  if Compare.Int32.(old_priority <= priority) then return ctxt
  else
    let new_prerejection : Tx_rollup_rejection_repr.prerejection =
      {hash = commitment; contract = source; priority; proof}
    in
    Storage.Tx_rollup.Accepted_prerejections.add
      ((ctxt, tx_rollup), level)
      commitment
      new_prerejection
    >>=? fun (ctxt, _, _) -> return ctxt

let finalize_prerejections ctxt tx_rollup level =
  (* Find all of the accepted prerejections for this level *)
  Storage.Tx_rollup.Accepted_prerejections.list_values ((ctxt, tx_rollup), level)
  >>=? fun (ctxt, accepted_prerejections) ->
  let to_reward =
    List.map
      (fun (accepted : Tx_rollup_rejection_repr.prerejection) ->
        accepted.contract)
      accepted_prerejections
  in
  (* Remove them *)
  List.fold_left_es
    (fun ctxt (accepted : Tx_rollup_rejection_repr.prerejection) ->
      Storage.Tx_rollup.Accepted_prerejections.remove
        ((ctxt, tx_rollup), level)
        accepted.hash
      >|=? fun (ctxt, _, _) -> ctxt)
    ctxt
    accepted_prerejections
  >>=? fun ctxt ->
  (* Now, find all of the prerejections submitted for this level *)
  Storage.Tx_rollup.Prerejections_by_index.list_values ((ctxt, tx_rollup), level)
  >>=? fun (ctxt, prerejections) ->
  List.fold_left_es
    (fun ctxt prerejection ->
      Storage.Tx_rollup.Prerejection.get ctxt prerejection
      >>=? fun (ctxt, (_, index)) ->
      (* Remove the prerejection from both tables *)
      Storage.Tx_rollup.Prerejection.remove ctxt prerejection
      >>=? fun (ctxt, _, _) ->
      Storage.Tx_rollup.Prerejections_by_index.remove
        ((ctxt, tx_rollup), level)
        index
      >|=? fun (ctxt, _, _) -> ctxt)
    ctxt
    prerejections
  >|=? fun ctxt -> (ctxt, to_reward)
