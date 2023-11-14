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
pub struct Id011Pthangz2VotingPeriodKind {
    pub _root: SharedType<Id011Pthangz2VotingPeriodKind>,
    pub _parent: SharedType<Id011Pthangz2VotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__voting_period__kind_tag: RefCell<Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2VotingPeriodKind {
    type Root = Id011Pthangz2VotingPeriodKind;
    type Parent = Id011Pthangz2VotingPeriodKind;

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
        *self_rc.id_011__pthangz2__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id011Pthangz2VotingPeriodKind {
}
impl Id011Pthangz2VotingPeriodKind {
    pub fn id_011__pthangz2__voting_period__kind_tag(&self) -> Ref<Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag> {
        self.id_011__pthangz2__voting_period__kind_tag.borrow()
    }
}
impl Id011Pthangz2VotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag> {
        match flag {
            0 => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Proposal),
            1 => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Exploration),
            2 => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Cooldown),
            3 => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Promotion),
            4 => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Adoption),
            _ => Ok(Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag> for i64 {
    fn from(v: &Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag) -> Self {
        match *v {
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Proposal => 0,
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Exploration => 1,
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Cooldown => 2,
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Promotion => 3,
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Adoption => 4,
            Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag {
    fn default() -> Self { Id011Pthangz2VotingPeriodKind_Id011Pthangz2VotingPeriodKindTag::Unknown(0) }
}

