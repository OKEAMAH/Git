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
pub struct Id011Pthangz2Constants {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    proof_of_work_nonce_size: RefCell<u8>,
    nonce_length: RefCell<u8>,
    max_anon_ops_per_block: RefCell<u8>,
    max_operation_data_length: RefCell<i32>,
    max_proposals_per_delegate: RefCell<u8>,
    max_micheline_node_count: RefCell<i32>,
    max_micheline_bytes_limit: RefCell<i32>,
    max_allowed_global_constants_depth: RefCell<i32>,
    cache_layout: RefCell<OptRc<Id011Pthangz2Constants_CacheLayout>>,
    michelson_maximum_type_size: RefCell<u16>,
    preserved_cycles: RefCell<u8>,
    blocks_per_cycle: RefCell<i32>,
    blocks_per_commitment: RefCell<i32>,
    blocks_per_roll_snapshot: RefCell<i32>,
    blocks_per_voting_period: RefCell<i32>,
    time_between_blocks: RefCell<OptRc<Id011Pthangz2Constants_TimeBetweenBlocks>>,
    endorsers_per_block: RefCell<u16>,
    hard_gas_limit_per_operation: RefCell<OptRc<Id011Pthangz2Constants_Z>>,
    hard_gas_limit_per_block: RefCell<OptRc<Id011Pthangz2Constants_Z>>,
    proof_of_work_threshold: RefCell<i64>,
    tokens_per_roll: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    seed_nonce_revelation_tip: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    origination_size: RefCell<i32>,
    block_security_deposit: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    endorsement_security_deposit: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    baking_reward_per_endorsement: RefCell<OptRc<Id011Pthangz2Constants_BakingRewardPerEndorsement>>,
    endorsement_reward: RefCell<OptRc<Id011Pthangz2Constants_EndorsementReward>>,
    cost_per_byte: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    hard_storage_limit_per_operation: RefCell<OptRc<Id011Pthangz2Constants_Z>>,
    quorum_min: RefCell<i32>,
    quorum_max: RefCell<i32>,
    min_proposal_quorum: RefCell<i32>,
    initial_endorsers: RefCell<u16>,
    delay_per_missing_endorsement: RefCell<i64>,
    minimal_block_delay: RefCell<i64>,
    liquidity_baking_subsidy: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    liquidity_baking_sunset_level: RefCell<i32>,
    liquidity_baking_escape_ema_threshold: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
        let t = Self::read_into::<_, Id011Pthangz2Constants_CacheLayout>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cache_layout.borrow_mut() = t;
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.preserved_cycles.borrow_mut() = _io.read_u1()?.into();
        *self_rc.blocks_per_cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_commitment.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_roll_snapshot.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.blocks_per_voting_period.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Constants_TimeBetweenBlocks>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.time_between_blocks.borrow_mut() = t;
        *self_rc.endorsers_per_block.borrow_mut() = _io.read_u2be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Constants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_operation.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_gas_limit_per_block.borrow_mut() = t;
        *self_rc.proof_of_work_threshold.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.tokens_per_roll.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.seed_nonce_revelation_tip.borrow_mut() = t;
        *self_rc.origination_size.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.block_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.endorsement_security_deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_BakingRewardPerEndorsement>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.baking_reward_per_endorsement.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_EndorsementReward>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.endorsement_reward.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.cost_per_byte.borrow_mut() = t;
        let t = Self::read_into::<_, Id011Pthangz2Constants_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.hard_storage_limit_per_operation.borrow_mut() = t;
        *self_rc.quorum_min.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.quorum_max.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.min_proposal_quorum.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.initial_endorsers.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.delay_per_missing_endorsement.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.minimal_block_delay.borrow_mut() = _io.read_s8be()?.into();
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.liquidity_baking_subsidy.borrow_mut() = t;
        *self_rc.liquidity_baking_sunset_level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.liquidity_baking_escape_ema_threshold.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id011Pthangz2Constants {
}
impl Id011Pthangz2Constants {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn cache_layout(&self) -> Ref<OptRc<Id011Pthangz2Constants_CacheLayout>> {
        self.cache_layout.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn preserved_cycles(&self) -> Ref<u8> {
        self.preserved_cycles.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn blocks_per_cycle(&self) -> Ref<i32> {
        self.blocks_per_cycle.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn blocks_per_commitment(&self) -> Ref<i32> {
        self.blocks_per_commitment.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn blocks_per_roll_snapshot(&self) -> Ref<i32> {
        self.blocks_per_roll_snapshot.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn blocks_per_voting_period(&self) -> Ref<i32> {
        self.blocks_per_voting_period.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn time_between_blocks(&self) -> Ref<OptRc<Id011Pthangz2Constants_TimeBetweenBlocks>> {
        self.time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn endorsers_per_block(&self) -> Ref<u16> {
        self.endorsers_per_block.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn hard_gas_limit_per_operation(&self) -> Ref<OptRc<Id011Pthangz2Constants_Z>> {
        self.hard_gas_limit_per_operation.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn hard_gas_limit_per_block(&self) -> Ref<OptRc<Id011Pthangz2Constants_Z>> {
        self.hard_gas_limit_per_block.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn proof_of_work_threshold(&self) -> Ref<i64> {
        self.proof_of_work_threshold.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn tokens_per_roll(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.tokens_per_roll.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn seed_nonce_revelation_tip(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.seed_nonce_revelation_tip.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn origination_size(&self) -> Ref<i32> {
        self.origination_size.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn block_security_deposit(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.block_security_deposit.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn endorsement_security_deposit(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.endorsement_security_deposit.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn baking_reward_per_endorsement(&self) -> Ref<OptRc<Id011Pthangz2Constants_BakingRewardPerEndorsement>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn endorsement_reward(&self) -> Ref<OptRc<Id011Pthangz2Constants_EndorsementReward>> {
        self.endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn cost_per_byte(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.cost_per_byte.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn hard_storage_limit_per_operation(&self) -> Ref<OptRc<Id011Pthangz2Constants_Z>> {
        self.hard_storage_limit_per_operation.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn quorum_min(&self) -> Ref<i32> {
        self.quorum_min.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn quorum_max(&self) -> Ref<i32> {
        self.quorum_max.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn min_proposal_quorum(&self) -> Ref<i32> {
        self.min_proposal_quorum.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn initial_endorsers(&self) -> Ref<u16> {
        self.initial_endorsers.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn delay_per_missing_endorsement(&self) -> Ref<i64> {
        self.delay_per_missing_endorsement.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn minimal_block_delay(&self) -> Ref<i64> {
        self.minimal_block_delay.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn liquidity_baking_subsidy(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.liquidity_baking_subsidy.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn liquidity_baking_sunset_level(&self) -> Ref<i32> {
        self.liquidity_baking_sunset_level.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn liquidity_baking_escape_ema_threshold(&self) -> Ref<i32> {
        self.liquidity_baking_escape_ema_threshold.borrow()
    }
}
impl Id011Pthangz2Constants {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_TimeBetweenBlocksEntries {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants_TimeBetweenBlocks>,
    pub _self: SharedType<Self>,
    time_between_blocks_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_TimeBetweenBlocksEntries {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants_TimeBetweenBlocks;

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
impl Id011Pthangz2Constants_TimeBetweenBlocksEntries {
}
impl Id011Pthangz2Constants_TimeBetweenBlocksEntries {
    pub fn time_between_blocks_elt(&self) -> Ref<i64> {
        self.time_between_blocks_elt.borrow()
    }
}
impl Id011Pthangz2Constants_TimeBetweenBlocksEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_N {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id011Pthangz2Constants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_N {
    type Root = Id011Pthangz2Constants;
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
                let t = Self::read_into::<_, Id011Pthangz2Constants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id011Pthangz2Constants_N {
}
impl Id011Pthangz2Constants_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_NChunk>>> {
        self.n.borrow()
    }
}
impl Id011Pthangz2Constants_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_TimeBetweenBlocks {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    len_time_between_blocks: RefCell<i32>,
    time_between_blocks: RefCell<Vec<OptRc<Id011Pthangz2Constants_TimeBetweenBlocksEntries>>>,
    _io: RefCell<BytesReader>,
    time_between_blocks_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Constants_TimeBetweenBlocks {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Constants_TimeBetweenBlocksEntries>(&io_time_between_blocks_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.time_between_blocks.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Constants_TimeBetweenBlocks {
}
impl Id011Pthangz2Constants_TimeBetweenBlocks {
    pub fn len_time_between_blocks(&self) -> Ref<i32> {
        self.len_time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Constants_TimeBetweenBlocks {
    pub fn time_between_blocks(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_TimeBetweenBlocksEntries>>> {
        self.time_between_blocks.borrow()
    }
}
impl Id011Pthangz2Constants_TimeBetweenBlocks {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Constants_TimeBetweenBlocks {
    pub fn time_between_blocks_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.time_between_blocks_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_EndorsementReward {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    len_endorsement_reward: RefCell<i32>,
    endorsement_reward: RefCell<Vec<OptRc<Id011Pthangz2Constants_EndorsementRewardEntries>>>,
    _io: RefCell<BytesReader>,
    endorsement_reward_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Constants_EndorsementReward {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Constants_EndorsementRewardEntries>(&io_endorsement_reward_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.endorsement_reward.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Constants_EndorsementReward {
}
impl Id011Pthangz2Constants_EndorsementReward {
    pub fn len_endorsement_reward(&self) -> Ref<i32> {
        self.len_endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Constants_EndorsementReward {
    pub fn endorsement_reward(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_EndorsementRewardEntries>>> {
        self.endorsement_reward.borrow()
    }
}
impl Id011Pthangz2Constants_EndorsementReward {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Constants_EndorsementReward {
    pub fn endorsement_reward_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.endorsement_reward_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_CacheLayoutEntries {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants_CacheLayout>,
    pub _self: SharedType<Self>,
    cache_layout_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_CacheLayoutEntries {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants_CacheLayout;

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
impl Id011Pthangz2Constants_CacheLayoutEntries {
}
impl Id011Pthangz2Constants_CacheLayoutEntries {
    pub fn cache_layout_elt(&self) -> Ref<i64> {
        self.cache_layout_elt.borrow()
    }
}
impl Id011Pthangz2Constants_CacheLayoutEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_CacheLayout {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    len_cache_layout: RefCell<i32>,
    cache_layout: RefCell<Vec<OptRc<Id011Pthangz2Constants_CacheLayoutEntries>>>,
    _io: RefCell<BytesReader>,
    cache_layout_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Constants_CacheLayout {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Constants_CacheLayoutEntries>(&io_cache_layout_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.cache_layout.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Constants_CacheLayout {
}
impl Id011Pthangz2Constants_CacheLayout {
    pub fn len_cache_layout(&self) -> Ref<i32> {
        self.len_cache_layout.borrow()
    }
}
impl Id011Pthangz2Constants_CacheLayout {
    pub fn cache_layout(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_CacheLayoutEntries>>> {
        self.cache_layout.borrow()
    }
}
impl Id011Pthangz2Constants_CacheLayout {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Constants_CacheLayout {
    pub fn cache_layout_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.cache_layout_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_EndorsementRewardEntries {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants_EndorsementReward>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__mutez: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_EndorsementRewardEntries {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants_EndorsementReward;

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
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_011__pthangz2__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Constants_EndorsementRewardEntries {
}
impl Id011Pthangz2Constants_EndorsementRewardEntries {
    pub fn id_011__pthangz2__mutez(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.id_011__pthangz2__mutez.borrow()
    }
}
impl Id011Pthangz2Constants_EndorsementRewardEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_BakingRewardPerEndorsement {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    len_baking_reward_per_endorsement: RefCell<i32>,
    baking_reward_per_endorsement: RefCell<Vec<OptRc<Id011Pthangz2Constants_BakingRewardPerEndorsementEntries>>>,
    _io: RefCell<BytesReader>,
    baking_reward_per_endorsement_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id011Pthangz2Constants_BakingRewardPerEndorsement {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
                let t = Self::read_into::<BytesReader, Id011Pthangz2Constants_BakingRewardPerEndorsementEntries>(&io_baking_reward_per_endorsement_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.baking_reward_per_endorsement.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsement {
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsement {
    pub fn len_baking_reward_per_endorsement(&self) -> Ref<i32> {
        self.len_baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_BakingRewardPerEndorsementEntries>>> {
        self.baking_reward_per_endorsement.borrow()
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsement {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsement {
    pub fn baking_reward_per_endorsement_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.baking_reward_per_endorsement_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_NChunk {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_NChunk {
    type Root = Id011Pthangz2Constants;
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
impl Id011Pthangz2Constants_NChunk {
}
impl Id011Pthangz2Constants_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id011Pthangz2Constants_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id011Pthangz2Constants_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_Z {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id011Pthangz2Constants_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_Z {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants;

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
                    let t = Self::read_into::<_, Id011Pthangz2Constants_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id011Pthangz2Constants_Z {
}
impl Id011Pthangz2Constants_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id011Pthangz2Constants_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id011Pthangz2Constants_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id011Pthangz2Constants_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id011Pthangz2Constants_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id011Pthangz2Constants_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2Constants_BakingRewardPerEndorsementEntries {
    pub _root: SharedType<Id011Pthangz2Constants>,
    pub _parent: SharedType<Id011Pthangz2Constants_BakingRewardPerEndorsement>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__mutez: RefCell<OptRc<Id011Pthangz2Constants_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Constants_BakingRewardPerEndorsementEntries {
    type Root = Id011Pthangz2Constants;
    type Parent = Id011Pthangz2Constants_BakingRewardPerEndorsement;

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
        let t = Self::read_into::<_, Id011Pthangz2Constants_N>(&*_io, Some(self_rc._root.clone()), None)?.into();
        *self_rc.id_011__pthangz2__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsementEntries {
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsementEntries {
    pub fn id_011__pthangz2__mutez(&self) -> Ref<OptRc<Id011Pthangz2Constants_N>> {
        self.id_011__pthangz2__mutez.borrow()
    }
}
impl Id011Pthangz2Constants_BakingRewardPerEndorsementEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
