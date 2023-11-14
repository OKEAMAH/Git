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
pub struct Id009PsflorenVotingPeriodKind {
    pub _root: SharedType<Id009PsflorenVotingPeriodKind>,
    pub _parent: SharedType<Id009PsflorenVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_009__psfloren__voting_period__kind_tag: RefCell<Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id009PsflorenVotingPeriodKind {
    type Root = Id009PsflorenVotingPeriodKind;
    type Parent = Id009PsflorenVotingPeriodKind;

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
        *self_rc.id_009__psfloren__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id009PsflorenVotingPeriodKind {
}
impl Id009PsflorenVotingPeriodKind {
    pub fn id_009__psfloren__voting_period__kind_tag(&self) -> Ref<Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag> {
        self.id_009__psfloren__voting_period__kind_tag.borrow()
    }
}
impl Id009PsflorenVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Proposal),
            1 => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Exploration),
            2 => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Cooldown),
            3 => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Promotion),
            4 => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Adoption),
            _ => Ok(Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag> for i64 {
    fn from(v: &Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag) -> Self {
        match *v {
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Proposal => 0,
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Exploration => 1,
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Cooldown => 2,
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Promotion => 3,
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Adoption => 4,
            Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag {
    fn default() -> Self { Id009PsflorenVotingPeriodKind_Id009PsflorenVotingPeriodKindTag::Unknown(0) }
}

