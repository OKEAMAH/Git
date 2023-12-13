(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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
open Baking_state
module Events = Baking_events.Actions

module Operations_source = struct
  type error +=
    | Failed_operations_fetch of {
        path : string;
        reason : string;
        details : Data_encoding.json option;
      }

  let operations_encoding =
    Data_encoding.(
      list (dynamic_size Operation.encoding_with_legacy_attestation_name))

  let retrieve =
    let open Lwt_result_syntax in
    function
    | None -> Lwt.return_none
    | Some operations -> (
        Baking_profiler.record_s "retrieve external operations" @@ fun () ->
        let fail reason details =
          let path =
            match operations with
            | Baking_configuration.Operations_source.Local {filename} ->
                filename
            | Baking_configuration.Operations_source.Remote {uri; _} ->
                Uri.to_string uri
          in
          tzfail (Failed_operations_fetch {path; reason; details})
        in
        let decode_operations json =
          protect
            ~on_error:(fun _ ->
              fail "cannot decode the received JSON into operations" (Some json))
            (fun () ->
              return (Data_encoding.Json.destruct operations_encoding json))
        in
        match operations with
        | Baking_configuration.Operations_source.Local {filename} ->
            if Sys.file_exists filename then
              let*! result =
                Tezos_stdlib_unix.Lwt_utils_unix.Json.read_file filename
              in
              match result with
              | Error _ ->
                  let*! () = Events.(emit invalid_json_file filename) in
                  Lwt.return_none
              | Ok json -> (
                  let*! operations = decode_operations json in
                  match operations with
                  | Ok operations -> Lwt.return_some operations
                  | Error errs ->
                      let*! () = Events.(emit cannot_fetch_operations errs) in
                      Lwt.return_none)
            else
              let*! () = Events.(emit no_operations_found_in_file filename) in
              Lwt.return_none
        | Baking_configuration.Operations_source.Remote {uri; http_headers} -> (
            let*! operations_opt =
              let* result =
                with_timeout
                  (Systime_os.sleep (Time.System.Span.of_seconds_exn 5.))
                  (fun _ ->
                    Tezos_rpc_http_client_unix.RPC_client_unix
                    .generic_media_type_call
                      ~accept:[Media_type.json]
                      ?headers:http_headers
                      `GET
                      uri)
              in
              let* rest =
                match result with
                | `Json json -> return json
                | _ -> fail "json not returned" None
              in
              let* json =
                match rest with
                | `Ok json -> return json
                | `Unauthorized json -> fail "unauthorized request" json
                | `Gone json -> fail "gone" json
                | `Error json -> fail "error" json
                | `Not_found json -> fail "not found" json
                | `Forbidden json -> fail "forbidden" json
                | `Conflict json -> fail "conflict" json
              in
              decode_operations json
            in
            match operations_opt with
            | Ok operations -> Lwt.return_some operations
            | Error errs ->
                let*! () = Events.(emit cannot_fetch_operations errs) in
                Lwt.return_none))
end

type block_kind =
  | Fresh of Operation_pool.pool
  | Reproposal of {
      consensus_operations : packed_operation list;
      payload_hash : Block_payload_hash.t;
      payload_round : Round.t;
      payload : Operation_pool.payload;
    }

type block_to_bake = {
  predecessor : block_info;
  round : Round.t;
  delegate : Baking_state.consensus_key_and_delegate;
  kind : block_kind;
  force_apply : bool;
}

type inject_block_kind =
  | Forge_and_inject of block_to_bake
  | Inject_only of signed_block

type action =
  | Do_nothing
  | Inject_block of {kind : inject_block_kind; updated_state : state}
  | Forge_block of {block_to_bake : block_to_bake; updated_state : state}
  | Inject_preattestations of {
      preattestations : (consensus_key_and_delegate * consensus_content) list;
    }
  | Inject_attestations of {
      attestations : (consensus_key_and_delegate * consensus_content) list;
    }
  | Update_to_level of level_update
  | Synchronize_round of round_update
  | Watch_proposal

and level_update = {
  new_level_proposal : proposal;
  compute_new_state :
    current_round:Round.t ->
    delegate_slots:delegate_slots ->
    next_level_delegate_slots:delegate_slots ->
    (state * action) Lwt.t;
}

and round_update = {
  new_round_proposal : proposal;
  handle_proposal : state -> (state * action) Lwt.t;
}

type t = action

let pp_action fmt = function
  | Do_nothing -> Format.fprintf fmt "do nothing"
  | Inject_block {kind; _} -> (
      match kind with
      | Forge_and_inject _ -> Format.fprintf fmt "forge and inject block"
      | Inject_only _ -> Format.fprintf fmt "inject forged block")
  | Forge_block _ -> Format.fprintf fmt "forge_block"
  | Inject_preattestations _ -> Format.fprintf fmt "inject preattestations"
  | Inject_attestations _ -> Format.fprintf fmt "inject attestations"
  | Update_to_level _ -> Format.fprintf fmt "update to level"
  | Synchronize_round _ -> Format.fprintf fmt "synchronize round"
  | Watch_proposal -> Format.fprintf fmt "watch proposal"

let generate_seed_nonce_hash config delegate level =
  let open Lwt_result_syntax in
  if level.Level.expected_commitment then
    let* seed_nonce =
      Baking_nonces.generate_seed_nonce config delegate level.level
    in
    return_some seed_nonce
  else return_none

let sign_block_header state proposer unsigned_block_header =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let force = state.global_state.config.force in
  let {Block_header.shell; protocol_data = {contents; _}} =
    unsigned_block_header
  in
  let unsigned_header =
    Baking_profiler.record_f "serializing" @@ fun () ->
    Data_encoding.Binary.to_bytes_exn
      Alpha_context.Block_header.unsigned_encoding
      (shell, contents)
  in
  let level = shell.level in
  let*? round = Baking_state.round_of_shell_header shell in
  let open Baking_highwatermarks in
  Baking_profiler.record "waiting for lockfile" ;
  let* result =
    cctxt#with_lock (fun () ->
        Baking_profiler.stop () ;
        let block_location =
          Baking_files.resolve_location ~chain_id `Highwatermarks
        in
        let* may_sign =
          Baking_profiler.record_s "check highwatermark" @@ fun () ->
          may_sign_block
            cctxt
            block_location
            ~delegate:proposer.public_key_hash
            ~level
            ~round
        in
        match may_sign with
        | true ->
            let* () =
              Baking_profiler.record_s "record highwatermark" @@ fun () ->
              record_block
                cctxt
                block_location
                ~delegate:proposer.public_key_hash
                ~level
                ~round
            in
            return_true
        | false ->
            let*! () = Events.(emit potential_double_baking (level, round)) in
            return force)
  in
  match result with
  | false -> tzfail (Block_previously_baked {level; round})
  | true ->
      let* signature =
        Baking_profiler.record_s "signing block" @@ fun () ->
        Client_keys.sign
          cctxt
          proposer.secret_key_uri
          ~watermark:Block_header.(to_watermark (Block_header chain_id))
          unsigned_header
      in
      return {Block_header.shell; protocol_data = {contents; signature}}

let forge_signed_block ~state_recorder ~updated_state block_to_bake state =
  let open Lwt_result_syntax in
  let {
    predecessor;
    round;
    delegate = (consensus_key, _) as delegate;
    kind;
    force_apply;
  } =
    block_to_bake
  in
  let*! () =
    Events.(
      emit
        prepare_forging_block
        (Int32.succ predecessor.shell.level, round, delegate))
  in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let simulation_mode = state.global_state.validation_mode in
  let round_durations = state.global_state.round_durations in
  let*? timestamp =
    Baking_profiler.record_f "timestamp of round" @@ fun () ->
    Environment.wrap_tzresult
      (Round.timestamp_of_round
         round_durations
         ~predecessor_timestamp:predecessor.shell.timestamp
         ~predecessor_round:predecessor.round
         ~round)
  in
  let external_operation_source = state.global_state.config.extra_operations in
  let*! extern_ops = Operations_source.retrieve external_operation_source in
  let simulation_kind, payload_round =
    match kind with
    | Fresh pool ->
        let pool =
          let node_pool = Operation_pool.Prioritized.of_pool pool in
          match extern_ops with
          | None -> node_pool
          | Some ops ->
              Operation_pool.Prioritized.merge_external_operations node_pool ops
        in
        (Block_forge.Filter pool, round)
    | Reproposal {consensus_operations; payload_hash; payload_round; payload} ->
        ( Block_forge.Apply
            {
              ordered_pool =
                Operation_pool.ordered_pool_of_payload
                  ~consensus_operations
                  payload;
              payload_hash;
            },
          payload_round )
  in
  let*! () =
    Events.(
      emit forging_block (Int32.succ predecessor.shell.level, round, delegate))
  in
  let* injection_level =
    Baking_profiler.record_s "retrieve injection level" @@ fun () ->
    Plugin.RPC.current_level
      cctxt
      ~offset:1l
      (`Hash state.global_state.chain_id, `Hash (predecessor.hash, 0))
  in
  let* seed_nonce_opt =
    Baking_profiler.record_s "generate seed nonce" @@ fun () ->
    generate_seed_nonce_hash
      state.global_state.config.Baking_configuration.nonce
      consensus_key
      injection_level
  in
  let seed_nonce_hash = Option.map fst seed_nonce_opt in
  let user_activated_upgrades =
    state.global_state.config.user_activated_upgrades
  in
  (* Set liquidity_baking_toggle_vote for this block *)
  let {
    Baking_configuration.vote_file;
    liquidity_baking_vote;
    adaptive_issuance_vote;
  } =
    state.global_state.config.per_block_votes
  in
  (* Prioritize reading from the [vote_file] if it exists. *)
  let*! {liquidity_baking_vote; adaptive_issuance_vote} =
    let default =
      Protocol.Alpha_context.Per_block_votes.
        {liquidity_baking_vote; adaptive_issuance_vote}
    in
    match vote_file with
    | Some per_block_vote_file ->
        Per_block_vote_file.read_per_block_votes_no_fail
          ~default
          ~per_block_vote_file
    | None -> Lwt.return default
  in
  (* Cache last per-block votes to use in case of vote file errors *)
  let updated_state =
    {
      updated_state with
      global_state =
        {
          updated_state.global_state with
          config =
            {
              updated_state.global_state.config with
              per_block_votes =
                {
                  updated_state.global_state.config.per_block_votes with
                  liquidity_baking_vote;
                  adaptive_issuance_vote;
                };
            };
        };
    }
  in
  let*! () =
    Events.(emit vote_for_liquidity_baking_toggle) liquidity_baking_vote
  in
  let*! () = Events.(emit vote_for_adaptive_issuance) adaptive_issuance_vote in
  let chain = `Hash state.global_state.chain_id in
  let pred_block = `Hash (predecessor.hash, 0) in
  let* pred_resulting_context_hash =
    Baking_profiler.record_s "retrieve resulting context hash" @@ fun () ->
    Shell_services.Blocks.resulting_context_hash
      cctxt
      ~chain
      ~block:pred_block
      ()
  in
  let* pred_live_blocks =
    Baking_profiler.record_s "retrieve live blocks" @@ fun () ->
    Chain_services.Blocks.live_blocks cctxt ~chain ~block:pred_block ()
  in
  let* {unsigned_block_header; operations} =
    Block_forge.forge
      cctxt
      ~chain_id
      ~pred_info:predecessor
      ~pred_live_blocks
      ~pred_resulting_context_hash
      ~timestamp
      ~round
      ~seed_nonce_hash
      ~payload_round
      ~liquidity_baking_toggle_vote:liquidity_baking_vote
      ~adaptive_issuance_vote
      ~user_activated_upgrades
      ~force_apply
      state.global_state.config.fees
      simulation_mode
      simulation_kind
      state.global_state.constants.parametric
  in
  let* signed_block_header =
    Baking_profiler.record_s "sign block header" @@ fun () ->
    sign_block_header state consensus_key unsigned_block_header
  in
  let* () =
    match seed_nonce_opt with
    | None ->
        (* Nothing to do *)
        return_unit
    | Some (_, nonce) ->
        let block_hash = Block_header.hash signed_block_header in
        Baking_profiler.record_s "register nonce" @@ fun () ->
        Baking_nonces.register_nonce cctxt ~chain_id block_hash nonce
  in
  let* () = state_recorder ~new_state:updated_state in
  let signed_block =
    {round; delegate; operations; block_header = signed_block_header}
  in
  return (signed_block, updated_state)

let inject_block ~updated_state state signed_block =
  let open Lwt_result_syntax in
  let {round; delegate; block_header; operations} = signed_block in
  let*! () =
    Events.(emit injecting_block (block_header.shell.level, round, delegate))
  in
  let cctxt = state.global_state.cctxt in
  let* bh =
    Baking_profiler.record_s "inject block to node" @@ fun () ->
    Node_rpc.inject_block
      cctxt
      ~force:state.global_state.config.force
      ~chain:(`Hash state.global_state.chain_id)
      block_header
      operations
  in
  let*! () =
    Events.(emit block_injected (bh, block_header.shell.level, round, delegate))
  in
  return updated_state

let sign_consensus_votes state operations kind =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  (* N.b. signing a lot of operations may take some time *)
  (* Don't parallelize signatures: the signer might not be able to
     handle concurrent requests *)
  let block_location =
    Baking_files.resolve_location ~chain_id `Highwatermarks
  in
  (* Hypothesis: all consensus votes have the same round and level *)
  match operations with
  | [] -> return_nil
  | (_, (consensus_content : consensus_content)) :: _ ->
      let level = Raw_level.to_int32 consensus_content.level in
      let round = consensus_content.round in
      (* Filter all operations that don't satisfy the highwatermark *)
      let* authorized_consensus_votes =
        Baking_profiler.record_s
          (Format.sprintf
             "filter consensus votes: %s"
             (match kind with
             | `Preattestation -> "preattestation"
             | `Attestation -> "attestation"))
        @@ fun () ->
        Baking_profiler.record "wait for lock" ;
        cctxt#with_lock @@ fun () ->
        Baking_profiler.stop () ;
        let* highwatermarks =
          Baking_profiler.record_s "load highwatermarks" @@ fun () ->
          Baking_highwatermarks.load cctxt block_location
        in
        let may_sign_consensus_vote =
          match kind with
          | `Preattestation -> Baking_highwatermarks.may_sign_preattestation
          | `Attestation -> Baking_highwatermarks.may_sign_attestation
        in
        let*! authorized_operations =
          List.filter_s
            (fun (((consensus_key, _delegate_pkh) as delegate), _) ->
              let may_sign =
                may_sign_consensus_vote
                  highwatermarks
                  ~delegate:consensus_key.public_key_hash
                  ~level
                  ~round
              in
              if may_sign || state.global_state.config.force then
                Lwt.return_true
              else
                let*! () =
                  match kind with
                  | `Preattestation ->
                      Events.(
                        emit
                          skipping_preattestation
                          ( delegate,
                            [
                              Baking_highwatermarks.Block_previously_preattested
                                {round; level};
                            ] ))
                  | `Attestation ->
                      Events.(
                        emit
                          skipping_attestation
                          ( delegate,
                            [
                              Baking_highwatermarks.Block_previously_attested
                                {round; level};
                            ] ))
                in
                Lwt.return_false)
            operations
        in
        (* Record all consensus votes new highwatermarks as one batch *)
        let* () =
          Baking_profiler.record_s
            (Format.sprintf
               "record consensus votes: %s"
               (match kind with
               | `Preattestation -> "preattestation"
               | `Attestation -> "attestation"))
          @@ fun () ->
          let delegates =
            List.map
              (fun ((ck, _), _) -> ck.public_key_hash)
              authorized_operations
          in
          let record_all_consensus_vote =
            match kind with
            | `Preattestation ->
                Baking_highwatermarks.record_all_preattestations
            | `Attestation -> Baking_highwatermarks.record_all_attestations
          in
          record_all_consensus_vote
            highwatermarks
            cctxt
            block_location
            ~delegates
            ~level
            ~round
        in
        return authorized_operations
      in
      let forge_and_sign_consensus_vote : type a. _ -> a contents_list -> _ =
       fun ((consensus_key, _) as delegate) contents ->
        let shell =
          (* The branch is the latest finalized block. *)
          {
            Tezos_base.Operation.branch =
              state.level_state.latest_proposal.predecessor.shell.predecessor;
          }
        in
        let watermark =
          match kind with
          | `Preattestation ->
              Operation.(to_watermark (Preattestation chain_id))
          | `Attestation -> Operation.(to_watermark (Attestation chain_id))
        in
        let unsigned_operation = (shell, Contents_list contents) in
        let unsigned_operation_bytes =
          Data_encoding.Binary.to_bytes_exn
            Operation.unsigned_encoding
            unsigned_operation
        in
        let level = Raw_level.to_int32 consensus_content.level in
        let round = consensus_content.round in
        let sk_uri = consensus_key.secret_key_uri in
        let*! signature =
          Baking_profiler.record_s
            (Format.sprintf
               "sign consensus vote: %s"
               (match kind with
               | `Preattestation -> "preattestation"
               | `Attestation -> "attestation"))
          @@ fun () ->
          Client_keys.sign cctxt ~watermark sk_uri unsigned_operation_bytes
        in
        match signature with
        | Error err ->
            let*! () =
              match kind with
              | `Preattestation ->
                  Events.(emit skipping_preattestation (delegate, err))
              | `Attestation ->
                  Events.(emit skipping_attestation (delegate, err))
            in
            return_none
        | Ok signature ->
            let protocol_data =
              Operation_data {contents; signature = Some signature}
            in
            let operation : Operation.packed = {shell; protocol_data} in
            return_some (delegate, operation, level, round)
      in
      List.filter_map_es
        (fun (delegate, consensus_content) ->
          let event =
            match kind with
            | `Preattestation -> Events.signing_preattestation
            | `Attestation -> Events.signing_attestation
          in
          let*! () = Events.(emit event delegate) in
          match kind with
          | `Attestation ->
              forge_and_sign_consensus_vote
                delegate
                (Single (Attestation consensus_content))
          | `Preattestation ->
              forge_and_sign_consensus_vote
                delegate
                (Single (Preattestation consensus_content)))
        authorized_consensus_votes

let inject_consensus_vote state preattestations kind =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let* signed_operations =
    Baking_profiler.record_s
      (Format.sprintf
         "sign consensus votes: %s"
         (match kind with
         | `Preattestation -> "preattestation"
         | `Attestation -> "attestation"))
      (fun () -> sign_consensus_votes state preattestations kind)
  in
  (* TODO: add a RPC to inject multiple operations *)
  let fail_inject_event, injected_event =
    match kind with
    | `Preattestation ->
        (Events.failed_to_inject_preattestation, Events.preattestation_injected)
    | `Attestation ->
        (Events.failed_to_inject_attestation, Events.attestation_injected)
  in
  List.iter_ep
    (fun (delegate, operation, level, round) ->
      Baking_profiler.span_s
        [
          Format.asprintf
            "inject preendorsement for %a"
            Signature.Public_key_hash.pp_short
            (snd delegate);
        ]
      @@ fun () ->
      protect
        ~on_error:(fun err ->
          let*! () = Events.(emit fail_inject_event (delegate, err)) in
          return_unit)
        (fun () ->
          let* oph =
            Node_rpc.inject_operation cctxt ~chain:(`Hash chain_id) operation
          in
          let*! () =
            Events.(emit injected_event (oph, delegate, level, round))
          in
          return_unit))
    signed_operations

let sign_dal_attestations state attestations =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  (* N.b. signing a lot of operations may take some time *)
  (* Don't parallelize signatures: the signer might not be able to
     handle concurrent requests *)
  let shell =
    {
      Tezos_base.Operation.branch =
        state.level_state.latest_proposal.predecessor.hash;
    }
  in
  List.filter_map_es
    (fun (((consensus_key, _) as delegate), consensus_content, published_level) ->
      let watermark = Operation.(to_watermark (Dal_attestation chain_id)) in
      let contents = Single (Dal_attestation consensus_content) in
      let unsigned_operation = (shell, Contents_list contents) in
      let unsigned_operation_bytes =
        Data_encoding.Binary.to_bytes_exn
          Operation.unsigned_encoding_with_legacy_attestation_name
          unsigned_operation
      in
      let*! signature =
        Client_keys.sign
          cctxt
          ~watermark
          consensus_key.secret_key_uri
          unsigned_operation_bytes
      in
      match signature with
      | Error err ->
          let*! () = Events.(emit skipping_dal_attestation (delegate, err)) in
          return_none
      | Ok signature ->
          let protocol_data =
            Operation_data {contents; signature = Some signature}
          in
          let operation : Operation.packed = {shell; protocol_data} in
          return_some
            ( delegate,
              operation,
              consensus_content.Dal.Attestation.attestation,
              published_level ))
    attestations

let inject_dal_attestations state attestations =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let* signed_operations = sign_dal_attestations state attestations in
  List.iter_ep
    (fun ( delegate,
           signed_operation,
           (attestation : Dal.Attestation.t),
           published_level ) ->
      let encoded_op =
        Data_encoding.Binary.to_bytes_exn
          Operation.encoding_with_legacy_attestation_name
          signed_operation
      in
      let* oph =
        Shell_services.Injection.operation
          cctxt
          ~chain:(`Hash chain_id)
          encoded_op
      in
      let bitset_int = Bitset.to_z (attestation :> Bitset.t) in
      let attestation_level = state.level_state.current_level in
      let*! () =
        Events.(
          emit
            dal_attestation_injected
            (oph, delegate, bitset_int, published_level, attestation_level))
      in
      return_unit)
    signed_operations

let no_dal_node_warning_counter = ref 0

let only_if_dal_feature_enabled state ~default_value f =
  let open Lwt_result_syntax in
  let open Constants in
  let Parametric.{dal = {feature_enable; _}; _} =
    state.global_state.constants.parametric
  in
  if feature_enable then
    match state.global_state.dal_node_rpc_ctxt with
    | None ->
        incr no_dal_node_warning_counter ;
        let*! () =
          if !no_dal_node_warning_counter mod 10 = 1 then
            Events.(emit no_dal_node ())
          else Lwt.return_unit
        in
        return default_value
    | Some ctxt -> f ctxt
  else return default_value

let get_dal_attestations state =
  let open Lwt_result_syntax in
  only_if_dal_feature_enabled state ~default_value:[] (fun dal_node_rpc_ctxt ->
      let attestation_level = state.level_state.current_level in
      let attested_level = Int32.succ attestation_level in
      let delegates =
        List.map
          (fun delegate_slot ->
            (delegate_slot.consensus_key_and_delegate, delegate_slot.first_slot))
          (Delegate_slots.own_delegates state.level_state.delegate_slots)
      in
      let signing_key delegate = (fst delegate).public_key_hash in
      let* attestations =
        List.fold_left_es
          (fun acc (delegate, first_slot) ->
            let*! tz_res =
              Node_rpc.get_attestable_slots
                dal_node_rpc_ctxt
                (signing_key delegate)
                ~attested_level
            in
            match tz_res with
            | Error errs ->
                let*! () =
                  Events.(emit failed_to_get_dal_attestations (delegate, errs))
                in
                return acc
            | Ok res -> (
                match res with
                | Tezos_dal_node_services.Types.Not_in_committee -> return acc
                | Attestable_slots {slots = attestation; published_level} ->
                    if List.exists Fun.id attestation then
                      return
                        ((delegate, attestation, published_level, first_slot)
                        :: acc)
                    else
                      (* No slot is attested, no need to send an attestation, at least
                         for now. *)
                      let*! () =
                        Events.(
                          emit
                            dal_attestation_void
                            (delegate, attestation_level, published_level))
                      in
                      return acc))
          []
          delegates
      in
      let number_of_slots =
        state.global_state.constants.parametric.dal.number_of_slots
      in
      List.map
        (fun (delegate, attestation_flags, published_level, first_slot) ->
          let attestation =
            List.fold_left_i
              (fun i acc flag ->
                match Dal.Slot_index.of_int_opt ~number_of_slots i with
                | Some index when flag -> Dal.Attestation.commit acc index
                | None | Some _ -> acc)
              Dal.Attestation.empty
              attestation_flags
          in
          ( delegate,
            Dal.Attestation.
              {
                attestation;
                level = Raw_level.of_int32_exn attestation_level;
                slot = first_slot;
              },
            published_level ))
        attestations
      |> return)

let get_and_inject_dal_attestations state =
  let open Lwt_result_syntax in
  let* attestations = get_dal_attestations state in
  inject_dal_attestations state attestations

let prepare_waiting_for_quorum state =
  let consensus_threshold =
    state.global_state.constants.parametric.consensus_threshold
  in
  let get_slot_voting_power ~slot =
    Delegate_slots.voting_power state.level_state.delegate_slots ~slot
  in
  let latest_proposal = state.level_state.latest_proposal.block in
  (* assert (latest_proposal.block.round = state.round_state.current_round) ; *)
  let candidate =
    {
      Operation_worker.hash = latest_proposal.hash;
      round_watched = latest_proposal.round;
      payload_hash_watched = latest_proposal.payload_hash;
    }
  in
  (consensus_threshold, get_slot_voting_power, candidate)

let start_waiting_for_preattestation_quorum state =
  let consensus_threshold, get_slot_voting_power, candidate =
    prepare_waiting_for_quorum state
  in
  let operation_worker = state.global_state.operation_worker in
  Operation_worker.monitor_preattestation_quorum
    operation_worker
    ~consensus_threshold
    ~get_slot_voting_power
    candidate

let start_waiting_for_attestation_quorum state =
  let consensus_threshold, get_slot_voting_power, candidate =
    prepare_waiting_for_quorum state
  in
  let operation_worker = state.global_state.operation_worker in
  Operation_worker.monitor_attestation_quorum
    operation_worker
    ~consensus_threshold
    ~get_slot_voting_power
    candidate

let compute_round proposal round_durations =
  let open Protocol in
  let open Baking_state in
  let timestamp = Time.System.now () |> Time.System.to_protocol in
  let predecessor_block = proposal.predecessor in
  Baking_profiler.record_f "compute round" @@ fun () ->
  Environment.wrap_tzresult
  @@ Alpha_context.Round.round_of_timestamp
       round_durations
       ~predecessor_timestamp:predecessor_block.shell.timestamp
       ~predecessor_round:predecessor_block.round
       ~timestamp

let update_to_level state level_update =
  let open Lwt_result_syntax in
  let {new_level_proposal; compute_new_state} = level_update in
  let cctxt = state.global_state.cctxt in
  let delegates = state.global_state.delegates in
  let new_level = new_level_proposal.block.shell.level in
  let chain = `Hash state.global_state.chain_id in
  (* Sync the context to clean-up potential GC artifacts *)
  let*! () =
    match state.global_state.validation_mode with
    | Node -> Lwt.return_unit
    | Local index -> index.sync_fun ()
  in
  let* delegate_slots =
    if Int32.(new_level = succ state.level_state.current_level) then
      return state.level_state.next_level_delegate_slots
    else
      Baking_profiler.record_s "compute predecessor delegate slots" @@ fun () ->
      Baking_state.compute_delegate_slots
        cctxt
        delegates
        ~level:new_level
        ~chain
  in
  let* next_level_delegate_slots =
    Baking_profiler.record_s "compute current delegate slots" @@ fun () ->
    Baking_state.compute_delegate_slots
      cctxt
      delegates
      ~level:(Int32.succ new_level)
      ~chain
  in
  let round_durations = state.global_state.round_durations in
  let*? current_round = compute_round new_level_proposal round_durations in
  let*! new_state =
    compute_new_state ~current_round ~delegate_slots ~next_level_delegate_slots
  in
  return new_state

let synchronize_round state {new_round_proposal; handle_proposal} =
  let open Lwt_result_syntax in
  let*! () =
    Events.(emit synchronizing_round new_round_proposal.predecessor.hash)
  in
  let round_durations = state.global_state.round_durations in
  let*? current_round = compute_round new_round_proposal round_durations in
  if Round.(current_round < new_round_proposal.block.round) then
    (* impossible *)
    failwith
      "synchronize_round: current round (%a) is behind the new proposal's \
       round (%a)"
      Round.pp
      current_round
      Round.pp
      new_round_proposal.block.round
  else
    let new_round_state =
      {current_round; current_phase = Idle; delayed_quorum = None}
    in
    let new_state = {state with round_state = new_round_state} in
    let*! new_state = handle_proposal new_state in
    return new_state

(* TODO: https://gitlab.com/tezos/tezos/-/issues/4539
   Avoid updating the state here.
   (See also comment in {!State_transitions.step}.)

   TODO: https://gitlab.com/tezos/tezos/-/issues/4538
   Improve/clarify when the state is recorded.
*)
let rec perform_action ~state_recorder state (action : action) =
  let open Lwt_result_syntax in
  match action with
  | Do_nothing ->
      let* () = state_recorder ~new_state:state in
      return state
  | Inject_block {kind; updated_state} ->
      let* signed_block, updated_state =
        match kind with
        | Forge_and_inject block_to_bake ->
            Baking_profiler.record_s
              (Format.asprintf
                 "forge and inject block for %a"
                 Signature.Public_key_hash.pp_short
                 (snd block_to_bake.delegate))
            @@ fun () ->
            forge_signed_block
              ~state_recorder
              ~updated_state
              block_to_bake
              state
        | Inject_only signed_block ->
            Baking_profiler.record_s
              (Format.asprintf
                 "inject block for %a"
                 Signature.Public_key_hash.pp_short
                 (snd signed_block.delegate))
            @@ fun () -> return (signed_block, updated_state)
      in
      inject_block ~updated_state state signed_block
  | Forge_block {block_to_bake; updated_state} ->
      let+ signed_block, updated_state =
        Baking_profiler.record_s
          (Format.asprintf
             "forge block for %a"
             Signature.Public_key_hash.pp_short
             (snd block_to_bake.delegate))
        @@ fun () ->
        forge_signed_block ~state_recorder ~updated_state block_to_bake state
      in
      let updated_state =
        {
          updated_state with
          level_state =
            {
              updated_state.level_state with
              next_forged_block = Some signed_block;
            };
        }
      in
      updated_state
  | Inject_preattestations {preattestations} ->
      let* () =
        Baking_profiler.record_s "inject preattestations" @@ fun () ->
        inject_consensus_vote state preattestations `Preattestation
      in
      perform_action ~state_recorder state Watch_proposal
  | Inject_attestations {attestations} ->
      let* () = state_recorder ~new_state:state in
      let* () =
        Baking_profiler.record_s "inject attestations" @@ fun () ->
        inject_consensus_vote state attestations `Attestation
      in
      (* We wait for attestations to trigger the [Quorum_reached]
         event *)
      let*! () =
        Baking_profiler.record_s "wait for endorsements quorum" @@ fun () ->
        start_waiting_for_attestation_quorum state
      in
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4667
         Also inject attestations for the migration block. *)
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4671
         Don't inject multiple attestations? *)
      let* () = get_and_inject_dal_attestations state in
      return state
  | Update_to_level level_update ->
      let* new_state, new_action =
        Baking_profiler.record_s "update to level" @@ fun () ->
        update_to_level state level_update
      in
      perform_action ~state_recorder new_state new_action
  | Synchronize_round round_update ->
      let* new_state, new_action =
        Baking_profiler.record_s "synchronize round" @@ fun () ->
        synchronize_round state round_update
      in
      perform_action ~state_recorder new_state new_action
  | Watch_proposal ->
      (* We wait for preattestations to trigger the
           [Prequorum_reached] event *)
      let*! () =
        Baking_profiler.record_s "wait for preendorsements quorum" @@ fun () ->
        start_waiting_for_preattestation_quorum state
      in
      return state
