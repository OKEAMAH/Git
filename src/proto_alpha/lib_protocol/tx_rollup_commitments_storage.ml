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

(** Return commitments in the order that they were submitted *)
let get_or_empty_commitments :
    Raw_context.t ->
    Raw_level_repr.t * Tx_rollup_repr.t ->
    (Raw_context.t * Tx_rollup_commitments_repr.t) tzresult Lwt.t =
 fun ctxt key ->
  Storage.Tx_rollup.Commitment_list.find ctxt key >|=? fun (ctxt, commitment) ->
  Option.fold
    commitment
    ~none:(ctxt, Tx_rollup_commitments_repr.empty)
    ~some:(fun l -> (ctxt, List.rev l))

let get_next_level ctxt tx_rollup level =
  Tx_rollup_inbox_storage.get_adjacent_levels ctxt level tx_rollup
  >|=? fun (ctxt, _, next_level) -> (ctxt, next_level)

let get_prev_level ctxt tx_rollup level =
  Tx_rollup_inbox_storage.get_adjacent_levels ctxt level tx_rollup
  >|=? fun (ctxt, predecessor_level, _) -> (ctxt, predecessor_level)

(* This indicates a programming error. *)
type error += (*`Temporary*) Commitment_bond_negative of int

let adjust_commitment_bond ctxt tx_rollup pkh delta =
  let bond_key = (tx_rollup, pkh) in
  Storage.Tx_rollup.Commitment_bond.find ctxt bond_key
  >>=? fun (ctxt, commitment) ->
  let count =
    match commitment with Some count -> count + delta | None -> delta
  in
  fail_when Compare.Int.(count < 0) (Commitment_bond_negative count)
  >>=? fun () ->
  Storage.Tx_rollup.Commitment_bond.add ctxt bond_key count >|=? just_ctxt

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

let add_commitment ctxt tx_rollup pkh (commitment : Commitment.t) =
  let key = (commitment.level, tx_rollup) in
  get_or_empty_commitments ctxt key >>=? fun (ctxt, pending) ->
  Tx_rollup_inbox_storage.get_metadata ctxt commitment.level tx_rollup
  >>=? fun (ctxt, {count; hash; _}) ->
  let actual_len = List.length commitment.batches in
  fail_unless Compare.Int.(count = actual_len) Wrong_batch_count >>=? fun () ->
  fail_unless
    Compare.Int.(
      0 = Tx_rollup_inbox_repr.Hash.compare commitment.inbox_hash hash)
    Wrong_inbox_hash
  >>=? fun () ->
  check_commitment_predecessor_hash ctxt tx_rollup commitment >>=? fun ctxt ->
  Tx_rollup_commitments_repr.append
    pending
    pkh
    commitment
    (Raw_context.current_level ctxt).level
  >>?= fun new_pending ->
  Storage.Tx_rollup.Commitment_list.add ctxt key new_pending
  >>=? fun (ctxt, _, _) -> adjust_commitment_bond ctxt tx_rollup pkh 1

module Commitment_set = Set.Make (Commitment_hash)

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
        let pending = List.rev pending in
        let next_commitments =
          List.fold_left
            (fun next_commitments {commitment; hash; _} ->
              if
                Option.fold
                  ~none:false
                  ~some:(fun predecessor ->
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
              adjust_commitment_bond ctxt tx_rollup committer (-1))
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

let retire_rollup_level :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    Raw_context.t tzresult Lwt.t =
 fun ctxt tx_rollup level ->
  let top = (Raw_context.current_level ctxt).level in
  let key = (level, tx_rollup) in
  get_or_empty_commitments ctxt key >>=? fun (ctxt, commitments) ->
  match commitments with
  | [] -> fail (Retire_uncommitted_level level)
  | accepted :: rejected ->
      let to_obviate =
        Commitment_set.of_seq
          (Seq.map (fun {hash; _} -> hash) (List.to_seq rejected))
      in
      remove_successors ctxt tx_rollup level top to_obviate >>=? fun ctxt ->
      adjust_commitment_bond ctxt tx_rollup accepted.committer (-1)
      >>=? fun ctxt ->
      Storage.Tx_rollup.Commitment_list.add ctxt key [accepted] >|=? just_ctxt

let get_commitments :
    Raw_context.t ->
    Tx_rollup_repr.t ->
    Raw_level_repr.t ->
    (Raw_context.t * Tx_rollup_commitments_repr.t) tzresult Lwt.t =
 fun ctxt tx_rollup level ->
  Storage.Tx_rollup.State.find ctxt tx_rollup >>=? fun (ctxt, state) ->
  match state with
  | None -> fail @@ Tx_rollup_state_storage.Tx_rollup_does_not_exist tx_rollup
  | Some _ -> get_or_empty_commitments ctxt (level, tx_rollup)

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
