(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

open Protocol
open Alpha_context

module Events = struct
  include Baking_events.Actions
  include Baking_events.Forge_worker
end

open Baking_state

module Delegate_signing_queue = struct
  type t = {
    delegate : consensus_key_and_delegate;
    task_stream : (unit -> unit Lwt.t) Lwt_stream.t;
    push : (unit -> unit Lwt.t) option -> unit;
    worker : unit Lwt.t;
  }

  let start_worker task_stream =
    let open Lwt_syntax in
    let rec loop () =
      let* task = Lwt_stream.get task_stream in
      match task with
      | None -> (* End of stream *) return_unit
      | Some task ->
          let* () = task () in
          loop ()
    in
    loop ()

  let create delegate =
    let task_stream, push = Lwt_stream.create () in
    let worker = start_worker task_stream in
    {delegate; task_stream; push; worker}

  let cancel_pending_tasks state =
    Lwt_stream.junk_while (fun _ -> true) state.task_stream

  let wait_all_tasks_and_close state =
    state.push None ;
    state.worker

  let _cancel_all_tasks_and_close state =
    let open Lwt_syntax in
    let* () = cancel_pending_tasks state in
    wait_all_tasks_and_close state

  let push_task ~(on_error : tztrace -> unit Lwt.t)
      (f : unit -> unit tzresult Lwt.t) state =
    let open Lwt_result_syntax in
    let task () =
      let*! r =
        protect
          ~on_error:(fun trace ->
            let*! () = on_error trace in
            return_unit)
          f
      in
      match r with Error _err -> assert false | Ok () -> Lwt.return_unit
    in
    state.push (Some task)
end

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

let generate_seed_nonce_hash config delegate level =
  let open Lwt_result_syntax in
  if level.Level.expected_commitment then
    let* seed_nonce =
      Baking_nonces.generate_seed_nonce config delegate level.level
    in
    return_some seed_nonce
  else return_none

let sign_block_header global_state proposer unsigned_block_header =
  let open Lwt_result_syntax in
  let cctxt = global_state.cctxt in
  let chain_id = global_state.chain_id in
  let force = global_state.config.force in
  let {Block_header.shell; protocol_data = {contents; _}} =
    unsigned_block_header
  in
  let unsigned_header =
    Data_encoding.Binary.to_bytes_exn
      Alpha_context.Block_header.unsigned_encoding
      (shell, contents)
  in
  let level = shell.level in
  let*? round = Baking_state.round_of_shell_header shell in
  let open Baking_highwatermarks in
  let* result =
    cctxt#with_lock (fun () ->
        let block_location =
          Baking_files.resolve_location ~chain_id `Highwatermarks
        in
        let* may_sign =
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
        Client_keys.sign
          cctxt
          proposer.secret_key_uri
          ~watermark:Block_header.(to_watermark (Block_header chain_id))
          unsigned_header
      in
      return {Block_header.shell; protocol_data = {contents; signature}}

let prepare_block (global_state : global_state) block_to_bake =
  let open Lwt_result_syntax in
  let {
    predecessor;
    round;
    delegate = (consensus_key, _) as delegate;
    kind;
    force_apply;
    per_block_votes;
  } =
    block_to_bake
  in
  let*! () =
    Events.(
      emit
        prepare_forging_block
        (Int32.succ predecessor.shell.level, round, delegate))
  in
  let cctxt = global_state.cctxt in
  let chain_id = global_state.chain_id in
  let simulation_mode = global_state.validation_mode in
  let round_durations = global_state.round_durations in
  let*? timestamp =
    Environment.wrap_tzresult
      (Round.timestamp_of_round
         round_durations
         ~predecessor_timestamp:predecessor.shell.timestamp
         ~predecessor_round:predecessor.round
         ~round)
  in
  let external_operation_source = global_state.config.extra_operations in
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
    Plugin.RPC.current_level
      cctxt
      ~offset:1l
      (`Hash global_state.chain_id, `Hash (predecessor.hash, 0))
  in
  let* seed_nonce_opt =
    generate_seed_nonce_hash
      global_state.config.Baking_configuration.nonce
      consensus_key
      injection_level
  in
  let seed_nonce_hash = Option.map fst seed_nonce_opt in
  let user_activated_upgrades = global_state.config.user_activated_upgrades in
  (* Set liquidity_baking_toggle_vote for this block *)
  let {
    Baking_configuration.vote_file;
    liquidity_baking_vote;
    adaptive_issuance_vote;
  } =
    per_block_votes
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
  let*! () =
    Events.(emit vote_for_liquidity_baking_toggle) liquidity_baking_vote
  in
  let*! () = Events.(emit vote_for_adaptive_issuance) adaptive_issuance_vote in
  let chain = `Hash global_state.chain_id in
  let pred_block = `Hash (predecessor.hash, 0) in
  let* pred_resulting_context_hash =
    Shell_services.Blocks.resulting_context_hash
      cctxt
      ~chain
      ~block:pred_block
      ()
  in
  let* pred_live_blocks =
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
      global_state.config.fees
      simulation_mode
      simulation_kind
      global_state.constants.parametric
  in
  let* signed_block_header =
    sign_block_header global_state consensus_key unsigned_block_header
  in
  let* () =
    match seed_nonce_opt with
    | None ->
        (* Nothing to do *)
        return_unit
    | Some (_, nonce) ->
        let block_hash = Block_header.hash signed_block_header in
        Baking_nonces.register_nonce cctxt ~chain_id block_hash nonce
  in
  let baking_votes =
    {Per_block_votes.liquidity_baking_vote; adaptive_issuance_vote}
  in
  return {signed_block_header; round; delegate; operations; baking_votes}

let sign_dal_attestations (cctxt : #Protocol_client_context.full) chain_id
    ~branch attestations =
  let open Lwt_result_syntax in
  (* N.b. signing a lot of operations may take some time *)
  (* Don't parallelize signatures: the signer might not be able to
     handle concurrent requests *)
  let shell = {Tezos_base.Operation.branch} in
  List.filter_map_es
    (fun ( ((consensus_key, _) as delegate),
           dal_operation_content,
           published_level ) ->
      let watermark = Operation.(to_watermark (Dal_attestation chain_id)) in
      let contents = Single (Dal_attestation dal_operation_content) in
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
            (delegate, operation, dal_operation_content, published_level))
    attestations

let authorize_consensus_votes kind (cctxt : #Protocol_client_context.full)
    ?(force = false) chain_id operations (consensus_content : consensus_content)
    =
  let open Lwt_result_syntax in
  let block_location =
    Baking_files.resolve_location ~chain_id `Highwatermarks
  in
  let level = Raw_level.to_int32 consensus_content.level in
  let round = consensus_content.round in
  (* Filter all operations that don't satisfy the highwatermark *)
  cctxt#with_lock @@ fun () ->
  let* highwatermarks = Baking_highwatermarks.load cctxt block_location in
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
        if may_sign || force then Lwt.return_true
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
    let delegates =
      List.map (fun ((ck, _), _) -> ck.public_key_hash) authorized_operations
    in
    let record_all_consensus_vote =
      match kind with
      | `Preattestation -> Baking_highwatermarks.record_all_preattestations
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

let forge_and_sign_consensus_vote kind cctxt chain_id ~branch
    ((consensus_key, _) as delegate) (consensus_content : consensus_content)
    (contents : _ contents_list) =
  let open Lwt_result_syntax in
  let shell =
    (* The branch is the latest finalized block. *)
    {Tezos_base.Operation.branch}
  in
  let watermark =
    match kind with
    | `Preattestation -> Operation.(to_watermark (Preattestation chain_id))
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
    Client_keys.sign cctxt ~watermark sk_uri unsigned_operation_bytes
  in
  match signature with
  | Error err ->
      let*! () =
        match kind with
        | `Preattestation ->
            Events.(emit skipping_preattestation (delegate, err))
        | `Attestation -> Events.(emit skipping_attestation (delegate, err))
      in
      return_none
  | Ok signature ->
      let protocol_data =
        Operation_data {contents; signature = Some signature}
      in
      let operation : Operation.packed = {shell; protocol_data} in
      return_some (delegate, operation, level, round)

let sign_consensus_votes kind (cctxt : #Protocol_client_context.full)
    ?(force = false) chain_id ~branch operations =
  let open Lwt_result_syntax in
  (* N.b. signing a lot of operations may take some time *)
  (* Don't parallelize signatures: the signer might not be able to
     handle concurrent requests *)
  (* Hypothesis: all consensus votes have the same round and level *)
  let consensus_content_opt = List.hd operations |> Option.map snd in
  match consensus_content_opt with
  | None -> return_nil
  | Some consensus_content ->
      let* authorized_consensus_votes =
        authorize_consensus_votes
          kind
          cctxt
          ~force
          chain_id
          operations
          consensus_content
      in
      (* N.b. signing a lot of operations may take some time *)
      (* Don't parallelize signatures: the signer might not be able to
         handle concurrent requests *)
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
                kind
                cctxt
                chain_id
                ~branch
                delegate
                consensus_content
                (Single (Attestation consensus_content))
          | `Preattestation ->
              forge_and_sign_consensus_vote
                kind
                cctxt
                chain_id
                ~branch
                delegate
                consensus_content
                (Single (Preattestation consensus_content)))
        authorized_consensus_votes

let sign_preattestations (cctxt : #Protocol_client_context.full) =
  sign_consensus_votes `Preattestation cctxt

let sign_attestations (cctxt : #Protocol_client_context.full) =
  sign_consensus_votes `Attestation cctxt

type worker = {
  push_task : forge_request option -> unit;
  push_event : forge_event option -> unit;
  event_stream : forge_event Lwt_stream.t;
  delegate_signing_queues :
    Delegate_signing_queue.t Signature.Public_key_hash.Table.t;
}

type t = worker

let push_request state request = state.push_task (Some request)

let get_event_stream state = state.event_stream

let shutdown state = state.push_task None

let forge_and_sign_consensus_vote kind cctxt chain_id ~branch delegate
    consensus_content =
  let open Lwt_result_syntax in
  let event =
    match kind with
    | `Preattestation -> Events.signing_preattestation
    | `Attestation -> Events.signing_attestation
  in
  let*! () = Events.(emit event delegate) in
  match kind with
  | `Attestation ->
      forge_and_sign_consensus_vote
        kind
        cctxt
        chain_id
        ~branch
        delegate
        consensus_content
        (Single (Attestation consensus_content))
  | `Preattestation ->
      forge_and_sign_consensus_vote
        kind
        cctxt
        chain_id
        ~branch
        delegate
        consensus_content
        (Single (Preattestation consensus_content))

let get_or_create_queue worker delegate =
  match
    Signature.Public_key_hash.Table.find_opt
      worker.delegate_signing_queues
      (snd delegate)
  with
  | None ->
      let queue = Delegate_signing_queue.create delegate in
      Signature.Public_key_hash.Table.add
        worker.delegate_signing_queues
        (snd delegate)
        queue ;
      queue
  | Some queue -> queue

let handle_consensus_signing_request worker cctxt ?force chain_id ~branch kind
    consensus_operations =
  let open Lwt_result_syntax in
  let* filtered_preattestations =
    (* Hypothesis: all consensus votes have the same round and level *)
    let consensus_content_opt =
      List.hd consensus_operations |> Option.map snd
    in
    match consensus_content_opt with
    | None -> return_nil
    | Some consensus_content ->
        authorize_consensus_votes
          kind
          cctxt
          ?force
          chain_id
          consensus_operations
          consensus_content
  in
  List.iter
    (fun (delegate, consensus_content) ->
      let task () =
        let* signed_consensus_opt =
          forge_and_sign_consensus_vote
            kind
            cctxt
            chain_id
            ~branch
            delegate
            consensus_content
        in
        match signed_consensus_opt with
        | None -> return_unit
        | Some signed_consensus ->
            (match kind with
            | `Preattestation ->
                worker.push_event (Some (Preattestation_ready signed_consensus))
            | `Attestation ->
                worker.push_event (Some (Attestation_ready signed_consensus))) ;
            return_unit
      in
      let queue = get_or_create_queue worker delegate in
      Delegate_signing_queue.push_task
        ~on_error:(fun _err -> Lwt.return_unit)
        task
        queue)
    filtered_preattestations ;
  return_unit

let handle_dal_attestations worker cctxt chain_id ~branch dal_attestations =
  let open Lwt_result_syntax in
  List.iter
    (fun ((delegate, _, _) as dal_attestation) ->
      let task () =
        let* signed_dal_attestation =
          sign_dal_attestations cctxt chain_id ~branch [dal_attestation]
        in
        List.iter
          (fun signed_dal_attestation ->
            worker.push_event
              (Some (Dal_attestation_ready signed_dal_attestation)))
          signed_dal_attestation ;
        return_unit
      in
      let queue = get_or_create_queue worker delegate in
      Delegate_signing_queue.push_task
        ~on_error:(fun _err -> Lwt.return_unit)
        task
        queue)
    dal_attestations

let handle_forge_block worker baking_state block_to_bake =
  let open Lwt_result_syntax in
  let task () =
    let* prepared_block = prepare_block baking_state block_to_bake in
    worker.push_event (Some (Block_ready prepared_block)) ;
    return_unit
  in
  let queue = get_or_create_queue worker block_to_bake.delegate in
  Delegate_signing_queue.push_task
    ~on_error:(fun _err -> Lwt.return_unit)
    task
    queue

let start (baking_state : Baking_state.global_state) =
  let open Lwt_result_syntax in
  let task_stream, push_task = Lwt_stream.create () in
  let event_stream, push_event = Lwt_stream.create () in
  let delegate_signing_queues = Signature.Public_key_hash.Table.create 13 in
  let state : worker =
    {push_task; push_event; event_stream; delegate_signing_queues}
  in
  let cctxt = baking_state.cctxt in
  let chain_id = baking_state.chain_id in
  let config = baking_state.config in
  let rec worker_loop () =
    let*! (forge_request_opt : forge_request option) =
      Lwt_stream.get task_stream
    in
    let process_request = function
      | Forge_and_sign_preattestations (branch, preattestations) ->
          handle_consensus_signing_request
            state
            cctxt
            ~force:config.force
            chain_id
            ~branch
            `Preattestation
            preattestations
      | Forge_and_sign_attestations (branch, attestations) ->
          handle_consensus_signing_request
            state
            cctxt
            ~force:config.force
            chain_id
            ~branch
            `Attestation
            attestations
      | Forge_and_sign_dal_attestations (branch, dal_attestations) ->
          handle_dal_attestations state cctxt chain_id ~branch dal_attestations ;
          return_unit
      | Forge_and_sign_block block_to_bake ->
          handle_forge_block state baking_state block_to_bake ;
          return_unit
    in
    match forge_request_opt with
    | None -> (* Shutdown called *) return_unit
    | Some request ->
        let*! result = process_request request in
        let*! () =
          match result with
          | Ok () -> Lwt.return_unit
          | Error errs ->
              let*! () =
                Events.(emit error_while_processing_forge_request errs)
              in
              Lwt.return_unit
        in
        worker_loop ()
  in
  Lwt.dont_wait
    (fun () ->
      Lwt.finalize
        (fun () ->
          let*! _r = worker_loop () in
          Lwt.return_unit)
        (fun () ->
          let () = shutdown state in
          Lwt.return_unit))
    (fun _exn -> ()) ;
  return state
