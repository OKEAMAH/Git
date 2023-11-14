// This is a generated file! Please edit source .ksy file and use kaitai-struct-compiler to rebuild

#![allow(unused_imports)]
#![allow(non_snake_case)]
#![allow(non_camel_case_types)]
#![allow(irrefutable_let_patterns)]
#![allow(unused_comparisons)]
#![allow(arithmetic_overflow)]
#![allow(overflowing_literals)]

extern crate kaitai;
use kaitai::*;
use std::convert::{TryFrom, TryInto};
use std::cell::{Ref, Cell, RefCell};
use std::rc::{Rc, Weak};

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    proof_of_work_nonce_size: RefCell<u8>,
    nonce_length: RefCell<u8>,
    max_anon_ops_per_block: RefCell<u8>,
    max_operation_data_length: RefCell<i32>,
    max_proposals_per_delegate: RefCell<u8>,
    max_micheline_node_count: RefCell<i32>,
    max_micheline_bytes_limit: RefCell<i32>,
    max_allowed_global_constants_depth: RefCell<i32>,
    cache_layout_size: RefCell<u8>,
    michelson_maximum_type_size: RefCell<u16>,
    max_slashing_period: RefCell<u8>,
    smart_rollup_max_wrapped_proof_binary_size: RefCell<i32>,
    smart_rollup_message_size_limit: RefCell<i32>,
    smart_rollup_max_number_of_messages_per_level: RefCell<OptRc<AlphaConstants_N>>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    nonce_revelation_threshold: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    cycles_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<AlphaConstants_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<AlphaConstants_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    minimal_stake: RefCell<OptRc<AlphaConstants_N>>,
    minimal_frozen_stake: RefCell<OptRc<AlphaConstants_N>>,
    vdf_difficulty: RefCell<i64>,
    origination_size: RefCell<i32>,
    issuance_weights: RefCell<OptRc<AlphaConstants_IssuanceWeights>>,
    cost_per_byte: RefCell<OptRc<AlphaConstants_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<AlphaConstants_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_toggle_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<AlphaConstants_MinimalParticipationRatio>>,
    limit_of_delegation_over_baking: RefCell<u8>,
    percentage_of_frozen_deposits_slashed_per_double_baking: RefCell<u8>,
    percentage_of_frozen_deposits_slashed_per_double_attestation: RefCell<u8>,
    testnet_dictator_tag: RefCell<AlphaConstants_Bool>,
    testnet_dictator: RefCell<OptRc<AlphaConstants_PublicKeyHash>>,
    initial_seed_tag: RefCell<AlphaConstants_Bool>,
    initial_seed: RefCell<Vec<u8>>,
    cache_script_size: RefCell<i32>,
    cache_stake_distribution_cycles: RefCell<i8>,
    cache_sampler_state_cycles: RefCell<i8>,
    dal_parametric: RefCell<OptRc<AlphaConstants_DalParametric>>,
    smart_rollup_enable: RefCell<AlphaConstants_Bool>,
    smart_rollup_arith_pvm_enable: RefCell<AlphaConstants_Bool>,
    smart_rollup_origination_size: RefCell<i32>,
    smart_rollup_challenge_window_in_blocks: RefCell<i32>,
    smart_rollup_stake_amount: RefCell<OptRc<AlphaConstants_N>>,
    smart_rollup_commitment_period_in_blocks: RefCell<i32>,
    smart_rollup_max_lookahead_in_blocks: RefCell<i32>,
    smart_rollup_max_active_outbox_levels: RefCell<i32>,
    smart_rollup_max_outbox_messages_per_level: RefCell<i32>,
    smart_rollup_number_of_sections_in_dissection: RefCell<u8>,
    smart_rollup_timeout_period_in_blocks: RefCell<i32>,
    smart_rollup_max_number_of_cemented_commitments: RefCell<i32>,
    smart_rollup_max_number_of_parallel_games: RefCell<i32>,
    smart_rollup_reveal_activation_level: RefCell<OptRc<AlphaConstants_SmartRollupRevealActivationLevel>>,
    smart_rollup_private_enable: RefCell<AlphaConstants_Bool>,
    smart_rollup_riscv_pvm_enable: RefCell<AlphaConstants_Bool>,
    zk_rollup_enable: RefCell<AlphaConstants_Bool>,
    zk_rollup_origination_size: RefCell<i32>,
    zk_rollup_min_pending_to_process: RefCell<i32>,
    zk_rollup_max_ticket_payload_size: RefCell<i32>,
    global_limit_of_staking_over_baking: RefCell<u8>,
    edge_of_staking_over_delegation: RefCell<u8>,
    adaptive_issuance_launch_ema_threshold: RefCell<i32>,
    adaptive_rewards_params: RefCell<OptRc<AlphaConstants_AdaptiveRewardsParams>>,
    adaptive_issuance_activation_vote_enable: RefCell<AlphaConstants_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.proof_of_work_nonce_size.borrow_mut() = _io.read_u1()?.into();
        *self_rc.nonce_length.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_anon_ops_per_block.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_operation_data_length.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_proposals_per_delegate.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_micheline_node_count.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_micheline_bytes_limit.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_allowed_global_constants_depth.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_layout_size.borrow_mut() = _io.read_u1()?.into();
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.max_slashing_period.borrow_mut() = _io.read_u1()?.into();
        *self_rc.smart_rollup_max_wrapped_proof_binary_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_message_size_limit.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.smart_rollup_max_number_of_messages_per_level.borrow_mut() = t;
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.nonce_revelation_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycles_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.minimal_stake.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.minimal_frozen_stake.borrow_mut() = t;
        *self_rc.vdf_difficulty.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_IssuanceWeights>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_weights.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_toggle_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.limit_of_delegation_over_baking.borrow_mut() = _io.read_u1()?.into();
        *self_rc.percentage_of_frozen_deposits_slashed_per_double_baking.borrow_mut() = _io.read_u1()?.into();
        *self_rc.percentage_of_frozen_deposits_slashed_per_double_attestation.borrow_mut() = _io.read_u1()?.into();
        *self_rc.testnet_dictator_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.testnet_dictator_tag() == AlphaConstants_Bool::True {
            let t = Self::read_into::<_, AlphaConstants_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.testnet_dictator.borrow_mut() = t;
        }
        *self_rc.initial_seed_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.initial_seed_tag() == AlphaConstants_Bool::True {
            *self_rc.initial_seed.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.cache_script_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_stake_distribution_cycles.borrow_mut() = _io.read_s1()?.into();
        *self_rc.cache_sampler_state_cycles.borrow_mut() = _io.read_s1()?.into();
        let t = Self::read_into::<_, AlphaConstants_DalParametric>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.dal_parametric.borrow_mut() = t;
        *self_rc.smart_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_arith_pvm_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_challenge_window_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.smart_rollup_stake_amount.borrow_mut() = t;
        *self_rc.smart_rollup_commitment_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_lookahead_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_active_outbox_levels.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_outbox_messages_per_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_number_of_sections_in_dissection.borrow_mut() = _io.read_u1()?.into();
        *self_rc.smart_rollup_timeout_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_cemented_commitments.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_parallel_games.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_SmartRollupRevealActivationLevel>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.smart_rollup_reveal_activation_level.borrow_mut() = t;
        *self_rc.smart_rollup_private_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_riscv_pvm_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.zk_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.zk_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_min_pending_to_process.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_max_ticket_payload_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.global_limit_of_staking_over_baking.borrow_mut() = _io.read_u1()?.into();
        *self_rc.edge_of_staking_over_delegation.borrow_mut() = _io.read_u1()?.into();
        *self_rc.adaptive_issuance_launch_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstants_AdaptiveRewardsParams>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.adaptive_rewards_params.borrow_mut() = t;
        *self_rc.adaptive_issuance_activation_vote_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaConstants {
}
impl AlphaConstants {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl AlphaConstants {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl AlphaConstants {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl AlphaConstants {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl AlphaConstants {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl AlphaConstants {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl AlphaConstants {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl AlphaConstants {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl AlphaConstants {
    pub fn cache_layout_size(&self) -> Ref<u8> {
        self.cache_layout_size.borrow()
    }
}
impl AlphaConstants {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl AlphaConstants {
    pub fn max_slashing_period(&self) -> Ref<u8> {
        self.max_slashing_period.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_wrapped_proof_binary_size(&self) -> Ref<i32> {
        self.smart_rollup_max_wrapped_proof_binary_size.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_message_size_limit(&self) -> Ref<i32> {
        self.smart_rollup_message_size_limit.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_number_of_messages_per_level(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.smart_rollup_max_number_of_messages_per_level.borrow()
    }
}
impl AlphaConstants {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl AlphaConstants {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl AlphaConstants {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl AlphaConstants {
    pub fn nonce_revelation_threshold(&self) -> Ref<i32> {
        self.nonce_revelation_threshold.borrow()
    }
}
impl AlphaConstants {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl AlphaConstants {
    pub fn cycles_per_voting_period(&self) -> Ref<i32> {
        self.cycles_per_voting_period.borrow()
    }
}
impl AlphaConstants {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl AlphaConstants {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl AlphaConstants {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl AlphaConstants {
    pub fn minimal_stake(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.minimal_stake.borrow()
    }
}
impl AlphaConstants {
    pub fn minimal_frozen_stake(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.minimal_frozen_stake.borrow()
    }
}
impl AlphaConstants {
    pub fn vdf_difficulty(&self) -> Ref<i64> {
        self.vdf_difficulty.borrow()
    }
}
impl AlphaConstants {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl AlphaConstants {
    pub fn issuance_weights(&self) -> Ref<OptRc<AlphaConstants_IssuanceWeights>> {
        self.issuance_weights.borrow()
    }
}
impl AlphaConstants {
    pub fn cost_per_byte(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.cost_per_byte.borrow()
    }
}
impl AlphaConstants {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl AlphaConstants {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl AlphaConstants {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl AlphaConstants {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl AlphaConstants {
    pub fn liquidity_baking_toggle_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_toggle_ema_threshold.borrow()
    }
}
impl AlphaConstants {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl AlphaConstants {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl AlphaConstants {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl AlphaConstants {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl AlphaConstants {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl AlphaConstants {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<AlphaConstants_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl AlphaConstants {
    pub fn limit_of_delegation_over_baking(&self) -> Ref<u8> {
        self.limit_of_delegation_over_baking.borrow()
    }
}
impl AlphaConstants {
    pub fn percentage_of_frozen_deposits_slashed_per_double_baking(&self) -> Ref<u8> {
        self.percentage_of_frozen_deposits_slashed_per_double_baking.borrow()
    }
}
impl AlphaConstants {
    pub fn percentage_of_frozen_deposits_slashed_per_double_attestation(&self) -> Ref<u8> {
        self.percentage_of_frozen_deposits_slashed_per_double_attestation.borrow()
    }
}
impl AlphaConstants {
    pub fn testnet_dictator_tag(&self) -> Ref<AlphaConstants_Bool> {
        self.testnet_dictator_tag.borrow()
    }
}
impl AlphaConstants {
    pub fn testnet_dictator(&self) -> Ref<OptRc<AlphaConstants_PublicKeyHash>> {
        self.testnet_dictator.borrow()
    }
}
impl AlphaConstants {
    pub fn initial_seed_tag(&self) -> Ref<AlphaConstants_Bool> {
        self.initial_seed_tag.borrow()
    }
}
impl AlphaConstants {
    pub fn initial_seed(&self) -> Ref<Vec<u8>> {
        self.initial_seed.borrow()
    }
}
impl AlphaConstants {
    pub fn cache_script_size(&self) -> Ref<i32> {
        self.cache_script_size.borrow()
    }
}
impl AlphaConstants {
    pub fn cache_stake_distribution_cycles(&self) -> Ref<i8> {
        self.cache_stake_distribution_cycles.borrow()
    }
}
impl AlphaConstants {
    pub fn cache_sampler_state_cycles(&self) -> Ref<i8> {
        self.cache_sampler_state_cycles.borrow()
    }
}
impl AlphaConstants {
    pub fn dal_parametric(&self) -> Ref<OptRc<AlphaConstants_DalParametric>> {
        self.dal_parametric.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.smart_rollup_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_arith_pvm_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.smart_rollup_arith_pvm_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_origination_size(&self) -> Ref<i32> {
        self.smart_rollup_origination_size.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_challenge_window_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_challenge_window_in_blocks.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_stake_amount(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.smart_rollup_stake_amount.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_commitment_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_commitment_period_in_blocks.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_lookahead_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_max_lookahead_in_blocks.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_active_outbox_levels(&self) -> Ref<i32> {
        self.smart_rollup_max_active_outbox_levels.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_outbox_messages_per_level(&self) -> Ref<i32> {
        self.smart_rollup_max_outbox_messages_per_level.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_number_of_sections_in_dissection(&self) -> Ref<u8> {
        self.smart_rollup_number_of_sections_in_dissection.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_timeout_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_timeout_period_in_blocks.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_number_of_cemented_commitments(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_cemented_commitments.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_max_number_of_parallel_games(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_parallel_games.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_reveal_activation_level(&self) -> Ref<OptRc<AlphaConstants_SmartRollupRevealActivationLevel>> {
        self.smart_rollup_reveal_activation_level.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_private_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.smart_rollup_private_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn smart_rollup_riscv_pvm_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.smart_rollup_riscv_pvm_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn zk_rollup_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.zk_rollup_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn zk_rollup_origination_size(&self) -> Ref<i32> {
        self.zk_rollup_origination_size.borrow()
    }
}
impl AlphaConstants {
    pub fn zk_rollup_min_pending_to_process(&self) -> Ref<i32> {
        self.zk_rollup_min_pending_to_process.borrow()
    }
}
impl AlphaConstants {
    pub fn zk_rollup_max_ticket_payload_size(&self) -> Ref<i32> {
        self.zk_rollup_max_ticket_payload_size.borrow()
    }
}
impl AlphaConstants {
    pub fn global_limit_of_staking_over_baking(&self) -> Ref<u8> {
        self.global_limit_of_staking_over_baking.borrow()
    }
}
impl AlphaConstants {
    pub fn edge_of_staking_over_delegation(&self) -> Ref<u8> {
        self.edge_of_staking_over_delegation.borrow()
    }
}
impl AlphaConstants {
    pub fn adaptive_issuance_launch_ema_threshold(&self) -> Ref<i32> {
        self.adaptive_issuance_launch_ema_threshold.borrow()
    }
}
impl AlphaConstants {
    pub fn adaptive_rewards_params(&self) -> Ref<OptRc<AlphaConstants_AdaptiveRewardsParams>> {
        self.adaptive_rewards_params.borrow()
    }
}
impl AlphaConstants {
    pub fn adaptive_issuance_activation_vote_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.adaptive_issuance_activation_vote_enable.borrow()
    }
}
impl AlphaConstants {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaConstants_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Bls,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaConstants_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaConstants_PublicKeyHashTag> {
        match flag {
            0 => Ok(AlphaConstants_PublicKeyHashTag::Ed25519),
            1 => Ok(AlphaConstants_PublicKeyHashTag::Secp256k1),
            2 => Ok(AlphaConstants_PublicKeyHashTag::P256),
            3 => Ok(AlphaConstants_PublicKeyHashTag::Bls),
            _ => Ok(AlphaConstants_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaConstants_PublicKeyHashTag> for i64 {
    fn from(v: &AlphaConstants_PublicKeyHashTag) -> Self {
        match *v {
            AlphaConstants_PublicKeyHashTag::Ed25519 => 0,
            AlphaConstants_PublicKeyHashTag::Secp256k1 => 1,
            AlphaConstants_PublicKeyHashTag::P256 => 2,
            AlphaConstants_PublicKeyHashTag::Bls => 3,
            AlphaConstants_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaConstants_PublicKeyHashTag {
    fn default() -> Self { AlphaConstants_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum AlphaConstants_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaConstants_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaConstants_Bool> {
        match flag {
            0 => Ok(AlphaConstants_Bool::False),
            255 => Ok(AlphaConstants_Bool::True),
            _ => Ok(AlphaConstants_Bool::Unknown(flag)),
        }
    }
}

impl From<&AlphaConstants_Bool> for i64 {
    fn from(v: &AlphaConstants_Bool) -> Self {
        match *v {
            AlphaConstants_Bool::False => 0,
            AlphaConstants_Bool::True => 255,
            AlphaConstants_Bool::Unknown(v) => v
        }
    }
}

impl Default for AlphaConstants_Bool {
    fn default() -> Self { AlphaConstants_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_AdaptiveRewardsParams {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    issuance_ratio_min: RefCell<OptRc<AlphaConstants_IssuanceRatioMin>>,
    issuance_ratio_max: RefCell<OptRc<AlphaConstants_IssuanceRatioMax>>,
    max_bonus: RefCell<i64>,
    growth_rate: RefCell<OptRc<AlphaConstants_GrowthRate>>,
    center_dz: RefCell<OptRc<AlphaConstants_CenterDz>>,
    radius_dz: RefCell<OptRc<AlphaConstants_RadiusDz>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_AdaptiveRewardsParams {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_IssuanceRatioMin>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_ratio_min.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_IssuanceRatioMax>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_ratio_max.borrow_mut() = t;
        *self_rc.max_bonus.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, AlphaConstants_GrowthRate>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.growth_rate.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_CenterDz>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.center_dz.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_RadiusDz>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.radius_dz.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn issuance_ratio_min(&self) -> Ref<OptRc<AlphaConstants_IssuanceRatioMin>> {
        self.issuance_ratio_min.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn issuance_ratio_max(&self) -> Ref<OptRc<AlphaConstants_IssuanceRatioMax>> {
        self.issuance_ratio_max.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn max_bonus(&self) -> Ref<i64> {
        self.max_bonus.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn growth_rate(&self) -> Ref<OptRc<AlphaConstants_GrowthRate>> {
        self.growth_rate.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn center_dz(&self) -> Ref<OptRc<AlphaConstants_CenterDz>> {
        self.center_dz.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn radius_dz(&self) -> Ref<OptRc<AlphaConstants_RadiusDz>> {
        self.radius_dz.borrow()
    }
}
impl AlphaConstants_AdaptiveRewardsParams {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_CenterDz {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstants_Z>>,
    denominator: RefCell<OptRc<AlphaConstants_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_CenterDz {
    type Root = AlphaConstants;
    type Parent = AlphaConstants_AdaptiveRewardsParams;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_CenterDz {
}
impl AlphaConstants_CenterDz {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_CenterDz {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_CenterDz {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_IssuanceWeights {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    base_total_issued_per_minute: RefCell<OptRc<AlphaConstants_N>>,
    baking_reward_fixed_portion_weight: RefCell<i32>,
    baking_reward_bonus_weight: RefCell<i32>,
    attesting_reward_weight: RefCell<i32>,
    liquidity_baking_subsidy_weight: RefCell<i32>,
    seed_nonce_revelation_tip_weight: RefCell<i32>,
    vdf_revelation_tip_weight: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_IssuanceWeights {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.base_total_issued_per_minute.borrow_mut() = t;
        *self_rc.baking_reward_fixed_portion_weight.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.baking_reward_bonus_weight.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.attesting_reward_weight.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_subsidy_weight.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.seed_nonce_revelation_tip_weight.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.vdf_revelation_tip_weight.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl AlphaConstants_IssuanceWeights {
}
impl AlphaConstants_IssuanceWeights {
    pub fn base_total_issued_per_minute(&self) -> Ref<OptRc<AlphaConstants_N>> {
        self.base_total_issued_per_minute.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn baking_reward_fixed_portion_weight(&self) -> Ref<i32> {
        self.baking_reward_fixed_portion_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn baking_reward_bonus_weight(&self) -> Ref<i32> {
        self.baking_reward_bonus_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn attesting_reward_weight(&self) -> Ref<i32> {
        self.attesting_reward_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn liquidity_baking_subsidy_weight(&self) -> Ref<i32> {
        self.liquidity_baking_subsidy_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn seed_nonce_revelation_tip_weight(&self) -> Ref<i32> {
        self.seed_nonce_revelation_tip_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn vdf_revelation_tip_weight(&self) -> Ref<i32> {
        self.vdf_revelation_tip_weight.borrow()
    }
}
impl AlphaConstants_IssuanceWeights {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_DalParametric {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    feature_enable: RefCell<AlphaConstants_Bool>,
    number_of_slots: RefCell<i16>,
    attestation_lag: RefCell<i16>,
    attestation_threshold: RefCell<i16>,
    blocks_per_epoch: RefCell<i32>,
    redundancy_factor: RefCell<u8>,
    page_size: RefCell<u16>,
    slot_size: RefCell<i32>,
    number_of_shards: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_DalParametric {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.feature_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.number_of_slots.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.attestation_lag.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.attestation_threshold.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.blocks_per_epoch.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.redundancy_factor.borrow_mut() = _io.read_u1()?.into();
        *self_rc.page_size.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.slot_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.number_of_shards.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl AlphaConstants_DalParametric {
}
impl AlphaConstants_DalParametric {
    pub fn feature_enable(&self) -> Ref<AlphaConstants_Bool> {
        self.feature_enable.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn number_of_slots(&self) -> Ref<i16> {
        self.number_of_slots.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn attestation_lag(&self) -> Ref<i16> {
        self.attestation_lag.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn attestation_threshold(&self) -> Ref<i16> {
        self.attestation_threshold.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn blocks_per_epoch(&self) -> Ref<i32> {
        self.blocks_per_epoch.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn redundancy_factor(&self) -> Ref<u8> {
        self.redundancy_factor.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn page_size(&self) -> Ref<u16> {
        self.page_size.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn slot_size(&self) -> Ref<i32> {
        self.slot_size.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn number_of_shards(&self) -> Ref<u16> {
        self.number_of_shards.borrow()
    }
}
impl AlphaConstants_DalParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_N {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<AlphaConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_N {
    type Root = AlphaConstants;
    type Parent = KStructUnit;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.n.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while {
                let t = Self::read_into::<_, AlphaConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
                self_rc.n.borrow_mut().push(t);
                let _t_n = self_rc.n.borrow();
                let _tmpa = _t_n.last().unwrap();
                _i += 1;
                let x = !(!((*_tmpa.has_more() as bool)));
                x
            } {}
        }
        Ok(())
    }
}
impl AlphaConstants_N {
}
impl AlphaConstants_N {
    pub fn n(&self) -> Ref<Vec<OptRc<AlphaConstants_NChunk>>> {
        self.n.borrow()
    }
}
impl AlphaConstants_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_IssuanceRatioMin {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstants_Z>>,
    denominator: RefCell<OptRc<AlphaConstants_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_IssuanceRatioMin {
    type Root = AlphaConstants;
    type Parent = AlphaConstants_AdaptiveRewardsParams;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_IssuanceRatioMin {
}
impl AlphaConstants_IssuanceRatioMin {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_IssuanceRatioMin {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_IssuanceRatioMin {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_IssuanceRatioMax {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstants_Z>>,
    denominator: RefCell<OptRc<AlphaConstants_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_IssuanceRatioMax {
    type Root = AlphaConstants;
    type Parent = AlphaConstants_AdaptiveRewardsParams;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_IssuanceRatioMax {
}
impl AlphaConstants_IssuanceRatioMax {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_IssuanceRatioMax {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_IssuanceRatioMax {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_MinimalParticipationRatio {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_MinimalParticipationRatio {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.numerator.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.denominator.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl AlphaConstants_MinimalParticipationRatio {
}
impl AlphaConstants_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_GrowthRate {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstants_Z>>,
    denominator: RefCell<OptRc<AlphaConstants_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_GrowthRate {
    type Root = AlphaConstants;
    type Parent = AlphaConstants_AdaptiveRewardsParams;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_GrowthRate {
}
impl AlphaConstants_GrowthRate {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_GrowthRate {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_GrowthRate {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_SmartRollupRevealActivationLevel {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    raw_data: RefCell<i32>,
    metadata: RefCell<i32>,
    dal_page: RefCell<i32>,
    dal_parameters: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_SmartRollupRevealActivationLevel {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.raw_data.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.metadata.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.dal_page.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.dal_parameters.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
    pub fn raw_data(&self) -> Ref<i32> {
        self.raw_data.borrow()
    }
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
    pub fn metadata(&self) -> Ref<i32> {
        self.metadata.borrow()
    }
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
    pub fn dal_page(&self) -> Ref<i32> {
        self.dal_page.borrow()
    }
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
    pub fn dal_parameters(&self) -> Ref<i32> {
        self.dal_parameters.borrow()
    }
}
impl AlphaConstants_SmartRollupRevealActivationLevel {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_RadiusDz {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstants_Z>>,
    denominator: RefCell<OptRc<AlphaConstants_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_RadiusDz {
    type Root = AlphaConstants;
    type Parent = AlphaConstants_AdaptiveRewardsParams;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstants_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstants_RadiusDz {
}
impl AlphaConstants_RadiusDz {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstants_RadiusDz {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstants_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstants_RadiusDz {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_NChunk {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_NChunk {
    type Root = AlphaConstants;
    type Parent = KStructUnit;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.has_more.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(7)?;
        Ok(())
    }
}
impl AlphaConstants_NChunk {
}
impl AlphaConstants_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl AlphaConstants_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaConstants_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, P256, or BLS public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_PublicKeyHash {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<AlphaConstants>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<AlphaConstants_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    public_key_hash_bls: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_PublicKeyHash {
    type Root = AlphaConstants;
    type Parent = AlphaConstants;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.public_key_hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.public_key_hash_tag() == AlphaConstants_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstants_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstants_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstants_PublicKeyHashTag::Bls {
            *self_rc.public_key_hash_bls.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl AlphaConstants_PublicKeyHash {
}
impl AlphaConstants_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<AlphaConstants_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl AlphaConstants_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl AlphaConstants_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl AlphaConstants_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl AlphaConstants_PublicKeyHash {
    pub fn public_key_hash_bls(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_bls.borrow()
    }
}
impl AlphaConstants_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstants_Z {
    pub _root: SharedType<AlphaConstants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<AlphaConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstants_Z {
    type Root = AlphaConstants;
    type Parent = KStructUnit;

    fn read<S: KStream>(
        self_rc: &OptRc<Self>,
        _io: &S,
        _root: SharedType<Self::Root>,
        _parent: SharedType<Self::Parent>,
    ) -> KResult<()> {
        *self_rc._io.borrow_mut() = _io.clone();
        self_rc._root.set(_root.get());
        self_rc._parent.set(_parent.get());
        self_rc._self.set(Ok(self_rc.clone()));
        let _rrc = self_rc._root.get_value().borrow().upgrade();
        let _prc = self_rc._parent.get_value().borrow().upgrade();
        let _r = _rrc.as_ref().unwrap();
        *self_rc.has_tail.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.sign.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(6)?;
        _io.align_to_byte()?;
        if (*self_rc.has_tail() as bool) {
            *self_rc.tail.borrow_mut() = Vec::new();
            {
                let mut _i = 0;
                while {
                    let t = Self::read_into::<_, AlphaConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
                    self_rc.tail.borrow_mut().push(t);
                    let _t_tail = self_rc.tail.borrow();
                    let _tmpa = _t_tail.last().unwrap();
                    _i += 1;
                    let x = !(!((*_tmpa.has_more() as bool)));
                    x
                } {}
            }
        }
        Ok(())
    }
}
impl AlphaConstants_Z {
}
impl AlphaConstants_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl AlphaConstants_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl AlphaConstants_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaConstants_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<AlphaConstants_NChunk>>> {
        self.tail.borrow()
    }
}
impl AlphaConstants_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
