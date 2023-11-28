(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

open Alpha_context

(** Returns the proposal submitted by the most delegates.
    Returns None in case of a tie, if proposal quorum is below required
    minimum or if there are no proposals. *)
let select_winning_proposal ctxt =
  let open Lwt_result_syntax in
  let* proposals = Vote.get_proposals ctxt in
  let merge proposal vote winners =
    match winners with
    | None -> Some ([proposal], vote)
    | Some (winners, winners_vote) as previous ->
        if Uint63.(vote = winners_vote) then
          Some (proposal :: winners, winners_vote)
        else if Uint63.(vote > winners_vote) then Some ([proposal], vote)
        else previous
  in
  match Protocol_hash.Map.fold merge proposals None with
  | Some ([proposal], vote) ->
      let* max_vote = Vote.get_total_voting_power_free ctxt in
      let min_proposal_quorum = Constants.min_proposal_quorum ctxt in
      let min_vote_to_pass =
        Uint63.(
          mul_ratio
            ~rounding:`Down
            max_vote
            ~num:(min_proposal_quorum :> t)
            ~den:
              (Centile_of_percentage.Div_safe.one_hundred_percent :> Div_safe.t))
        |> Option.value ~default:Uint63.max_int
      in
      if Uint63.(vote >= min_vote_to_pass) then return_some proposal
      else return_none
  | _ -> return_none

(* in case of a tie, let's do nothing. *)

(** A proposal is approved if it has supermajority and the participation reaches
    the current quorum.
    Supermajority means the yays are more 8/10 of casted votes.
    The participation is the ratio of all received votes, including passes, with
    respect to the number of possible votes.
    The participation EMA (exponential moving average) uses the last
    participation EMA and the current participation./
    The expected quorum is calculated using the last participation EMA, capped
    by the min/max quorum protocol constants. *)
let approval_and_participation_ema (ballots : Vote.ballots) ~total_voting_power
    ~participation_ema ~expected_quorum =
  (* Note overflows: considering a maximum of 1e9 tokens (around 2^30),
     hence 1e15 mutez (around 2^50)
  *)
  let casted_votes = Uint63.With_exceptions.add ballots.yay ballots.nay in
  let all_votes = Uint63.With_exceptions.add casted_votes ballots.pass in
  let supermajority =
    Uint63.mul_percentage ~rounding:`Down casted_votes Int_percentage.p80
  in
  let participation =
    Centile_of_percentage.Saturating.of_ratio
      ~rounding:`Down
      ~num:all_votes
      ~den:total_voting_power
  in
  let approval =
    Centile_of_percentage.(participation >= expected_quorum)
    && Uint63.(ballots.yay >= supermajority)
  in
  let new_participation_ema =
    Centile_of_percentage.(
      average ~left_weight:eighty_percent participation_ema participation)
  in
  (approval, new_participation_ema)

let get_approval_and_update_participation_ema ctxt =
  let open Lwt_result_syntax in
  let* total_voting_power = Vote.get_total_voting_power_free ctxt in
  match Uint63.Div_safe.of_uint63 total_voting_power with
  | None -> return (ctxt, false)
  | Some total_voting_power ->
      let* ballots = Vote.get_ballots ctxt in
      let* participation_ema = Vote.get_participation_ema ctxt in
      let* expected_quorum = Vote.get_current_quorum ctxt in
      let*! ctxt = Vote.clear_ballots ctxt in
      let approval, new_participation_ema =
        approval_and_participation_ema
          ballots
          ~total_voting_power
          ~participation_ema
          ~expected_quorum
      in
      let+ ctxt = Vote.set_participation_ema ctxt new_participation_ema in
      (ctxt, approval)

(** Implements the state machine of the amendment procedure. Note that
   [update_listings], that computes the vote weight of each delegate, is run at
   the end of each voting period. This state-machine prepare the voting_period
   for the next block. *)
let start_new_voting_period ctxt =
  (* any change related to the storage in this function must probably
     be replicated in `record_testnet_dictator_proposals` *)
  let open Lwt_result_syntax in
  let* kind = Voting_period.get_current_kind ctxt in
  let* ctxt =
    match kind with
    | Proposal -> (
        let* proposal = select_winning_proposal ctxt in
        let*! ctxt = Vote.clear_proposals ctxt in
        match proposal with
        | None -> Voting_period.reset ctxt
        | Some proposal ->
            let* ctxt = Vote.init_current_proposal ctxt proposal in
            Voting_period.succ ctxt)
    | Exploration ->
        let* ctxt, approved = get_approval_and_update_participation_ema ctxt in
        if approved then Voting_period.succ ctxt
        else
          let*! ctxt = Vote.clear_current_proposal ctxt in
          Voting_period.reset ctxt
    | Cooldown -> Voting_period.succ ctxt
    | Promotion ->
        let* ctxt, approved = get_approval_and_update_participation_ema ctxt in
        if approved then Voting_period.succ ctxt
        else
          let*! ctxt = Vote.clear_current_proposal ctxt in
          Voting_period.reset ctxt
    | Adoption ->
        let* proposal = Vote.get_current_proposal ctxt in
        let*! ctxt = activate ctxt proposal in
        let*! ctxt = Vote.clear_current_proposal ctxt in
        Voting_period.reset ctxt
  in
  Vote.update_listings ctxt

let may_start_new_voting_period ctxt =
  let open Lwt_result_syntax in
  let* is_last = Voting_period.is_last_block ctxt in
  if is_last then start_new_voting_period ctxt else return ctxt

(** {2 Application of voting operations} *)

let get_testnet_dictator ctxt chain_id =
  (* This function should always, ALWAYS, return None on mainnet!!!! *)
  match Constants.testnet_dictator ctxt with
  | Some pkh when Chain_id.(chain_id <> Constants.mainnet_id) -> Some pkh
  | _ -> None

let is_testnet_dictator ctxt chain_id delegate =
  (* This function should always, ALWAYS, return false on mainnet!!!! *)
  match get_testnet_dictator ctxt chain_id with
  | Some pkh -> Signature.Public_key_hash.equal pkh delegate
  | _ -> false

(** Apply a [Proposals] operation from a registered dictator of a test
    chain. This forcibly updates the voting period, changing the
    current voting period kind and the current proposal if
    applicable. Of course, there must never be such a dictator on
    mainnet: see {!is_testnet_dictator}. *)
let apply_testnet_dictator_proposals ctxt chain_id proposals =
  let open Lwt_result_syntax in
  let*! ctxt = Vote.clear_ballots ctxt in
  let*! ctxt = Vote.clear_proposals ctxt in
  let*! ctxt = Vote.clear_current_proposal ctxt in
  let ctxt = record_dictator_proposal_seen ctxt in
  match proposals with
  | [] ->
      Voting_period.Testnet_dictator.overwrite_current_kind
        ctxt
        chain_id
        Proposal
  | [proposal] ->
      let* ctxt = Vote.init_current_proposal ctxt proposal in
      Voting_period.Testnet_dictator.overwrite_current_kind
        ctxt
        chain_id
        Adoption
  | _ :: _ :: _ ->
      (* This case should not be possible if the operation has been
         previously validated by {!Validate.validate_operation}. *)
      tzfail Validate_errors.Voting.Testnet_dictator_multiple_proposals

let apply_proposals ctxt chain_id (Proposals {source; period = _; proposals}) =
  let open Lwt_result_syntax in
  let* ctxt =
    if is_testnet_dictator ctxt chain_id source then
      apply_testnet_dictator_proposals ctxt chain_id proposals
    else if dictator_proposal_seen ctxt then
      (* Noop if dictator voted *)
      return ctxt
    else
      let* count = Vote.get_delegate_proposal_count ctxt source in
      let new_count = count + List.length proposals in
      let*! ctxt = Vote.set_delegate_proposal_count ctxt source new_count in
      let*! ctxt =
        List.fold_left_s
          (fun ctxt proposal -> Vote.add_proposal ctxt source proposal)
          ctxt
          proposals
      in
      return ctxt
  in
  return (ctxt, Apply_results.Single_result Proposals_result)

let apply_ballot ctxt (Ballot {source; period = _; proposal = _; ballot}) =
  let open Lwt_result_syntax in
  let* ctxt =
    if dictator_proposal_seen ctxt then (* Noop if dictator voted *) return ctxt
    else Vote.record_ballot ctxt source ballot
  in
  return (ctxt, Apply_results.Single_result Ballot_result)
