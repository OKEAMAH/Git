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
pub struct Id015PtlimaptVotingPeriodKind {
    pub _root: SharedType<Id015PtlimaptVotingPeriodKind>,
    pub _parent: SharedType<Id015PtlimaptVotingPeriodKind>,
    pub _self: SharedType<Self>,
    id_015__ptlimapt__voting_period__kind_tag: RefCell<Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptVotingPeriodKind {
    type Root = Id015PtlimaptVotingPeriodKind;
    type Parent = Id015PtlimaptVotingPeriodKind;

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
        *self_rc.id_015__ptlimapt__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id015PtlimaptVotingPeriodKind {
}
impl Id015PtlimaptVotingPeriodKind {
    pub fn id_015__ptlimapt__voting_period__kind_tag(&self) -> Ref<Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag> {
        self.id_015__ptlimapt__voting_period__kind_tag.borrow()
    }
}
impl Id015PtlimaptVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag> {
        match flag {
            0 => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Proposal),
            1 => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Exploration),
            2 => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Cooldown),
            3 => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Promotion),
            4 => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Adoption),
            _ => Ok(Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag> for i64 {
    fn from(v: &Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag) -> Self {
        match *v {
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Proposal => 0,
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Exploration => 1,
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Cooldown => 2,
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Promotion => 3,
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Adoption => 4,
            Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag {
    fn default() -> Self { Id015PtlimaptVotingPeriodKind_Id015PtlimaptVotingPeriodKindTag::Unknown(0) }
}

