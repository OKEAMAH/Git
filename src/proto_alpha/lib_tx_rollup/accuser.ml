(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol
open Alpha_context

type error += Tx_rollup_missing_block of L2block.hash

let () =
  register_error_kind
    ~id:"tx_rollup.node.missing_block"
    ~title:"A block cannot be found"
    ~description:"An L2 block cannot be found."
    ~pp:(fun ppf b ->
      Format.fprintf ppf "The L2 block %a cannot be found." L2block.Hash.pp b)
    `Permanent
    Data_encoding.(obj1 (req "block" L2block.Hash.encoding))
    (function Tx_rollup_missing_block b -> Some b | _ -> None)
    (fun b -> Tx_rollup_missing_block b)

let eq_merkle_roots r1 r2 =
  let mekle_root_to_bytes r =
    Data_encoding.Binary.to_bytes_exn Tx_rollup_inbox.Merkle.root_encoding r
  in
  let r1 = mekle_root_to_bytes r1 in
  let r2 = mekle_root_to_bytes r2 in
  Bytes.equal r1 r2

(* TODO/TORU: https://gitlab.com/tezos/tezos/-/issues/2925
   Strengthen accuser *)
let rejectable_commitment (state : State.t)
    (commitment : Tx_rollup_commitment.Full.t) =
  let open Lwt_result_syntax in
  let*! finalized_level = State.get_finalized_level state in
  match finalized_level with
  | Some finalized_level
    when Tx_rollup_level.(commitment.level <= finalized_level) ->
      (* This commitment is already finalized, nothing we can do anyway. *)
      let*! () =
        Event.(emit Accuser.bad_finalized_commitment) commitment.level
      in
      return `Don't_reject
  | _ -> (
      let*! block =
        State.get_level_l2_block state (L2block.Rollup_level commitment.level)
      in
      match block with
      | None ->
          (* Should not happen. We have no block for that level, so we cannot
             know if the commitment is bad. *)
          let*! () = Debug_events.(emit should_not_happen) __LOC__ in
          tzfail (Error.Tx_rollup_internal __LOC__)
      | Some block -> (
          let our_commitment =
            WithExceptions.Option.get ~loc:__LOC__ block.commitment
          in
          let* () =
            if
              eq_merkle_roots
                commitment.inbox_merkle_root
                our_commitment.inbox_merkle_root
            then return_unit
            else
              let*! () =
                Event.(emit Accuser.inbox_merkle_root_mismatch)
                  ( commitment.inbox_merkle_root,
                    our_commitment.inbox_merkle_root )
              in
              tzfail (Error.Tx_rollup_internal __LOC__)
          in
          if
            not
            @@ Option.equal
                 Tx_rollup_commitment_hash.equal
                 commitment.predecessor
                 our_commitment.predecessor
          then
            (* Commitments have different predecessors, we cannot construct
               rejection. This means that the commitment is on top of a bad
               commitment so it will be slashed automatically. *)
            let*! () =
              Event.(emit Accuser.commitment_predecessor_mismatch)
                (commitment.predecessor, our_commitment.predecessor)
            in
            return `Don't_reject
          else
            match
              List.fold_left2_e
                ~when_different_lengths:None
                (fun position m1 m2 ->
                  if Tx_rollup_message_result_hash.(m1 = m2) then
                    Ok (position + 1)
                  else
                    let path =
                      let open Tx_rollup_commitment.Merkle in
                      let tree = List.fold_left snoc nil commitment.messages in
                      compute_path tree position
                    in
                    Error (Some (position, m1, path)))
                0
                commitment.messages
                our_commitment.messages
            with
            | Ok _ -> return `Don't_reject
            | Error None ->
                (* Should not happen if the inboxes are the same *)
                let*! () = Debug_events.(emit should_not_happen) __LOC__ in
                tzfail (Error.Tx_rollup_internal __LOC__)
            | Error (Some (position, message_result, message_path)) ->
                (* We found a bad commitment *)
                let*! () =
                  Event.(emit Accuser.bad_commitment)
                    (commitment.level, position)
                in
                return (`Reject (position, message_result, message_path, block))
          ))

let reject_bad_commitment ~source (state : State.t)
    (commitment : Tx_rollup_commitment.Full.t) =
  let open Lwt_result_syntax in
  let* rejectable = rejectable_commitment state commitment in
  match rejectable with
  | `Don't_reject -> return_unit
  | `Reject (position, message_result_hash, message_result_path, block) ->
      (* This commitment is bad, because of message result at [position], we
         should inject a rejection *)
      let*? message_result_path =
        Environment.wrap_tzresult @@ message_result_path
      in
      let* ( previous_message_result,
             previous_message_result_path,
             previous_context ) =
        if position = 0 && Tx_rollup_level.(commitment.level = root) then
          (* Rejecting first message of first level, no predecessor *)
          let*! context = Context.init_context state.context_index in
          return
            ( Tx_rollup_message_result.init,
              Tx_rollup_commitment.Merkle.dummy_path,
              context )
        else
          let* (inbox_of_previous_message, previous_message_position) =
            match position with
            | 0 ->
                let*! predecessor =
                  State.get_block state block.header.predecessor
                in
                let*? predecessor =
                  Result.of_option
                    predecessor
                    ~error:[Tx_rollup_missing_block block.header.predecessor]
                in
                return
                  (predecessor.inbox, List.length predecessor.inbox.contents - 1)
            | _ -> return (block.inbox, position - 1)
          in
          let previous_message_results =
            Inbox.proto_message_results inbox_of_previous_message
          in
          let previous_message_results_hashes =
            List.map
              Tx_rollup_message_result_hash.hash_uncarbonated
              previous_message_results
          in
          let previous_message_result =
            WithExceptions.Option.get ~loc:__LOC__
            @@ List.nth previous_message_results previous_message_position
          in
          let*? previous_message_result_path =
            let open Tx_rollup_commitment.Merkle in
            let tree =
              List.fold_left snoc nil previous_message_results_hashes
            in
            Environment.wrap_tzresult
            @@ compute_path tree previous_message_position
          in
          let previous_message =
            WithExceptions.Option.get ~loc:__LOC__
            @@ List.nth
                 inbox_of_previous_message.contents
                 previous_message_position
          in
          let+ previous_context =
            Context.checkout
              state.context_index
              previous_message.l2_context_hash.irmin_hash
          in
          ( previous_message_result,
            previous_message_result_path,
            previous_context )
      in
      let inbox_message =
        WithExceptions.Option.get ~loc:__LOC__
        @@ List.nth block.inbox.contents position
      in
      let message = inbox_message.message in
      let message_hashes =
        List.map
          (fun Inbox.{message; _} ->
            Tx_rollup_message_hash.hash_uncarbonated message)
          block.inbox.contents
      in
      let*? message_path =
        Environment.wrap_tzresult
        @@ Tx_rollup_inbox.Merkle.compute_path message_hashes position
      in
      let l2_parameters =
        Protocol.Tx_rollup_l2_apply.
          {
            tx_rollup_max_withdrawals_per_batch =
              state.constants.parametric.tx_rollup_max_withdrawals_per_batch;
          }
      in
      let* (proof, _) =
        Prover_apply.apply_message previous_context l2_parameters message
      in
      let rejection_operation =
        Tx_rollup_rejection
          {
            tx_rollup = state.rollup_info.rollup_id;
            level = commitment.level;
            message;
            message_position = position;
            message_path;
            message_result_hash;
            message_result_path;
            previous_message_result;
            previous_message_result_path;
            proof;
          }
      in
      let manager_operation = L1_operation.make ~source rejection_operation in
      Injector.add_pending_operation manager_operation
