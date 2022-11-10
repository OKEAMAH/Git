(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2021 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2021-2022 Trili Tech, <contact@trili.tech>                  *)
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

type dal = {
  feature_enable : bool;
  number_of_slots : int;
  endorsement_lag : int;
  availability_threshold : int;
  cryptobox_parameters : Dal.parameters;
}

let dal_encoding =
  let open Data_encoding in
  conv
    (fun {
           feature_enable;
           number_of_slots;
           endorsement_lag;
           availability_threshold;
           cryptobox_parameters;
         } ->
      ( ( feature_enable,
          number_of_slots,
          endorsement_lag,
          availability_threshold ),
        cryptobox_parameters ))
    (fun ( ( feature_enable,
             number_of_slots,
             endorsement_lag,
             availability_threshold ),
           cryptobox_parameters ) ->
      {
        feature_enable;
        number_of_slots;
        endorsement_lag;
        availability_threshold;
        cryptobox_parameters;
      })
    (merge_objs
       (obj4
          (req "feature_enable" bool)
          (req "number_of_slots" int16)
          (req "endorsement_lag" int16)
          (req "availability_threshold" int16))
       Dal.parameters_encoding)

(* The encoded representation of this type is stored in the context as
   bytes. Changing the encoding, or the value of these constants from
   the previous protocol may break the context migration, or (even
   worse) yield an incorrect context after migration.

   If you change this encoding compared to `Constants_parametric_previous_repr.t`,
   you should ensure that there is a proper migration of the constants
   during context migration. See: `Raw_context.prepare_first_block` *)

type tx_rollup = {
  enable : bool;
  origination_size : int;
  hard_size_limit_per_inbox : int;
  hard_size_limit_per_message : int;
  commitment_bond : Tez_repr.t;
  finality_period : int;
  withdraw_period : int;
  max_inboxes_count : int;
  max_messages_per_inbox : int;
  max_commitments_count : int;
  cost_per_byte_ema_factor : int;
  max_ticket_payload_size : int;
  max_withdrawals_per_batch : int;
  rejection_max_proof_size : int;
  sunset_level : int32;
}

type sc_rollup = {
  enable : bool;
  origination_size : int;
  challenge_window_in_blocks : int;
  max_number_of_messages_per_commitment_period : int;
  stake_amount : Tez_repr.t;
  commitment_period_in_blocks : int;
  max_lookahead_in_blocks : int32;
  max_active_outbox_levels : int32;
  max_outbox_messages_per_level : int;
  number_of_sections_in_dissection : int;
  timeout_period_in_blocks : int;
  max_number_of_stored_cemented_commitments : int;
}

type zk_rollup = {
  enable : bool;
  origination_size : int;
  min_pending_to_process : int;
}

type t = {
  preserved_cycles : int;
  blocks_per_cycle : int32;
  blocks_per_commitment : int32;
  nonce_revelation_threshold : int32;
  blocks_per_stake_snapshot : int32;
  cycles_per_voting_period : int32;
  hard_gas_limit_per_operation : Gas_limit_repr.Arith.integral;
  hard_gas_limit_per_block : Gas_limit_repr.Arith.integral;
  proof_of_work_threshold : int64;
  minimal_stake : Tez_repr.t;
  vdf_difficulty : int64;
  seed_nonce_revelation_tip : Tez_repr.t;
  origination_size : int;
  baking_reward_fixed_portion : Tez_repr.t;
  baking_reward_bonus_per_slot : Tez_repr.t;
  endorsing_reward_per_slot : Tez_repr.t;
  cost_per_byte : Tez_repr.t;
  hard_storage_limit_per_operation : Z.t;
  quorum_min : int32;
  quorum_max : int32;
  min_proposal_quorum : int32;
  liquidity_baking_subsidy : Tez_repr.t;
  liquidity_baking_toggle_ema_threshold : int32;
  max_operations_time_to_live : int;
  minimal_block_delay : Period_repr.t;
  delay_increment_per_round : Period_repr.t;
  minimal_participation_ratio : Ratio_repr.t;
  consensus_committee_size : int;
  consensus_threshold : int;
  max_slashing_period : int;
  frozen_deposits_percentage : int;
  double_baking_punishment : Tez_repr.t;
  ratio_of_frozen_deposits_slashed_per_double_endorsement : Ratio_repr.t;
  testnet_dictator : Signature.Public_key_hash.t option;
  initial_seed : State_hash.t option;
  (* If a new cache is added, please also modify the
     [cache_layout_size] value. *)
  cache_script_size : int;
  cache_stake_distribution_cycles : int;
  cache_sampler_state_cycles : int;
  tx_rollup : tx_rollup;
  dal : dal;
  sc_rollup : sc_rollup;
  zk_rollup : zk_rollup;
}

let tx_rollup_encoding =
  let open Data_encoding in
  conv
    (fun (c : tx_rollup) ->
      ( ( c.enable,
          c.origination_size,
          c.hard_size_limit_per_inbox,
          c.hard_size_limit_per_message,
          c.max_withdrawals_per_batch,
          c.commitment_bond,
          c.finality_period,
          c.withdraw_period,
          c.max_inboxes_count,
          c.max_messages_per_inbox ),
        ( c.max_commitments_count,
          c.cost_per_byte_ema_factor,
          c.max_ticket_payload_size,
          c.rejection_max_proof_size,
          c.sunset_level ) ))
    (fun ( ( tx_rollup_enable,
             tx_rollup_origination_size,
             tx_rollup_hard_size_limit_per_inbox,
             tx_rollup_hard_size_limit_per_message,
             tx_rollup_max_withdrawals_per_batch,
             tx_rollup_commitment_bond,
             tx_rollup_finality_period,
             tx_rollup_withdraw_period,
             tx_rollup_max_inboxes_count,
             tx_rollup_max_messages_per_inbox ),
           ( tx_rollup_max_commitments_count,
             tx_rollup_cost_per_byte_ema_factor,
             tx_rollup_max_ticket_payload_size,
             tx_rollup_rejection_max_proof_size,
             tx_rollup_sunset_level ) ) ->
      {
        enable = tx_rollup_enable;
        origination_size = tx_rollup_origination_size;
        hard_size_limit_per_inbox = tx_rollup_hard_size_limit_per_inbox;
        hard_size_limit_per_message = tx_rollup_hard_size_limit_per_message;
        max_withdrawals_per_batch = tx_rollup_max_withdrawals_per_batch;
        commitment_bond = tx_rollup_commitment_bond;
        finality_period = tx_rollup_finality_period;
        withdraw_period = tx_rollup_withdraw_period;
        max_inboxes_count = tx_rollup_max_inboxes_count;
        max_messages_per_inbox = tx_rollup_max_messages_per_inbox;
        max_commitments_count = tx_rollup_max_commitments_count;
        cost_per_byte_ema_factor = tx_rollup_cost_per_byte_ema_factor;
        max_ticket_payload_size = tx_rollup_max_ticket_payload_size;
        rejection_max_proof_size = tx_rollup_rejection_max_proof_size;
        sunset_level = tx_rollup_sunset_level;
      })
    (merge_objs
       (obj10
          (req "tx_rollup_enable" bool)
          (req "tx_rollup_origination_size" int31)
          (req "tx_rollup_hard_size_limit_per_inbox" int31)
          (req "tx_rollup_hard_size_limit_per_message" int31)
          (req "tx_rollup_max_withdrawals_per_batch" int31)
          (req "tx_rollup_commitment_bond" Tez_repr.encoding)
          (req "tx_rollup_finality_period" int31)
          (req "tx_rollup_withdraw_period" int31)
          (req "tx_rollup_max_inboxes_count" int31)
          (req "tx_rollup_max_messages_per_inbox" int31))
       (obj5
          (req "tx_rollup_max_commitments_count" int31)
          (req "tx_rollup_cost_per_byte_ema_factor" int31)
          (req "tx_rollup_max_ticket_payload_size" int31)
          (req "tx_rollup_rejection_max_proof_size" int31)
          (req "tx_rollup_sunset_level" int32)))

let sc_rollup_encoding =
  let open Data_encoding in
  conv
    (fun (c : sc_rollup) ->
      ( ( c.enable,
          c.origination_size,
          c.challenge_window_in_blocks,
          c.max_number_of_messages_per_commitment_period,
          c.stake_amount,
          c.commitment_period_in_blocks,
          c.max_lookahead_in_blocks,
          c.max_active_outbox_levels,
          c.max_outbox_messages_per_level,
          c.number_of_sections_in_dissection ),
        (c.timeout_period_in_blocks, c.max_number_of_stored_cemented_commitments)
      ))
    (fun ( ( sc_rollup_enable,
             sc_rollup_origination_size,
             sc_rollup_challenge_window_in_blocks,
             sc_rollup_max_number_of_messages_per_commitment_period,
             sc_rollup_stake_amount,
             sc_rollup_commitment_period_in_blocks,
             sc_rollup_max_lookahead_in_blocks,
             sc_rollup_max_active_outbox_levels,
             sc_rollup_max_outbox_messages_per_level,
             sc_rollup_number_of_sections_in_dissection ),
           ( sc_rollup_timeout_period_in_blocks,
             sc_rollup_max_number_of_cemented_commitments ) ) ->
      {
        enable = sc_rollup_enable;
        origination_size = sc_rollup_origination_size;
        challenge_window_in_blocks = sc_rollup_challenge_window_in_blocks;
        max_number_of_messages_per_commitment_period =
          sc_rollup_max_number_of_messages_per_commitment_period;
        stake_amount = sc_rollup_stake_amount;
        commitment_period_in_blocks = sc_rollup_commitment_period_in_blocks;
        max_lookahead_in_blocks = sc_rollup_max_lookahead_in_blocks;
        max_active_outbox_levels = sc_rollup_max_active_outbox_levels;
        max_outbox_messages_per_level = sc_rollup_max_outbox_messages_per_level;
        number_of_sections_in_dissection =
          sc_rollup_number_of_sections_in_dissection;
        timeout_period_in_blocks = sc_rollup_timeout_period_in_blocks;
        max_number_of_stored_cemented_commitments =
          sc_rollup_max_number_of_cemented_commitments;
      })
    (merge_objs
       (obj10
          (req "sc_rollup_enable" bool)
          (req "sc_rollup_origination_size" int31)
          (req "sc_rollup_challenge_window_in_blocks" int31)
          (req "sc_rollup_max_number_of_messages_per_commitment_period" int31)
          (req "sc_rollup_stake_amount" Tez_repr.encoding)
          (req "sc_rollup_commitment_period_in_blocks" int31)
          (req "sc_rollup_max_lookahead_in_blocks" int32)
          (req "sc_rollup_max_active_outbox_levels" int32)
          (req "sc_rollup_max_outbox_messages_per_level" int31)
          (req "sc_rollup_number_of_sections_in_dissection" uint8))
       (obj2
          (req "sc_rollup_timeout_period_in_blocks" int31)
          (req "sc_rollup_max_number_of_cemented_commitments" int31)))

let zk_rollup_encoding =
  let open Data_encoding in
  conv
    (fun ({enable; origination_size; min_pending_to_process} : zk_rollup) ->
      (enable, origination_size, min_pending_to_process))
    (fun ( zk_rollup_enable,
           zk_rollup_origination_size,
           zk_rollup_min_pending_to_process ) ->
      {
        enable = zk_rollup_enable;
        origination_size = zk_rollup_origination_size;
        min_pending_to_process = zk_rollup_min_pending_to_process;
      })
    (obj3
       (req "zk_rollup_enable" bool)
       (req "zk_rollup_origination_size" int31)
       (req "zk_rollup_min_pending_to_process" int31))

let encoding =
  let open Data_encoding in
  conv
    (fun c ->
      ( ( c.preserved_cycles,
          c.blocks_per_cycle,
          c.blocks_per_commitment,
          c.nonce_revelation_threshold,
          c.blocks_per_stake_snapshot,
          c.cycles_per_voting_period,
          c.hard_gas_limit_per_operation,
          c.hard_gas_limit_per_block,
          c.proof_of_work_threshold,
          c.minimal_stake ),
        ( ( c.vdf_difficulty,
            c.seed_nonce_revelation_tip,
            c.origination_size,
            c.baking_reward_fixed_portion,
            c.baking_reward_bonus_per_slot,
            c.endorsing_reward_per_slot,
            c.cost_per_byte,
            c.hard_storage_limit_per_operation,
            c.quorum_min ),
          ( ( c.quorum_max,
              c.min_proposal_quorum,
              c.liquidity_baking_subsidy,
              c.liquidity_baking_toggle_ema_threshold,
              c.max_operations_time_to_live,
              c.minimal_block_delay,
              c.delay_increment_per_round,
              c.consensus_committee_size,
              c.consensus_threshold ),
            ( ( c.minimal_participation_ratio,
                c.max_slashing_period,
                c.frozen_deposits_percentage,
                c.double_baking_punishment,
                c.ratio_of_frozen_deposits_slashed_per_double_endorsement,
                c.testnet_dictator,
                c.initial_seed ),
              ( ( c.cache_script_size,
                  c.cache_stake_distribution_cycles,
                  c.cache_sampler_state_cycles ),
                (c.tx_rollup, (c.dal, (c.sc_rollup, c.zk_rollup))) ) ) ) ) ))
    (fun ( ( preserved_cycles,
             blocks_per_cycle,
             blocks_per_commitment,
             nonce_revelation_threshold,
             blocks_per_stake_snapshot,
             cycles_per_voting_period,
             hard_gas_limit_per_operation,
             hard_gas_limit_per_block,
             proof_of_work_threshold,
             minimal_stake ),
           ( ( vdf_difficulty,
               seed_nonce_revelation_tip,
               origination_size,
               baking_reward_fixed_portion,
               baking_reward_bonus_per_slot,
               endorsing_reward_per_slot,
               cost_per_byte,
               hard_storage_limit_per_operation,
               quorum_min ),
             ( ( quorum_max,
                 min_proposal_quorum,
                 liquidity_baking_subsidy,
                 liquidity_baking_toggle_ema_threshold,
                 max_operations_time_to_live,
                 minimal_block_delay,
                 delay_increment_per_round,
                 consensus_committee_size,
                 consensus_threshold ),
               ( ( minimal_participation_ratio,
                   max_slashing_period,
                   frozen_deposits_percentage,
                   double_baking_punishment,
                   ratio_of_frozen_deposits_slashed_per_double_endorsement,
                   testnet_dictator,
                   initial_seed ),
                 ( ( cache_script_size,
                     cache_stake_distribution_cycles,
                     cache_sampler_state_cycles ),
                   (tx_rollup, (dal, (sc_rollup, zk_rollup))) ) ) ) ) ) ->
      {
        preserved_cycles;
        blocks_per_cycle;
        blocks_per_commitment;
        nonce_revelation_threshold;
        blocks_per_stake_snapshot;
        cycles_per_voting_period;
        hard_gas_limit_per_operation;
        hard_gas_limit_per_block;
        proof_of_work_threshold;
        minimal_stake;
        vdf_difficulty;
        seed_nonce_revelation_tip;
        origination_size;
        baking_reward_fixed_portion;
        baking_reward_bonus_per_slot;
        endorsing_reward_per_slot;
        cost_per_byte;
        hard_storage_limit_per_operation;
        quorum_min;
        quorum_max;
        min_proposal_quorum;
        liquidity_baking_subsidy;
        liquidity_baking_toggle_ema_threshold;
        max_operations_time_to_live;
        minimal_block_delay;
        delay_increment_per_round;
        minimal_participation_ratio;
        max_slashing_period;
        consensus_committee_size;
        consensus_threshold;
        frozen_deposits_percentage;
        double_baking_punishment;
        ratio_of_frozen_deposits_slashed_per_double_endorsement;
        testnet_dictator;
        initial_seed;
        cache_script_size;
        cache_stake_distribution_cycles;
        cache_sampler_state_cycles;
        tx_rollup;
        dal;
        sc_rollup;
        zk_rollup;
      })
    (merge_objs
       (obj10
          (req "preserved_cycles" uint8)
          (req "blocks_per_cycle" int32)
          (req "blocks_per_commitment" int32)
          (req "nonce_revelation_threshold" int32)
          (req "blocks_per_stake_snapshot" int32)
          (req "cycles_per_voting_period" int32)
          (req
             "hard_gas_limit_per_operation"
             Gas_limit_repr.Arith.z_integral_encoding)
          (req
             "hard_gas_limit_per_block"
             Gas_limit_repr.Arith.z_integral_encoding)
          (req "proof_of_work_threshold" int64)
          (req "minimal_stake" Tez_repr.encoding))
       (merge_objs
          (obj9
             (req "vdf_difficulty" int64)
             (req "seed_nonce_revelation_tip" Tez_repr.encoding)
             (req "origination_size" int31)
             (req "baking_reward_fixed_portion" Tez_repr.encoding)
             (req "baking_reward_bonus_per_slot" Tez_repr.encoding)
             (req "endorsing_reward_per_slot" Tez_repr.encoding)
             (req "cost_per_byte" Tez_repr.encoding)
             (req "hard_storage_limit_per_operation" z)
             (req "quorum_min" int32))
          (merge_objs
             (obj9
                (req "quorum_max" int32)
                (req "min_proposal_quorum" int32)
                (req "liquidity_baking_subsidy" Tez_repr.encoding)
                (req "liquidity_baking_toggle_ema_threshold" int32)
                (req "max_operations_time_to_live" int16)
                (req "minimal_block_delay" Period_repr.encoding)
                (req "delay_increment_per_round" Period_repr.encoding)
                (req "consensus_committee_size" int31)
                (req "consensus_threshold" int31))
             (merge_objs
                (obj7
                   (req "minimal_participation_ratio" Ratio_repr.encoding)
                   (req "max_slashing_period" int31)
                   (req "frozen_deposits_percentage" int31)
                   (req "double_baking_punishment" Tez_repr.encoding)
                   (req
                      "ratio_of_frozen_deposits_slashed_per_double_endorsement"
                      Ratio_repr.encoding)
                   (opt "testnet_dictator" Signature.Public_key_hash.encoding)
                   (opt "initial_seed" State_hash.encoding))
                (merge_objs
                   (obj3
                      (req "cache_script_size" int31)
                      (req "cache_stake_distribution_cycles" int8)
                      (req "cache_sampler_state_cycles" int8))
                   (merge_objs
                      tx_rollup_encoding
                      (merge_objs
                         (obj1 (req "dal_parametric" dal_encoding))
                         (merge_objs sc_rollup_encoding zk_rollup_encoding))))))))

module History = struct
  type parametric = t

  type content = {parametric : parametric; activation_level : Raw_level_repr.t}

  let content_encoding =
    let open Data_encoding in
    conv
      (fun {parametric; activation_level} -> (parametric, activation_level))
      (fun (parametric, activation_level) -> {parametric; activation_level})
      (obj2
         (req "parametric" encoding)
         (req "activation_level" Raw_level_repr.encoding))

  module Leaf = struct
    type t = content

    let to_bytes = Data_encoding.Binary.to_bytes_exn content_encoding
  end

  module Content_prefix = struct
    let (_prefix : string) = "dash1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\094\219" (* dash1(55) *)

    let size = Some 32

    let name = "dal_skip_list_content"

    let title = "A hash to represent the content of a cell in the skip list"
  end

  module Content_hash = Blake2B.Make (Base58) (Content_prefix)
  module Merkle_list = Merkle_list.Make (Leaf) (Content_hash)

  (* Pointers of the skip lists are used to encode the content and the
     backpointers. *)
  module Pointer_prefix = struct
    let (_prefix : string) = "dask1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\115\035" (* dask1(55) *)

    let size = Some 32

    let name = "dal_skip_list_pointer"

    let title = "A hash that represents the skip list pointers"
  end

  module Pointer_hash = Blake2B.Make (Base58) (Pointer_prefix)

  module Skip_list_parameters = struct
    let basis = 2
  end

  type error += Add_element_in_slots_skip_list_violates_ordering

  let () =
    register_error_kind
      `Temporary
      ~id:
        "Constants_parametric_repr.add_element_in_slots_skip_list_violates_ordering"
      ~title:"Add an element in slots skip list that violates ordering"
      ~description:
        "Attempting to add an element on top of the  skip list that violates \
         the ordering."
      Data_encoding.unit
      (function
        | Add_element_in_slots_skip_list_violates_ordering -> Some ()
        | _ -> None)
      (fun () -> Add_element_in_slots_skip_list_violates_ordering)

  module Skip_list = struct
    include Skip_list_repr.Make (Skip_list_parameters)

    (** All confirmed DAL slots will be stored in a skip list, where only the
        last cell is remembered in the L1 context. The skip list is used in
        the proof phase of a refutation game to verify whether a given slot
        exists (i.e., confirmed) or not in the skip list. The skip list is
        supposed to be sorted, as its 'search' function explicitly uses a given
        `compare` function during the list traversal to quickly (in log(size))
        reach the target if any.

        In our case, we will store one slot per cell in the skip list and
        maintain that the list is well sorted (and without redundancy) w.r.t.
        the [compare_slot_id] function.

        Below, we redefine the [next] function (that allows adding elements
        on top of the list) to enforce that the constructed skip list is
        well-sorted. We also define a wrapper around the search function to
        guarantee that it can only be called with the adequate compare function.
    *)

    let next ~prev_cell ~prev_cell_ptr elt =
      let open Tzresult_syntax in
      let* () =
        error_when
          (Compare.Int.( <= )
             (Raw_level_repr.compare
                elt.activation_level
                (content prev_cell).activation_level)
             0)
          Add_element_in_slots_skip_list_violates_ordering
      in
      return @@ next ~prev_cell ~prev_cell_ptr elt

    let _search ~deref ~cell ~target_id =
      search ~deref ~cell ~compare:(fun elt ->
          Raw_level_repr.compare elt.activation_level target_id)
  end

  module V1 = struct
    (* A pointer to a cell is the hash of its content and all the back
       pointers. *)
    type ptr = Pointer_hash.t

    type history = (content, ptr) Skip_list.cell

    type t = history

    let encoding = Skip_list.encoding Pointer_hash.encoding content_encoding

    let hash_skip_list_cell cell =
      let content = Skip_list.content cell in
      let back_pointers_hashes = Skip_list.back_pointers cell in
      Data_encoding.Binary.to_bytes_exn content_encoding content
      :: List.map Pointer_hash.to_bytes back_pointers_hashes
      |> Pointer_hash.hash_bytes

    let equal : history -> history -> bool =
      Skip_list.equal Pointer_hash.equal (fun a b ->
          Raw_level_repr.equal a.activation_level b.activation_level)

    let pp fmt (history : history) =
      let history_hash = hash_skip_list_cell history in
      Format.fprintf
        fmt
        "@[hash : %a@;%a@]"
        Pointer_hash.pp
        history_hash
        (Skip_list.pp
           ~pp_content:(fun fmt c ->
             Format.fprintf
               fmt
               "%a -> <parametric>"
               Raw_level_repr.pp
               c.activation_level)
           ~pp_ptr:Pointer_hash.pp)
        history

    let genesis = Skip_list.genesis

    module Cache =
      Bounded_history_repr.Make
        (struct
          let name = "constants_parametric_repr_history_cache"
        end)
        (Pointer_hash)
        (struct
          type t = history

          let encoding = encoding

          let pp = pp

          let equal = equal
        end)

    let add t cache content =
      let open Tzresult_syntax in
      let prev_cell_ptr = hash_skip_list_cell t in
      let* cache = Cache.remember prev_cell_ptr t cache in
      let* new_cell = Skip_list.next ~prev_cell:t ~prev_cell_ptr content in
      return (new_cell, cache)
  end

  include V1
end
