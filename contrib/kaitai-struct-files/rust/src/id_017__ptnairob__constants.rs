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
pub struct Id017PtnairobConstants {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
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
    smart_rollup_max_wrapped_proof_binary_size: RefCell<i32>,
    smart_rollup_message_size_limit: RefCell<i32>,
    smart_rollup_max_number_of_messages_per_level: RefCell<OptRc<Id017PtnairobConstants_N>>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    nonce_revelation_threshold: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    cycles_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id017PtnairobConstants_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id017PtnairobConstants_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    minimal_stake: RefCell<OptRc<Id017PtnairobConstants_N>>,
    vdf_difficulty: RefCell<i64>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id017PtnairobConstants_N>>,
    origination_size: RefCell<i32>,
    baking_reward_fixed_portion: RefCell<OptRc<Id017PtnairobConstants_N>>,
    baking_reward_bonus_per_slot: RefCell<OptRc<Id017PtnairobConstants_N>>,
    endorsing_reward_per_slot: RefCell<OptRc<Id017PtnairobConstants_N>>,
    cost_per_byte: RefCell<OptRc<Id017PtnairobConstants_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id017PtnairobConstants_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_subsidy: RefCell<OptRc<Id017PtnairobConstants_N>>,
    liquidity_baking_toggle_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<Id017PtnairobConstants_MinimalParticipationRatio>>,
    max_slashing_period: RefCell<i32>,
    frozen_deposits_percentage: RefCell<i32>,
    double_baking_punishment: RefCell<OptRc<Id017PtnairobConstants_N>>,
    ratio_of_frozen_deposits_slashed_per_double_endorsement: RefCell<OptRc<Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>>,
    testnet_dictator_tag: RefCell<Id017PtnairobConstants_Bool>,
    testnet_dictator: RefCell<OptRc<Id017PtnairobConstants_PublicKeyHash>>,
    initial_seed_tag: RefCell<Id017PtnairobConstants_Bool>,
    initial_seed: RefCell<Vec<u8>>,
    cache_script_size: RefCell<i32>,
    cache_stake_distribution_cycles: RefCell<i8>,
    cache_sampler_state_cycles: RefCell<i8>,
    tx_rollup_enable: RefCell<Id017PtnairobConstants_Bool>,
    tx_rollup_origination_size: RefCell<i32>,
    tx_rollup_hard_size_limit_per_inbox: RefCell<i32>,
    tx_rollup_hard_size_limit_per_message: RefCell<i32>,
    tx_rollup_max_withdrawals_per_batch: RefCell<i32>,
    tx_rollup_commitment_bond: RefCell<OptRc<Id017PtnairobConstants_N>>,
    tx_rollup_finality_period: RefCell<i32>,
    tx_rollup_withdraw_period: RefCell<i32>,
    tx_rollup_max_inboxes_count: RefCell<i32>,
    tx_rollup_max_messages_per_inbox: RefCell<i32>,
    tx_rollup_max_commitments_count: RefCell<i32>,
    tx_rollup_cost_per_byte_ema_factor: RefCell<i32>,
    tx_rollup_max_ticket_payload_size: RefCell<i32>,
    tx_rollup_rejection_max_proof_size: RefCell<i32>,
    tx_rollup_sunset_level: RefCell<i32>,
    dal_parametric: RefCell<OptRc<Id017PtnairobConstants_DalParametric>>,
    smart_rollup_enable: RefCell<Id017PtnairobConstants_Bool>,
    smart_rollup_arith_pvm_enable: RefCell<Id017PtnairobConstants_Bool>,
    smart_rollup_origination_size: RefCell<i32>,
    smart_rollup_challenge_window_in_blocks: RefCell<i32>,
    smart_rollup_stake_amount: RefCell<OptRc<Id017PtnairobConstants_N>>,
    smart_rollup_commitment_period_in_blocks: RefCell<i32>,
    smart_rollup_max_lookahead_in_blocks: RefCell<i32>,
    smart_rollup_max_active_outbox_levels: RefCell<i32>,
    smart_rollup_max_outbox_messages_per_level: RefCell<i32>,
    smart_rollup_number_of_sections_in_dissection: RefCell<u8>,
    smart_rollup_timeout_period_in_blocks: RefCell<i32>,
    smart_rollup_max_number_of_cemented_commitments: RefCell<i32>,
    smart_rollup_max_number_of_parallel_games: RefCell<i32>,
    zk_rollup_enable: RefCell<Id017PtnairobConstants_Bool>,
    zk_rollup_origination_size: RefCell<i32>,
    zk_rollup_min_pending_to_process: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
        *self_rc.smart_rollup_max_wrapped_proof_binary_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_message_size_limit.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.smart_rollup_max_number_of_messages_per_level.borrow_mut() = t;
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.nonce_revelation_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycles_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_stake.borrow_mut() = t;
        *self_rc.vdf_difficulty.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_fixed_portion.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_bonus_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsing_reward_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_toggle_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.max_slashing_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.frozen_deposits_percentage.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.double_baking_punishment.borrow_mut() = t;
        let t = Self::read_into::<_, Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow_mut() = t;
        *self_rc.testnet_dictator_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.testnet_dictator_tag() == Id017PtnairobConstants_Bool::True {
            let t = Self::read_into::<_, Id017PtnairobConstants_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.testnet_dictator.borrow_mut() = t;
        }
        *self_rc.initial_seed_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.initial_seed_tag() == Id017PtnairobConstants_Bool::True {
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
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
        let t = Self::read_into::<_, Id017PtnairobConstants_DalParametric>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.dal_parametric.borrow_mut() = t;
        *self_rc.smart_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_arith_pvm_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.smart_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_challenge_window_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.smart_rollup_stake_amount.borrow_mut() = t;
        *self_rc.smart_rollup_commitment_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_lookahead_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_active_outbox_levels.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_outbox_messages_per_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_number_of_sections_in_dissection.borrow_mut() = _io.read_u1()?.into();
        *self_rc.smart_rollup_timeout_period_in_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_cemented_commitments.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_max_number_of_parallel_games.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_enable.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.zk_rollup_origination_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.zk_rollup_min_pending_to_process.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id017PtnairobConstants {
}
impl Id017PtnairobConstants {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cache_layout_size(&self) -> Ref<u8> {
        self.cache_layout_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_wrapped_proof_binary_size(&self) -> Ref<i32> {
        self.smart_rollup_max_wrapped_proof_binary_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_message_size_limit(&self) -> Ref<i32> {
        self.smart_rollup_message_size_limit.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_number_of_messages_per_level(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.smart_rollup_max_number_of_messages_per_level.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn nonce_revelation_threshold(&self) -> Ref<i32> {
        self.nonce_revelation_threshold.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cycles_per_voting_period(&self) -> Ref<i32> {
        self.cycles_per_voting_period.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id017PtnairobConstants_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id017PtnairobConstants_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn minimal_stake(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.minimal_stake.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn vdf_difficulty(&self) -> Ref<i64> {
        self.vdf_difficulty.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn baking_reward_fixed_portion(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.baking_reward_fixed_portion.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn baking_reward_bonus_per_slot(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.baking_reward_bonus_per_slot.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn endorsing_reward_per_slot(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.endorsing_reward_per_slot.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id017PtnairobConstants_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn liquidity_baking_toggle_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_toggle_ema_threshold.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<Id017PtnairobConstants_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn max_slashing_period(&self) -> Ref<i32> {
        self.max_slashing_period.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn frozen_deposits_percentage(&self) -> Ref<i32> {
        self.frozen_deposits_percentage.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn double_baking_punishment(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.double_baking_punishment.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn ratio_of_frozen_deposits_slashed_per_double_endorsement(&self) -> Ref<OptRc<Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>> {
        self.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn testnet_dictator_tag(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.testnet_dictator_tag.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn testnet_dictator(&self) -> Ref<OptRc<Id017PtnairobConstants_PublicKeyHash>> {
        self.testnet_dictator.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn initial_seed_tag(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.initial_seed_tag.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn initial_seed(&self) -> Ref<Vec<u8>> {
        self.initial_seed.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cache_script_size(&self) -> Ref<i32> {
        self.cache_script_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cache_stake_distribution_cycles(&self) -> Ref<i8> {
        self.cache_stake_distribution_cycles.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn cache_sampler_state_cycles(&self) -> Ref<i8> {
        self.cache_sampler_state_cycles.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_enable(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.tx_rollup_enable.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_origination_size(&self) -> Ref<i32> {
        self.tx_rollup_origination_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_hard_size_limit_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_inbox.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_hard_size_limit_per_message(&self) -> Ref<i32> {
        self.tx_rollup_hard_size_limit_per_message.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_max_withdrawals_per_batch(&self) -> Ref<i32> {
        self.tx_rollup_max_withdrawals_per_batch.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_commitment_bond(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.tx_rollup_commitment_bond.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_finality_period(&self) -> Ref<i32> {
        self.tx_rollup_finality_period.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_withdraw_period(&self) -> Ref<i32> {
        self.tx_rollup_withdraw_period.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_max_inboxes_count(&self) -> Ref<i32> {
        self.tx_rollup_max_inboxes_count.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_max_messages_per_inbox(&self) -> Ref<i32> {
        self.tx_rollup_max_messages_per_inbox.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_max_commitments_count(&self) -> Ref<i32> {
        self.tx_rollup_max_commitments_count.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_cost_per_byte_ema_factor(&self) -> Ref<i32> {
        self.tx_rollup_cost_per_byte_ema_factor.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_max_ticket_payload_size(&self) -> Ref<i32> {
        self.tx_rollup_max_ticket_payload_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_rejection_max_proof_size(&self) -> Ref<i32> {
        self.tx_rollup_rejection_max_proof_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn tx_rollup_sunset_level(&self) -> Ref<i32> {
        self.tx_rollup_sunset_level.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn dal_parametric(&self) -> Ref<OptRc<Id017PtnairobConstants_DalParametric>> {
        self.dal_parametric.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_enable(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.smart_rollup_enable.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_arith_pvm_enable(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.smart_rollup_arith_pvm_enable.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_origination_size(&self) -> Ref<i32> {
        self.smart_rollup_origination_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_challenge_window_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_challenge_window_in_blocks.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_stake_amount(&self) -> Ref<OptRc<Id017PtnairobConstants_N>> {
        self.smart_rollup_stake_amount.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_commitment_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_commitment_period_in_blocks.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_lookahead_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_max_lookahead_in_blocks.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_active_outbox_levels(&self) -> Ref<i32> {
        self.smart_rollup_max_active_outbox_levels.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_outbox_messages_per_level(&self) -> Ref<i32> {
        self.smart_rollup_max_outbox_messages_per_level.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_number_of_sections_in_dissection(&self) -> Ref<u8> {
        self.smart_rollup_number_of_sections_in_dissection.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_timeout_period_in_blocks(&self) -> Ref<i32> {
        self.smart_rollup_timeout_period_in_blocks.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_number_of_cemented_commitments(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_cemented_commitments.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn smart_rollup_max_number_of_parallel_games(&self) -> Ref<i32> {
        self.smart_rollup_max_number_of_parallel_games.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn zk_rollup_enable(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.zk_rollup_enable.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn zk_rollup_origination_size(&self) -> Ref<i32> {
        self.zk_rollup_origination_size.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn zk_rollup_min_pending_to_process(&self) -> Ref<i32> {
        self.zk_rollup_min_pending_to_process.borrow()
    }
}
impl Id017PtnairobConstants {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id017PtnairobConstants_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Bls,
    Unknown(i64),
}

impl TryFrom<i64> for Id017PtnairobConstants_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id017PtnairobConstants_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id017PtnairobConstants_PublicKeyHashTag::Ed25519),
            1 => Ok(Id017PtnairobConstants_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id017PtnairobConstants_PublicKeyHashTag::P256),
            3 => Ok(Id017PtnairobConstants_PublicKeyHashTag::Bls),
            _ => Ok(Id017PtnairobConstants_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id017PtnairobConstants_PublicKeyHashTag> for i64 {
    fn from(v: &Id017PtnairobConstants_PublicKeyHashTag) -> Self {
        match *v {
            Id017PtnairobConstants_PublicKeyHashTag::Ed25519 => 0,
            Id017PtnairobConstants_PublicKeyHashTag::Secp256k1 => 1,
            Id017PtnairobConstants_PublicKeyHashTag::P256 => 2,
            Id017PtnairobConstants_PublicKeyHashTag::Bls => 3,
            Id017PtnairobConstants_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id017PtnairobConstants_PublicKeyHashTag {
    fn default() -> Self { Id017PtnairobConstants_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id017PtnairobConstants_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id017PtnairobConstants_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id017PtnairobConstants_Bool> {
        match flag {
            0 => Ok(Id017PtnairobConstants_Bool::False),
            255 => Ok(Id017PtnairobConstants_Bool::True),
            _ => Ok(Id017PtnairobConstants_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id017PtnairobConstants_Bool> for i64 {
    fn from(v: &Id017PtnairobConstants_Bool) -> Self {
        match *v {
            Id017PtnairobConstants_Bool::False => 0,
            Id017PtnairobConstants_Bool::True => 255,
            Id017PtnairobConstants_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id017PtnairobConstants_Bool {
    fn default() -> Self { Id017PtnairobConstants_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
impl Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
}
impl Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id017PtnairobConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_DalParametric {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    feature_enable: RefCell<Id017PtnairobConstants_Bool>,
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
impl KStruct for Id017PtnairobConstants_DalParametric {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
impl Id017PtnairobConstants_DalParametric {
}
impl Id017PtnairobConstants_DalParametric {
    pub fn feature_enable(&self) -> Ref<Id017PtnairobConstants_Bool> {
        self.feature_enable.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn number_of_slots(&self) -> Ref<i16> {
        self.number_of_slots.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn attestation_lag(&self) -> Ref<i16> {
        self.attestation_lag.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn attestation_threshold(&self) -> Ref<i16> {
        self.attestation_threshold.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn blocks_per_epoch(&self) -> Ref<i32> {
        self.blocks_per_epoch.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn redundancy_factor(&self) -> Ref<u8> {
        self.redundancy_factor.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn page_size(&self) -> Ref<u16> {
        self.page_size.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn slot_size(&self) -> Ref<i32> {
        self.slot_size.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn number_of_shards(&self) -> Ref<u16> {
        self.number_of_shards.borrow()
    }
}
impl Id017PtnairobConstants_DalParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_N {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id017PtnairobConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_N {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
                let t = Self::read_into::<_, Id017PtnairobConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id017PtnairobConstants_N {
}
impl Id017PtnairobConstants_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id017PtnairobConstants_NChunk>>> {
        self.n.borrow()
    }
}
impl Id017PtnairobConstants_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_MinimalParticipationRatio {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_MinimalParticipationRatio {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
impl Id017PtnairobConstants_MinimalParticipationRatio {
}
impl Id017PtnairobConstants_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id017PtnairobConstants_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id017PtnairobConstants_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_NChunk {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_NChunk {
    type Root = Id017PtnairobConstants;
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
impl Id017PtnairobConstants_NChunk {
}
impl Id017PtnairobConstants_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id017PtnairobConstants_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id017PtnairobConstants_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, P256, or BLS public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_PublicKeyHash {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id017PtnairobConstants_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    public_key_hash_bls: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_PublicKeyHash {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
        if *self_rc.public_key_hash_tag() == Id017PtnairobConstants_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id017PtnairobConstants_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id017PtnairobConstants_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id017PtnairobConstants_PublicKeyHashTag::Bls {
            *self_rc.public_key_hash_bls.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id017PtnairobConstants_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn public_key_hash_bls(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_bls.borrow()
    }
}
impl Id017PtnairobConstants_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstants_Z {
    pub _root: SharedType<Id017PtnairobConstants>,
    pub _parent: SharedType<Id017PtnairobConstants>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id017PtnairobConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstants_Z {
    type Root = Id017PtnairobConstants;
    type Parent = Id017PtnairobConstants;

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
                    let t = Self::read_into::<_, Id017PtnairobConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id017PtnairobConstants_Z {
}
impl Id017PtnairobConstants_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id017PtnairobConstants_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id017PtnairobConstants_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id017PtnairobConstants_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id017PtnairobConstants_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id017PtnairobConstants_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
