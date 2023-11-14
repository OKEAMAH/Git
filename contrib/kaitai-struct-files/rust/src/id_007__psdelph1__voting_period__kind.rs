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
pub struct Id007Psdelph1VotingPeriodKind {
    pub _root: SharedType<Id007Psdelph1VotingPeriodKind>,
    pub _parent: SharedType<Id007Psdelph1VotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_007__psdelph1__voting_period__kind_tag: RefCell<Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1VotingPeriodKind {
    type Root = Id007Psdelph1VotingPeriodKind;
    type Parent = Id007Psdelph1VotingPeriodKind;

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
        *self_rc.id_007__psdelph1__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id007Psdelph1VotingPeriodKind {
}
impl Id007Psdelph1VotingPeriodKind {
    pub fn id_007__psdelph1__voting_period__kind_tag(&self) -> Ref<Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag> {
        self.id_007__psdelph1__voting_period__kind_tag.borrow()
    }
}
impl Id007Psdelph1VotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag {
    Proposal,
    TestingVote,
    Testing,
    PromotionVote,
    Unknown(i64),
}

impl TryFrom<i64> for Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag> {
        match flag {
            0 => Ok(Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Proposal),
            1 => Ok(Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::TestingVote),
            2 => Ok(Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Testing),
            3 => Ok(Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::PromotionVote),
            _ => Ok(Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag> for i64 {
    fn from(v: &Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag) -> Self {
        match *v {
            Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Proposal => 0,
            Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::TestingVote => 1,
            Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Testing => 2,
            Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::PromotionVote => 3,
            Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag {
    fn default() -> Self { Id007Psdelph1VotingPeriodKind_Id007Psdelph1VotingPeriodKindTag::Unknown(0) }
}

