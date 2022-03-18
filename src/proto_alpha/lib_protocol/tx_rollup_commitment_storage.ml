(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

let just_ctxt (ctxt, _, _) = ctxt

open Tx_rollup_commitment_repr
open Tx_rollup_errors_repr

let adjust_unfinalized_commitments_count ctxt tx_rollup pkh
    ~(dir : [`Incr | `Decr]) =
  let delta = match dir with `Incr -> 1 | `Decr -> -1 in
  let bond_key = (tx_rollup, pkh) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key
  >>=? fun (ctxt, commitment) ->
  let count =
    match commitment with Some count -> count + delta | None -> delta
  in
  fail_when Compare.Int.(count < 0) (Commitment_bond_negative count)
  >>=? fun () ->
  Storage.Tx_rollup.Commitment_bond.add ctxt bond_key count >|=? just_ctxt

let remove_bond :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Signature.public_key_hash ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup contract ->
  let bond_key = (tx_rollup, contract) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key >>=? fun (ctxt, bond) ->
  match bond with
  | None -> fail (Bond_does_not_exist contract)
  | Some 0 ->
      Storage.Tx_rollup.Commitment_bond.remove ctxt bond_key >|=? just_ctxt
  | Some _ -> fail (Bond_in_use contract)

let slash_bond ctxt tx_rollup contract =
  let bond_key = (tx_rollup, contract) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key
  >>=? fun (ctxt, bond_counter) ->
  match bond_counter with
  | None -> return (ctxt, false)
  | Some c ->
      Storage.Tx_rollup.Commitment_bond.remove ctxt bond_key
      >|=? fun (ctxt, _, _) -> (ctxt, Compare.Int.(0 < c))

let find :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_level_repr.t ->
    (Raw_context.t * Tx_rollup_commitment_repr.Submitted_commitment.t option)
    tzresult
    Lwt.t =
 fun ctxt tx_rollup level ->
  Storage.Tx_rollup.Commitment.find ctxt (level, tx_rollup)
  >>=? fun (ctxt, commitment) ->
  match commitment with
  | None ->
      Tx_rollup_state_storage.assert_exist ctxt tx_rollup >>=? fun ctxt ->
      return (ctxt, None)
  | Some res -> return (ctxt, Some res)

let get :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_level_repr.t ->
    (Raw_context.t * Tx_rollup_commitment_repr.Submitted_commitment.t) tzresult
    Lwt.t =
 fun ctxt tx_rollup level ->
  find ctxt tx_rollup level >>=? fun (ctxt, commitment) ->
  match commitment with
  (* TODO: why not use directly `.get` and get the default error for a missing key ? *)
  | None -> fail @@ Tx_rollup_errors_repr.Commitment_does_not_exist level
  | Some commitment -> return (ctxt, commitment)

let get_finalized :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Tx_rollup_level_repr.t ->
    (Raw_context.t * Tx_rollup_commitment_repr.Submitted_commitment.t) tzresult
    Lwt.t =
 fun ctxt tx_rollup level ->
  Tx_rollup_state_storage.assert_exist ctxt tx_rollup >>=? fun ctxt ->
  Storage.Tx_rollup.State.get ctxt tx_rollup >>=? fun (ctxt, state) ->
  let window = Tx_rollup_state_repr.finalized_commitments_range state in
  (match window with
  | Some (first, last) ->
      error_unless
        Tx_rollup_level_repr.(first <= level && level <= last)
        (Tx_rollup_errors_repr.No_finalized_commitment_for_level {level; window})
  | None ->
      error
        (Tx_rollup_errors_repr.No_finalized_commitment_for_level {level; window}))
  >>?= fun () ->
  Storage.Tx_rollup.Commitment.find ctxt (level, tx_rollup)
  >>=? fun (ctxt, commitment) ->
  match commitment with
  | None -> fail @@ Tx_rollup_errors_repr.Commitment_does_not_exist level
  | Some commitment -> return (ctxt, commitment)

let check_commitment_level state commitment =
  Tx_rollup_state_repr.next_commitment_level state >>? fun expected_level ->
  error_when
    Tx_rollup_level_repr.(commitment.level < expected_level)
    (Level_already_has_commitment commitment.level)
  >>? fun () ->
  error_when
    Tx_rollup_level_repr.(expected_level < commitment.level)
    (Commitment_too_early
       {provided = commitment.level; expected = expected_level})

(** [check_commitment_predecessor ctxt tx_rollup state commitment]
    will raise an error if the [predecessor] field of [commitment] is
    not consistent with the context, assuming its [level] field is
    correct. *)
let check_commitment_predecessor ctxt state commitment =
  match
    ( commitment.predecessor,
      Tx_rollup_state_repr.next_commitment_predecessor state )
  with
  | (Some pred_hash, Some expected_hash)
    when Commitment_hash.(pred_hash = expected_hash) ->
      return ctxt
  | (None, None) -> return ctxt
  | (provided, expected) -> fail (Wrong_predecessor_hash {provided; expected})

let check_commitment_batches_and_inbox_hash ctxt tx_rollup commitment =
  Tx_rollup_inbox_storage.get_metadata ctxt commitment.level tx_rollup
  >>=? fun (ctxt, {inbox_length; hash; _}) ->
  fail_unless
    Compare.List_length_with.(commitment.messages = Int32.to_int inbox_length)
    Wrong_batch_count
  >>=? fun () ->
  fail_unless
    (Tx_rollup_inbox_repr.equal_hash commitment.inbox_hash hash)
    Wrong_inbox_hash
  >>=? fun () -> return ctxt

let add_commitment ctxt tx_rollup state pkh commitment =
  let commitment_limit =
    Constants_storage.tx_rollup_max_finalized_levels ctxt
  in
  fail_when
    Compare.Int.(
      Tx_rollup_state_repr.finalized_commitments_count state >= commitment_limit)
    Too_many_finalized_commitments
  >>=? fun () ->
  (* Check the commitment has the correct values *)
  check_commitment_level state commitment >>?= fun () ->
  check_commitment_predecessor ctxt state commitment >>=? fun ctxt ->
  check_commitment_batches_and_inbox_hash ctxt tx_rollup commitment
  >>=? fun ctxt ->
  (* Everything has been sorted out, let’s update the storage *)
  let current_level = (Raw_context.current_level ctxt).level in
  let commitment_hash = Tx_rollup_commitment_repr.hash commitment in
  let submitted : Tx_rollup_commitment_repr.Submitted_commitment.t =
    {
      commitment;
      commitment_hash;
      committer = pkh;
      submitted_at = current_level;
      finalized_at = None;
    }
  in
  Storage.Tx_rollup.Commitment.add ctxt (commitment.level, tx_rollup) submitted
  >>=? fun (ctxt, _, _) ->
  Tx_rollup_state_repr.record_commitment_creation
    state
    commitment.level
    commitment_hash
  >>?= fun state ->
  adjust_unfinalized_commitments_count ctxt tx_rollup pkh ~dir:`Incr
  >>=? fun ctxt -> return (ctxt, state)

let pending_bonded_commitments :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Signature.public_key_hash ->
    (Raw_context.t * int) tzresult Lwt.t =
 fun ctxt tx_rollup pkh ->
  Storage.Tx_rollup.Commitment_bond.find ctxt (tx_rollup, pkh)
  >|=? fun (ctxt, pending) -> (ctxt, Option.value ~default:0 pending)

let has_bond :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Signature.public_key_hash ->
    (Raw_context.t * bool) tzresult Lwt.t =
 fun ctxt tx_rollup pkh ->
  Storage.Tx_rollup.Commitment_bond.find ctxt (tx_rollup, pkh)
  >|=? fun (ctxt, pending) -> (ctxt, Option.is_some pending)

let finalize_commitment ctxt rollup state =
  match Tx_rollup_state_repr.next_commitment_to_finalize state with
  | Some oldest_inbox_level ->
      (* Since the commitment head is not null, we know the oldest
         inbox has a commitment. *)
      get ctxt rollup oldest_inbox_level >>=? fun (ctxt, commitment) ->
      (* Is the finality period for this commitment over? *)
      let finality_period = Constants_storage.tx_rollup_finality_period ctxt in
      let current_level = (Raw_context.current_level ctxt).level in
      fail_when
        Raw_level_repr.(
          current_level < add commitment.submitted_at finality_period)
        No_commitment_to_finalize
      >>=? fun () ->
      (* Decrement the bond count of the committer *)
      adjust_unfinalized_commitments_count
        ctxt
        rollup
        commitment.committer
        ~dir:`Decr
      >>=? fun ctxt ->
      (* We remove the inbox *)
      Tx_rollup_inbox_storage.remove ctxt oldest_inbox_level rollup
      >>=? fun ctxt ->
      (* We update the commitment to mark it as finalized *)
      Storage.Tx_rollup.Commitment.update
        ctxt
        (oldest_inbox_level, rollup)
        {commitment with finalized_at = Some current_level}
      >>=? fun (ctxt, _) ->
      (* We update the state *)
      Tx_rollup_state_repr.record_inbox_deletion state oldest_inbox_level
      >>?= fun state -> return (ctxt, state, oldest_inbox_level)
  | None -> fail No_commitment_to_finalize

let remove_commitment ctxt rollup state =
  match Tx_rollup_state_repr.next_commitment_to_remove state with
  | Some tail ->
      (* We check the commitment is old enough *)
      get ctxt rollup tail >>=? fun (ctxt, commitment) ->
      (match commitment.finalized_at with
      | Some finalized_at ->
          let withdraw_period =
            Constants_storage.tx_rollup_withdraw_period ctxt
          in
          let current_level = (Raw_context.current_level ctxt).level in
          fail_when
            Raw_level_repr.(current_level < add finalized_at withdraw_period)
            (* FIXME dedicated error *)
            No_commitment_to_remove
      | None ->
          (* unreachable code if the implementation is correct *)
          fail (Internal_error "Missing finalized_at field"))
      >>=? fun () ->
      (* We remove the commitment *)
      Storage.Tx_rollup.Commitment.remove ctxt (tail, rollup)
      >>=? fun (ctxt, _freed_size, _existed) ->
      let inbox_length =
        (* safe because inbox cannot be more than int32 *)
        Int32.of_int @@ List.length commitment.commitment.messages
      in
      Tx_rollup_withdraw_storage.remove ctxt rollup tail ~inbox_length
      >>=? fun ctxt ->
      (* We update the state *)
      (match List.last_opt commitment.commitment.messages with
      | Some hash -> ok hash
      | None ->
          error (Internal_error "empty commitments should not be possible"))
      >>?= fun msg_hash ->
      Tx_rollup_state_repr.record_commitment_deletion
        state
        tail
        commitment.commitment_hash
        msg_hash
      >>?= fun state -> return (ctxt, state, tail)
  | None -> fail No_commitment_to_remove

let get_nth_commitment commitment message_position =
  let level = commitment.level in
  Option.value_e
    ~error:
      (Error_monad.trace_of_error
         (Wrong_message_position
            {
              level;
              position = message_position;
              length = List.length commitment.messages;
            }))
    (List.nth_opt commitment.messages message_position)

let get_before_and_after_results ctxt tx_rollup
    (submitted_commitment : Submitted_commitment.t) ~message_position state =
  let commitment = submitted_commitment.commitment in
  get_nth_commitment commitment message_position >>?= fun after_hash ->
  let level = commitment.level in
  if Compare.Int.(message_position = 0) then
    match Tx_rollup_level_repr.pred level with
    | None ->
        return
          ( ctxt,
            Tx_rollup_commitment_repr.initial_message_result_hash,
            after_hash )
    | Some pred_level -> (
        Storage.Tx_rollup.Commitment.find ctxt (pred_level, tx_rollup)
        >>=? function
        | (ctxt, None) -> (
            (* In this case, the predecessor commitment is not stored.  We need to
               check a bunch of things to ensure that the last removed commitment
               is a valid predecessor.
            *)
            fail_unless
              (Option.is_none
                 (Tx_rollup_state_repr.finalized_commitment_oldest_level state))
              (Internal_error "Missing commitment predecessor")
            >>=? fun () ->
            match Tx_rollup_state_repr.last_removed_commitment_hashes state with
            | None -> fail (Internal_error "Missing last removed commitment")
            | Some (message_commitment, commitment_hash) ->
                Option.value_e
                  ~error:
                    (Error_monad.trace_of_error
                       (Internal_error
                          "Non-initial commitment has empty predecessor"))
                  commitment.predecessor
                >>?= fun predecessor_commitment_hash ->
                fail_unless
                  (Commitment_hash.( = )
                     predecessor_commitment_hash
                     commitment_hash)
                  (Internal_error
                     "Last removed commitment has wrong predecessor hash")
                >>=? fun () -> return (ctxt, message_commitment, after_hash))
        | (ctxt, Some {commitment = {messages; _}; _}) ->
            Option.value_e
              ~error:
                (Error_monad.trace_of_error (Internal_error "Empty commitment"))
              (List.last_opt messages)
            >>?= fun message_result -> return (ctxt, message_result, after_hash)
        )
  else
    Storage.Tx_rollup.Commitment.get ctxt (level, tx_rollup)
    >>=? fun (ctxt, submitted_commitment) ->
    let commitment = submitted_commitment.commitment in
    get_nth_commitment commitment (message_position - 1) >>?= fun before_hash ->
    return (ctxt, before_hash, after_hash)

let reject_commitment ctxt rollup state level =
  Tx_rollup_state_repr.check_level_can_be_rejected state level >>?= fun () ->
  (* Fetching the next predecessor hash to be used *)
  (match Tx_rollup_level_repr.pred level with
  | Some pred_level ->
      find ctxt rollup pred_level >>=? fun (ctxt, pred_commitment) ->
      let pred_hash =
        Option.map
          (fun (x : Submitted_commitment.t) ->
            Tx_rollup_commitment_repr.hash x.commitment)
          pred_commitment
      in
      return (ctxt, pred_hash)
  | None -> return (ctxt, None))
  (* We record in the state *)
  >>=? fun (ctxt, pred_hash) ->
  Tx_rollup_state_repr.record_commitment_rejection state level pred_hash
  >>?= fun state -> return (ctxt, state)
