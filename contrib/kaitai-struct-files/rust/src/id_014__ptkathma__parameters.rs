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
pub struct Id014PtkathmaParameters {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    bootstrap_accounts: RefCell<OptRc<Id014PtkathmaParameters_BootstrapAccounts>>,
    bootstrap_contracts: RefCell<OptRc<Id014PtkathmaParameters_BootstrapContracts>>,
    commitments: RefCell<OptRc<Id014PtkathmaParameters_Commitments>>,
    security_deposit_ramp_up_cycles_tag: RefCell<Id014PtkathmaParameters_Bool>,
    security_deposit_ramp_up_cycles: RefCell<i32>,
    no_reward_cycles_tag: RefCell<Id014PtkathmaParameters_Bool>,
    no_reward_cycles: RefCell<i32>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    nonce_revelation_threshold: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    cycles_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id014PtkathmaParameters_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id014PtkathmaParameters_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    vdf_difficulty: RefCell<i64>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    origination_size: RefCell<i32>,
    baking_reward_fixed_portion: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    baking_reward_bonus_per_slot: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    endorsing_reward_per_slot: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    cost_per_byte: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id014PtkathmaParameters_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_subsidy: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    liquidity_baking_sunset_level: RefCell<i32>,
    liquidity_baking_toggle_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<Id014PtkathmaParameters_MinimalParticipationRatio>>,
    max_slashing_period: RefCell<i32>,
    frozen_deposits_percentage: RefCell<i32>,
    double_baking_punishment: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    ratio_of_frozen_deposits_slashed_per_double_endorsement: RefCell<OptRc<Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>>,
    testnet_dictator_tag: RefCell<Id014PtkathmaParameters_Bool>,
    testnet_dictator: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    initial_seed_tag: RefCell<Id014PtkathmaParameters_Bool>,
    initial_seed: RefCell<Vec<u8>>,
    cache_script_size: RefCell<i32>,
    cache_stake_distribution_cycles: RefCell<i8>,
    cache_sampler_state_cycles: RefCell<i8>,
    tx_rollup_enable: RefCell<Id014PtkathmaParameters_Bool>,
    tx_rollup_origination_size: RefCell<i32>,
    tx_rollup_hard_size_limit_per_inbox: RefCell<i32>,
    tx_rollup_hard_size_limit_per_message: RefCell<i32>,
    tx_rollup_max_withdrawals_per_batch: RefCell<i32>,
    tx_rollup_commitment_bond: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    tx_rollup_finality_period: RefCell<i32>,
    tx_rollup_withdraw_period: RefCell<i32>,
    tx_rollup_max_inboxes_count: RefCell<i32>,
    tx_rollup_max_messages_per_inbox: RefCell<i32>,
    tx_rollup_max_commitments_count: RefCell<i32>,
    tx_rollup_cost_per_byte_ema_factor: RefCell<i32>,
    tx_rollup_max_ticket_payload_size: RefCell<i32>,
    tx_rollup_rejection_max_proof_size: RefCell<i32>,
    tx_rollup_sunset_level: RefCell<i32>,
    dal_parametric: RefCell<OptRc<Id014PtkathmaParameters_DalParametric>>,
    sc_rollup_enable: RefCell<Id014PtkathmaParameters_Bool>,
    sc_rollup_origination_size: RefCell<i32>,
    sc_rollup_challenge_window_in_blocks: RefCell<i32>,
    sc_rollup_max_available_messages: RefCell<i32>,
    sc_rollup_stake_amount: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    sc_rollup_commitment_period_in_blocks: RefCell<i32>,
    sc_rollup_max_lookahead_in_blocks: RefCell<i32>,
    sc_rollup_max_active_outbox_levels: RefCell<i32>,
    sc_rollup_max_outbox_messages_per_level: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapAccounts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_accounts.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_contracts.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_Commitments>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.commitments.borrow_mut() = t;
        *self_rc.security_deposit_ramp_up_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.security_deposit_ramp_up_cycles_tag() == Id014PtkathmaParameters_Bool::True {
            *self_rc.security_deposit_ramp_up_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.no_reward_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.no_reward_cycles_tag() == Id014PtkathmaParameters_Bool::True {
            *self_rc.no_reward_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.nonce_revelation_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycles_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        *self_rc.vdf_difficulty.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.baking_reward_fixed_portion.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.baking_reward_bonus_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.endorsing_reward_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_toggle_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.max_slashing_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.frozen_deposits_percentage.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.double_baking_punishment.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow_mut() = t;
        *self_rc.testnet_dictator_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.testnet_dictator_tag() == Id014PtkathmaParameters_Bool::True {
            let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
            *self_rc.testnet_dictator.borrow_mut() = t;
        }
        *self_rc.initial_seed_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.initial_seed_tag() == Id014PtkathmaParameters_Bool::True {
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
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
        let t = Self::read_into::<_, Id014PtkathmaParameters_DalParametric>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.dal_parametric.borrow_mut() = t;
        *self_rc.sc_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.sc_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_challenge_window_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_available_messages.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.sc_rollup_stake_amount.borrow_mut() = t;
        *self_rc.sc_rollup_commitment_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_lookahead_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_active_outbox_levels.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_max_outbox_messages_per_level.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id014PtkathmaParameters {
}
impl Id014PtkathmaParameters {
    pub fn bootstrap_accounts(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapAccounts>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn bootstrap_contracts(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapContracts>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn commitments(&self) -> Ref<OptRc<Id014PtkathmaParameters_Commitments>> {
        self.commitments.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn security_deposit_ramp_up_cycles_tag(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.security_deposit_ramp_up_cycles_tag.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn security_deposit_ramp_up_cycles(&self) -> Ref<i32> {
        self.security_deposit_ramp_up_cycles.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn no_reward_cycles_tag(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.no_reward_cycles_tag.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn no_reward_cycles(&self) -> Ref<i32> {
        self.no_reward_cycles.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn nonce_revelation_threshold(&self) -> Ref<i32> {
        self.nonce_revelation_threshold.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn cycles_per_voting_period(&self) -> Ref<i32> {
        self.cycles_per_voting_period.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id014PtkathmaParameters_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id014PtkathmaParameters_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn vdf_difficulty(&self) -> Ref<i64> {
        self.vdf_difficulty.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn baking_reward_fixed_portion(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.baking_reward_fixed_portion.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn baking_reward_bonus_per_slot(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.baking_reward_bonus_per_slot.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn endorsing_reward_per_slot(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.endorsing_reward_per_slot.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id014PtkathmaParameters_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn liquidity_baking_sunset_level(&self) -> Ref<i32> {
        self.liquidity_baking_sunset_level.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn liquidity_baking_toggle_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_toggle_ema_threshold.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<Id014PtkathmaParameters_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn max_slashing_period(&self) -> Ref<i32> {
        self.max_slashing_period.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn frozen_deposits_percentage(&self) -> Ref<i32> {
        self.frozen_deposits_percentage.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn double_baking_punishment(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.double_baking_punishment.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn ratio_of_frozen_deposits_slashed_per_double_endorsement(&self) -> Ref<OptRc<Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>> {
        self.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn testnet_dictator_tag(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.testnet_dictator_tag.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn testnet_dictator(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.testnet_dictator.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn initial_seed_tag(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.initial_seed_tag.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn initial_seed(&self) -> Ref<Vec<u8>> {
        self.initial_seed.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn cache_script_size(&self) -> Ref<i32> {
        self.cache_script_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn cache_stake_distribution_cycles(&self) -> Ref<i8> {
        self.cache_stake_distribution_cycles.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn cache_sampler_state_cycles(&self) -> Ref<i8> {
        self.cache_sampler_state_cycles.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_enable(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.tx_rollup_enable.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_origination_size(&self) -> Ref<i32> {
        self.tx_rollup_origination_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_hard_size_limit_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_inbox.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_hard_size_limit_per_message(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_message.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_max_withdrawals_per_batch(&self) -> Ref<i32> {
        self.tx_rollup_max_withdrawals_per_batch.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_commitment_bond(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.tx_rollup_commitment_bond.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_finality_period(&self) -> Ref<i32> {
        self.tx_rollup_finality_period.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_withdraw_period(&self) -> Ref<i32> {
        self.tx_rollup_withdraw_period.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_max_inboxes_count(&self) -> Ref<i32> {
        self.tx_rollup_max_inboxes_count.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_max_messages_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_max_messages_per_inbox.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_max_commitments_count(&self) -> Ref<i32> {
        self.tx_rollup_max_commitments_count.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_cost_per_byte_ema_factor(&self) -> Ref<i32> {
        self.tx_rollup_cost_per_byte_ema_factor.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_max_ticket_payload_size(&self) -> Ref<i32> {
        self.tx_rollup_max_ticket_payload_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_rejection_max_proof_size(&self) -> Ref<i32> {
        self.tx_rollup_rejection_max_proof_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn tx_rollup_sunset_level(&self) -> Ref<i32> {
        self.tx_rollup_sunset_level.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn dal_parametric(&self) -> Ref<OptRc<Id014PtkathmaParameters_DalParametric>> {
        self.dal_parametric.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_enable(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.sc_rollup_enable.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_origination_size(&self) -> Ref<i32> {
        self.sc_rollup_origination_size.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_challenge_window_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_challenge_window_in_blocks.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_max_available_messages(&self) -> Ref<i32> {
        self.sc_rollup_max_available_messages.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_stake_amount(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.sc_rollup_stake_amount.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_commitment_period_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_commitment_period_in_blocks.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_max_lookahead_in_blocks(&self) -> Ref<i32> {
        self.sc_rollup_max_lookahead_in_blocks.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_max_active_outbox_levels(&self) -> Ref<i32> {
        self.sc_rollup_max_active_outbox_levels.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn sc_rollup_max_outbox_messages_per_level(&self) -> Ref<i32> {
        self.sc_rollup_max_outbox_messages_per_level.borrow()
    }
}
impl Id014PtkathmaParameters {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaParameters_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaParameters_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaParameters_Bool> {
        match flag {
            0 => Ok(Id014PtkathmaParameters_Bool::False),
            255 => Ok(Id014PtkathmaParameters_Bool::True),
            _ => Ok(Id014PtkathmaParameters_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaParameters_Bool> for i64 {
    fn from(v: &Id014PtkathmaParameters_Bool) -> Self {
        match *v {
            Id014PtkathmaParameters_Bool::False => 0,
            Id014PtkathmaParameters_Bool::True => 255,
            Id014PtkathmaParameters_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaParameters_Bool {
    fn default() -> Self { Id014PtkathmaParameters_Bool::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaParameters_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaParameters_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaParameters_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id014PtkathmaParameters_PublicKeyHashTag::Ed25519),
            1 => Ok(Id014PtkathmaParameters_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id014PtkathmaParameters_PublicKeyHashTag::P256),
            _ => Ok(Id014PtkathmaParameters_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaParameters_PublicKeyHashTag> for i64 {
    fn from(v: &Id014PtkathmaParameters_PublicKeyHashTag) -> Self {
        match *v {
            Id014PtkathmaParameters_PublicKeyHashTag::Ed25519 => 0,
            Id014PtkathmaParameters_PublicKeyHashTag::Secp256k1 => 1,
            Id014PtkathmaParameters_PublicKeyHashTag::P256 => 2,
            Id014PtkathmaParameters_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaParameters_PublicKeyHashTag {
    fn default() -> Self { Id014PtkathmaParameters_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaParameters_PublicKeyTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaParameters_PublicKeyTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaParameters_PublicKeyTag> {
        match flag {
            0 => Ok(Id014PtkathmaParameters_PublicKeyTag::Ed25519),
            1 => Ok(Id014PtkathmaParameters_PublicKeyTag::Secp256k1),
            2 => Ok(Id014PtkathmaParameters_PublicKeyTag::P256),
            _ => Ok(Id014PtkathmaParameters_PublicKeyTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaParameters_PublicKeyTag> for i64 {
    fn from(v: &Id014PtkathmaParameters_PublicKeyTag) -> Self {
        match *v {
            Id014PtkathmaParameters_PublicKeyTag::Ed25519 => 0,
            Id014PtkathmaParameters_PublicKeyTag::Secp256k1 => 1,
            Id014PtkathmaParameters_PublicKeyTag::P256 => 2,
            Id014PtkathmaParameters_PublicKeyTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaParameters_PublicKeyTag {
    fn default() -> Self { Id014PtkathmaParameters_PublicKeyTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaParameters_BootstrapAccountsEltTag {
    PublicKeyKnown,
    PublicKeyUnknown,
    PublicKeyKnownWithDelegate,
    PublicKeyUnknownWithDelegate,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaParameters_BootstrapAccountsEltTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaParameters_BootstrapAccountsEltTag> {
        match flag {
            0 => Ok(Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnown),
            1 => Ok(Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknown),
            2 => Ok(Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnownWithDelegate),
            3 => Ok(Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknownWithDelegate),
            _ => Ok(Id014PtkathmaParameters_BootstrapAccountsEltTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaParameters_BootstrapAccountsEltTag> for i64 {
    fn from(v: &Id014PtkathmaParameters_BootstrapAccountsEltTag) -> Self {
        match *v {
            Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnown => 0,
            Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknown => 1,
            Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnownWithDelegate => 2,
            Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknownWithDelegate => 3,
            Id014PtkathmaParameters_BootstrapAccountsEltTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaParameters_BootstrapAccountsEltTag {
    fn default() -> Self { Id014PtkathmaParameters_BootstrapAccountsEltTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
impl Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
}
impl Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id014PtkathmaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_Commitments {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    len_commitments: RefCell<i32>,
    commitments: RefCell<Vec<OptRc<Id014PtkathmaParameters_CommitmentsEntries>>>,
    _io: RefCell<BytesReader>,
    commitments_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id014PtkathmaParameters_Commitments {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
        *self_rc.len_commitments.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.commitments.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.commitments_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_commitments() as usize)?.into());
                let commitments_raw = self_rc.commitments_raw.borrow();
                let io_commitments_raw = BytesReader::from(commitments_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id014PtkathmaParameters_CommitmentsEntries>(&io_commitments_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.commitments.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_Commitments {
}
impl Id014PtkathmaParameters_Commitments {
    pub fn len_commitments(&self) -> Ref<i32> {
        self.len_commitments.borrow()
    }
}
impl Id014PtkathmaParameters_Commitments {
    pub fn commitments(&self) -> Ref<Vec<OptRc<Id014PtkathmaParameters_CommitmentsEntries>>> {
        self.commitments.borrow()
    }
}
impl Id014PtkathmaParameters_Commitments {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id014PtkathmaParameters_Commitments {
    pub fn commitments_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.commitments_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_DalParametric {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    feature_enable: RefCell<Id014PtkathmaParameters_Bool>,
    number_of_slots: RefCell<i16>,
    number_of_shards: RefCell<i16>,
    endorsement_lag: RefCell<i16>,
    availability_threshold: RefCell<i16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_DalParametric {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
        Ok(())
    }
}
impl Id014PtkathmaParameters_DalParametric {
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn feature_enable(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.feature_enable.borrow()
    }
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn number_of_slots(&self) -> Ref<i16> {
        self.number_of_slots.borrow()
    }
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn number_of_shards(&self) -> Ref<i16> {
        self.number_of_shards.borrow()
    }
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn endorsement_lag(&self) -> Ref<i16> {
        self.endorsement_lag.borrow()
    }
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn availability_threshold(&self) -> Ref<i16> {
        self.availability_threshold.borrow()
    }
}
impl Id014PtkathmaParameters_DalParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_N {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id014PtkathmaParameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_N {
    type Root = Id014PtkathmaParameters;
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
                let t = Self::read_into::<_, Id014PtkathmaParameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id014PtkathmaParameters_N {
}
impl Id014PtkathmaParameters_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id014PtkathmaParameters_NChunk>>> {
        self.n.borrow()
    }
}
impl Id014PtkathmaParameters_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_unknown_with_delegate_field0: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    public_key_unknown_with_delegate_field1: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    public_key_unknown_with_delegate_field2: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_with_delegate_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_with_delegate_field1.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_with_delegate_field2.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
}

/**
 * signature__v0__public_key_hash
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    pub fn public_key_unknown_with_delegate_field0(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.public_key_unknown_with_delegate_field0.borrow()
    }
}

/**
 * id_014__ptkathma__mutez
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    pub fn public_key_unknown_with_delegate_field1(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.public_key_unknown_with_delegate_field1.borrow()
    }
}

/**
 * signature__v0__public_key_hash
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    pub fn public_key_unknown_with_delegate_field2(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.public_key_unknown_with_delegate_field2.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_CommitmentsEntries {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_Commitments>,
    pub _self: SharedType<Self>,
    commitments_elt_field0: RefCell<Vec<u8>>,
    commitments_elt_field1: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_CommitmentsEntries {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_Commitments;

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
        *self_rc.commitments_elt_field0.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.commitments_elt_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_CommitmentsEntries {
}

/**
 * blinded__public__key__hash
 */
impl Id014PtkathmaParameters_CommitmentsEntries {
    pub fn commitments_elt_field0(&self) -> Ref<Vec<u8>> {
        self.commitments_elt_field0.borrow()
    }
}

/**
 * id_014__ptkathma__mutez
 */
impl Id014PtkathmaParameters_CommitmentsEntries {
    pub fn commitments_elt_field1(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.commitments_elt_field1.borrow()
    }
}
impl Id014PtkathmaParameters_CommitmentsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_unknown_field0: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    public_key_unknown_field1: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
}

/**
 * signature__v0__public_key_hash
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field0(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.public_key_unknown_field0.borrow()
    }
}

/**
 * id_014__ptkathma__mutez
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field1(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.public_key_unknown_field1.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_MinimalParticipationRatio {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_MinimalParticipationRatio {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
impl Id014PtkathmaParameters_MinimalParticipationRatio {
}
impl Id014PtkathmaParameters_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id014PtkathmaParameters_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id014PtkathmaParameters_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key
 */

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_PublicKey {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    public_key_tag: RefCell<Id014PtkathmaParameters_PublicKeyTag>,
    public_key_ed25519: RefCell<Vec<u8>>,
    public_key_secp256k1: RefCell<Vec<u8>>,
    public_key_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_PublicKey {
    type Root = Id014PtkathmaParameters;
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
        *self_rc.public_key_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.public_key_tag() == Id014PtkathmaParameters_PublicKeyTag::Ed25519 {
            *self_rc.public_key_ed25519.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id014PtkathmaParameters_PublicKeyTag::Secp256k1 {
            *self_rc.public_key_secp256k1.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id014PtkathmaParameters_PublicKeyTag::P256 {
            *self_rc.public_key_p256.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_PublicKey {
}
impl Id014PtkathmaParameters_PublicKey {
    pub fn public_key_tag(&self) -> Ref<Id014PtkathmaParameters_PublicKeyTag> {
        self.public_key_tag.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKey {
    pub fn public_key_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_ed25519.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKey {
    pub fn public_key_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_secp256k1.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKey {
    pub fn public_key_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_p256.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_known_field0: RefCell<OptRc<Id014PtkathmaParameters_PublicKey>>,
    public_key_known_field1: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKey>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
}

/**
 * signature__v0__public_key
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field0(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKey>> {
        self.public_key_known_field0.borrow()
    }
}

/**
 * id_014__ptkathma__mutez
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field1(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.public_key_known_field1.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_Code {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_Id014PtkathmaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_Code {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_Id014PtkathmaScriptedContracts;

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
        *self_rc.len_code.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.code.borrow_mut() = _io.read_bytes(*self_rc.len_code() as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaParameters_Code {
}
impl Id014PtkathmaParameters_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id014PtkathmaParameters_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id014PtkathmaParameters_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapAccounts>,
    pub _self: SharedType<Self>,
    bootstrap_accounts_elt_tag: RefCell<Id014PtkathmaParameters_BootstrapAccountsEltTag>,
    bootstrap_accounts_elt_public_key_known: RefCell<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown>>,
    bootstrap_accounts_elt_public_key_unknown: RefCell<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown>>,
    bootstrap_accounts_elt_public_key_known_with_delegate: RefCell<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate>>,
    bootstrap_accounts_elt_public_key_unknown_with_delegate: RefCell<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccountsEntries {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapAccounts;

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
        *self_rc.bootstrap_accounts_elt_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.bootstrap_accounts_elt_tag() == Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnown {
            let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_known.borrow_mut() = t;
        }
        if *self_rc.bootstrap_accounts_elt_tag() == Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknown {
            let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_unknown.borrow_mut() = t;
        }
        if *self_rc.bootstrap_accounts_elt_tag() == Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyKnownWithDelegate {
            let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_known_with_delegate.borrow_mut() = t;
        }
        if *self_rc.bootstrap_accounts_elt_tag() == Id014PtkathmaParameters_BootstrapAccountsEltTag::PublicKeyUnknownWithDelegate {
            let t = Self::read_into::<_, Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_unknown_with_delegate.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_tag(&self) -> Ref<Id014PtkathmaParameters_BootstrapAccountsEltTag> {
        self.bootstrap_accounts_elt_tag.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_known(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnown>> {
        self.bootstrap_accounts_elt_public_key_known.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_unknown(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknown>> {
        self.bootstrap_accounts_elt_public_key_unknown.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_known_with_delegate(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate>> {
        self.bootstrap_accounts_elt_public_key_known_with_delegate.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_unknown_with_delegate(&self) -> Ref<OptRc<Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyUnknownWithDelegate>> {
        self.bootstrap_accounts_elt_public_key_unknown_with_delegate.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_Storage {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_Id014PtkathmaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_Storage {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_Id014PtkathmaScriptedContracts;

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
        *self_rc.len_storage.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.storage.borrow_mut() = _io.read_bytes(*self_rc.len_storage() as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaParameters_Storage {
}
impl Id014PtkathmaParameters_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id014PtkathmaParameters_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id014PtkathmaParameters_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapContractsEntries {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapContracts>,
    pub _self: SharedType<Self>,
    delegate_tag: RefCell<Id014PtkathmaParameters_Bool>,
    delegate: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    amount: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    script: RefCell<OptRc<Id014PtkathmaParameters_Id014PtkathmaScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapContractsEntries {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapContracts;

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
        *self_rc.delegate_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.delegate_tag() == Id014PtkathmaParameters_Bool::True {
            let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
            *self_rc.delegate.borrow_mut() = t;
        }
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.amount.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_Id014PtkathmaScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.script.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
    pub fn delegate_tag(&self) -> Ref<Id014PtkathmaParameters_Bool> {
        self.delegate_tag.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
    pub fn delegate(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.delegate.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
    pub fn amount(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.amount.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
    pub fn script(&self) -> Ref<OptRc<Id014PtkathmaParameters_Id014PtkathmaScriptedContracts>> {
        self.script.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContractsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapContracts {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_contracts: RefCell<i32>,
    bootstrap_contracts: RefCell<Vec<OptRc<Id014PtkathmaParameters_BootstrapContractsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_contracts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapContracts {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
        *self_rc.len_bootstrap_contracts.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.bootstrap_contracts.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.bootstrap_contracts_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_bootstrap_contracts() as usize)?.into());
                let bootstrap_contracts_raw = self_rc.bootstrap_contracts_raw.borrow();
                let io_bootstrap_contracts_raw = BytesReader::from(bootstrap_contracts_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id014PtkathmaParameters_BootstrapContractsEntries>(&io_bootstrap_contracts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_contracts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapContracts {
}
impl Id014PtkathmaParameters_BootstrapContracts {
    pub fn len_bootstrap_contracts(&self) -> Ref<i32> {
        self.len_bootstrap_contracts.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContracts {
    pub fn bootstrap_contracts(&self) -> Ref<Vec<OptRc<Id014PtkathmaParameters_BootstrapContractsEntries>>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapContracts {
    pub fn bootstrap_contracts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_contracts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccounts {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_accounts: RefCell<i32>,
    bootstrap_accounts: RefCell<Vec<OptRc<Id014PtkathmaParameters_BootstrapAccountsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_accounts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccounts {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
        *self_rc.len_bootstrap_accounts.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.bootstrap_accounts.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.bootstrap_accounts_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_bootstrap_accounts() as usize)?.into());
                let bootstrap_accounts_raw = self_rc.bootstrap_accounts_raw.borrow();
                let io_bootstrap_accounts_raw = BytesReader::from(bootstrap_accounts_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id014PtkathmaParameters_BootstrapAccountsEntries>(&io_bootstrap_accounts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_accounts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccounts {
}
impl Id014PtkathmaParameters_BootstrapAccounts {
    pub fn len_bootstrap_accounts(&self) -> Ref<i32> {
        self.len_bootstrap_accounts.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccounts {
    pub fn bootstrap_accounts(&self) -> Ref<Vec<OptRc<Id014PtkathmaParameters_BootstrapAccountsEntries>>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccounts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccounts {
    pub fn bootstrap_accounts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_accounts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapContractsEntries>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id014PtkathmaParameters_Code>>,
    storage: RefCell<OptRc<Id014PtkathmaParameters_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapContractsEntries;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
}
impl Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id014PtkathmaParameters_Code>> {
        self.code.borrow()
    }
}
impl Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id014PtkathmaParameters_Storage>> {
        self.storage.borrow()
    }
}
impl Id014PtkathmaParameters_Id014PtkathmaScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_NChunk {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_NChunk {
    type Root = Id014PtkathmaParameters;
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
impl Id014PtkathmaParameters_NChunk {
}
impl Id014PtkathmaParameters_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id014PtkathmaParameters_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id014PtkathmaParameters_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_known_with_delegate_field0: RefCell<OptRc<Id014PtkathmaParameters_PublicKey>>,
    public_key_known_with_delegate_field1: RefCell<OptRc<Id014PtkathmaParameters_N>>,
    public_key_known_with_delegate_field2: RefCell<OptRc<Id014PtkathmaParameters_PublicKeyHash>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKey>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_with_delegate_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_with_delegate_field1.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_with_delegate_field2.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
}

/**
 * signature__v0__public_key
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    pub fn public_key_known_with_delegate_field0(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKey>> {
        self.public_key_known_with_delegate_field0.borrow()
    }
}

/**
 * id_014__ptkathma__mutez
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    pub fn public_key_known_with_delegate_field1(&self) -> Ref<OptRc<Id014PtkathmaParameters_N>> {
        self.public_key_known_with_delegate_field1.borrow()
    }
}

/**
 * signature__v0__public_key_hash
 */
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    pub fn public_key_known_with_delegate_field2(&self) -> Ref<OptRc<Id014PtkathmaParameters_PublicKeyHash>> {
        self.public_key_known_with_delegate_field2.borrow()
    }
}
impl Id014PtkathmaParameters_BootstrapAccountsEltPublicKeyKnownWithDelegate {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_PublicKeyHash {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id014PtkathmaParameters_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_PublicKeyHash {
    type Root = Id014PtkathmaParameters;
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
        *self_rc.public_key_hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.public_key_hash_tag() == Id014PtkathmaParameters_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id014PtkathmaParameters_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id014PtkathmaParameters_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id014PtkathmaParameters_PublicKeyHash {
}
impl Id014PtkathmaParameters_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id014PtkathmaParameters_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id014PtkathmaParameters_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaParameters_Z {
    pub _root: SharedType<Id014PtkathmaParameters>,
    pub _parent: SharedType<Id014PtkathmaParameters>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id014PtkathmaParameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaParameters_Z {
    type Root = Id014PtkathmaParameters;
    type Parent = Id014PtkathmaParameters;

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
                    let t = Self::read_into::<_, Id014PtkathmaParameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id014PtkathmaParameters_Z {
}
impl Id014PtkathmaParameters_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id014PtkathmaParameters_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id014PtkathmaParameters_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id014PtkathmaParameters_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id014PtkathmaParameters_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id014PtkathmaParameters_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
