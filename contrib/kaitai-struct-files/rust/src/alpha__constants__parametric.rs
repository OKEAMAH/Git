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
pub struct AlphaConstantsParametric {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    nonce_revelation_threshold: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    cycles_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    minimal_stake: RefCell<OptRc<AlphaConstantsParametric_N>>,
    minimal_frozen_stake: RefCell<OptRc<AlphaConstantsParametric_N>>,
    vdf_difficulty: RefCell<i64>,
    origination_size: RefCell<i32>,
    issuance_weights: RefCell<OptRc<AlphaConstantsParametric_IssuanceWeights>>,
    cost_per_byte: RefCell<OptRc<AlphaConstantsParametric_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_toggle_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<AlphaConstantsParametric_MinimalParticipationRatio>>,
    limit_of_delegation_over_baking: RefCell<u8>,
    percentage_of_frozen_deposits_slashed_per_double_baking: RefCell<u8>,
    percentage_of_frozen_deposits_slashed_per_double_attestation: RefCell<u8>,
    testnet_dictator_tag: RefCell<AlphaConstantsParametric_Bool>,
    testnet_dictator: RefCell<OptRc<AlphaConstantsParametric_PublicKeyHash>>,
    initial_seed_tag: RefCell<AlphaConstantsParametric_Bool>,
    initial_seed: RefCell<Vec<u8>>,
    cache_script_size: RefCell<i32>,
    cache_stake_distribution_cycles: RefCell<i8>,
    cache_sampler_state_cycles: RefCell<i8>,
    dal_parametric: RefCell<OptRc<AlphaConstantsParametric_DalParametric>>,
    smart_rollup_enable: RefCell<AlphaConstantsParametric_Bool>,
    smart_rollup_arith_pvm_enable: RefCell<AlphaConstantsParametric_Bool>,
    smart_rollup_origination_size: RefCell<i32>,
    smart_rollup_challenge_window_in_blocks: RefCell<i32>,
    smart_rollup_stake_amount: RefCell<OptRc<AlphaConstantsParametric_N>>,
    smart_rollup_commitment_period_in_blocks: RefCell<i32>,
    smart_rollup_max_lookahead_in_blocks: RefCell<i32>,
    smart_rollup_max_active_outbox_levels: RefCell<i32>,
    smart_rollup_max_outbox_messages_per_level: RefCell<i32>,
    smart_rollup_number_of_sections_in_dissection: RefCell<u8>,
    smart_rollup_timeout_period_in_blocks: RefCell<i32>,
    smart_rollup_max_number_of_cemented_commitments: RefCell<i32>,
    smart_rollup_max_number_of_parallel_games: RefCell<i32>,
    smart_rollup_reveal_activation_level: RefCell<OptRc<AlphaConstantsParametric_SmartRollupRevealActivationLevel>>,
    smart_rollup_private_enable: RefCell<AlphaConstantsParametric_Bool>,
    smart_rollup_riscv_pvm_enable: RefCell<AlphaConstantsParametric_Bool>,
    zk_rollup_enable: RefCell<AlphaConstantsParametric_Bool>,
    zk_rollup_origination_size: RefCell<i32>,
    zk_rollup_min_pending_to_process: RefCell<i32>,
    zk_rollup_max_ticket_payload_size: RefCell<i32>,
    global_limit_of_staking_over_baking: RefCell<u8>,
    edge_of_staking_over_delegation: RefCell<u8>,
    adaptive_issuance_launch_ema_threshold: RefCell<i32>,
    adaptive_rewards_params: RefCell<OptRc<AlphaConstantsParametric_AdaptiveRewardsParams>>,
    adaptive_issuance_activation_vote_enable: RefCell<AlphaConstantsParametric_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.nonce_revelation_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycles_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.minimal_stake.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.minimal_frozen_stake.borrow_mut() = t;
        *self_rc.vdf_difficulty.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_IssuanceWeights>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_weights.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
        let t = Self::read_into::<_, AlphaConstantsParametric_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.limit_of_delegation_over_baking.borrow_mut() = _io.read_u1()?.into();
        *self_rc.percentage_of_frozen_deposits_slashed_per_double_baking.borrow_mut() = _io.read_u1()?.into();
        *self_rc.percentage_of_frozen_deposits_slashed_per_double_attestation.borrow_mut() = _io.read_u1()?.into();
        *self_rc.testnet_dictator_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.testnet_dictator_tag() == AlphaConstantsParametric_Bool::True {
            let t = Self::read_into::<_, AlphaConstantsParametric_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.testnet_dictator.borrow_mut() = t;
        }
        *self_rc.initial_seed_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.initial_seed_tag() == AlphaConstantsParametric_Bool::True {
            *self_rc.initial_seed.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.cache_script_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_stake_distribution_cycles.borrow_mut() = _io.read_s1()?.into();
        *self_rc.cache_sampler_state_cycles.borrow_mut() = _io.read_s1()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_DalParametric>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.dal_parametric.borrow_mut() = t;
        *self_rc.smart_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_arith_pvm_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_challenge_window_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.smart_rollup_stake_amount.borrow_mut() = t;
        *self_rc.smart_rollup_commitment_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_lookahead_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_active_outbox_levels.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_outbox_messages_per_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_number_of_sections_in_dissection.borrow_mut() = _io.read_u1()?.into();
        *self_rc.smart_rollup_timeout_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_cemented_commitments.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_parallel_games.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_SmartRollupRevealActivationLevel>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
        let t = Self::read_into::<_, AlphaConstantsParametric_AdaptiveRewardsParams>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.adaptive_rewards_params.borrow_mut() = t;
        *self_rc.adaptive_issuance_activation_vote_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaConstantsParametric {
}
impl AlphaConstantsParametric {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn nonce_revelation_threshold(&self) -> Ref<i32> {
        self.nonce_revelation_threshold.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn cycles_per_voting_period(&self) -> Ref<i32> {
        self.cycles_per_voting_period.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn minimal_stake(&self) -> Ref<OptRc<AlphaConstantsParametric_N>> {
        self.minimal_stake.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn minimal_frozen_stake(&self) -> Ref<OptRc<AlphaConstantsParametric_N>> {
        self.minimal_frozen_stake.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn vdf_difficulty(&self) -> Ref<i64> {
        self.vdf_difficulty.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn issuance_weights(&self) -> Ref<OptRc<AlphaConstantsParametric_IssuanceWeights>> {
        self.issuance_weights.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn cost_per_byte(&self) -> Ref<OptRc<AlphaConstantsParametric_N>> {
        self.cost_per_byte.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn liquidity_baking_toggle_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_toggle_ema_threshold.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<AlphaConstantsParametric_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn limit_of_delegation_over_baking(&self) -> Ref<u8> {
        self.limit_of_delegation_over_baking.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn percentage_of_frozen_deposits_slashed_per_double_baking(&self) -> Ref<u8> {
        self.percentage_of_frozen_deposits_slashed_per_double_baking.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn percentage_of_frozen_deposits_slashed_per_double_attestation(&self) -> Ref<u8> {
        self.percentage_of_frozen_deposits_slashed_per_double_attestation.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn testnet_dictator_tag(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.testnet_dictator_tag.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn testnet_dictator(&self) -> Ref<OptRc<AlphaConstantsParametric_PublicKeyHash>> {
        self.testnet_dictator.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn initial_seed_tag(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.initial_seed_tag.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn initial_seed(&self) -> Ref<Vec<u8>> {
        self.initial_seed.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn cache_script_size(&self) -> Ref<i32> {
        self.cache_script_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn cache_stake_distribution_cycles(&self) -> Ref<i8> {
        self.cache_stake_distribution_cycles.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn cache_sampler_state_cycles(&self) -> Ref<i8> {
        self.cache_sampler_state_cycles.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn dal_parametric(&self) -> Ref<OptRc<AlphaConstantsParametric_DalParametric>> {
        self.dal_parametric.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.smart_rollup_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_arith_pvm_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.smart_rollup_arith_pvm_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_origination_size(&self) -> Ref<i32> {
        self.smart_rollup_origination_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_challenge_window_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_challenge_window_in_blocks.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_stake_amount(&self) -> Ref<OptRc<AlphaConstantsParametric_N>> {
        self.smart_rollup_stake_amount.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_commitment_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_commitment_period_in_blocks.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_max_lookahead_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_max_lookahead_in_blocks.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_max_active_outbox_levels(&self) -> Ref<i32> {
        self.smart_rollup_max_active_outbox_levels.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_max_outbox_messages_per_level(&self) -> Ref<i32> {
        self.smart_rollup_max_outbox_messages_per_level.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_number_of_sections_in_dissection(&self) -> Ref<u8> {
        self.smart_rollup_number_of_sections_in_dissection.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_timeout_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_timeout_period_in_blocks.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_max_number_of_cemented_commitments(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_cemented_commitments.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_max_number_of_parallel_games(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_parallel_games.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_reveal_activation_level(&self) -> Ref<OptRc<AlphaConstantsParametric_SmartRollupRevealActivationLevel>> {
        self.smart_rollup_reveal_activation_level.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_private_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.smart_rollup_private_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn smart_rollup_riscv_pvm_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.smart_rollup_riscv_pvm_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn zk_rollup_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.zk_rollup_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn zk_rollup_origination_size(&self) -> Ref<i32> {
        self.zk_rollup_origination_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn zk_rollup_min_pending_to_process(&self) -> Ref<i32> {
        self.zk_rollup_min_pending_to_process.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn zk_rollup_max_ticket_payload_size(&self) -> Ref<i32> {
        self.zk_rollup_max_ticket_payload_size.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn global_limit_of_staking_over_baking(&self) -> Ref<u8> {
        self.global_limit_of_staking_over_baking.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn edge_of_staking_over_delegation(&self) -> Ref<u8> {
        self.edge_of_staking_over_delegation.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn adaptive_issuance_launch_ema_threshold(&self) -> Ref<i32> {
        self.adaptive_issuance_launch_ema_threshold.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn adaptive_rewards_params(&self) -> Ref<OptRc<AlphaConstantsParametric_AdaptiveRewardsParams>> {
        self.adaptive_rewards_params.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn adaptive_issuance_activation_vote_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.adaptive_issuance_activation_vote_enable.borrow()
    }
}
impl AlphaConstantsParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaConstantsParametric_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Bls,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaConstantsParametric_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaConstantsParametric_PublicKeyHashTag> {
        match flag {
            0 => Ok(AlphaConstantsParametric_PublicKeyHashTag::Ed25519),
            1 => Ok(AlphaConstantsParametric_PublicKeyHashTag::Secp256k1),
            2 => Ok(AlphaConstantsParametric_PublicKeyHashTag::P256),
            3 => Ok(AlphaConstantsParametric_PublicKeyHashTag::Bls),
            _ => Ok(AlphaConstantsParametric_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaConstantsParametric_PublicKeyHashTag> for i64 {
    fn from(v: &AlphaConstantsParametric_PublicKeyHashTag) -> Self {
        match *v {
            AlphaConstantsParametric_PublicKeyHashTag::Ed25519 => 0,
            AlphaConstantsParametric_PublicKeyHashTag::Secp256k1 => 1,
            AlphaConstantsParametric_PublicKeyHashTag::P256 => 2,
            AlphaConstantsParametric_PublicKeyHashTag::Bls => 3,
            AlphaConstantsParametric_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaConstantsParametric_PublicKeyHashTag {
    fn default() -> Self { AlphaConstantsParametric_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum AlphaConstantsParametric_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaConstantsParametric_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaConstantsParametric_Bool> {
        match flag {
            0 => Ok(AlphaConstantsParametric_Bool::False),
            255 => Ok(AlphaConstantsParametric_Bool::True),
            _ => Ok(AlphaConstantsParametric_Bool::Unknown(flag)),
        }
    }
}

impl From<&AlphaConstantsParametric_Bool> for i64 {
    fn from(v: &AlphaConstantsParametric_Bool) -> Self {
        match *v {
            AlphaConstantsParametric_Bool::False => 0,
            AlphaConstantsParametric_Bool::True => 255,
            AlphaConstantsParametric_Bool::Unknown(v) => v
        }
    }
}

impl Default for AlphaConstantsParametric_Bool {
    fn default() -> Self { AlphaConstantsParametric_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_AdaptiveRewardsParams {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    issuance_ratio_min: RefCell<OptRc<AlphaConstantsParametric_IssuanceRatioMin>>,
    issuance_ratio_max: RefCell<OptRc<AlphaConstantsParametric_IssuanceRatioMax>>,
    max_bonus: RefCell<i64>,
    growth_rate: RefCell<OptRc<AlphaConstantsParametric_GrowthRate>>,
    center_dz: RefCell<OptRc<AlphaConstantsParametric_CenterDz>>,
    radius_dz: RefCell<OptRc<AlphaConstantsParametric_RadiusDz>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_AdaptiveRewardsParams {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_IssuanceRatioMin>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_ratio_min.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_IssuanceRatioMax>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.issuance_ratio_max.borrow_mut() = t;
        *self_rc.max_bonus.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, AlphaConstantsParametric_GrowthRate>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.growth_rate.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_CenterDz>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.center_dz.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_RadiusDz>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.radius_dz.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn issuance_ratio_min(&self) -> Ref<OptRc<AlphaConstantsParametric_IssuanceRatioMin>> {
        self.issuance_ratio_min.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn issuance_ratio_max(&self) -> Ref<OptRc<AlphaConstantsParametric_IssuanceRatioMax>> {
        self.issuance_ratio_max.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn max_bonus(&self) -> Ref<i64> {
        self.max_bonus.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn growth_rate(&self) -> Ref<OptRc<AlphaConstantsParametric_GrowthRate>> {
        self.growth_rate.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn center_dz(&self) -> Ref<OptRc<AlphaConstantsParametric_CenterDz>> {
        self.center_dz.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn radius_dz(&self) -> Ref<OptRc<AlphaConstantsParametric_RadiusDz>> {
        self.radius_dz.borrow()
    }
}
impl AlphaConstantsParametric_AdaptiveRewardsParams {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_CenterDz {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    denominator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_CenterDz {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric_AdaptiveRewardsParams;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_CenterDz {
}
impl AlphaConstantsParametric_CenterDz {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_CenterDz {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_CenterDz {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_IssuanceWeights {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    base_total_issued_per_minute: RefCell<OptRc<AlphaConstantsParametric_N>>,
    baking_reward_fixed_portion_weight: RefCell<i32>,
    baking_reward_bonus_weight: RefCell<i32>,
    attesting_reward_weight: RefCell<i32>,
    liquidity_baking_subsidy_weight: RefCell<i32>,
    seed_nonce_revelation_tip_weight: RefCell<i32>,
    vdf_revelation_tip_weight: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_IssuanceWeights {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl AlphaConstantsParametric_IssuanceWeights {
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn base_total_issued_per_minute(&self) -> Ref<OptRc<AlphaConstantsParametric_N>> {
        self.base_total_issued_per_minute.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn baking_reward_fixed_portion_weight(&self) -> Ref<i32> {
        self.baking_reward_fixed_portion_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn baking_reward_bonus_weight(&self) -> Ref<i32> {
        self.baking_reward_bonus_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn attesting_reward_weight(&self) -> Ref<i32> {
        self.attesting_reward_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn liquidity_baking_subsidy_weight(&self) -> Ref<i32> {
        self.liquidity_baking_subsidy_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn seed_nonce_revelation_tip_weight(&self) -> Ref<i32> {
        self.seed_nonce_revelation_tip_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn vdf_revelation_tip_weight(&self) -> Ref<i32> {
        self.vdf_revelation_tip_weight.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceWeights {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_DalParametric {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    feature_enable: RefCell<AlphaConstantsParametric_Bool>,
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
impl KStruct for AlphaConstantsParametric_DalParametric {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
impl AlphaConstantsParametric_DalParametric {
}
impl AlphaConstantsParametric_DalParametric {
    pub fn feature_enable(&self) -> Ref<AlphaConstantsParametric_Bool> {
        self.feature_enable.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn number_of_slots(&self) -> Ref<i16> {
        self.number_of_slots.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn attestation_lag(&self) -> Ref<i16> {
        self.attestation_lag.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn attestation_threshold(&self) -> Ref<i16> {
        self.attestation_threshold.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn blocks_per_epoch(&self) -> Ref<i32> {
        self.blocks_per_epoch.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn redundancy_factor(&self) -> Ref<u8> {
        self.redundancy_factor.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn page_size(&self) -> Ref<u16> {
        self.page_size.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn slot_size(&self) -> Ref<i32> {
        self.slot_size.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn number_of_shards(&self) -> Ref<u16> {
        self.number_of_shards.borrow()
    }
}
impl AlphaConstantsParametric_DalParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_N {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<AlphaConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_N {
    type Root = AlphaConstantsParametric;
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
                let t = Self::read_into::<_, AlphaConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl AlphaConstantsParametric_N {
}
impl AlphaConstantsParametric_N {
    pub fn n(&self) -> Ref<Vec<OptRc<AlphaConstantsParametric_NChunk>>> {
        self.n.borrow()
    }
}
impl AlphaConstantsParametric_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_IssuanceRatioMin {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    denominator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_IssuanceRatioMin {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric_AdaptiveRewardsParams;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_IssuanceRatioMin {
}
impl AlphaConstantsParametric_IssuanceRatioMin {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceRatioMin {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceRatioMin {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_IssuanceRatioMax {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    denominator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_IssuanceRatioMax {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric_AdaptiveRewardsParams;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_IssuanceRatioMax {
}
impl AlphaConstantsParametric_IssuanceRatioMax {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceRatioMax {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_IssuanceRatioMax {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_MinimalParticipationRatio {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_MinimalParticipationRatio {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
impl AlphaConstantsParametric_MinimalParticipationRatio {
}
impl AlphaConstantsParametric_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_GrowthRate {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    denominator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_GrowthRate {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric_AdaptiveRewardsParams;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_GrowthRate {
}
impl AlphaConstantsParametric_GrowthRate {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_GrowthRate {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_GrowthRate {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    raw_data: RefCell<i32>,
    metadata: RefCell<i32>,
    dal_page: RefCell<i32>,
    dal_parameters: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
}
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub fn raw_data(&self) -> Ref<i32> {
        self.raw_data.borrow()
    }
}
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub fn metadata(&self) -> Ref<i32> {
        self.metadata.borrow()
    }
}
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub fn dal_page(&self) -> Ref<i32> {
        self.dal_page.borrow()
    }
}
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub fn dal_parameters(&self) -> Ref<i32> {
        self.dal_parameters.borrow()
    }
}
impl AlphaConstantsParametric_SmartRollupRevealActivationLevel {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_RadiusDz {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric_AdaptiveRewardsParams>,
    pub _self: SharedType<Self>,
    numerator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    denominator: RefCell<OptRc<AlphaConstantsParametric_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_RadiusDz {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric_AdaptiveRewardsParams;

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
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.numerator.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.denominator.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaConstantsParametric_RadiusDz {
}
impl AlphaConstantsParametric_RadiusDz {
    pub fn numerator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.numerator.borrow()
    }
}
impl AlphaConstantsParametric_RadiusDz {
    pub fn denominator(&self) -> Ref<OptRc<AlphaConstantsParametric_Z>> {
        self.denominator.borrow()
    }
}
impl AlphaConstantsParametric_RadiusDz {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_NChunk {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_NChunk {
    type Root = AlphaConstantsParametric;
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
impl AlphaConstantsParametric_NChunk {
}
impl AlphaConstantsParametric_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl AlphaConstantsParametric_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaConstantsParametric_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, P256, or BLS public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_PublicKeyHash {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<AlphaConstantsParametric>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<AlphaConstantsParametric_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    public_key_hash_bls: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_PublicKeyHash {
    type Root = AlphaConstantsParametric;
    type Parent = AlphaConstantsParametric;

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
        if *self_rc.public_key_hash_tag() == AlphaConstantsParametric_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstantsParametric_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstantsParametric_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaConstantsParametric_PublicKeyHashTag::Bls {
            *self_rc.public_key_hash_bls.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<AlphaConstantsParametric_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_bls(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_bls.borrow()
    }
}
impl AlphaConstantsParametric_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaConstantsParametric_Z {
    pub _root: SharedType<AlphaConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<AlphaConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaConstantsParametric_Z {
    type Root = AlphaConstantsParametric;
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
                    let t = Self::read_into::<_, AlphaConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl AlphaConstantsParametric_Z {
}
impl AlphaConstantsParametric_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl AlphaConstantsParametric_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl AlphaConstantsParametric_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaConstantsParametric_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<AlphaConstantsParametric_NChunk>>> {
        self.tail.borrow()
    }
}
impl AlphaConstantsParametric_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
