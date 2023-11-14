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
pub struct Id017PtnairobVotingPeriodKind {
    pub _root: SharedType<Id017PtnairobVotingPeriodKind>,
    pub _parent: SharedType<Id017PtnairobVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_017__ptnairob__voting_period__kind_tag: RefCell<Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobVotingPeriodKind {
    type Root = Id017PtnairobVotingPeriodKind;
    type Parent = Id017PtnairobVotingPeriodKind;

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
        *self_rc.id_017__ptnairob__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id017PtnairobVotingPeriodKind {
}
impl Id017PtnairobVotingPeriodKind {
    pub fn id_017__ptnairob__voting_period__kind_tag(&self) -> Ref<Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag> {
        self.id_017__ptnairob__voting_period__kind_tag.borrow()
    }
}
impl Id017PtnairobVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Proposal),
            1 => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Exploration),
            2 => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Cooldown),
            3 => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Promotion),
            4 => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Adoption),
            _ => Ok(Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag> for i64 {
    fn from(v: &Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag) -> Self {
        match *v {
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Proposal => 0,
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Exploration => 1,
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Cooldown => 2,
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Promotion => 3,
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Adoption => 4,
            Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag {
    fn default() -> Self { Id017PtnairobVotingPeriodKind_Id017PtnairobVotingPeriodKindTag::Unknown(0) }
}

