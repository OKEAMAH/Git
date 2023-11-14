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
pub struct Id007Psdelph1ConstantsParametric {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _self: SharedType<Self>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    blocks_per_roll_snapshot: RefCell<i32>,
    blocks_per_voting_period: RefCell<i32>,
    time_between_blocks: RefCell<OptRc<Id007Psdelph1ConstantsParametric_TimeBetweenBlocks>>,
    endorsers_per_block: RefCell<u16>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id007Psdelph1ConstantsParametric_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id007Psdelph1ConstantsParametric_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    michelson_maximum_type_size: RefCell<u16>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    origination_size: RefCell<i32>,
    block_security_deposit: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    endorsement_security_deposit: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    baking_reward_per_endorsement: RefCell<OptRc<Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement>>,
    endorsement_reward: RefCell<OptRc<Id007Psdelph1ConstantsParametric_EndorsementReward>>,
    cost_per_byte: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id007Psdelph1ConstantsParametric_Z>>,
    test_chain_duration: RefCell<i64>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    initial_endorsers: RefCell<u16>,
    delay_per_missing_endorsement: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric;

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
        *self_rc.blocks_per_roll_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_TimeBetweenBlocks>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.time_between_blocks.borrow_mut() = t;
        *self_rc.endorsers_per_block.borrow_mut() = _io.read_u2be()?.into();
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.block_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.endorsement_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_per_endorsement.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_EndorsementReward>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsement_reward.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.test_chain_duration.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.initial_endorsers.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.delay_per_missing_endorsement.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric {
}
impl Id007Psdelph1ConstantsParametric {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn blocks_per_roll_snapshot(&self) -> Ref<i32> {
        self.blocks_per_roll_snapshot.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn blocks_per_voting_period(&self) -> Ref<i32> {
        self.blocks_per_voting_period.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn time_between_blocks(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_TimeBetweenBlocks>> {
        self.time_between_blocks.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn endorsers_per_block(&self) -> Ref<u16> {
        self.endorsers_per_block.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn block_security_deposit(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.block_security_deposit.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn endorsement_security_deposit(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.endorsement_security_deposit.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn baking_reward_per_endorsement(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn endorsement_reward(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_EndorsementReward>> {
        self.endorsement_reward.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn test_chain_duration(&self) -> Ref<i64> {
        self.test_chain_duration.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn initial_endorsers(&self) -> Ref<u16> {
        self.initial_endorsers.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn delay_per_missing_endorsement(&self) -> Ref<i64> {
        self.delay_per_missing_endorsement.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric_TimeBetweenBlocks>,
    pub _self: SharedType<Self>,
    time_between_blocks_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric_TimeBetweenBlocks;

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
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries {
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries {
    pub fn time_between_blocks_elt(&self) -> Ref<i64> {
        self.time_between_blocks_elt.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_N {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id007Psdelph1ConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_N {
    type Root = Id007Psdelph1ConstantsParametric;
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
                let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id007Psdelph1ConstantsParametric_N {
}
impl Id007Psdelph1ConstantsParametric_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id007Psdelph1ConstantsParametric_NChunk>>> {
        self.n.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _self: SharedType<Self>,
    len_time_between_blocks: RefCell<i32>,
    time_between_blocks: RefCell<Vec<OptRc<Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries>>>,
    _io: RefCell<BytesReader>,
    time_between_blocks_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric;

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
                let t = Self::read_into::<BytesReader, Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries>(&io_time_between_blocks_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.time_between_blocks.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    pub fn len_time_between_blocks(&self) -> Ref<i32> {
        self.len_time_between_blocks.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    pub fn time_between_blocks(&self) -> Ref<Vec<OptRc<Id007Psdelph1ConstantsParametric_TimeBetweenBlocksEntries>>> {
        self.time_between_blocks.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_TimeBetweenBlocks {
    pub fn time_between_blocks_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.time_between_blocks_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_EndorsementReward {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _self: SharedType<Self>,
    len_endorsement_reward: RefCell<i32>,
    endorsement_reward: RefCell<Vec<OptRc<Id007Psdelph1ConstantsParametric_EndorsementRewardEntries>>>,
    _io: RefCell<BytesReader>,
    endorsement_reward_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_EndorsementReward {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric;

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
                let t = Self::read_into::<BytesReader, Id007Psdelph1ConstantsParametric_EndorsementRewardEntries>(&io_endorsement_reward_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.endorsement_reward.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementReward {
}
impl Id007Psdelph1ConstantsParametric_EndorsementReward {
    pub fn len_endorsement_reward(&self) -> Ref<i32> {
        self.len_endorsement_reward.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementReward {
    pub fn endorsement_reward(&self) -> Ref<Vec<OptRc<Id007Psdelph1ConstantsParametric_EndorsementRewardEntries>>> {
        self.endorsement_reward.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementReward {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementReward {
    pub fn endorsement_reward_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.endorsement_reward_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_EndorsementRewardEntries {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric_EndorsementReward>,
    pub _self: SharedType<Self>,
    id_007__psdelph1__mutez: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_EndorsementRewardEntries {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric_EndorsementReward;

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
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_007__psdelph1__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementRewardEntries {
}
impl Id007Psdelph1ConstantsParametric_EndorsementRewardEntries {
    pub fn id_007__psdelph1__mutez(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.id_007__psdelph1__mutez.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_EndorsementRewardEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _self: SharedType<Self>,
    len_baking_reward_per_endorsement: RefCell<i32>,
    baking_reward_per_endorsement: RefCell<Vec<OptRc<Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries>>>,
    _io: RefCell<BytesReader>,
    baking_reward_per_endorsement_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric;

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
                let t = Self::read_into::<BytesReader, Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries>(&io_baking_reward_per_endorsement_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.baking_reward_per_endorsement.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    pub fn len_baking_reward_per_endorsement(&self) -> Ref<i32> {
        self.len_baking_reward_per_endorsement.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement(&self) -> Ref<Vec<OptRc<Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries>>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.baking_reward_per_endorsement_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_NChunk {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_NChunk {
    type Root = Id007Psdelph1ConstantsParametric;
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
impl Id007Psdelph1ConstantsParametric_NChunk {
}
impl Id007Psdelph1ConstantsParametric_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_Z {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id007Psdelph1ConstantsParametric_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_Z {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric;

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
                    let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id007Psdelph1ConstantsParametric_Z {
}
impl Id007Psdelph1ConstantsParametric_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id007Psdelph1ConstantsParametric_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries {
    pub _root: SharedType<Id007Psdelph1ConstantsParametric>,
    pub _parent: SharedType<Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement>,
    pub _self: SharedType<Self>,
    id_007__psdelph1__mutez: RefCell<OptRc<Id007Psdelph1ConstantsParametric_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries {
    type Root = Id007Psdelph1ConstantsParametric;
    type Parent = Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsement;

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
        let t = Self::read_into::<_, Id007Psdelph1ConstantsParametric_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_007__psdelph1__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries {
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries {
    pub fn id_007__psdelph1__mutez(&self) -> Ref<OptRc<Id007Psdelph1ConstantsParametric_N>> {
        self.id_007__psdelph1__mutez.borrow()
    }
}
impl Id007Psdelph1ConstantsParametric_BakingRewardPerEndorsementEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
