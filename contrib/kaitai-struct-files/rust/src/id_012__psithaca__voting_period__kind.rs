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
pub struct Id012PsithacaVotingPeriodKind {
    pub _root: SharedType<Id012PsithacaVotingPeriodKind>,
    pub _parent: SharedType<Id012PsithacaVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_012__psithaca__voting_period__kind_tag: RefCell<Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaVotingPeriodKind {
    type Root = Id012PsithacaVotingPeriodKind;
    type Parent = Id012PsithacaVotingPeriodKind;

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
        *self_rc.id_012__psithaca__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id012PsithacaVotingPeriodKind {
}
impl Id012PsithacaVotingPeriodKind {
    pub fn id_012__psithaca__voting_period__kind_tag(&self) -> Ref<Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag> {
        self.id_012__psithaca__voting_period__kind_tag.borrow()
    }
}
impl Id012PsithacaVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Proposal),
            1 => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Exploration),
            2 => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Cooldown),
            3 => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Promotion),
            4 => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Adoption),
            _ => Ok(Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag> for i64 {
    fn from(v: &Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag) -> Self {
        match *v {
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Proposal => 0,
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Exploration => 1,
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Cooldown => 2,
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Promotion => 3,
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Adoption => 4,
            Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag {
    fn default() -> Self { Id012PsithacaVotingPeriodKind_Id012PsithacaVotingPeriodKindTag::Unknown(0) }
}

