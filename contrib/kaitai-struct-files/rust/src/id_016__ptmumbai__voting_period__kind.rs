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
pub struct Id016PtmumbaiVotingPeriodKind {
    pub _root: SharedType<Id016PtmumbaiVotingPeriodKind>,
    pub _parent: SharedType<Id016PtmumbaiVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_016__ptmumbai__voting_period__kind_tag: RefCell<Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiVotingPeriodKind {
    type Root = Id016PtmumbaiVotingPeriodKind;
    type Parent = Id016PtmumbaiVotingPeriodKind;

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
        *self_rc.id_016__ptmumbai__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id016PtmumbaiVotingPeriodKind {
}
impl Id016PtmumbaiVotingPeriodKind {
    pub fn id_016__ptmumbai__voting_period__kind_tag(&self) -> Ref<Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag> {
        self.id_016__ptmumbai__voting_period__kind_tag.borrow()
    }
}
impl Id016PtmumbaiVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Proposal),
            1 => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Exploration),
            2 => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Cooldown),
            3 => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Promotion),
            4 => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Adoption),
            _ => Ok(Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag> for i64 {
    fn from(v: &Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag) -> Self {
        match *v {
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Proposal => 0,
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Exploration => 1,
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Cooldown => 2,
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Promotion => 3,
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Adoption => 4,
            Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag {
    fn default() -> Self { Id016PtmumbaiVotingPeriodKind_Id016PtmumbaiVotingPeriodKindTag::Unknown(0) }
}

