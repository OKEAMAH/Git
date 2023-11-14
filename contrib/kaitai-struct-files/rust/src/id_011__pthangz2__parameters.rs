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
pub struct Id011Pthangz2Parameters {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    bootstrap_accounts: RefCell<OptRc<Id011Pthangz2Parameters_BootstrapAccounts>>,
    bootstrap_contracts: RefCell<OptRc<Id011Pthangz2Parameters_BootstrapContracts>>,
    commitments: RefCell<OptRc<Id011Pthangz2Parameters_Commitments>>,
    security_deposit_ramp_up_cycles_tag: RefCell<Id011Pthangz2Parameters_Bool>,
    security_deposit_ramp_up_cycles: RefCell<i32>,
    no_reward_cycles_tag: RefCell<Id011Pthangz2Parameters_Bool>,
    no_reward_cycles: RefCell<i32>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    blocks_per_roll_snapshot: RefCell<i32>,
    blocks_per_voting_period: RefCell<i32>,
    time_between_blocks: RefCell<OptRc<Id011Pthangz2Parameters_TimeBetweenBlocks>>,
    endorsers_per_block: RefCell<u16>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id011Pthangz2Parameters_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id011Pthangz2Parameters_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    origination_size: RefCell<i32>,
    block_security_deposit: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    endorsement_security_deposit: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    baking_reward_per_endorsement: RefCell<OptRc<Id011Pthangz2Parameters_BakingRewardPerEndorsement>>,
    endorsement_reward: RefCell<OptRc<Id011Pthangz2Parameters_EndorsementReward>>,
    cost_per_byte: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id011Pthangz2Parameters_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    initial_endorsers: RefCell<u16>,
    delay_per_missing_endorsement: RefCell<i64>,
    minimal_block_delay: RefCell<i64>,
    liquidity_baking_subsidy: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    liquidity_baking_sunset_level: RefCell<i32>,
    liquidity_baking_escape_ema_threshold: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_BootstrapAccounts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_accounts.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_BootstrapContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bootstrap_contracts.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Commitments>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.commitments.borrow_mut() = t;
        *self_rc.security_deposit_ramp_up_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.security_deposit_ramp_up_cycles_tag() == Id011Pthangz2Parameters_Bool::True {
            *self_rc.security_deposit_ramp_up_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.no_reward_cycles_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.no_reward_cycles_tag() == Id011Pthangz2Parameters_Bool::True {
            *self_rc.no_reward_cycles.borrow_mut() = _io.read_s4be()?.into();
        }
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_roll_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Parameters_TimeBetweenBlocks>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.time_between_blocks.borrow_mut() = t;
        *self_rc.endorsers_per_block.borrow_mut() = _io.read_u2be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.block_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.endorsement_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_BakingRewardPerEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_per_endorsement.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_EndorsementReward>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsement_reward.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.initial_endorsers.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.delay_per_missing_endorsement.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_escape_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id011Pthangz2Parameters {
}
impl Id011Pthangz2Parameters {
    pub fn bootstrap_accounts(&self) -> Ref<OptRc<Id011Pthangz2Parameters_BootstrapAccounts>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn bootstrap_contracts(&self) -> Ref<OptRc<Id011Pthangz2Parameters_BootstrapContracts>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn commitments(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Commitments>> {
        self.commitments.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn security_deposit_ramp_up_cycles_tag(&self) -> Ref<Id011Pthangz2Parameters_Bool> {
        self.security_deposit_ramp_up_cycles_tag.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn security_deposit_ramp_up_cycles(&self) -> Ref<i32> {
        self.security_deposit_ramp_up_cycles.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn no_reward_cycles_tag(&self) -> Ref<Id011Pthangz2Parameters_Bool> {
        self.no_reward_cycles_tag.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn no_reward_cycles(&self) -> Ref<i32> {
        self.no_reward_cycles.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn blocks_per_roll_snapshot(&self) -> Ref<i32> {
        self.blocks_per_roll_snapshot.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn blocks_per_voting_period(&self) -> Ref<i32> {
        self.blocks_per_voting_period.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn time_between_blocks(&self) -> Ref<OptRc<Id011Pthangz2Parameters_TimeBetweenBlocks>> {
        self.time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn endorsers_per_block(&self) -> Ref<u16> {
        self.endorsers_per_block.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn block_security_deposit(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.block_security_deposit.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn endorsement_security_deposit(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.endorsement_security_deposit.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn baking_reward_per_endorsement(&self) -> Ref<OptRc<Id011Pthangz2Parameters_BakingRewardPerEndorsement>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn endorsement_reward(&self) -> Ref<OptRc<Id011Pthangz2Parameters_EndorsementReward>> {
        self.endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn initial_endorsers(&self) -> Ref<u16> {
        self.initial_endorsers.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn delay_per_missing_endorsement(&self) -> Ref<i64> {
        self.delay_per_missing_endorsement.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn liquidity_baking_sunset_level(&self) -> Ref<i32> {
        self.liquidity_baking_sunset_level.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn liquidity_baking_escape_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_escape_ema_threshold.borrow()
    }
}
impl Id011Pthangz2Parameters {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2Parameters_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2Parameters_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2Parameters_Bool> {
        match flag {
            0 => Ok(Id011Pthangz2Parameters_Bool::False),
            255 => Ok(Id011Pthangz2Parameters_Bool::True),
            _ => Ok(Id011Pthangz2Parameters_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2Parameters_Bool> for i64 {
    fn from(v: &Id011Pthangz2Parameters_Bool) -> Self {
        match *v {
            Id011Pthangz2Parameters_Bool::False => 0,
            Id011Pthangz2Parameters_Bool::True => 255,
            Id011Pthangz2Parameters_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2Parameters_Bool {
    fn default() -> Self { Id011Pthangz2Parameters_Bool::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2Parameters_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2Parameters_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2Parameters_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id011Pthangz2Parameters_PublicKeyHashTag::Ed25519),
            1 => Ok(Id011Pthangz2Parameters_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id011Pthangz2Parameters_PublicKeyHashTag::P256),
            _ => Ok(Id011Pthangz2Parameters_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2Parameters_PublicKeyHashTag> for i64 {
    fn from(v: &Id011Pthangz2Parameters_PublicKeyHashTag) -> Self {
        match *v {
            Id011Pthangz2Parameters_PublicKeyHashTag::Ed25519 => 0,
            Id011Pthangz2Parameters_PublicKeyHashTag::Secp256k1 => 1,
            Id011Pthangz2Parameters_PublicKeyHashTag::P256 => 2,
            Id011Pthangz2Parameters_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2Parameters_PublicKeyHashTag {
    fn default() -> Self { Id011Pthangz2Parameters_PublicKeyHashTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2Parameters_PublicKeyTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2Parameters_PublicKeyTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2Parameters_PublicKeyTag> {
        match flag {
            0 => Ok(Id011Pthangz2Parameters_PublicKeyTag::Ed25519),
            1 => Ok(Id011Pthangz2Parameters_PublicKeyTag::Secp256k1),
            2 => Ok(Id011Pthangz2Parameters_PublicKeyTag::P256),
            _ => Ok(Id011Pthangz2Parameters_PublicKeyTag::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2Parameters_PublicKeyTag> for i64 {
    fn from(v: &Id011Pthangz2Parameters_PublicKeyTag) -> Self {
        match *v {
            Id011Pthangz2Parameters_PublicKeyTag::Ed25519 => 0,
            Id011Pthangz2Parameters_PublicKeyTag::Secp256k1 => 1,
            Id011Pthangz2Parameters_PublicKeyTag::P256 => 2,
            Id011Pthangz2Parameters_PublicKeyTag::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2Parameters_PublicKeyTag {
    fn default() -> Self { Id011Pthangz2Parameters_PublicKeyTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2Parameters_BootstrapAccountsEltTag {
    PublicKeyKnown,
    PublicKeyUnknown,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2Parameters_BootstrapAccountsEltTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2Parameters_BootstrapAccountsEltTag> {
        match flag {
            0 => Ok(Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyKnown),
            1 => Ok(Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyUnknown),
            _ => Ok(Id011Pthangz2Parameters_BootstrapAccountsEltTag::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2Parameters_BootstrapAccountsEltTag> for i64 {
    fn from(v: &Id011Pthangz2Parameters_BootstrapAccountsEltTag) -> Self {
        match *v {
            Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyKnown => 0,
            Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyUnknown => 1,
            Id011Pthangz2Parameters_BootstrapAccountsEltTag::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2Parameters_BootstrapAccountsEltTag {
    fn default() -> Self { Id011Pthangz2Parameters_BootstrapAccountsEltTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_TimeBetweenBlocksEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_TimeBetweenBlocks>,
    pub _self: SharedType<Self>,
    time_between_blocks_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_TimeBetweenBlocksEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_TimeBetweenBlocks;

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
        *self_rc.time_between_blocks_elt.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocksEntries {
}
impl Id011Pthangz2Parameters_TimeBetweenBlocksEntries {
    pub fn time_between_blocks_elt(&self) -> Ref<i64> {
        self.time_between_blocks_elt.borrow()
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocksEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_Commitments {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_commitments: RefCell<i32>,
    commitments: RefCell<Vec<OptRc<Id011Pthangz2Parameters_CommitmentsEntries>>>,
    _io: RefCell<BytesReader>,
    commitments_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_Commitments {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_CommitmentsEntries>(&io_commitments_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.commitments.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_Commitments {
}
impl Id011Pthangz2Parameters_Commitments {
    pub fn len_commitments(&self) -> Ref<i32> {
        self.len_commitments.borrow()
    }
}
impl Id011Pthangz2Parameters_Commitments {
    pub fn commitments(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_CommitmentsEntries>>> {
        self.commitments.borrow()
    }
}
impl Id011Pthangz2Parameters_Commitments {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_Commitments {
    pub fn commitments_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.commitments_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_N {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id011Pthangz2Parameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_N {
    type Root = Id011Pthangz2Parameters;
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
                let t = Self::read_into::<_, Id011Pthangz2Parameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id011Pthangz2Parameters_N {
}
impl Id011Pthangz2Parameters_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_NChunk>>> {
        self.n.borrow()
    }
}
impl Id011Pthangz2Parameters_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_TimeBetweenBlocks {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_time_between_blocks: RefCell<i32>,
    time_between_blocks: RefCell<Vec<OptRc<Id011Pthangz2Parameters_TimeBetweenBlocksEntries>>>,
    _io: RefCell<BytesReader>,
    time_between_blocks_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_TimeBetweenBlocks {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
        *self_rc.len_time_between_blocks.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.time_between_blocks.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.time_between_blocks_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_time_between_blocks() as usize)?.into());
                let time_between_blocks_raw = self_rc.time_between_blocks_raw.borrow();
                let io_time_between_blocks_raw = BytesReader::from(time_between_blocks_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_TimeBetweenBlocksEntries>(&io_time_between_blocks_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.time_between_blocks.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocks {
}
impl Id011Pthangz2Parameters_TimeBetweenBlocks {
    pub fn len_time_between_blocks(&self) -> Ref<i32> {
        self.len_time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocks {
    pub fn time_between_blocks(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_TimeBetweenBlocksEntries>>> {
        self.time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocks {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_TimeBetweenBlocks {
    pub fn time_between_blocks_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.time_between_blocks_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_EndorsementReward {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_endorsement_reward: RefCell<i32>,
    endorsement_reward: RefCell<Vec<OptRc<Id011Pthangz2Parameters_EndorsementRewardEntries>>>,
    _io: RefCell<BytesReader>,
    endorsement_reward_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_EndorsementReward {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
        *self_rc.len_endorsement_reward.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.endorsement_reward.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.endorsement_reward_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_endorsement_reward() as usize)?.into());
                let endorsement_reward_raw = self_rc.endorsement_reward_raw.borrow();
                let io_endorsement_reward_raw = BytesReader::from(endorsement_reward_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_EndorsementRewardEntries>(&io_endorsement_reward_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.endorsement_reward.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_EndorsementReward {
}
impl Id011Pthangz2Parameters_EndorsementReward {
    pub fn len_endorsement_reward(&self) -> Ref<i32> {
        self.len_endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Parameters_EndorsementReward {
    pub fn endorsement_reward(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_EndorsementRewardEntries>>> {
        self.endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Parameters_EndorsementReward {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_EndorsementReward {
    pub fn endorsement_reward_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.endorsement_reward_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_CommitmentsEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_Commitments>,
    pub _self: SharedType<Self>,
    commitments_elt_field0: RefCell<Vec<u8>>,
    commitments_elt_field1: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_CommitmentsEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_Commitments;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.commitments_elt_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_CommitmentsEntries {
}

/**
 * blinded__public__key__hash
 */
impl Id011Pthangz2Parameters_CommitmentsEntries {
    pub fn commitments_elt_field0(&self) -> Ref<Vec<u8>> {
        self.commitments_elt_field0.borrow()
    }
}

/**
 * id_011__pthangz2__mutez
 */
impl Id011Pthangz2Parameters_CommitmentsEntries {
    pub fn commitments_elt_field1(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.commitments_elt_field1.borrow()
    }
}
impl Id011Pthangz2Parameters_CommitmentsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_unknown_field0: RefCell<OptRc<Id011Pthangz2Parameters_PublicKeyHash>>,
    public_key_unknown_field1: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_unknown_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
}

/**
 * signature__v0__public_key_hash
 */
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field0(&self) -> Ref<OptRc<Id011Pthangz2Parameters_PublicKeyHash>> {
        self.public_key_unknown_field0.borrow()
    }
}

/**
 * id_011__pthangz2__mutez
 */
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn public_key_unknown_field1(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.public_key_unknown_field1.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key
 */

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_PublicKey {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown>,
    pub _self: SharedType<Self>,
    public_key_tag: RefCell<Id011Pthangz2Parameters_PublicKeyTag>,
    public_key_ed25519: RefCell<Vec<u8>>,
    public_key_secp256k1: RefCell<Vec<u8>>,
    public_key_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_PublicKey {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown;

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
        if *self_rc.public_key_tag() == Id011Pthangz2Parameters_PublicKeyTag::Ed25519 {
            *self_rc.public_key_ed25519.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id011Pthangz2Parameters_PublicKeyTag::Secp256k1 {
            *self_rc.public_key_secp256k1.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == Id011Pthangz2Parameters_PublicKeyTag::P256 {
            *self_rc.public_key_p256.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_PublicKey {
}
impl Id011Pthangz2Parameters_PublicKey {
    pub fn public_key_tag(&self) -> Ref<Id011Pthangz2Parameters_PublicKeyTag> {
        self.public_key_tag.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKey {
    pub fn public_key_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_ed25519.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKey {
    pub fn public_key_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_secp256k1.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKey {
    pub fn public_key_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_p256.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapAccountsEntries>,
    pub _self: SharedType<Self>,
    public_key_known_field0: RefCell<OptRc<Id011Pthangz2Parameters_PublicKey>>,
    public_key_known_field1: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapAccountsEntries;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_PublicKey>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.public_key_known_field0.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.public_key_known_field1.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
}

/**
 * signature__v0__public_key
 */
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field0(&self) -> Ref<OptRc<Id011Pthangz2Parameters_PublicKey>> {
        self.public_key_known_field0.borrow()
    }
}

/**
 * id_011__pthangz2__mutez
 */
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn public_key_known_field1(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.public_key_known_field1.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_Code {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_Code {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts;

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
impl Id011Pthangz2Parameters_Code {
}
impl Id011Pthangz2Parameters_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id011Pthangz2Parameters_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id011Pthangz2Parameters_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapAccountsEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapAccounts>,
    pub _self: SharedType<Self>,
    bootstrap_accounts_elt_tag: RefCell<Id011Pthangz2Parameters_BootstrapAccountsEltTag>,
    bootstrap_accounts_elt_public_key_known: RefCell<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown>>,
    bootstrap_accounts_elt_public_key_unknown: RefCell<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapAccountsEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapAccounts;

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
        if *self_rc.bootstrap_accounts_elt_tag() == Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyKnown {
            let t = Self::read_into::<_, Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_known.borrow_mut() = t;
        }
        if *self_rc.bootstrap_accounts_elt_tag() == Id011Pthangz2Parameters_BootstrapAccountsEltTag::PublicKeyUnknown {
            let t = Self::read_into::<_, Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.bootstrap_accounts_elt_public_key_unknown.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEntries {
}
impl Id011Pthangz2Parameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_tag(&self) -> Ref<Id011Pthangz2Parameters_BootstrapAccountsEltTag> {
        self.bootstrap_accounts_elt_tag.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_known(&self) -> Ref<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyKnown>> {
        self.bootstrap_accounts_elt_public_key_known.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEntries {
    pub fn bootstrap_accounts_elt_public_key_unknown(&self) -> Ref<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEltPublicKeyUnknown>> {
        self.bootstrap_accounts_elt_public_key_unknown.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccountsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_EndorsementRewardEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_EndorsementReward>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__mutez: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_EndorsementRewardEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_EndorsementReward;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_011__pthangz2__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_EndorsementRewardEntries {
}
impl Id011Pthangz2Parameters_EndorsementRewardEntries {
    pub fn id_011__pthangz2__mutez(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.id_011__pthangz2__mutez.borrow()
    }
}
impl Id011Pthangz2Parameters_EndorsementRewardEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapContractsEntries>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id011Pthangz2Parameters_Code>>,
    storage: RefCell<OptRc<Id011Pthangz2Parameters_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapContractsEntries;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
}
impl Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Code>> {
        self.code.borrow()
    }
}
impl Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Storage>> {
        self.storage.borrow()
    }
}
impl Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_baking_reward_per_endorsement: RefCell<i32>,
    baking_reward_per_endorsement: RefCell<Vec<OptRc<Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries>>>,
    _io: RefCell<BytesReader>,
    baking_reward_per_endorsement_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
        *self_rc.len_baking_reward_per_endorsement.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.baking_reward_per_endorsement.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.baking_reward_per_endorsement_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_baking_reward_per_endorsement() as usize)?.into());
                let baking_reward_per_endorsement_raw = self_rc.baking_reward_per_endorsement_raw.borrow();
                let io_baking_reward_per_endorsement_raw = BytesReader::from(baking_reward_per_endorsement_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries>(&io_baking_reward_per_endorsement_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.baking_reward_per_endorsement.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsement {
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    pub fn len_baking_reward_per_endorsement(&self) -> Ref<i32> {
        self.len_baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries>>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.baking_reward_per_endorsement_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_Storage {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_Storage {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts;

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
impl Id011Pthangz2Parameters_Storage {
}
impl Id011Pthangz2Parameters_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id011Pthangz2Parameters_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id011Pthangz2Parameters_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapContractsEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BootstrapContracts>,
    pub _self: SharedType<Self>,
    delegate: RefCell<OptRc<Id011Pthangz2Parameters_PublicKeyHash>>,
    amount: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    script: RefCell<OptRc<Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapContractsEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BootstrapContracts;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.delegate.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.amount.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.script.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapContractsEntries {
}
impl Id011Pthangz2Parameters_BootstrapContractsEntries {
    pub fn delegate(&self) -> Ref<OptRc<Id011Pthangz2Parameters_PublicKeyHash>> {
        self.delegate.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContractsEntries {
    pub fn amount(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.amount.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContractsEntries {
    pub fn script(&self) -> Ref<OptRc<Id011Pthangz2Parameters_Id011Pthangz2ScriptedContracts>> {
        self.script.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContractsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapContracts {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_contracts: RefCell<i32>,
    bootstrap_contracts: RefCell<Vec<OptRc<Id011Pthangz2Parameters_BootstrapContractsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_contracts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapContracts {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_BootstrapContractsEntries>(&io_bootstrap_contracts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_contracts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapContracts {
}
impl Id011Pthangz2Parameters_BootstrapContracts {
    pub fn len_bootstrap_contracts(&self) -> Ref<i32> {
        self.len_bootstrap_contracts.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContracts {
    pub fn bootstrap_contracts(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_BootstrapContractsEntries>>> {
        self.bootstrap_contracts.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapContracts {
    pub fn bootstrap_contracts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_contracts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BootstrapAccounts {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    len_bootstrap_accounts: RefCell<i32>,
    bootstrap_accounts: RefCell<Vec<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEntries>>>,
    _io: RefCell<BytesReader>,
    bootstrap_accounts_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Parameters_BootstrapAccounts {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Parameters_BootstrapAccountsEntries>(&io_bootstrap_accounts_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.bootstrap_accounts.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BootstrapAccounts {
}
impl Id011Pthangz2Parameters_BootstrapAccounts {
    pub fn len_bootstrap_accounts(&self) -> Ref<i32> {
        self.len_bootstrap_accounts.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccounts {
    pub fn bootstrap_accounts(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_BootstrapAccountsEntries>>> {
        self.bootstrap_accounts.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccounts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Parameters_BootstrapAccounts {
    pub fn bootstrap_accounts_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.bootstrap_accounts_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_NChunk {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_NChunk {
    type Root = Id011Pthangz2Parameters;
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
impl Id011Pthangz2Parameters_NChunk {
}
impl Id011Pthangz2Parameters_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id011Pthangz2Parameters_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id011Pthangz2Parameters_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_PublicKeyHash {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id011Pthangz2Parameters_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_PublicKeyHash {
    type Root = Id011Pthangz2Parameters;
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
        if *self_rc.public_key_hash_tag() == Id011Pthangz2Parameters_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id011Pthangz2Parameters_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id011Pthangz2Parameters_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id011Pthangz2Parameters_PublicKeyHash {
}
impl Id011Pthangz2Parameters_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id011Pthangz2Parameters_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id011Pthangz2Parameters_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_Z {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id011Pthangz2Parameters_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_Z {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters;

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
                    let t = Self::read_into::<_, Id011Pthangz2Parameters_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id011Pthangz2Parameters_Z {
}
impl Id011Pthangz2Parameters_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id011Pthangz2Parameters_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id011Pthangz2Parameters_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id011Pthangz2Parameters_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id011Pthangz2Parameters_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id011Pthangz2Parameters_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries {
    pub _root: SharedType<Id011Pthangz2Parameters>,
    pub _parent: SharedType<Id011Pthangz2Parameters_BakingRewardPerEndorsement>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__mutez: RefCell<OptRc<Id011Pthangz2Parameters_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries {
    type Root = Id011Pthangz2Parameters;
    type Parent = Id011Pthangz2Parameters_BakingRewardPerEndorsement;

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
        let t = Self::read_into::<_, Id011Pthangz2Parameters_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_011__pthangz2__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries {
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries {
    pub fn id_011__pthangz2__mutez(&self) -> Ref<OptRc<Id011Pthangz2Parameters_N>> {
        self.id_011__pthangz2__mutez.borrow()
    }
}
impl Id011Pthangz2Parameters_BakingRewardPerEndorsementEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
