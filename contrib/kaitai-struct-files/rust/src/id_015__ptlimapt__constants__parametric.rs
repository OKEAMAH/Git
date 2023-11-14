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
pub struct Id015PtlimaptConstantsParametric {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    nonce_revelation_threshold: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    cycles_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id015PtlimaptConstantsParametric_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id015PtlimaptConstantsParametric_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    minimal_stake: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    vdf_difficulty: RefCell<i64>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    origination_size: RefCell<i32>,
    baking_reward_fixed_portion: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    baking_reward_bonus_per_slot: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    endorsing_reward_per_slot: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    cost_per_byte: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id015PtlimaptConstantsParametric_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_subsidy: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    liquidity_baking_toggle_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<Id015PtlimaptConstantsParametric_MinimalParticipationRatio>>,
    max_slashing_period: RefCell<i32>,
    frozen_deposits_percentage: RefCell<i32>,
    double_baking_punishment: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    ratio_of_frozen_deposits_slashed_per_double_endorsement: RefCell<OptRc<Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>>,
    testnet_dictator_tag: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    testnet_dictator: RefCell<OptRc<Id015PtlimaptConstantsParametric_PublicKeyHash>>,
    initial_seed_tag: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    initial_seed: RefCell<Vec<u8>>,
    cache_script_size: RefCell<i32>,
    cache_stake_distribution_cycles: RefCell<i8>,
    cache_sampler_state_cycles: RefCell<i8>,
    tx_rollup_enable: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    tx_rollup_origination_size: RefCell<i32>,
    tx_rollup_hard_size_limit_per_inbox: RefCell<i32>,
    tx_rollup_hard_size_limit_per_message: RefCell<i32>,
    tx_rollup_max_withdrawals_per_batch: RefCell<i32>,
    tx_rollup_commitment_bond: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    tx_rollup_finality_period: RefCell<i32>,
    tx_rollup_withdraw_period: RefCell<i32>,
    tx_rollup_max_inboxes_count: RefCell<i32>,
    tx_rollup_max_messages_per_inbox: RefCell<i32>,
    tx_rollup_max_commitments_count: RefCell<i32>,
    tx_rollup_cost_per_byte_ema_factor: RefCell<i32>,
    tx_rollup_max_ticket_payload_size: RefCell<i32>,
    tx_rollup_rejection_max_proof_size: RefCell<i32>,
    tx_rollup_sunset_level: RefCell<i32>,
    dal_parametric: RefCell<OptRc<Id015PtlimaptConstantsParametric_DalParametric>>,
    sc_rollup_enable: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    sc_rollup_origination_size: RefCell<i32>,
    sc_rollup_challenge_window_in_blocks: RefCell<i32>,
    sc_rollup_max_number_of_messages_per_commitment_period: RefCell<i32>,
    sc_rollup_stake_amount: RefCell<OptRc<Id015PtlimaptConstantsParametric_N>>,
    sc_rollup_commitment_period_in_blocks: RefCell<i32>,
    sc_rollup_max_lookahead_in_blocks: RefCell<i32>,
    sc_rollup_max_active_outbox_levels: RefCell<i32>,
    sc_rollup_max_outbox_messages_per_level: RefCell<i32>,
    sc_rollup_number_of_sections_in_dissection: RefCell<u8>,
    sc_rollup_timeout_period_in_blocks: RefCell<i32>,
    sc_rollup_max_number_of_cemented_commitments: RefCell<i32>,
    zk_rollup_enable: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    zk_rollup_origination_size: RefCell<i32>,
    zk_rollup_min_pending_to_process: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_stake.borrow_mut() = t;
        *self_rc.vdf_difficulty.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_fixed_portion.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_bonus_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsing_reward_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_toggle_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.max_slashing_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.frozen_deposits_percentage.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.double_baking_punishment.borrow_mut() = t;
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow_mut() = t;
        *self_rc.testnet_dictator_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.testnet_dictator_tag() == Id015PtlimaptConstantsParametric_Bool::True {
            let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.testnet_dictator.borrow_mut() = t;
        }
        *self_rc.initial_seed_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.initial_seed_tag() == Id015PtlimaptConstantsParametric_Bool::True {
            *self_rc.initial_seed.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.cache_script_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_stake_distribution_cycles.borrow_mut() = _io.read_s1()?.into();
        *self_rc.cache_sampler_state_cycles.borrow_mut() = _io.read_s1()?.into();
        *self_rc.tx_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.tx_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_hard_size_limit_per_inbox.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_hard_size_limit_per_message.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_max_withdrawals_per_batch.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.tx_rollup_commitment_bond.borrow_mut() = t;
        *self_rc.tx_rollup_finality_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_withdraw_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_max_inboxes_count.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_max_messages_per_inbox.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_max_commitments_count.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_cost_per_byte_ema_factor.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_max_ticket_payload_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_rejection_max_proof_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tx_rollup_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_DalParametric>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.dal_parametric.borrow_mut() = t;
        *self_rc.sc_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.sc_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_challenge_window_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_number_of_messages_per_commitment_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.sc_rollup_stake_amount.borrow_mut() = t;
        *self_rc.sc_rollup_commitment_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_lookahead_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_active_outbox_levels.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_outbox_messages_per_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_number_of_sections_in_dissection.borrow_mut() = _io.read_u1()?.into();
        *self_rc.sc_rollup_timeout_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_number_of_cemented_commitments.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.zk_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_min_pending_to_process.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id015PtlimaptConstantsParametric {
}
impl Id015PtlimaptConstantsParametric {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn nonce_revelation_threshold(&self) -> Ref<i32> {
        self.nonce_revelation_threshold.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn cycles_per_voting_period(&self) -> Ref<i32> {
        self.cycles_per_voting_period.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn minimal_stake(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.minimal_stake.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn vdf_difficulty(&self) -> Ref<i64> {
        self.vdf_difficulty.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn baking_reward_fixed_portion(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.baking_reward_fixed_portion.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn baking_reward_bonus_per_slot(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.baking_reward_bonus_per_slot.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn endorsing_reward_per_slot(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.endorsing_reward_per_slot.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn liquidity_baking_toggle_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_toggle_ema_threshold.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn max_slashing_period(&self) -> Ref<i32> {
        self.max_slashing_period.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn frozen_deposits_percentage(&self) -> Ref<i32> {
        self.frozen_deposits_percentage.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn double_baking_punishment(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.double_baking_punishment.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn ratio_of_frozen_deposits_slashed_per_double_endorsement(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>> {
        self.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn testnet_dictator_tag(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.testnet_dictator_tag.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn testnet_dictator(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_PublicKeyHash>> {
        self.testnet_dictator.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn initial_seed_tag(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.initial_seed_tag.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn initial_seed(&self) -> Ref<Vec<u8>> {
        self.initial_seed.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn cache_script_size(&self) -> Ref<i32> {
        self.cache_script_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn cache_stake_distribution_cycles(&self) -> Ref<i8> {
        self.cache_stake_distribution_cycles.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn cache_sampler_state_cycles(&self) -> Ref<i8> {
        self.cache_sampler_state_cycles.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_enable(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.tx_rollup_enable.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_origination_size(&self) -> Ref<i32> {
        self.tx_rollup_origination_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_hard_size_limit_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_inbox.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_hard_size_limit_per_message(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_message.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_max_withdrawals_per_batch(&self) -> Ref<i32> {
        self.tx_rollup_max_withdrawals_per_batch.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_commitment_bond(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.tx_rollup_commitment_bond.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_finality_period(&self) -> Ref<i32> {
        self.tx_rollup_finality_period.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_withdraw_period(&self) -> Ref<i32> {
        self.tx_rollup_withdraw_period.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_max_inboxes_count(&self) -> Ref<i32> {
        self.tx_rollup_max_inboxes_count.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_max_messages_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_max_messages_per_inbox.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_max_commitments_count(&self) -> Ref<i32> {
        self.tx_rollup_max_commitments_count.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_cost_per_byte_ema_factor(&self) -> Ref<i32> {
        self.tx_rollup_cost_per_byte_ema_factor.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_max_ticket_payload_size(&self) -> Ref<i32> {
        self.tx_rollup_max_ticket_payload_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_rejection_max_proof_size(&self) -> Ref<i32> {
        self.tx_rollup_rejection_max_proof_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn tx_rollup_sunset_level(&self) -> Ref<i32> {
        self.tx_rollup_sunset_level.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn dal_parametric(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_DalParametric>> {
        self.dal_parametric.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_enable(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.sc_rollup_enable.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_origination_size(&self) -> Ref<i32> {
        self.sc_rollup_origination_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_challenge_window_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_challenge_window_in_blocks.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_max_number_of_messages_per_commitment_period(&self) -> Ref<i32> {
        self.sc_rollup_max_number_of_messages_per_commitment_period.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_stake_amount(&self) -> Ref<OptRc<Id015PtlimaptConstantsParametric_N>> {
        self.sc_rollup_stake_amount.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_commitment_period_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_commitment_period_in_blocks.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_max_lookahead_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_max_lookahead_in_blocks.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_max_active_outbox_levels(&self) -> Ref<i32> {
        self.sc_rollup_max_active_outbox_levels.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_max_outbox_messages_per_level(&self) -> Ref<i32> {
        self.sc_rollup_max_outbox_messages_per_level.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_number_of_sections_in_dissection(&self) -> Ref<u8> {
        self.sc_rollup_number_of_sections_in_dissection.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_timeout_period_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_timeout_period_in_blocks.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn sc_rollup_max_number_of_cemented_commitments(&self) -> Ref<i32> {
        self.sc_rollup_max_number_of_cemented_commitments.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn zk_rollup_enable(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.zk_rollup_enable.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn zk_rollup_origination_size(&self) -> Ref<i32> {
        self.zk_rollup_origination_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn zk_rollup_min_pending_to_process(&self) -> Ref<i32> {
        self.zk_rollup_min_pending_to_process.borrow()
    }
}
impl Id015PtlimaptConstantsParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id015PtlimaptConstantsParametric_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id015PtlimaptConstantsParametric_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id015PtlimaptConstantsParametric_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id015PtlimaptConstantsParametric_PublicKeyHashTag::Ed25519),
            1 => Ok(Id015PtlimaptConstantsParametric_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id015PtlimaptConstantsParametric_PublicKeyHashTag::P256),
            _ => Ok(Id015PtlimaptConstantsParametric_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id015PtlimaptConstantsParametric_PublicKeyHashTag> for i64 {
    fn from(v: &Id015PtlimaptConstantsParametric_PublicKeyHashTag) -> Self {
        match *v {
            Id015PtlimaptConstantsParametric_PublicKeyHashTag::Ed25519 => 0,
            Id015PtlimaptConstantsParametric_PublicKeyHashTag::Secp256k1 => 1,
            Id015PtlimaptConstantsParametric_PublicKeyHashTag::P256 => 2,
            Id015PtlimaptConstantsParametric_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id015PtlimaptConstantsParametric_PublicKeyHashTag {
    fn default() -> Self { Id015PtlimaptConstantsParametric_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id015PtlimaptConstantsParametric_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id015PtlimaptConstantsParametric_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id015PtlimaptConstantsParametric_Bool> {
        match flag {
            0 => Ok(Id015PtlimaptConstantsParametric_Bool::False),
            255 => Ok(Id015PtlimaptConstantsParametric_Bool::True),
            _ => Ok(Id015PtlimaptConstantsParametric_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id015PtlimaptConstantsParametric_Bool> for i64 {
    fn from(v: &Id015PtlimaptConstantsParametric_Bool) -> Self {
        match *v {
            Id015PtlimaptConstantsParametric_Bool::False => 0,
            Id015PtlimaptConstantsParametric_Bool::True => 255,
            Id015PtlimaptConstantsParametric_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id015PtlimaptConstantsParametric_Bool {
    fn default() -> Self { Id015PtlimaptConstantsParametric_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
impl Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
}
impl Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_DalParametric {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    feature_enable: RefCell<Id015PtlimaptConstantsParametric_Bool>,
    number_of_slots: RefCell<i16>,
    number_of_shards: RefCell<i16>,
    endorsement_lag: RefCell<i16>,
    availability_threshold: RefCell<i16>,
    slot_size: RefCell<i32>,
    redundancy_factor: RefCell<u8>,
    page_size: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_DalParametric {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
        *self_rc.number_of_shards.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.endorsement_lag.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.availability_threshold.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.slot_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.redundancy_factor.borrow_mut() = _io.read_u1()?.into();
        *self_rc.page_size.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn feature_enable(&self) -> Ref<Id015PtlimaptConstantsParametric_Bool> {
        self.feature_enable.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn number_of_slots(&self) -> Ref<i16> {
        self.number_of_slots.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn number_of_shards(&self) -> Ref<i16> {
        self.number_of_shards.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn endorsement_lag(&self) -> Ref<i16> {
        self.endorsement_lag.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn availability_threshold(&self) -> Ref<i16> {
        self.availability_threshold.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn slot_size(&self) -> Ref<i32> {
        self.slot_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn redundancy_factor(&self) -> Ref<u8> {
        self.redundancy_factor.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn page_size(&self) -> Ref<u16> {
        self.page_size.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_DalParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_N {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id015PtlimaptConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_N {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
                let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id015PtlimaptConstantsParametric_N {
}
impl Id015PtlimaptConstantsParametric_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id015PtlimaptConstantsParametric_NChunk>>> {
        self.n.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
impl Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
}
impl Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_NChunk {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_NChunk {
    type Root = Id015PtlimaptConstantsParametric;
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
impl Id015PtlimaptConstantsParametric_NChunk {
}
impl Id015PtlimaptConstantsParametric_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id015PtlimaptConstantsParametric_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_PublicKeyHash {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
        if *self_rc.public_key_hash_tag() == Id015PtlimaptConstantsParametric_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id015PtlimaptConstantsParametric_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id015PtlimaptConstantsParametric_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id015PtlimaptConstantsParametric_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptConstantsParametric_Z {
    pub _root: SharedType<Id015PtlimaptConstantsParametric>,
    pub _parent: SharedType<Id015PtlimaptConstantsParametric>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id015PtlimaptConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsParametric_Z {
    type Root = Id015PtlimaptConstantsParametric;
    type Parent = Id015PtlimaptConstantsParametric;

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
                    let t = Self::read_into::<_, Id015PtlimaptConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id015PtlimaptConstantsParametric_Z {
}
impl Id015PtlimaptConstantsParametric_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id015PtlimaptConstantsParametric_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id015PtlimaptConstantsParametric_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
