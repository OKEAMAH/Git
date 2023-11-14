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
pub struct Id013PtjakartVotingPeriodKind {
    pub _root: SharedType<Id013PtjakartVotingPeriodKind>,
    pub _parent: SharedType<Id013PtjakartVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_013__ptjakart__voting_period__kind_tag: RefCell<Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartVotingPeriodKind {
    type Root = Id013PtjakartVotingPeriodKind;
    type Parent = Id013PtjakartVotingPeriodKind;

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
        *self_rc.id_013__ptjakart__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id013PtjakartVotingPeriodKind {
}
impl Id013PtjakartVotingPeriodKind {
    pub fn id_013__ptjakart__voting_period__kind_tag(&self) -> Ref<Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag> {
        self.id_013__ptjakart__voting_period__kind_tag.borrow()
    }
}
impl Id013PtjakartVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Proposal),
            1 => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Exploration),
            2 => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Cooldown),
            3 => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Promotion),
            4 => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Adoption),
            _ => Ok(Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag> for i64 {
    fn from(v: &Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag) -> Self {
        match *v {
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Proposal => 0,
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Exploration => 1,
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Cooldown => 2,
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Promotion => 3,
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Adoption => 4,
            Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag {
    fn default() -> Self { Id013PtjakartVotingPeriodKind_Id013PtjakartVotingPeriodKindTag::Unknown(0) }
}

