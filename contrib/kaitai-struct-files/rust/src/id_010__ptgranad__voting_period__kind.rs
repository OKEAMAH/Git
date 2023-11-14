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
pub struct Id010PtgranadVotingPeriodKind {
    pub _root: SharedType<Id010PtgranadVotingPeriodKind>,
    pub _parent: SharedType<Id010PtgranadVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_010__ptgranad__voting_period__kind_tag: RefCell<Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id010PtgranadVotingPeriodKind {
    type Root = Id010PtgranadVotingPeriodKind;
    type Parent = Id010PtgranadVotingPeriodKind;

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
        *self_rc.id_010__ptgranad__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id010PtgranadVotingPeriodKind {
}
impl Id010PtgranadVotingPeriodKind {
    pub fn id_010__ptgranad__voting_period__kind_tag(&self) -> Ref<Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag> {
        self.id_010__ptgranad__voting_period__kind_tag.borrow()
    }
}
impl Id010PtgranadVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Proposal),
            1 => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Exploration),
            2 => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Cooldown),
            3 => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Promotion),
            4 => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Adoption),
            _ => Ok(Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag> for i64 {
    fn from(v: &Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag) -> Self {
        match *v {
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Proposal => 0,
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Exploration => 1,
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Cooldown => 2,
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Promotion => 3,
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Adoption => 4,
            Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag {
    fn default() -> Self { Id010PtgranadVotingPeriodKind_Id010PtgranadVotingPeriodKindTag::Unknown(0) }
}

