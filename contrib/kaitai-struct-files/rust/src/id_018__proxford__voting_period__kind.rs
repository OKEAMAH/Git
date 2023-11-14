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
pub struct Id018ProxfordVotingPeriodKind {
    pub _root: SharedType<Id018ProxfordVotingPeriodKind>,
    pub _parent: SharedType<Id018ProxfordVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_018__proxford__voting_period__kind_tag: RefCell<Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id018ProxfordVotingPeriodKind {
    type Root = Id018ProxfordVotingPeriodKind;
    type Parent = Id018ProxfordVotingPeriodKind;

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
        *self_rc.id_018__proxford__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id018ProxfordVotingPeriodKind {
}
impl Id018ProxfordVotingPeriodKind {
    pub fn id_018__proxford__voting_period__kind_tag(&self) -> Ref<Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag> {
        self.id_018__proxford__voting_period__kind_tag.borrow()
    }
}
impl Id018ProxfordVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Proposal),
            1 => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Exploration),
            2 => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Cooldown),
            3 => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Promotion),
            4 => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Adoption),
            _ => Ok(Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag> for i64 {
    fn from(v: &Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag) -> Self {
        match *v {
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Proposal => 0,
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Exploration => 1,
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Cooldown => 2,
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Promotion => 3,
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Adoption => 4,
            Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag {
    fn default() -> Self { Id018ProxfordVotingPeriodKind_Id018ProxfordVotingPeriodKindTag::Unknown(0) }
}

