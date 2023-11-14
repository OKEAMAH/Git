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
pub struct Id012PsithacaConstants {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    proof_of_work_nonce_size: RefCell<u8>,
    nonce_length: RefCell<u8>,
    max_anon_ops_per_block: RefCell<u8>,
    max_operation_data_length: RefCell<i32>,
    max_proposals_per_delegate: RefCell<u8>,
    max_micheline_node_count: RefCell<i32>,
    max_micheline_bytes_limit: RefCell<i32>,
    max_allowed_global_constants_depth: RefCell<i32>,
    cache_layout: RefCell<OptRc<Id012PsithacaConstants_CacheLayout>>,
    michelson_maximum_type_size: RefCell<u16>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    blocks_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id012PsithacaConstants_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id012PsithacaConstants_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id012PsithacaConstants_N>>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id012PsithacaConstants_N>>,
    origination_size: RefCell<i32>,
    baking_reward_fixed_portion: RefCell<OptRc<Id012PsithacaConstants_N>>,
    baking_reward_bonus_per_slot: RefCell<OptRc<Id012PsithacaConstants_N>>,
    endorsing_reward_per_slot: RefCell<OptRc<Id012PsithacaConstants_N>>,
    cost_per_byte: RefCell<OptRc<Id012PsithacaConstants_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id012PsithacaConstants_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_subsidy: RefCell<OptRc<Id012PsithacaConstants_N>>,
    liquidity_baking_sunset_level: RefCell<i32>,
    liquidity_baking_escape_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<Id012PsithacaConstants_MinimalParticipationRatio>>,
    max_slashing_period: RefCell<i32>,
    frozen_deposits_percentage: RefCell<i32>,
    double_baking_punishment: RefCell<OptRc<Id012PsithacaConstants_N>>,
    ratio_of_frozen_deposits_slashed_per_double_endorsement: RefCell<OptRc<Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>>,
    delegate_selection: RefCell<OptRc<Id012PsithacaConstants_DelegateSelection>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
        let t = Self::read_into::<_, Id012PsithacaConstants_CacheLayout>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cache_layout.borrow_mut() = t;
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_fixed_portion.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_bonus_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsing_reward_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_escape_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.max_slashing_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.frozen_deposits_percentage.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstants_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.double_baking_punishment.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaConstants_DelegateSelection>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.delegate_selection.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaConstants {
}
impl Id012PsithacaConstants {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn cache_layout(&self) -> Ref<OptRc<Id012PsithacaConstants_CacheLayout>> {
        self.cache_layout.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn blocks_per_voting_period(&self) -> Ref<i32> {
        self.blocks_per_voting_period.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id012PsithacaConstants_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id012PsithacaConstants_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn baking_reward_fixed_portion(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.baking_reward_fixed_portion.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn baking_reward_bonus_per_slot(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.baking_reward_bonus_per_slot.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn endorsing_reward_per_slot(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.endorsing_reward_per_slot.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id012PsithacaConstants_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn liquidity_baking_sunset_level(&self) -> Ref<i32> {
        self.liquidity_baking_sunset_level.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn liquidity_baking_escape_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_escape_ema_threshold.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<Id012PsithacaConstants_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn max_slashing_period(&self) -> Ref<i32> {
        self.max_slashing_period.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn frozen_deposits_percentage(&self) -> Ref<i32> {
        self.frozen_deposits_percentage.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn double_baking_punishment(&self) -> Ref<OptRc<Id012PsithacaConstants_N>> {
        self.double_baking_punishment.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn ratio_of_frozen_deposits_slashed_per_double_endorsement(&self) -> Ref<OptRc<Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>> {
        self.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn delegate_selection(&self) -> Ref<OptRc<Id012PsithacaConstants_DelegateSelection>> {
        self.delegate_selection.borrow()
    }
}
impl Id012PsithacaConstants {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaConstants_PublicKeyTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaConstants_PublicKeyTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaConstants_PublicKeyTag> {
        match flag {
            0 => Ok(Id012PsithacaConstants_PublicKeyTag::Ed25519),
            1 => Ok(Id012PsithacaConstants_PublicKeyTag::Secp256k1),
            2 => Ok(Id012PsithacaConstants_PublicKeyTag::P256),
            _ => Ok(Id012PsithacaConstants_PublicKeyTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaConstants_PublicKeyTag> for i64 {
    fn from(v: &Id012PsithacaConstants_PublicKeyTag) -> Self {
        match *v {
            Id012PsithacaConstants_PublicKeyTag::Ed25519 => 0,
            Id012PsithacaConstants_PublicKeyTag::Secp256k1 => 1,
            Id012PsithacaConstants_PublicKeyTag::P256 => 2,
            Id012PsithacaConstants_PublicKeyTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaConstants_PublicKeyTag {
    fn default() -> Self { Id012PsithacaConstants_PublicKeyTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaConstants_DelegateSelectionTag {
    RandomDelegateSelection,
    RoundRobinOverDelegates,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaConstants_DelegateSelectionTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaConstants_DelegateSelectionTag> {
        match flag {
            0 => Ok(Id012PsithacaConstants_DelegateSelectionTag::RandomDelegateSelection),
            1 => Ok(Id012PsithacaConstants_DelegateSelectionTag::RoundRobinOverDelegates),
            _ => Ok(Id012PsithacaConstants_DelegateSelectionTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaConstants_DelegateSelectionTag> for i64 {
    fn from(v: &Id012PsithacaConstants_DelegateSelectionTag) -> Self {
        match *v {
            Id012PsithacaConstants_DelegateSelectionTag::RandomDelegateSelection => 0,
            Id012PsithacaConstants_DelegateSelectionTag::RoundRobinOverDelegates => 1,
            Id012PsithacaConstants_DelegateSelectionTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaConstants_DelegateSelectionTag {
    fn default() -> Self { Id012PsithacaConstants_DelegateSelectionTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
impl Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
}
impl Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id012PsithacaConstants_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_N {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id012PsithacaConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_N {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
                let t = Self::read_into::<_, Id012PsithacaConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id012PsithacaConstants_N {
}
impl Id012PsithacaConstants_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id012PsithacaConstants_NChunk>>> {
        self.n.borrow()
    }
}
impl Id012PsithacaConstants_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates>,
    pub _self: SharedType<Self>,
    len_round_robin_over_delegates_elt: RefCell<i32>,
    round_robin_over_delegates_elt: RefCell<Vec<OptRc<Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries>>>,
    _io: RefCell<BytesReader>,
    round_robin_over_delegates_elt_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates;

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
        *self_rc.len_round_robin_over_delegates_elt.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.round_robin_over_delegates_elt.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.round_robin_over_delegates_elt_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_round_robin_over_delegates_elt() as usize)?.into());
                let round_robin_over_delegates_elt_raw = self_rc.round_robin_over_delegates_elt_raw.borrow();
                let io_round_robin_over_delegates_elt_raw = BytesReader::from(round_robin_over_delegates_elt_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries>(&io_round_robin_over_delegates_elt_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.round_robin_over_delegates_elt.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    pub fn len_round_robin_over_delegates_elt(&self) -> Ref<i32> {
        self.len_round_robin_over_delegates_elt.borrow()
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    pub fn round_robin_over_delegates_elt(&self) -> Ref<Vec<OptRc<Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries>>> {
        self.round_robin_over_delegates_elt.borrow()
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEntries {
    pub fn round_robin_over_delegates_elt_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.round_robin_over_delegates_elt_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_CacheLayoutEntries {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants_CacheLayout>,
    pub _self: SharedType<Self>,
    cache_layout_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_CacheLayoutEntries {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants_CacheLayout;

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
        *self_rc.cache_layout_elt.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id012PsithacaConstants_CacheLayoutEntries {
}
impl Id012PsithacaConstants_CacheLayoutEntries {
    pub fn cache_layout_elt(&self) -> Ref<i64> {
        self.cache_layout_elt.borrow()
    }
}
impl Id012PsithacaConstants_CacheLayoutEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants_DelegateSelection>,
    pub _self: SharedType<Self>,
    len_round_robin_over_delegates: RefCell<i32>,
    round_robin_over_delegates: RefCell<Vec<OptRc<Id012PsithacaConstants_RoundRobinOverDelegatesEntries>>>,
    _io: RefCell<BytesReader>,
    round_robin_over_delegates_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants_DelegateSelection;

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
        *self_rc.len_round_robin_over_delegates.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.round_robin_over_delegates.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.round_robin_over_delegates_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_round_robin_over_delegates() as usize)?.into());
                let round_robin_over_delegates_raw = self_rc.round_robin_over_delegates_raw.borrow();
                let io_round_robin_over_delegates_raw = BytesReader::from(round_robin_over_delegates_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id012PsithacaConstants_RoundRobinOverDelegatesEntries>(&io_round_robin_over_delegates_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.round_robin_over_delegates.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
}
impl Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    pub fn len_round_robin_over_delegates(&self) -> Ref<i32> {
        self.len_round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    pub fn round_robin_over_delegates(&self) -> Ref<Vec<OptRc<Id012PsithacaConstants_RoundRobinOverDelegatesEntries>>> {
        self.round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates {
    pub fn round_robin_over_delegates_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.round_robin_over_delegates_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_CacheLayout {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    len_cache_layout: RefCell<i32>,
    cache_layout: RefCell<Vec<OptRc<Id012PsithacaConstants_CacheLayoutEntries>>>,
    _io: RefCell<BytesReader>,
    cache_layout_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaConstants_CacheLayout {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
        *self_rc.len_cache_layout.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_layout.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.cache_layout_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_cache_layout() as usize)?.into());
                let cache_layout_raw = self_rc.cache_layout_raw.borrow();
                let io_cache_layout_raw = BytesReader::from(cache_layout_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id012PsithacaConstants_CacheLayoutEntries>(&io_cache_layout_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.cache_layout.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaConstants_CacheLayout {
}
impl Id012PsithacaConstants_CacheLayout {
    pub fn len_cache_layout(&self) -> Ref<i32> {
        self.len_cache_layout.borrow()
    }
}
impl Id012PsithacaConstants_CacheLayout {
    pub fn cache_layout(&self) -> Ref<Vec<OptRc<Id012PsithacaConstants_CacheLayoutEntries>>> {
        self.cache_layout.borrow()
    }
}
impl Id012PsithacaConstants_CacheLayout {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaConstants_CacheLayout {
    pub fn cache_layout_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.cache_layout_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_MinimalParticipationRatio {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_MinimalParticipationRatio {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
impl Id012PsithacaConstants_MinimalParticipationRatio {
}
impl Id012PsithacaConstants_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id012PsithacaConstants_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id012PsithacaConstants_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key
 */

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_PublicKey {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries>,
    pub _self: SharedType<Self>,
    public_key_tag: RefCell<Id012PsithacaConstants_PublicKeyTag>,
    public_key_ed25519: RefCell<Vec<u8>>,
    public_key_secp256k1: RefCell<Vec<u8>>,
    public_key_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_PublicKey {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries;

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
        if *self_rc.public_key_tag() == Id012PsithacaConstants_PublicKeyTag::Ed25519 {
            *self_rc.public_key_ed25519.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id012PsithacaConstants_PublicKeyTag::Secp256k1 {
            *self_rc.public_key_secp256k1.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id012PsithacaConstants_PublicKeyTag::P256 {
            *self_rc.public_key_p256.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        Ok(())
    }
}
impl Id012PsithacaConstants_PublicKey {
}
impl Id012PsithacaConstants_PublicKey {
    pub fn public_key_tag(&self) -> Ref<Id012PsithacaConstants_PublicKeyTag> {
        self.public_key_tag.borrow()
    }
}
impl Id012PsithacaConstants_PublicKey {
    pub fn public_key_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_ed25519.borrow()
    }
}
impl Id012PsithacaConstants_PublicKey {
    pub fn public_key_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_secp256k1.borrow()
    }
}
impl Id012PsithacaConstants_PublicKey {
    pub fn public_key_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_p256.borrow()
    }
}
impl Id012PsithacaConstants_PublicKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_DelegateSelection {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    delegate_selection_tag: RefCell<Id012PsithacaConstants_DelegateSelectionTag>,
    delegate_selection_round_robin_over_delegates: RefCell<OptRc<Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_DelegateSelection {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
        *self_rc.delegate_selection_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.delegate_selection_tag() == Id012PsithacaConstants_DelegateSelectionTag::RoundRobinOverDelegates {
            let t = Self::read_into::<_, Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.delegate_selection_round_robin_over_delegates.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id012PsithacaConstants_DelegateSelection {
}
impl Id012PsithacaConstants_DelegateSelection {
    pub fn delegate_selection_tag(&self) -> Ref<Id012PsithacaConstants_DelegateSelectionTag> {
        self.delegate_selection_tag.borrow()
    }
}
impl Id012PsithacaConstants_DelegateSelection {
    pub fn delegate_selection_round_robin_over_delegates(&self) -> Ref<OptRc<Id012PsithacaConstants_DelegateSelectionRoundRobinOverDelegates>> {
        self.delegate_selection_round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaConstants_DelegateSelection {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants_RoundRobinOverDelegatesEntries>,
    pub _self: SharedType<Self>,
    signature__v0__public_key: RefCell<OptRc<Id012PsithacaConstants_PublicKey>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants_RoundRobinOverDelegatesEntries;

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
        let t = Self::read_into::<_, Id012PsithacaConstants_PublicKey>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.signature__v0__public_key.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries {
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries {
    pub fn signature__v0__public_key(&self) -> Ref<OptRc<Id012PsithacaConstants_PublicKey>> {
        self.signature__v0__public_key.borrow()
    }
}
impl Id012PsithacaConstants_RoundRobinOverDelegatesEltEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_NChunk {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_NChunk {
    type Root = Id012PsithacaConstants;
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
impl Id012PsithacaConstants_NChunk {
}
impl Id012PsithacaConstants_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id012PsithacaConstants_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaConstants_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstants_Z {
    pub _root: SharedType<Id012PsithacaConstants>,
    pub _parent: SharedType<Id012PsithacaConstants>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id012PsithacaConstants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstants_Z {
    type Root = Id012PsithacaConstants;
    type Parent = Id012PsithacaConstants;

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
                    let t = Self::read_into::<_, Id012PsithacaConstants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id012PsithacaConstants_Z {
}
impl Id012PsithacaConstants_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id012PsithacaConstants_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id012PsithacaConstants_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaConstants_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id012PsithacaConstants_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id012PsithacaConstants_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
