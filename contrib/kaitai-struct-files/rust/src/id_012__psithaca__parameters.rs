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
pub struct Id012PsithacaParameters {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    bootstrap_accounts: RefCell<OptRc<Id012PsithacaParameters_BootstrapAccounts>>,
    bootstrap_contracts: RefCell<OptRc<Id012PsithacaParameters_BootstrapContracts>>,
    commitments: RefCell<OptRc<Id012PsithacaParameters_Commitments>>,
    security_deposit_ramp_up_cycles_tag: RefCell<Id012PsithacaParameters_Bool>,
    security_deposit_ramp_up_cycles: RefCell<i32>,
    no_reward_cycles_tag: RefCell<Id012PsithacaParameters_Bool>,
    no_reward_cycles: RefCell<i32>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    blocks_per_stake_snapshot: RefCell<i32>,
    blocks_per_voting_period: RefCell<i32>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id012PsithacaParameters_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id012PsithacaParameters_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id012PsithacaParameters_N>>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id012PsithacaParameters_N>>,
    origination_size: RefCell<i32>,
    baking_reward_fixed_portion: RefCell<OptRc<Id012PsithacaParameters_N>>,
    baking_reward_bonus_per_slot: RefCell<OptRc<Id012PsithacaParameters_N>>,
    endorsing_reward_per_slot: RefCell<OptRc<Id012PsithacaParameters_N>>,
    cost_per_byte: RefCell<OptRc<Id012PsithacaParameters_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id012PsithacaParameters_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    liquidity_baking_subsidy: RefCell<OptRc<Id012PsithacaParameters_N>>,
    liquidity_baking_sunset_level: RefCell<i32>,
    liquidity_baking_escape_ema_threshold: RefCell<i32>,
    max_operations_time_to_live: RefCell<i16>,
    minimal_block_delay: RefCell<i64>,
    delay_increment_per_round: RefCell<i64>,
    consensus_committee_size: RefCell<i32>,
    consensus_threshold: RefCell<i32>,
    minimal_participation_ratio: RefCell<OptRc<Id012PsithacaParameters_MinimalParticipationRatio>>,
    max_slashing_period: RefCell<i32>,
    frozen_deposits_percentage: RefCell<i32>,
    double_baking_punishment: RefCell<OptRc<Id012PsithacaParameters_N>>,
    ratio_of_frozen_deposits_slashed_per_double_endorsement: RefCell<OptRc<Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>>,
    delegate_selection: RefCell<OptRc<Id012PsithacaParameters_DelegateSelection>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_BootstrapAccounts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_accounts.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_BootstrapContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_contracts.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_Commitments>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.commitments.borrow_mut() = t;
        *self_rc.security_deposit_ramp_up_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.security_deposit_ramp_up_cycles_tag() == Id012PsithacaParameters_Bool::True {
            *self_rc.security_deposit_ramp_up_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.no_reward_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.no_reward_cycles_tag() == Id012PsithacaParameters_Bool::True {
            *self_rc.no_reward_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_stake_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.baking_reward_fixed_portion.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.baking_reward_bonus_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.endorsing_reward_per_slot.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_escape_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_operations_time_to_live.borrow_mut() = _io.read_s2be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.delay_increment_per_round.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.consensus_committee_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.consensus_threshold.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_MinimalParticipationRatio>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.minimal_participation_ratio.borrow_mut() = t;
        *self_rc.max_slashing_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.frozen_deposits_percentage.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.double_baking_punishment.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_DelegateSelection>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.delegate_selection.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters {
}
impl Id012PsithacaParameters {
    pub fn bootstrap_accounts(&self) -> Ref<OptRc<Id012PsithacaParameters_BootstrapAccounts>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn bootstrap_contracts(&self) -> Ref<OptRc<Id012PsithacaParameters_BootstrapContracts>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn commitments(&self) -> Ref<OptRc<Id012PsithacaParameters_Commitments>> {
        self.commitments.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn security_deposit_ramp_up_cycles_tag(&self) -> Ref<Id012PsithacaParameters_Bool> {
        self.security_deposit_ramp_up_cycles_tag.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn security_deposit_ramp_up_cycles(&self) -> Ref<i32> {
        self.security_deposit_ramp_up_cycles.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn no_reward_cycles_tag(&self) -> Ref<Id012PsithacaParameters_Bool> {
        self.no_reward_cycles_tag.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn no_reward_cycles(&self) -> Ref<i32> {
        self.no_reward_cycles.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn blocks_per_stake_snapshot(&self) -> Ref<i32> {
        self.blocks_per_stake_snapshot.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn blocks_per_voting_period(&self) -> Ref<i32> {
        self.blocks_per_voting_period.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id012PsithacaParameters_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id012PsithacaParameters_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn baking_reward_fixed_portion(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.baking_reward_fixed_portion.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn baking_reward_bonus_per_slot(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.baking_reward_bonus_per_slot.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn endorsing_reward_per_slot(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.endorsing_reward_per_slot.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id012PsithacaParameters_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn liquidity_baking_sunset_level(&self) -> Ref<i32> {
        self.liquidity_baking_sunset_level.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn liquidity_baking_escape_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_escape_ema_threshold.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn max_operations_time_to_live(&self) -> Ref<i16> {
        self.max_operations_time_to_live.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn delay_increment_per_round(&self) -> Ref<i64> {
        self.delay_increment_per_round.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn consensus_committee_size(&self) -> Ref<i32> {
        self.consensus_committee_size.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn consensus_threshold(&self) -> Ref<i32> {
        self.consensus_threshold.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn minimal_participation_ratio(&self) -> Ref<OptRc<Id012PsithacaParameters_MinimalParticipationRatio>> {
        self.minimal_participation_ratio.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn max_slashing_period(&self) -> Ref<i32> {
        self.max_slashing_period.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn frozen_deposits_percentage(&self) -> Ref<i32> {
        self.frozen_deposits_percentage.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn double_baking_punishment(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.double_baking_punishment.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn ratio_of_frozen_deposits_slashed_per_double_endorsement(&self) -> Ref<OptRc<Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement>> {
        self.ratio_of_frozen_deposits_slashed_per_double_endorsement.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn delegate_selection(&self) -> Ref<OptRc<Id012PsithacaParameters_DelegateSelection>> {
        self.delegate_selection.borrow()
    }
}
impl Id012PsithacaParameters {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaParameters_PublicKeyTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaParameters_PublicKeyTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaParameters_PublicKeyTag> {
        match flag {
            0 => Ok(Id012PsithacaParameters_PublicKeyTag::Ed25519),
            1 => Ok(Id012PsithacaParameters_PublicKeyTag::Secp256k1),
            2 => Ok(Id012PsithacaParameters_PublicKeyTag::P256),
            _ => Ok(Id012PsithacaParameters_PublicKeyTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaParameters_PublicKeyTag> for i64 {
    fn from(v: &Id012PsithacaParameters_PublicKeyTag) -> Self {
        match *v {
            Id012PsithacaParameters_PublicKeyTag::Ed25519 => 0,
            Id012PsithacaParameters_PublicKeyTag::Secp256k1 => 1,
            Id012PsithacaParameters_PublicKeyTag::P256 => 2,
            Id012PsithacaParameters_PublicKeyTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaParameters_PublicKeyTag {
    fn default() -> Self { Id012PsithacaParameters_PublicKeyTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaParameters_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaParameters_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaParameters_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id012PsithacaParameters_PublicKeyHashTag::Ed25519),
            1 => Ok(Id012PsithacaParameters_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id012PsithacaParameters_PublicKeyHashTag::P256),
            _ => Ok(Id012PsithacaParameters_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaParameters_PublicKeyHashTag> for i64 {
    fn from(v: &Id012PsithacaParameters_PublicKeyHashTag) -> Self {
        match *v {
            Id012PsithacaParameters_PublicKeyHashTag::Ed25519 => 0,
            Id012PsithacaParameters_PublicKeyHashTag::Secp256k1 => 1,
            Id012PsithacaParameters_PublicKeyHashTag::P256 => 2,
            Id012PsithacaParameters_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaParameters_PublicKeyHashTag {
    fn default() -> Self { Id012PsithacaParameters_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaParameters_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaParameters_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaParameters_Bool> {
        match flag {
            0 => Ok(Id012PsithacaParameters_Bool::False),
            255 => Ok(Id012PsithacaParameters_Bool::True),
            _ => Ok(Id012PsithacaParameters_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaParameters_Bool> for i64 {
    fn from(v: &Id012PsithacaParameters_Bool) -> Self {
        match *v {
            Id012PsithacaParameters_Bool::False => 0,
            Id012PsithacaParameters_Bool::True => 255,
            Id012PsithacaParameters_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaParameters_Bool {
    fn default() -> Self { Id012PsithacaParameters_Bool::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaParameters_DelegateSelectionTag {
    RandomDelegateSelection,
    RoundRobinOverDelegates,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaParameters_DelegateSelectionTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaParameters_DelegateSelectionTag> {
        match flag {
            0 => Ok(Id012PsithacaParameters_DelegateSelectionTag::RandomDelegateSelection),
            1 => Ok(Id012PsithacaParameters_DelegateSelectionTag::RoundRobinOverDelegates),
            _ => Ok(Id012PsithacaParameters_DelegateSelectionTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaParameters_DelegateSelectionTag> for i64 {
    fn from(v: &Id012PsithacaParameters_DelegateSelectionTag) -> Self {
        match *v {
            Id012PsithacaParameters_DelegateSelectionTag::RandomDelegateSelection => 0,
            Id012PsithacaParameters_DelegateSelectionTag::RoundRobinOverDelegates => 1,
            Id012PsithacaParameters_DelegateSelectionTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaParameters_DelegateSelectionTag {
    fn default() -> Self { Id012PsithacaParameters_DelegateSelectionTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaParameters_BootstrapAccountsEltTag {
    PublicKeyKnown,
    PublicKeyUnknown,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaParameters_BootstrapAccountsEltTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaParameters_BootstrapAccountsEltTag> {
        match flag {
            0 => Ok(Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyKnown),
            1 => Ok(Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyUnknown),
            _ => Ok(Id012PsithacaParameters_BootstrapAccountsEltTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaParameters_BootstrapAccountsEltTag> for i64 {
    fn from(v: &Id012PsithacaParameters_BootstrapAccountsEltTag) -> Self {
        match *v {
            Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyKnown => 0,
            Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyUnknown => 1,
            Id012PsithacaParameters_BootstrapAccountsEltTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaParameters_BootstrapAccountsEltTag {
    fn default() -> Self { Id012PsithacaParameters_BootstrapAccountsEltTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
impl Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
}
impl Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id012PsithacaParameters_RatioOfFrozenDepositsSlashedPerDoubleEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_Commitments {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    len_commitments: RefCell<i32>,
    commitments: RefCell<Vec<OptRc<Id012PsithacaParameters_CommitmentsEntries>>>,
    _io: RefCell<BytesReader>,
    commitments_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaParameters_Commitments {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
                let t = Self::read_into::<BytesReader, Id012PsithacaParameters_CommitmentsEntries>(&io_commitments_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.commitments.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_Commitments {
}
impl Id012PsithacaParameters_Commitments {
    pub fn len_commitments(&self) -> Ref<i32> {
        self.len_commitments.borrow()
    }
}
impl Id012PsithacaParameters_Commitments {
    pub fn commitments(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_CommitmentsEntries>>> {
        self.commitments.borrow()
    }
}
impl Id012PsithacaParameters_Commitments {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaParameters_Commitments {
    pub fn commitments_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.commitments_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_Id012PsithacaScriptedContracts {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_BootstrapContractsEntries>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id012PsithacaParameters_Code>>,
    storage: RefCell<OptRc<Id012PsithacaParameters_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_Id012PsithacaScriptedContracts {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_BootstrapContractsEntries;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_Id012PsithacaScriptedContracts {
}
impl Id012PsithacaParameters_Id012PsithacaScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id012PsithacaParameters_Code>> {
        self.code.borrow()
    }
}
impl Id012PsithacaParameters_Id012PsithacaScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id012PsithacaParameters_Storage>> {
        self.storage.borrow()
    }
}
impl Id012PsithacaParameters_Id012PsithacaScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_N {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id012PsithacaParameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_N {
    type Root = Id012PsithacaParameters;
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
                let t = Self::read_into::<_, Id012PsithacaParameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id012PsithacaParameters_N {
}
impl Id012PsithacaParameters_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_NChunk>>> {
        self.n.borrow()
    }
}
impl Id012PsithacaParameters_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates>,
    pub _self: SharedType<Self>,
    len_round_robin_over_delegates_elt: RefCell<i32>,
    round_robin_over_delegates_elt: RefCell<Vec<OptRc<Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries>>>,
    _io: RefCell<BytesReader>,
    round_robin_over_delegates_elt_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates;

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
                let t = Self::read_into::<BytesReader, Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries>(&io_round_robin_over_delegates_elt_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.round_robin_over_delegates_elt.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    pub fn len_round_robin_over_delegates_elt(&self) -> Ref<i32> {
        self.len_round_robin_over_delegates_elt.borrow()
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    pub fn round_robin_over_delegates_elt(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries>>> {
        self.round_robin_over_delegates_elt.borrow()
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEntries {
    pub fn round_robin_over_delegates_elt_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.round_robin_over_delegates_elt_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_CommitmentsEntries {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_Commitments>,
    pub _self: SharedType<Self>,
    commitments_elt_field0: RefCell<Vec<u8>>,
    commitments_elt_field1: RefCell<OptRc<Id012PsithacaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_CommitmentsEntries {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_Commitments;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.commitments_elt_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_CommitmentsEntries {
}

/**
 * blinded__public__key__hash
 */
impl Id012PsithacaParameters_CommitmentsEntries {
    pub fn commitments_elt_field0(&self) -> Ref<Vec<u8>> {
        self.commitments_elt_field0.borrow()
    }
}

/**
 * id_012__psithaca__mutez
 */
impl Id012PsithacaParameters_CommitmentsEntries {
    pub fn commitments_elt_field1(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.commitments_elt_field1.borrow()
    }
}
impl Id012PsithacaParameters_CommitmentsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_unknown_field0: RefCell<OptRc<Id012PsithacaParameters_PublicKeyHash>>,
    public_key_unknown_field1: RefCell<OptRc<Id012PsithacaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
}

/**
 * signature__v0__public_key_hash
 */
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field0(&self) -> Ref<OptRc<Id012PsithacaParameters_PublicKeyHash>> {
        self.public_key_unknown_field0.borrow()
    }
}

/**
 * id_012__psithaca__mutez
 */
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field1(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.public_key_unknown_field1.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_DelegateSelection>,
    pub _self: SharedType<Self>,
    len_round_robin_over_delegates: RefCell<i32>,
    round_robin_over_delegates: RefCell<Vec<OptRc<Id012PsithacaParameters_RoundRobinOverDelegatesEntries>>>,
    _io: RefCell<BytesReader>,
    round_robin_over_delegates_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_DelegateSelection;

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
                let t = Self::read_into::<BytesReader, Id012PsithacaParameters_RoundRobinOverDelegatesEntries>(&io_round_robin_over_delegates_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.round_robin_over_delegates.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
}
impl Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    pub fn len_round_robin_over_delegates(&self) -> Ref<i32> {
        self.len_round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    pub fn round_robin_over_delegates(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_RoundRobinOverDelegatesEntries>>> {
        self.round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates {
    pub fn round_robin_over_delegates_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.round_robin_over_delegates_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_MinimalParticipationRatio {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    numerator: RefCell<u16>,
    denominator: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_MinimalParticipationRatio {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
impl Id012PsithacaParameters_MinimalParticipationRatio {
}
impl Id012PsithacaParameters_MinimalParticipationRatio {
    pub fn numerator(&self) -> Ref<u16> {
        self.numerator.borrow()
    }
}
impl Id012PsithacaParameters_MinimalParticipationRatio {
    pub fn denominator(&self) -> Ref<u16> {
        self.denominator.borrow()
    }
}
impl Id012PsithacaParameters_MinimalParticipationRatio {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key
 */

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_PublicKey {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    public_key_tag: RefCell<Id012PsithacaParameters_PublicKeyTag>,
    public_key_ed25519: RefCell<Vec<u8>>,
    public_key_secp256k1: RefCell<Vec<u8>>,
    public_key_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_PublicKey {
    type Root = Id012PsithacaParameters;
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
        if *self_rc.public_key_tag() == Id012PsithacaParameters_PublicKeyTag::Ed25519 {
            *self_rc.public_key_ed25519.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id012PsithacaParameters_PublicKeyTag::Secp256k1 {
            *self_rc.public_key_secp256k1.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id012PsithacaParameters_PublicKeyTag::P256 {
            *self_rc.public_key_p256.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_PublicKey {
}
impl Id012PsithacaParameters_PublicKey {
    pub fn public_key_tag(&self) -> Ref<Id012PsithacaParameters_PublicKeyTag> {
        self.public_key_tag.borrow()
    }
}
impl Id012PsithacaParameters_PublicKey {
    pub fn public_key_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_ed25519.borrow()
    }
}
impl Id012PsithacaParameters_PublicKey {
    pub fn public_key_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_secp256k1.borrow()
    }
}
impl Id012PsithacaParameters_PublicKey {
    pub fn public_key_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_p256.borrow()
    }
}
impl Id012PsithacaParameters_PublicKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_known_field0: RefCell<OptRc<Id012PsithacaParameters_PublicKey>>,
    public_key_known_field1: RefCell<OptRc<Id012PsithacaParameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_PublicKey>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
}

/**
 * signature__v0__public_key
 */
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field0(&self) -> Ref<OptRc<Id012PsithacaParameters_PublicKey>> {
        self.public_key_known_field0.borrow()
    }
}

/**
 * id_012__psithaca__mutez
 */
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field1(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.public_key_known_field1.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_Code {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_Id012PsithacaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_Code {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_Id012PsithacaScriptedContracts;

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
impl Id012PsithacaParameters_Code {
}
impl Id012PsithacaParameters_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id012PsithacaParameters_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id012PsithacaParameters_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapAccountsEntries {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_BootstrapAccounts>,
    pub _self: SharedType<Self>,
    bootstrap_accounts_elt_tag: RefCell<Id012PsithacaParameters_BootstrapAccountsEltTag>,
    bootstrap_accounts_elt_public_key_known: RefCell<OptRc<Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown>>,
    bootstrap_accounts_elt_public_key_unknown: RefCell<OptRc<Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_BootstrapAccountsEntries {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_BootstrapAccounts;

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
        if *self_rc.bootstrap_accounts_elt_tag() == Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyKnown {
            let t = Self::read_into::<_, Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_known.borrow_mut() = t;
        }
        if *self_rc.bootstrap_accounts_elt_tag() == Id012PsithacaParameters_BootstrapAccountsEltTag::PublicKeyUnknown {
            let t = Self::read_into::<_, Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_unknown.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEntries {
}
impl Id012PsithacaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_tag(&self) -> Ref<Id012PsithacaParameters_BootstrapAccountsEltTag> {
        self.bootstrap_accounts_elt_tag.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_known(&self) -> Ref<OptRc<Id012PsithacaParameters_BootstrapAccountsEltPublicKeyKnown>> {
        self.bootstrap_accounts_elt_public_key_known.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_unknown(&self) -> Ref<OptRc<Id012PsithacaParameters_BootstrapAccountsEltPublicKeyUnknown>> {
        self.bootstrap_accounts_elt_public_key_unknown.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccountsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_DelegateSelection {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    delegate_selection_tag: RefCell<Id012PsithacaParameters_DelegateSelectionTag>,
    delegate_selection_round_robin_over_delegates: RefCell<OptRc<Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_DelegateSelection {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
        if *self_rc.delegate_selection_tag() == Id012PsithacaParameters_DelegateSelectionTag::RoundRobinOverDelegates {
            let t = Self::read_into::<_, Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.delegate_selection_round_robin_over_delegates.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_DelegateSelection {
}
impl Id012PsithacaParameters_DelegateSelection {
    pub fn delegate_selection_tag(&self) -> Ref<Id012PsithacaParameters_DelegateSelectionTag> {
        self.delegate_selection_tag.borrow()
    }
}
impl Id012PsithacaParameters_DelegateSelection {
    pub fn delegate_selection_round_robin_over_delegates(&self) -> Ref<OptRc<Id012PsithacaParameters_DelegateSelectionRoundRobinOverDelegates>> {
        self.delegate_selection_round_robin_over_delegates.borrow()
    }
}
impl Id012PsithacaParameters_DelegateSelection {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_Storage {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_Id012PsithacaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_Storage {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_Id012PsithacaScriptedContracts;

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
impl Id012PsithacaParameters_Storage {
}
impl Id012PsithacaParameters_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id012PsithacaParameters_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id012PsithacaParameters_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapContractsEntries {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_BootstrapContracts>,
    pub _self: SharedType<Self>,
    delegate_tag: RefCell<Id012PsithacaParameters_Bool>,
    delegate: RefCell<OptRc<Id012PsithacaParameters_PublicKeyHash>>,
    amount: RefCell<OptRc<Id012PsithacaParameters_N>>,
    script: RefCell<OptRc<Id012PsithacaParameters_Id012PsithacaScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_BootstrapContractsEntries {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_BootstrapContracts;

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
        if *self_rc.delegate_tag() == Id012PsithacaParameters_Bool::True {
            let t = Self::read_into::<_, Id012PsithacaParameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
            *self_rc.delegate.borrow_mut() = t;
        }
        let t = Self::read_into::<_, Id012PsithacaParameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.amount.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaParameters_Id012PsithacaScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.script.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
    pub fn delegate_tag(&self) -> Ref<Id012PsithacaParameters_Bool> {
        self.delegate_tag.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
    pub fn delegate(&self) -> Ref<OptRc<Id012PsithacaParameters_PublicKeyHash>> {
        self.delegate.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
    pub fn amount(&self) -> Ref<OptRc<Id012PsithacaParameters_N>> {
        self.amount.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
    pub fn script(&self) -> Ref<OptRc<Id012PsithacaParameters_Id012PsithacaScriptedContracts>> {
        self.script.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContractsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters_RoundRobinOverDelegatesEntries>,
    pub _self: SharedType<Self>,
    signature__v0__public_key: RefCell<OptRc<Id012PsithacaParameters_PublicKey>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters_RoundRobinOverDelegatesEntries;

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
        let t = Self::read_into::<_, Id012PsithacaParameters_PublicKey>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.signature__v0__public_key.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries {
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries {
    pub fn signature__v0__public_key(&self) -> Ref<OptRc<Id012PsithacaParameters_PublicKey>> {
        self.signature__v0__public_key.borrow()
    }
}
impl Id012PsithacaParameters_RoundRobinOverDelegatesEltEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapContracts {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_contracts: RefCell<i32>,
    bootstrap_contracts: RefCell<Vec<OptRc<Id012PsithacaParameters_BootstrapContractsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_contracts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaParameters_BootstrapContracts {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
                let t = Self::read_into::<BytesReader, Id012PsithacaParameters_BootstrapContractsEntries>(&io_bootstrap_contracts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_contracts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapContracts {
}
impl Id012PsithacaParameters_BootstrapContracts {
    pub fn len_bootstrap_contracts(&self) -> Ref<i32> {
        self.len_bootstrap_contracts.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContracts {
    pub fn bootstrap_contracts(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_BootstrapContractsEntries>>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapContracts {
    pub fn bootstrap_contracts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_contracts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_BootstrapAccounts {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_accounts: RefCell<i32>,
    bootstrap_accounts: RefCell<Vec<OptRc<Id012PsithacaParameters_BootstrapAccountsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_accounts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaParameters_BootstrapAccounts {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
                let t = Self::read_into::<BytesReader, Id012PsithacaParameters_BootstrapAccountsEntries>(&io_bootstrap_accounts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_accounts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_BootstrapAccounts {
}
impl Id012PsithacaParameters_BootstrapAccounts {
    pub fn len_bootstrap_accounts(&self) -> Ref<i32> {
        self.len_bootstrap_accounts.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccounts {
    pub fn bootstrap_accounts(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_BootstrapAccountsEntries>>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccounts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaParameters_BootstrapAccounts {
    pub fn bootstrap_accounts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_accounts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_NChunk {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_NChunk {
    type Root = Id012PsithacaParameters;
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
impl Id012PsithacaParameters_NChunk {
}
impl Id012PsithacaParameters_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id012PsithacaParameters_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaParameters_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_PublicKeyHash {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id012PsithacaParameters_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_PublicKeyHash {
    type Root = Id012PsithacaParameters;
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
        if *self_rc.public_key_hash_tag() == Id012PsithacaParameters_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id012PsithacaParameters_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id012PsithacaParameters_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id012PsithacaParameters_PublicKeyHash {
}
impl Id012PsithacaParameters_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id012PsithacaParameters_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id012PsithacaParameters_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id012PsithacaParameters_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id012PsithacaParameters_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id012PsithacaParameters_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaParameters_Z {
    pub _root: SharedType<Id012PsithacaParameters>,
    pub _parent: SharedType<Id012PsithacaParameters>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id012PsithacaParameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaParameters_Z {
    type Root = Id012PsithacaParameters;
    type Parent = Id012PsithacaParameters;

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
                    let t = Self::read_into::<_, Id012PsithacaParameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id012PsithacaParameters_Z {
}
impl Id012PsithacaParameters_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id012PsithacaParameters_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id012PsithacaParameters_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaParameters_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id012PsithacaParameters_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id012PsithacaParameters_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
