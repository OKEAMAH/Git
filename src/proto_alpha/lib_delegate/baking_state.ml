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
open Protocol_client_context

(** A consensus key (aka, a validator) is identified by its alias name, its
    public key, its public key hash, and its secret key. *)
type consensus_key = {
  alias : string option;
  public_key : Signature.Public_key.t;
  public_key_hash : Signature.Public_key_hash.t;
  secret_key_uri : Client_keys.sk_uri;
}

let consensus_key_encoding =
  let open Data_encoding in
  conv
    (fun {alias; public_key; public_key_hash; secret_key_uri} ->
      ( alias,
        public_key,
        public_key_hash,
        Uri.to_string (secret_key_uri :> Uri.t) ))
    (fun (alias, public_key, public_key_hash, secret_key_uri) ->
      {
        alias;
        public_key;
        public_key_hash;
        secret_key_uri =
          (match Client_keys.make_sk_uri (Uri.of_string secret_key_uri) with
          | Ok sk -> sk
          | Error e -> Format.kasprintf Stdlib.failwith "%a" pp_print_trace e);
      })
    (obj4
       (req "alias" (option string))
       (req "public_key" Signature.Public_key.encoding)
       (req "public_key_hash" Signature.Public_key_hash.encoding)
       (req "secret_key_uri" string))

let pp_consensus_key fmt {alias; public_key_hash; _} =
  match alias with
  | None -> Format.fprintf fmt "%a" Signature.Public_key_hash.pp public_key_hash
  | Some alias ->
      Format.fprintf
        fmt
        "%s (%a)"
        alias
        Signature.Public_key_hash.pp
        public_key_hash

type consensus_key_and_delegate = consensus_key * Signature.Public_key_hash.t

let consensus_key_and_delegate_encoding =
  let open Data_encoding in
  merge_objs
    consensus_key_encoding
    (obj1 (req "delegate" Signature.Public_key_hash.encoding))

let pp_consensus_key_and_delegate fmt (consensus_key, delegate) =
  if Signature.Public_key_hash.equal consensus_key.public_key_hash delegate then
    pp_consensus_key fmt consensus_key
  else
    Format.fprintf
      fmt
      "%a@,on behalf of %a"
      pp_consensus_key
      consensus_key
      Signature.Public_key_hash.pp
      delegate

type validation_mode = Node | Local of Abstract_context_index.t

type prequorum = {
  level : int32;
  round : Round.t;
  block_payload_hash : Block_payload_hash.t;
  preattestations : Kind.preattestation operation list;
}

type block_info = {
  hash : Block_hash.t;
  shell : Block_header.shell_header;
  payload_hash : Block_payload_hash.t;
  payload_round : Round.t;
  round : Round.t;
  prequorum : prequorum option;
  quorum : Kind.attestation operation list;
  dal_attestations : Kind.dal_attestation operation list;
  payload : Operation_pool.payload;
}

type cache = {
  known_timestamps : Timestamp.time Baking_cache.Timestamp_of_round_cache.t;
  round_timestamps :
    (Timestamp.time * Round.t * consensus_key_and_delegate)
    Baking_cache.Round_timestamp_interval_cache.t;
}

type global_state = {
  (* client context *)
  cctxt : Protocol_client_context.full;
  (* chain id *)
  chain_id : Chain_id.t;
  (* baker configuration *)
  config : Baking_configuration.t;
  (* protocol constants *)
  constants : Constants.t;
  (* round durations *)
  round_durations : Round.round_durations;
  (* worker that monitor and aggregates new operations *)
  operation_worker : Operation_worker.t;
  (* the validation mode used by the baker*)
  validation_mode : validation_mode;
  (* the delegates on behalf of which the baker is running *)
  delegates : consensus_key list;
  cache : cache;
  dal_node_rpc_ctxt : Tezos_rpc.Context.generic option;
}

let prequorum_encoding =
  let open Data_encoding in
  conv
    (fun {level; round; block_payload_hash; preattestations} ->
      (level, round, block_payload_hash, List.map Operation.pack preattestations))
    (fun (level, round, block_payload_hash, preattestations) ->
      {
        level;
        round;
        block_payload_hash;
        preattestations =
          List.filter_map Operation_pool.unpack_preattestation preattestations;
      })
    (obj4
       (req "level" int32)
       (req "round" Round.encoding)
       (req "block_payload_hash" Block_payload_hash.encoding)
       (req
          "preattestations"
          (list (dynamic_size Operation.encoding_with_legacy_attestation_name))))

let block_info_encoding =
  let open Data_encoding in
  conv
    (fun {
           hash;
           shell;
           payload_hash;
           payload_round;
           round;
           prequorum;
           quorum;
           dal_attestations;
           payload;
         } ->
      ( hash,
        shell,
        payload_hash,
        payload_round,
        round,
        prequorum,
        List.map Operation.pack quorum,
        List.map Operation.pack dal_attestations,
        payload ))
    (fun ( hash,
           shell,
           payload_hash,
           payload_round,
           round,
           prequorum,
           quorum,
           dal_attestations,
           payload ) ->
      {
        hash;
        shell;
        payload_hash;
        payload_round;
        round;
        prequorum;
        quorum = List.filter_map Operation_pool.unpack_attestation quorum;
        dal_attestations =
          List.filter_map Operation_pool.unpack_dal_attestation dal_attestations;
        payload;
      })
    (obj9
       (req "hash" Block_hash.encoding)
       (req "shell" Block_header.shell_header_encoding)
       (req "payload_hash" Block_payload_hash.encoding)
       (req "payload_round" Round.encoding)
       (req "round" Round.encoding)
       (req "prequorum" (option prequorum_encoding))
       (req
          "quorum"
          (list (dynamic_size Operation.encoding_with_legacy_attestation_name)))
       (req
          "dal_attestations"
          (list (dynamic_size Operation.encoding_with_legacy_attestation_name)))
       (req "payload" Operation_pool.payload_encoding))

let round_of_shell_header shell_header =
  let open Result_syntax in
  let* fitness =
    Environment.wrap_tzresult
    @@ Fitness.from_raw shell_header.Tezos_base.Block_header.fitness
  in
  return (Fitness.round fitness)

module SlotMap : Map.S with type key = Slot.t = Map.Make (Slot)

type delegate_slot = {
  consensus_key_and_delegate : consensus_key_and_delegate;
  first_slot : Slot.t;
  attesting_power : int;
}

module Delegate_slots = struct
  (* Note that we also use the delegate slots as proposal slots. *)
  type t = {
    own_delegates : delegate_slot list;
    own_delegate_slots : delegate_slot SlotMap.t;
        (* This map cannot have as keys just the first slot of delegates,
           because it is used in [round_proposer] for which we need all slots,
           as the round can be arbitrary. *)
    all_delegate_voting_power : int SlotMap.t;
        (* This is a map having as keys the first slot of all delegates, and as
           values their attesting power.
           This map contains just the first slot for a delegate, because it is
           only used in [slot_voting_power] which is about (pre)attestations,
           not proposals. Indeed, only (pre)attestations that use the delegate's
           first slot are valid for inclusion in a block and count toward the
           (pre)quorum. Note that the baker might receive nominally valid
           non-first-slot operations from the mempool because this check is
           skipped in the mempool to increase its speed; the baker can and
           should ignore such operations. *)
  }

  let own_delegates slots = slots.own_delegates

  let own_slot_owner slots ~slot = SlotMap.find slot slots.own_delegate_slots

  let voting_power slots ~slot =
    SlotMap.find slot slots.all_delegate_voting_power
end

type delegate_slots = Delegate_slots.t

type proposal = {block : block_info; predecessor : block_info}

let proposal_encoding =
  let open Data_encoding in
  conv
    (fun {block; predecessor} -> (block, predecessor))
    (fun (block, predecessor) -> {block; predecessor})
    (obj2
       (req "block" block_info_encoding)
       (req "predecessor" block_info_encoding))

let is_first_block_in_protocol {block; predecessor; _} =
  Compare.Int.(block.shell.proto_level <> predecessor.shell.proto_level)

type locked_round = {payload_hash : Block_payload_hash.t; round : Round.t}

let locked_round_encoding =
  let open Data_encoding in
  conv
    (fun {payload_hash; round} -> (payload_hash, round))
    (fun (payload_hash, round) -> {payload_hash; round})
    (obj2
       (req "payload_hash" Block_payload_hash.encoding)
       (req "round" Round.encoding))

type attestable_payload = {proposal : proposal; prequorum : prequorum}

let attestable_payload_encoding =
  let open Data_encoding in
  conv
    (fun {proposal; prequorum} -> (proposal, prequorum))
    (fun (proposal, prequorum) -> {proposal; prequorum})
    (obj2
       (req "proposal" proposal_encoding)
       (req "prequorum" prequorum_encoding))

type elected_block = {
  proposal : proposal;
  attestation_qc : Kind.attestation Operation.t list;
}

type signed_block = {
  round : Round.t;
  delegate : consensus_key_and_delegate;
  block_header : block_header;
  operations : Tezos_base.Operation.t list list;
}

(* The fields {current_level}, {delegate_slots}, {next_level_delegate_slots},
   {next_level_proposed_round} are updated only when we receive a block at a
   different level than {current_level}.  Note that this means that there is
   always a {latest_proposal}, which may be our own baked block. *)
type level_state = {
  current_level : int32;
  latest_proposal : proposal;
  is_latest_proposal_applied : bool;
  (* Last proposal received where we injected an attestation (thus we
     have seen 2f+1 preattestations) *)
  locked_round : locked_round option;
  (* Latest payload where we've seen a proposal reach 2f+1 preattestations *)
  attestable_payload : attestable_payload option;
  (* Block for which we've seen 2f+1 attestations and that we may bake onto *)
  elected_block : elected_block option;
  delegate_slots : delegate_slots;
  next_level_delegate_slots : delegate_slots;
  next_level_proposed_round : Round.t option;
  next_forged_block : signed_block option;
      (* Block that is preemptively forged for the next level when baker is
           round 0 proposer. *)
}

type phase =
  | Idle
  | Awaiting_preattestations
  | Awaiting_attestations
  | Awaiting_application

let phase_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Idle"
        (Tag 0)
        (constant "Idle")
        (function Idle -> Some () | _ -> None)
        (fun () -> Idle);
      case
        ~title:"Awaiting_preattestations"
        (Tag 1)
        (constant "Awaiting_preattestations")
        (function Awaiting_preattestations -> Some () | _ -> None)
        (fun () -> Awaiting_preattestations);
      case
        ~title:"Awaiting_application"
        (Tag 2)
        (constant "Awaiting_application")
        (function Awaiting_application -> Some () | _ -> None)
        (fun () -> Awaiting_application);
      case
        ~title:"Awaiting_attestationss"
        (Tag 3)
        (constant "Awaiting_attestationss")
        (function Awaiting_attestations -> Some () | _ -> None)
        (fun () -> Awaiting_attestations);
    ]

type round_state = {
  current_round : Round.t;
  current_phase : phase;
  delayed_quorum : Kind.attestation operation list option;
}

type state = {
  global_state : global_state;
  level_state : level_state;
  round_state : round_state;
}

type t = state

let update_current_phase state new_phase =
  {state with round_state = {state.round_state with current_phase = new_phase}}

type timeout_kind =
  | End_of_round of {ending_round : Round.t}
  | Time_to_bake_next_level of {at_round : Round.t}
  | Time_to_forge_block

let timeout_kind_encoding =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"End_of_round"
        (obj2
           (req "kind" (constant "End_of_round"))
           (req "round" Round.encoding))
        (function
          | End_of_round {ending_round} -> Some ((), ending_round) | _ -> None)
        (fun ((), ending_round) -> End_of_round {ending_round});
      case
        (Tag 1)
        ~title:"Time_to_bake_next_level"
        (obj2
           (req "kind" (constant "Time_to_bake_next_level"))
           (req "round" Round.encoding))
        (function
          | Time_to_bake_next_level {at_round} -> Some ((), at_round)
          | _ -> None)
        (fun ((), at_round) -> Time_to_bake_next_level {at_round});
    ]

type event =
  | New_valid_proposal of proposal
  | New_head_proposal of proposal
  | Prequorum_reached of
      Operation_worker.candidate * Kind.preattestation operation list
  | Quorum_reached of
      Operation_worker.candidate * Kind.attestation operation list
  | Timeout of timeout_kind

let event_encoding =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"New_valid_proposal"
        (tup2 (constant "New_valid_proposal") proposal_encoding)
        (function New_valid_proposal p -> Some ((), p) | _ -> None)
        (fun ((), p) -> New_valid_proposal p);
      case
        (Tag 1)
        ~title:"New_head_proposal"
        (tup2 (constant "New_head_proposal") proposal_encoding)
        (function New_head_proposal p -> Some ((), p) | _ -> None)
        (fun ((), p) -> New_head_proposal p);
      case
        (Tag 2)
        ~title:"Prequorum_reached"
        (tup3
           (constant "Prequorum_reached")
           Operation_worker.candidate_encoding
           (Data_encoding.list
              (dynamic_size Operation.encoding_with_legacy_attestation_name)))
        (function
          | Prequorum_reached (candidate, ops) ->
              Some ((), candidate, List.map Operation.pack ops)
          | _ -> None)
        (fun ((), candidate, ops) ->
          Prequorum_reached
            (candidate, Operation_pool.filter_preattestations ops));
      case
        (Tag 3)
        ~title:"Quorum_reached"
        (tup3
           (constant "Quorum_reached")
           Operation_worker.candidate_encoding
           (Data_encoding.list
              (dynamic_size Operation.encoding_with_legacy_attestation_name)))
        (function
          | Quorum_reached (candidate, ops) ->
              Some ((), candidate, List.map Operation.pack ops)
          | _ -> None)
        (fun ((), candidate, ops) ->
          Quorum_reached (candidate, Operation_pool.filter_attestations ops));
      case
        (Tag 4)
        ~title:"Timeout"
        (tup2 (constant "Timeout") timeout_kind_encoding)
        (function Timeout tk -> Some ((), tk) | _ -> None)
        (fun ((), tk) -> Timeout tk);
    ]

(* Disk state *)

module Events = struct
  include Internal_event.Simple

  let section = [Protocol.name; "baker"; "disk"]

  let incompatible_stored_state =
    declare_0
      ~section
      ~name:"incompatible_stored_state"
      ~level:Warning
      ~msg:"found an outdated or corrupted baking state: discarding it"
      ()
end

type state_data = {
  level_data : int32;
  locked_round_data : locked_round option;
  attestable_payload_data : attestable_payload option;
}

let state_data_encoding =
  let open Data_encoding in
  conv
    (fun {level_data; locked_round_data; attestable_payload_data} ->
      (level_data, locked_round_data, attestable_payload_data))
    (fun (level_data, locked_round_data, attestable_payload_data) ->
      {level_data; locked_round_data; attestable_payload_data})
    (obj3
       (req "level" int32)
       (req "locked_round" (option locked_round_encoding))
       (req "attestable_payload" (option attestable_payload_encoding)))

let record_state (state : state) =
  let open Lwt_result_syntax in
  Baking_profiler.record_s "record state" @@ fun () ->
  let cctxt = state.global_state.cctxt in
  let location =
    Baking_files.resolve_location ~chain_id:state.global_state.chain_id `State
  in
  let filename =
    Filename.Infix.(cctxt#get_base_dir // Baking_files.filename location)
  in
  protect @@ fun () ->
  Baking_profiler.record "waiting lock" ;
  cctxt#with_lock @@ fun () ->
  Baking_profiler.stop () ;
  let level_data = state.level_state.current_level in
  let locked_round_data = state.level_state.locked_round in
  let attestable_payload_data = state.level_state.attestable_payload in
  let bytes =
    Baking_profiler.record_f "serializing baking state" @@ fun () ->
    Data_encoding.Binary.to_bytes_exn
      state_data_encoding
      {level_data; locked_round_data; attestable_payload_data}
  in
  let filename_tmp = filename ^ "_tmp" in
  let*! () =
    Baking_profiler.record_s "writing baking state" @@ fun () ->
    Lwt_io.with_file
      ~flags:[Unix.O_CREAT; O_WRONLY; O_TRUNC; O_CLOEXEC; O_SYNC]
      ~mode:Output
      filename_tmp
      (fun channel ->
        Lwt_io.write_from_exactly channel bytes 0 (Bytes.length bytes))
  in
  let*! () = Lwt_unix.rename filename_tmp filename in
  return_unit

type error += Broken_locked_values_invariant

let () =
  register_error_kind
    `Permanent
    ~id:"Baking_state.broken_locked_values_invariant"
    ~title:"Broken locked values invariant"
    ~description:
      "The expected consistency invariant on locked values does not hold"
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "The expected consistency invariant on locked values does not hold")
    Data_encoding.unit
    (function Broken_locked_values_invariant -> Some () | _ -> None)
    (fun () -> Broken_locked_values_invariant)

let may_record_new_state ~previous_state ~new_state =
  let open Lwt_result_syntax in
  if new_state.global_state.config.state_recorder = Baking_configuration.Memory
  then return_unit
  else
    let {
      current_level = previous_current_level;
      locked_round = previous_locked_round;
      attestable_payload = previous_attestable_payload;
      _;
    } =
      previous_state.level_state
    in
    let {
      current_level = new_current_level;
      locked_round = new_locked_round;
      attestable_payload = new_attestable_payload;
      _;
    } =
      new_state.level_state
    in
    let is_new_state_consistent =
      Compare.Int32.(new_current_level > previous_current_level)
      || new_current_level = previous_current_level
         &&
         if Compare.Int32.(new_current_level = previous_current_level) then
           let is_new_locked_round_consistent =
             match (new_locked_round, previous_locked_round) with
             | None, None -> true
             | Some _, None -> true
             | None, Some _ -> false
             | Some new_locked_round, Some previous_locked_round ->
                 Round.(new_locked_round.round >= previous_locked_round.round)
           in
           let is_new_attestable_payload_consistent =
             match (new_attestable_payload, previous_attestable_payload) with
             | None, None -> true
             | Some _, None -> true
             | None, Some _ -> false
             | Some new_attestable_payload, Some previous_attestable_payload ->
                 Round.(
                   new_attestable_payload.proposal.block.round
                   >= previous_attestable_payload.proposal.block.round)
           in
           is_new_locked_round_consistent
           && is_new_attestable_payload_consistent
         else true
    in
    let* () =
      fail_unless is_new_state_consistent Broken_locked_values_invariant
    in
    let has_not_changed =
      previous_state.level_state.current_level
      == new_state.level_state.current_level
      && previous_state.level_state.locked_round
         == new_state.level_state.locked_round
      && previous_state.level_state.attestable_payload
         == new_state.level_state.attestable_payload
    in
    if has_not_changed then return_unit else record_state new_state

let load_attestable_data cctxt location =
  let open Lwt_result_syntax in
  protect (fun () ->
      let filename =
        Filename.Infix.(cctxt#get_base_dir // Baking_files.filename location)
      in
      let*! exists = Lwt_unix.file_exists filename in
      match exists with
      | false -> return_none
      | true ->
          Lwt_io.with_file
            ~flags:[Unix.O_EXCL; O_RDONLY; O_CLOEXEC]
            ~mode:Input
            filename
            (fun channel ->
              let*! str = Lwt_io.read channel in
              match
                Data_encoding.Binary.of_string_opt state_data_encoding str
              with
              | Some state_data -> return_some state_data
              | None ->
                  (* The stored state format is incompatible: discard it. *)
                  let*! () = Events.(emit incompatible_stored_state ()) in
                  return_none))

let may_load_attestable_data state =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let location = Baking_files.resolve_location ~chain_id `State in
  protect ~on_error:(fun _ -> return state) @@ fun () ->
  cctxt#with_lock @@ fun () ->
  let* attestable_data_opt = load_attestable_data cctxt location in
  match attestable_data_opt with
  | None -> return state
  | Some {level_data; locked_round_data; attestable_payload_data} ->
      if Compare.Int32.(state.level_state.current_level = level_data) then
        let loaded_level_state =
          {
            state.level_state with
            locked_round = locked_round_data;
            attestable_payload = attestable_payload_data;
          }
        in
        return {state with level_state = loaded_level_state}
      else return state

(* Helpers *)

module DelegateSet = struct
  include Set.Make (struct
    type t = consensus_key

    let compare {public_key_hash = pkh; _} {public_key_hash = pkh'; _} =
      Signature.Public_key_hash.compare pkh pkh'
  end)

  let find_pkh pkh s =
    let exception Found of elt in
    try
      iter
        (fun ({public_key_hash; _} as delegate) ->
          if Signature.Public_key_hash.equal pkh public_key_hash then
            raise (Found delegate)
          else ())
        s ;
      None
    with Found d -> Some d
end

let delegate_slots attesting_rights delegates =
  let own_delegates = DelegateSet.of_list delegates in
  let own_delegate_first_slots, own_delegate_slots, all_delegate_voting_power =
    List.fold_left
      (fun (own_list, own_map, all_map) slot ->
        let {Plugin.RPC.Validators.consensus_key; delegate; slots; _} = slot in
        let first_slot = Stdlib.List.hd slots in
        let attesting_power = List.length slots in
        let all_map = SlotMap.add first_slot attesting_power all_map in
        let own_list, own_map =
          match DelegateSet.find_pkh consensus_key own_delegates with
          | Some consensus_key ->
              let attesting_slot =
                {
                  consensus_key_and_delegate = (consensus_key, delegate);
                  first_slot;
                  attesting_power;
                }
              in
              ( attesting_slot :: own_list,
                List.fold_left
                  (fun own_map slot -> SlotMap.add slot attesting_slot own_map)
                  own_map
                  slots )
          | None -> (own_list, own_map)
        in
        (own_list, own_map, all_map))
      ([], SlotMap.empty, SlotMap.empty)
      attesting_rights
  in
  Delegate_slots.
    {
      own_delegates = own_delegate_first_slots;
      own_delegate_slots;
      all_delegate_voting_power;
    }

let compute_delegate_slots (cctxt : Protocol_client_context.full)
    ?(block = `Head 0) ~level ~chain delegates =
  let open Lwt_result_syntax in
  let*? level = Environment.wrap_tzresult (Raw_level.of_int32 level) in
  let* attesting_rights =
    Plugin.RPC.Validators.get cctxt (chain, block) ~levels:[level]
  in
  delegate_slots attesting_rights delegates |> return

let round_proposer state ~level round =
  let slots =
    match level with
    | `Current -> state.level_state.delegate_slots
    | `Next -> state.level_state.next_level_delegate_slots
  in
  let committee_size =
    state.global_state.constants.parametric.consensus_committee_size
  in
  Round.to_slot round ~committee_size |> function
  | Error _ -> None
  | Ok slot -> Delegate_slots.own_slot_owner slots ~slot

let cache_size_limit = 100

let create_cache () =
  let open Baking_cache in
  {
    known_timestamps = Timestamp_of_round_cache.create cache_size_limit;
    round_timestamps = Round_timestamp_interval_cache.create cache_size_limit;
  }

(* Pretty-printers *)

let pp_validation_mode fmt = function
  | Node -> Format.fprintf fmt "node"
  | Local _ -> Format.fprintf fmt "local"

let pp_global_state fmt {chain_id; config; validation_mode; delegates; _} =
  Format.fprintf
    fmt
    "@[<v 2>Global state:@ chain_id: %a@ @[<v 2>config:@ %a@]@ \
     validation_mode: %a@ @[<v 2>delegates:@ %a@]@]"
    Chain_id.pp
    chain_id
    Baking_configuration.pp
    config
    pp_validation_mode
    validation_mode
    Format.(pp_print_list pp_consensus_key)
    delegates

let pp_option pp fmt = function
  | None -> Format.fprintf fmt "none"
  | Some v -> Format.fprintf fmt "%a" pp v

let pp_prequorum fmt {level; round; block_payload_hash; preattestations} =
  Format.fprintf
    fmt
    "level: %ld, round: %a, payload_hash: %a, preattestations: %d"
    level
    Round.pp
    round
    Block_payload_hash.pp_short
    block_payload_hash
    (List.length preattestations)

let pp_block_info fmt
    {
      hash;
      shell;
      payload_hash;
      round;
      prequorum;
      quorum;
      dal_attestations;
      payload;
      payload_round;
    } =
  Format.fprintf
    fmt
    "@[<v 2>Block:@ hash: %a@ payload_hash: %a@ level: %ld@ round: %a@ \
     prequorum: %a@ quorum: %d attestations@ dal_attestations: %d@ payload: \
     %a@ payload round: %a@]"
    Block_hash.pp
    hash
    Block_payload_hash.pp_short
    payload_hash
    shell.level
    Round.pp
    round
    (pp_option pp_prequorum)
    prequorum
    (List.length quorum)
    (List.length dal_attestations)
    Operation_pool.pp_payload
    payload
    Round.pp
    payload_round

let pp_proposal fmt {block; _} = pp_block_info fmt block

let pp_locked_round fmt ({payload_hash; round} : locked_round) =
  Format.fprintf
    fmt
    "payload hash: %a, round: %a"
    Block_payload_hash.pp_short
    payload_hash
    Round.pp
    round

let pp_attestable_payload fmt {proposal; prequorum} =
  Format.fprintf
    fmt
    "proposal: %a, prequorum: %a"
    Block_hash.pp
    proposal.block.hash
    pp_prequorum
    prequorum

let pp_elected_block fmt {proposal; attestation_qc} =
  Format.fprintf
    fmt
    "@[<v 2>%a@ nb quorum attestations: %d@]"
    pp_block_info
    proposal.block
    (List.length attestation_qc)

let pp_delegate_slot fmt
    {consensus_key_and_delegate; first_slot; attesting_power} =
  Format.fprintf
    fmt
    "slots: @[<h>first_slot: %a@],@ delegate: %a,@ attesting_power: %d"
    Slot.pp
    first_slot
    pp_consensus_key_and_delegate
    consensus_key_and_delegate
    attesting_power

let pp_delegate_slots fmt Delegate_slots.{own_delegate_slots; _} =
  Format.fprintf
    fmt
    "@[<v>%a@]"
    Format.(
      pp_print_list ~pp_sep:pp_print_cut (fun fmt (slot, attesting_slot) ->
          Format.fprintf
            fmt
            "slot: %a, %a"
            Slot.pp
            slot
            pp_delegate_slot
            attesting_slot))
    (SlotMap.bindings own_delegate_slots)

let pp_next_forged_block fmt
    {delegate = consensus_key_and_delegate; block_header; _} =
  Format.fprintf
    fmt
    "predecessor block hash: %a, payload hash: %a, level: %ld, delegate: %a"
    Block_hash.pp
    block_header.shell.predecessor
    Block_payload_hash.pp_short
    block_header.protocol_data.contents.payload_hash
    block_header.shell.level
    pp_consensus_key_and_delegate
    consensus_key_and_delegate

let pp_level_state fmt
    {
      current_level;
      latest_proposal;
      is_latest_proposal_applied;
      locked_round;
      attestable_payload;
      elected_block;
      delegate_slots;
      next_level_delegate_slots;
      next_level_proposed_round;
      next_forged_block;
    } =
  Format.fprintf
    fmt
    "@[<v 2>Level state:@ current level: %ld@ @[<v 2>proposal (applied:%b):@ \
     %a@]@ locked round: %a@ attestable payload: %a@ elected block: %a@ @[<v \
     2>own delegate slots:@ %a@]@ @[<v 2>next level own delegate slots:@ %a@]@ \
     next level proposed round: %a@  @next forged block: %a@]"
    current_level
    is_latest_proposal_applied
    pp_proposal
    latest_proposal
    (pp_option pp_locked_round)
    locked_round
    (pp_option pp_attestable_payload)
    attestable_payload
    (pp_option pp_elected_block)
    elected_block
    pp_delegate_slots
    delegate_slots
    pp_delegate_slots
    next_level_delegate_slots
    (pp_option Round.pp)
    next_level_proposed_round
    (pp_option pp_next_forged_block)
    next_forged_block

let pp_phase fmt = function
  | Idle -> Format.fprintf fmt "idle"
  | Awaiting_preattestations -> Format.fprintf fmt "awaiting preattestations"
  | Awaiting_application -> Format.fprintf fmt "awaiting application"
  | Awaiting_attestations -> Format.fprintf fmt "awaiting attestations"

let pp_round_state fmt {current_round; current_phase; delayed_quorum} =
  Format.fprintf
    fmt
    "@[<v 2>Round state:@ round: %a,@ phase: %a,@ delayed_quorum: %a@]"
    Round.pp
    current_round
    pp_phase
    current_phase
    (pp_option Format.pp_print_int)
    (Option.map List.length delayed_quorum)

let pp fmt {global_state; level_state; round_state} =
  Format.fprintf
    fmt
    "@[<v 2>State:@ %a@ %a@ %a@]"
    pp_global_state
    global_state
    pp_level_state
    level_state
    pp_round_state
    round_state

let pp_timeout_kind fmt = function
  | End_of_round {ending_round} ->
      Format.fprintf fmt "end of round %a" Round.pp ending_round
  | Time_to_bake_next_level {at_round} ->
      Format.fprintf fmt "time to bake next level at round %a" Round.pp at_round
  | Time_to_forge_block -> Format.fprintf fmt "time to forge block"

let pp_event fmt = function
  | New_valid_proposal proposal ->
      Format.fprintf
        fmt
        "new valid proposal received: %a"
        pp_block_info
        proposal.block
  | New_head_proposal proposal ->
      Format.fprintf
        fmt
        "new head proposal received: %a"
        pp_block_info
        proposal.block
  | Prequorum_reached (candidate, preattestations) ->
      Format.fprintf
        fmt
        "prequorum reached with %d preattestations for %a at round %a"
        (List.length preattestations)
        Block_hash.pp
        candidate.Operation_worker.hash
        Round.pp
        candidate.round_watched
  | Quorum_reached (candidate, attestations) ->
      Format.fprintf
        fmt
        "quorum reached with %d attestations for %a at round %a"
        (List.length attestations)
        Block_hash.pp
        candidate.Operation_worker.hash
        Round.pp
        candidate.round_watched
  | Timeout kind ->
      Format.fprintf fmt "timeout reached: %a" pp_timeout_kind kind

let pp_short_event fmt =
  let open Format in
  function
  | New_valid_proposal _ -> fprintf fmt "new valid proposal"
  | New_head_proposal _ -> fprintf fmt "new head proposal"
  | Prequorum_reached (_, _) -> fprintf fmt "prequorum reached"
  | Quorum_reached (_, _) -> fprintf fmt "quorum reached"
  | Timeout _ -> fprintf fmt "timeout"
