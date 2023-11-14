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
pub struct Id008Ptedo2zkVotingPeriodKind {
    pub _root: SharedType<Id008Ptedo2zkVotingPeriodKind>,
    pub _parent: SharedType<Id008Ptedo2zkVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_008__ptedo2zk__voting_period__kind_tag: RefCell<Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkVotingPeriodKind {
    type Root = Id008Ptedo2zkVotingPeriodKind;
    type Parent = Id008Ptedo2zkVotingPeriodKind;

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
        *self_rc.id_008__ptedo2zk__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id008Ptedo2zkVotingPeriodKind {
}
impl Id008Ptedo2zkVotingPeriodKind {
    pub fn id_008__ptedo2zk__voting_period__kind_tag(&self) -> Ref<Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag> {
        self.id_008__ptedo2zk__voting_period__kind_tag.borrow()
    }
}
impl Id008Ptedo2zkVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag {
    Proposal,
    TestingVote,
    Testing,
    PromotionVote,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Proposal),
            1 => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::TestingVote),
            2 => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Testing),
            3 => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::PromotionVote),
            4 => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Adoption),
            _ => Ok(Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag> for i64 {
    fn from(v: &Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag) -> Self {
        match *v {
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Proposal => 0,
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::TestingVote => 1,
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Testing => 2,
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::PromotionVote => 3,
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Adoption => 4,
            Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag {
    fn default() -> Self { Id008Ptedo2zkVotingPeriodKind_Id008Ptedo2zkVotingPeriodKindTag::Unknown(0) }
}

