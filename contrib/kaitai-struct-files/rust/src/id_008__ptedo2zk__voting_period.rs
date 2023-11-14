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
pub struct Id008Ptedo2zkVotingPeriod {
    pub _root: SharedType<Id008Ptedo2zkVotingPeriod>,
    pub _parent: SharedType<Id008Ptedo2zkVotingPeriod>,
    pub _self: SharedType<Self>,
    index: RefCell<i32>,
    kind: RefCell<Id008Ptedo2zkVotingPeriod_KindTag>,
    start_position: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkVotingPeriod {
    type Root = Id008Ptedo2zkVotingPeriod;
    type Parent = Id008Ptedo2zkVotingPeriod;

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
        *self_rc.index.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.kind.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.start_position.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id008Ptedo2zkVotingPeriod {
}

/**
 * The voting period's index. Starts at 0 with the first block of protocol alpha.
 */
impl Id008Ptedo2zkVotingPeriod {
    pub fn index(&self) -> Ref<i32> {
        self.index.borrow()
    }
}
impl Id008Ptedo2zkVotingPeriod {
    pub fn kind(&self) -> Ref<Id008Ptedo2zkVotingPeriod_KindTag> {
        self.kind.borrow()
    }
}
impl Id008Ptedo2zkVotingPeriod {
    pub fn start_position(&self) -> Ref<i32> {
        self.start_position.borrow()
    }
}
impl Id008Ptedo2zkVotingPeriod {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id008Ptedo2zkVotingPeriod_KindTag {
    Proposal,
    TestingVote,
    Testing,
    PromotionVote,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id008Ptedo2zkVotingPeriod_KindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id008Ptedo2zkVotingPeriod_KindTag> {
        match flag {
            0 => Ok(Id008Ptedo2zkVotingPeriod_KindTag::Proposal),
            1 => Ok(Id008Ptedo2zkVotingPeriod_KindTag::TestingVote),
            2 => Ok(Id008Ptedo2zkVotingPeriod_KindTag::Testing),
            3 => Ok(Id008Ptedo2zkVotingPeriod_KindTag::PromotionVote),
            4 => Ok(Id008Ptedo2zkVotingPeriod_KindTag::Adoption),
            _ => Ok(Id008Ptedo2zkVotingPeriod_KindTag::Unknown(flag)),
        }
    }
}

impl From<&Id008Ptedo2zkVotingPeriod_KindTag> for i64 {
    fn from(v: &Id008Ptedo2zkVotingPeriod_KindTag) -> Self {
        match *v {
            Id008Ptedo2zkVotingPeriod_KindTag::Proposal => 0,
            Id008Ptedo2zkVotingPeriod_KindTag::TestingVote => 1,
            Id008Ptedo2zkVotingPeriod_KindTag::Testing => 2,
            Id008Ptedo2zkVotingPeriod_KindTag::PromotionVote => 3,
            Id008Ptedo2zkVotingPeriod_KindTag::Adoption => 4,
            Id008Ptedo2zkVotingPeriod_KindTag::Unknown(v) => v
        }
    }
}

impl Default for Id008Ptedo2zkVotingPeriod_KindTag {
    fn default() -> Self { Id008Ptedo2zkVotingPeriod_KindTag::Unknown(0) }
}

