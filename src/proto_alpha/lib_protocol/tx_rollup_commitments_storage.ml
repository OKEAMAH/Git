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

open Tx_rollup_commitments_repr

let get_or_empty_commitments :
    Raw_context.t ->
    Raw_level_repr.t * Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_commitments_repr.t) tzresult Lwt.t =
 fun ctxt key ->
  Storage.Tx_rollup.Commitment_list.find ctxt key >|=? fun (ctxt, commitment) ->
  Option.fold
    commitment
    ~none:(ctxt, Tx_rollup_commitments_repr.empty)
    ~some:(fun l -> (ctxt, l))

let get_next_level ctxt tx_rollup level =
  Tx_rollup_inbox_storage.get_adjacent_levels ctxt level tx_rollup
  >|=? fun (ctxt, _, next_level) -> (ctxt, next_level)

let get_prev_level ctxt tx_rollup level =
  Tx_rollup_inbox_storage.get_adjacent_levels ctxt level tx_rollup
  >|=? fun (ctxt, predecessor_level, _) -> (ctxt, predecessor_level)

let adjust_commitment_bond ctxt tx_rollup contract delta =
  let bond_key = (tx_rollup, contract) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key
  >>=? fun (ctxt, commitment) ->
  (match commitment with
  | Some count -> return (count + delta)
  | None -> return delta)
  >>=? fun count ->
  Storage.Tx_rollup.Commitment_bond.add ctxt bond_key count >|=? just_ctxt

let remove_bond :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Contract_repr.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup contract ->
  let bond_key = (tx_rollup, contract) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key >>=? fun (ctxt, bond) ->
  match bond with
  | None -> fail (Bond_does_not_exist contract)
  | Some 0 ->
      Storage.Tx_rollup.Commitment_bond.remove ctxt bond_key >|=? just_ctxt
  | Some _ -> fail (Bond_in_use contract)

let check_commitment_predecessor_hash ctxt tx_rollup (commitment : Commitment.t)
    =
  let level = commitment.level in
  (* Check that level has the correct predecessor *)
  get_prev_level ctxt tx_rollup level >>=? fun (ctxt, predecessor_level) ->
  match (predecessor_level, commitment.predecessor) with
  | (None, None) -> return ctxt
  | (Some _, None) | (None, Some _) -> fail Wrong_commitment_predecessor_level
  | (Some predecessor_level, Some hash) ->
      (* The predecessor level must include this commitment*)
      get_or_empty_commitments ctxt (predecessor_level, tx_rollup)
      >>=? fun (ctxt, predecesor_commitments) ->
      fail_unless
        (Tx_rollup_commitments_repr.commitment_exists
           predecesor_commitments
           hash)
        Missing_commitment_predecessor
      >>=? fun () -> return ctxt

let add_commitment ctxt tx_rollup contract (commitment : Commitment.t) =
  let key = (commitment.level, tx_rollup) in
  get_or_empty_commitments ctxt key >>=? fun (ctxt, pending) ->
  let hash = Commitment.hash commitment in
  (* We fail if this contract already has a commitment at this level,
     or if anyone has already made this commitment at this level; a
     bond entitles you to at most one commitment per level. *)
  fail_when (commitment_exists pending hash) Commitment_hash_already_submitted
  >>=? fun () ->
  fail_when
    (commitment_with_committer_exists pending contract)
    Two_commitments_from_one_committer
  >>=? fun () ->
  Tx_rollup_inbox_storage.get ctxt ~level:(`Level commitment.level) tx_rollup
  >>=? fun (ctxt, inbox) ->
  let expected_len = List.length inbox.contents in
  let actual_len = List.length commitment.batches in
  fail_unless Compare.Int.(expected_len = actual_len) Wrong_batch_count
  >>=? fun () ->
  check_commitment_predecessor_hash ctxt tx_rollup commitment >>=? fun ctxt ->
  let current_level = (Raw_context.current_level ctxt).level in
  let new_pending =
    Tx_rollup_commitments_repr.append pending contract commitment current_level
  in
  Storage.Tx_rollup.Commitment_list.add ctxt key new_pending
  >>=? fun (ctxt, _, _) -> adjust_commitment_bond ctxt tx_rollup contract 1

module Contract_set = Set.Make (Contract_repr)
module Commitment_set = Set.Make (Commitment_hash)

let rec accumulate_bad_commitments :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    Raw_level_repr.t ->
    Commitment_set.t ->
    Contract_set.t ->
    (Commitment_set.t * Contract_set.t) tzresult Lwt.t =
 fun ctxt tx_rollup level top commitments contracts ->
  let add_bad_commitments (commitments, contracts)
      {commitment; hash; committer; _} =
    if
      Option.value ~default:false
      @@ Option.map
           (fun predecessor -> Commitment_set.mem predecessor commitments)
           commitment.predecessor
      || Contract_set.mem committer contracts
    then
      (Commitment_set.add hash commitments, Contract_set.add committer contracts)
    else (commitments, contracts)
  in
  if Raw_level_repr.(level > top) then return (commitments, contracts)
  else
    let key = (level, tx_rollup) in
    Storage.Tx_rollup.Commitment_list.find ctxt key
    >>=? fun (ctxt, commitment_list) ->
    let pending =
      match commitment_list with None -> [] | Some pending -> pending
    in
    let (commitments, contracts) =
      List.fold_left add_bad_commitments (commitments, contracts) pending
    in
    get_next_level ctxt tx_rollup level >>=? fun (ctxt, next_level) ->
    match next_level with
    | None -> return (commitments, contracts)
    | Some next_level ->
        accumulate_bad_commitments
          ctxt
          tx_rollup
          next_level
          top
          commitments
          contracts

let rec remove_successors :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    Raw_level_repr.t ->
    Commitment_set.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup level top commitments ->
  if Raw_level_repr.(level > top) then return ctxt
  else
    let key = (level, tx_rollup) in
    get_next_level ctxt tx_rollup level >>=? fun (ctxt, next_level) ->
    Storage.Tx_rollup.Commitment_list.find ctxt key
    >>=? fun (ctxt, commitment_list) ->
    match commitment_list with
    | None -> (
        match next_level with
        | None -> return ctxt
        | Some next_level ->
            remove_successors ctxt tx_rollup next_level top commitments)
    | Some pending ->
        let next_commitments =
          List.fold_left
            (fun next_commitments {commitment; hash; _} ->
              if
                Option.value ~default:false
                @@ Option.map
                     (fun predecessor ->
                       Commitment_set.mem predecessor commitments)
                     commitment.predecessor
              then Commitment_set.add hash next_commitments
              else next_commitments)
            commitments
            pending
        in
        if not @@ Commitment_set.is_empty commitments then
          let (to_remove, new_pending) =
            List.partition
              (fun {hash; _} -> Commitment_set.mem hash next_commitments)
              pending
          in
          List.fold_left_es
            (fun ctxt {committer; _} ->
              adjust_commitment_bond ctxt tx_rollup committer 1)
            ctxt
            to_remove
          >>=? fun ctxt ->
          Storage.Tx_rollup.Commitment_list.add ctxt key new_pending
          >>=? fun (ctxt, _, _) ->
          match next_level with
          | None -> return ctxt
          | Some next_level ->
              remove_successors ctxt tx_rollup next_level top next_commitments
        else return ctxt

let rec remove_commitments_by_hash :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    Raw_level_repr.t ->
    Commitment_set.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup level top commitments ->
  if Raw_level_repr.(level > top) then return ctxt
  else
    let key = (level, tx_rollup) in
    Storage.Tx_rollup.Commitment_list.find ctxt key
    >>=? fun (ctxt, commitment_list) ->
    (match commitment_list with
    | None ->
        (* No commitments at this level -- just recurse *)
        return ctxt
    | Some pending ->
        let new_pending =
          List.filter
            (fun {hash; _} -> not @@ Commitment_set.mem hash commitments)
            pending
        in
        Storage.Tx_rollup.Commitment_list.add ctxt key new_pending
        >|=? just_ctxt)
    >>=? fun ctxt ->
    get_next_level ctxt tx_rollup level >>=? fun (ctxt, next_level) ->
    match next_level with
    | None -> return ctxt
    | Some next_level ->
        remove_commitments_by_hash ctxt tx_rollup next_level top commitments

let adjust_successful_prerejection ctxt tx_rollup level hash contract counter =
  Storage.Tx_rollup.Successful_prerejections.find
    ((ctxt, level), tx_rollup)
    hash
  >>=? fun (ctxt, existing) ->
  match existing with
  | None ->
      Storage.Tx_rollup.Successful_prerejections.add
        ((ctxt, level), tx_rollup)
        hash
        (counter, contract)
      >|=? just_ctxt
  | Some (old_counter, _) when Compare.Z.(old_counter > counter) ->
      Storage.Tx_rollup.Successful_prerejections.add
        ((ctxt, level), tx_rollup)
        hash
        (counter, contract)
      >|=? just_ctxt
  | Some _ -> return ctxt

let reject_commitment ctxt tx_rollup (level : Raw_level_repr.t)
    (commitment_id : Commitment_hash.t) (contract : Contract_repr.t)
    (counter : Z.t) =
  let top = (Raw_context.current_level ctxt).level in
  Storage.Tx_rollup.Commitment_list.get ctxt (level, tx_rollup)
  >>=? fun (ctxt, commitments) ->
  let matching_commitments =
    List.filter
      (fun {hash; _} -> Commitment_hash.(hash = commitment_id))
      commitments
  in
  match List.hd matching_commitments with
  | None ->
      (* This commit has already been rejected, but maybe this rejection
         corresponds to an earlier prerejection which needs to be credited. *)
      adjust_successful_prerejection
        ctxt
        tx_rollup
        level
        commitment_id
        contract
        counter
  | Some to_remove ->
      let initial_bad_commitments = Commitment_set.of_list [commitment_id] in
      let initial_evildoers = Contract_set.of_list [to_remove.committer] in
      let rec aux bad_commitments evildoers =
        accumulate_bad_commitments
          ctxt
          tx_rollup
          level
          top
          bad_commitments
          evildoers
        >>=? fun (new_bad_commitments, new_evildoers) ->
        if
          Compare.Int.(
            Contract_set.cardinal new_evildoers
            = Contract_set.cardinal evildoers
            && Commitment_set.cardinal new_bad_commitments
               = Commitment_set.cardinal bad_commitments)
        then return (new_bad_commitments, new_evildoers)
        else aux new_bad_commitments new_evildoers
      in
      aux initial_bad_commitments initial_evildoers
      >>=? fun (bad_commitments, evildoers) ->
      remove_commitments_by_hash ctxt tx_rollup level top bad_commitments
      >>=? fun ctxt ->
      Contract_set.fold_es
        (fun contract ctxt ->
          let key = (tx_rollup, contract) in
          Storage.Tx_rollup.Commitment_bond.remove ctxt key >|=? just_ctxt)
        evildoers
        ctxt
      >>=? fun ctxt ->
      adjust_successful_prerejection
        ctxt
        tx_rollup
        level
        commitment_id
        contract
        counter

let find_commitment_by_hash ctxt tx_rollup level hash =
  Storage.Tx_rollup.Commitment_list.get ctxt (level, tx_rollup)
  >|=? fun (ctxt, commitments) ->
  let pending_commitment =
    List.find
      (fun {commitment; _} ->
        Commitment_hash.(hash = Commitment.hash commitment))
      commitments
  in
  (ctxt, pending_commitment)

let get_commitment_roots ctxt tx_rollup (level : Raw_level_repr.t)
    (commitment_id : Commitment_hash.t) (index : int) =
  let find_commitment_or_die ctxt level commitment_id =
    find_commitment_by_hash ctxt tx_rollup level commitment_id
    >>=? fun (ctxt, maybe_pending) ->
    Option.map_es (fun pending -> return (ctxt, pending)) maybe_pending
    >>=? fun maybe_pending ->
    Lwt.return
    @@ Option.value_e
         ~error:(Error_monad.trace_of_error No_such_commitment)
         maybe_pending
  in
  find_commitment_or_die ctxt level commitment_id
  >>=? fun (ctxt, pending_commitment) ->
  let commitment = pending_commitment.commitment in
  let nth_root (commitment : Commitment.t) n =
    let nth = List.nth commitment.batches n in
    Option.value_e
      ~error:(Error_monad.trace_of_error (No_such_batch (level, index)))
      nth
  in
  (match index with
  | 0 -> (
      match commitment.predecessor with
      | None ->
          (* TODO: empty merkle tree when we have this*)
          let empty : Tx_rollup_commitments_repr.Commitment.batch_commitment =
            {root = Bytes.empty}
          in
          return (ctxt, empty)
      | Some prev_hash ->
          get_prev_level ctxt tx_rollup level >>=? fun (ctxt, prev_level) ->
          let prev_level =
            match prev_level with
            | None -> assert false
            | Some prev_level -> prev_level
          in
          find_commitment_or_die ctxt prev_level prev_hash
          >>=? fun (ctxt, {commitment = {batches; _}; _}) ->
          (let last = List.last_opt batches in
           Option.value_e
             ~error:(Error_monad.trace_of_error (No_such_batch (level, -1)))
             last)
          >>?= fun p -> return (ctxt, p))
  | index -> nth_root commitment (index - 1) >>?= fun p -> return (ctxt, p))
  >>=? fun (ctxt, before_hash) ->
  nth_root commitment index >>?= fun after_hash ->
  return (ctxt, (before_hash, after_hash))

let retire_rollup_level :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    Raw_level_repr.t ->
    (Raw_context.t * bool) tzresult Lwt.t =
 fun ctxt tx_rollup level last_level_to_finalize ->
  let top = (Raw_context.current_level ctxt).level in
  let key = (level, tx_rollup) in
  get_or_empty_commitments ctxt key >>=? fun (ctxt, commitments) ->
  let commitments = List.rev commitments in
  match commitments with
  | [] -> return (ctxt, false)
  | accepted :: rejected ->
      if Raw_level_repr.(accepted.submitted_at > last_level_to_finalize) then
        return (ctxt, false)
      else
        let to_reject =
          Commitment_set.of_seq
            (Seq.map (fun {hash; _} -> hash) (List.to_seq rejected))
        in
        remove_successors ctxt tx_rollup level top to_reject >>=? fun ctxt ->
        adjust_commitment_bond ctxt tx_rollup accepted.committer (-1)
        >>=? fun ctxt ->
        Storage.Tx_rollup.Commitment_list.add ctxt key [accepted]
        >>=? fun (ctxt, _, _) -> return (ctxt, true)

let get_commitments :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    (Raw_context.t * Tx_rollup_commitments_repr.t) tzresult Lwt.t =
 fun ctxt tx_rollup level ->
  Storage.Tx_rollup.State.find ctxt tx_rollup >>=? fun (ctxt, state) ->
  match state with
  | None -> fail @@ Tx_rollup_state_storage.Tx_rollup_does_not_exist tx_rollup
  | Some _ ->
      Storage.Tx_rollup.Commitment_list.get ctxt (level, tx_rollup)
      >|=? fun (ctxt, commitments) -> (ctxt, List.rev commitments)

let pending_bonded_commitments :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Contract_repr.t ->
    (Raw_context.t * int) tzresult Lwt.t =
 fun ctxt tx_rollup contract ->
  Storage.Tx_rollup.Commitment_bond.find ctxt (tx_rollup, contract)
  >|=? fun (ctxt, pending) -> (ctxt, Option.value ~default:0 pending)

let finalize_successful_prerejections ctxt tx_rollup level =
  Storage.Tx_rollup.Successful_prerejections.list_values
    ((ctxt, level), tx_rollup)
  >>=? fun (ctxt, values) ->
  (* TODO: clear this out -- we can't do that because there is no function
     which will give us the list of keys, nor one which will remove everything
     under a context. *)
  return (ctxt, List.to_seq @@ List.map snd values)

let finalize_pending_commitments ctxt tx_rollup =
  Tx_rollup_state_storage.get ctxt tx_rollup >>=? fun (ctxt, state) ->
  let first_unfinalized_level =
    Tx_rollup_state_repr.first_unfinalized_level state
  in
  match first_unfinalized_level with
  | None -> return (ctxt, [])
  | Some first_unfinalized_level ->
      let current_level = (Raw_context.current_level ctxt).level in
      let last_level_to_finalize =
        match Raw_level_repr.sub current_level 30 with
        | Some level -> level
        | None -> Raw_level_repr.root
      in
      let rec finalize_level ctxt level top count to_credit =
        if Raw_level_repr.(level > top) then
          return (ctxt, count, to_credit, Some level)
        else
          retire_rollup_level ctxt tx_rollup level last_level_to_finalize
          >>=? fun (ctxt, finalized) ->
          if not finalized then return (ctxt, 0, Seq.empty, Some level)
          else
            finalize_successful_prerejections ctxt tx_rollup level
            >>=? fun (ctxt, new_to_credit) ->
            let to_credit = Seq.append to_credit new_to_credit in
            get_next_level ctxt tx_rollup level >>=? fun (ctxt, next_level) ->
            match next_level with
            | None -> return (ctxt, count, to_credit, None)
            | Some next_level ->
                finalize_level ctxt next_level top (count + 1) to_credit
      in
      finalize_level
        ctxt
        first_unfinalized_level
        last_level_to_finalize
        0
        Seq.empty
      >>=? fun (ctxt, finalized_count, to_credit, first_unfinalized_level) ->
      let new_state =
        Tx_rollup_state_repr.update_after_finalize
          state
          first_unfinalized_level
          finalized_count
      in
      Storage.Tx_rollup.State.add ctxt tx_rollup new_state
      >>=? fun (ctxt, _, _) -> return (ctxt, List.of_seq to_credit)

let prereject :
    Raw_context.t ->
    Tx_rollup_rejection_repr.Rejection_hash.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt hash ->
  Storage.Tx_rollup.Prerejection.mem ctxt hash >>=? fun (ctxt, is_mem) ->
  fail_when is_mem Tx_rollup_rejection_repr.Duplicate_prerejection
  >>=? fun () ->
  (Storage.Tx_rollup.Prerejection_counter.find ctxt >>=? function
   | None ->
       Storage.Tx_rollup.Prerejection_counter.init ctxt Z.one >>=? fun ctxt ->
       return (ctxt, Z.zero)
   | Some counter ->
       Storage.Tx_rollup.Prerejection_counter.update ctxt (Z.succ counter)
       >>=? fun ctxt -> return (ctxt, counter))
  >>=? fun (ctxt, counter) ->
  Storage.Tx_rollup.Prerejection.add ctxt hash counter >|=? just_ctxt

let check_prerejection :
    Raw_context.t ->
    Tx_rollup_rejection_repr.t ->
    int64 ->
    Contract_repr.t ->
    (Raw_context.t * Z.t * bool) tzresult Lwt.t =
 fun ctxt {rollup; level; hash; batch_index; _} nonce source ->
  let prerejection_hash =
    Tx_rollup_rejection_repr.generate_prerejection
      ~nonce
      ~source
      ~rollup
      ~level
      ~commitment_hash:hash
      ~batch_index
  in
  Storage.Tx_rollup.Prerejection.find ctxt prerejection_hash
  >>=? fun (ctxt, priority) ->
  match priority with
  | None -> fail Tx_rollup_rejection_repr.Rejection_without_prerejection
  | Some priority ->
      find_commitment_by_hash ctxt rollup level hash
      >>=? fun (ctxt, maybe_commitment) ->
      return (ctxt, priority, Option.is_some maybe_commitment)
