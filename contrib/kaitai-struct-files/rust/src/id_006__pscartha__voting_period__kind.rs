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
pub struct Id006PscarthaVotingPeriodKind {
    pub _root: SharedType<Id006PscarthaVotingPeriodKind>,
    pub _parent: SharedType<Id006PscarthaVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_006__pscartha__voting_period__kind_tag: RefCell<Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaVotingPeriodKind {
    type Root = Id006PscarthaVotingPeriodKind;
    type Parent = Id006PscarthaVotingPeriodKind;

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
        *self_rc.id_006__pscartha__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id006PscarthaVotingPeriodKind {
}
impl Id006PscarthaVotingPeriodKind {
    pub fn id_006__pscartha__voting_period__kind_tag(&self) -> Ref<Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag> {
        self.id_006__pscartha__voting_period__kind_tag.borrow()
    }
}
impl Id006PscarthaVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag {
    Proposal,
    TestingVote,
    Testing,
    PromotionVote,
    Unknown(i64),
}

impl TryFrom<i64> for Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Proposal),
            1 => Ok(Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::TestingVote),
            2 => Ok(Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Testing),
            3 => Ok(Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::PromotionVote),
            _ => Ok(Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag> for i64 {
    fn from(v: &Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag) -> Self {
        match *v {
            Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Proposal => 0,
            Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::TestingVote => 1,
            Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Testing => 2,
            Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::PromotionVote => 3,
            Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag {
    fn default() -> Self { Id006PscarthaVotingPeriodKind_Id006PscarthaVotingPeriodKindTag::Unknown(0) }
}

