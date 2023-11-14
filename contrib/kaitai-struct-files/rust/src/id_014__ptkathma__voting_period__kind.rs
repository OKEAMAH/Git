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
pub struct Id014PtkathmaVotingPeriodKind {
    pub _root: SharedType<Id014PtkathmaVotingPeriodKind>,
    pub _parent: SharedType<Id014PtkathmaVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__voting_period__kind_tag: RefCell<Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaVotingPeriodKind {
    type Root = Id014PtkathmaVotingPeriodKind;
    type Parent = Id014PtkathmaVotingPeriodKind;

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
        *self_rc.id_014__ptkathma__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id014PtkathmaVotingPeriodKind {
}
impl Id014PtkathmaVotingPeriodKind {
    pub fn id_014__ptkathma__voting_period__kind_tag(&self) -> Ref<Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag> {
        self.id_014__ptkathma__voting_period__kind_tag.borrow()
    }
}
impl Id014PtkathmaVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Proposal),
            1 => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Exploration),
            2 => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Cooldown),
            3 => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Promotion),
            4 => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Adoption),
            _ => Ok(Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag> for i64 {
    fn from(v: &Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag) -> Self {
        match *v {
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Proposal => 0,
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Exploration => 1,
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Cooldown => 2,
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Promotion => 3,
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Adoption => 4,
            Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag {
    fn default() -> Self { Id014PtkathmaVotingPeriodKind_Id014PtkathmaVotingPeriodKindTag::Unknown(0) }
}

