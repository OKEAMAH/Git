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
pub struct Id010PtgranadVotingPeriod {
    pub _root: SharedType<Id010PtgranadVotingPeriod>,
    pub _parent: SharedType<Id010PtgranadVotingPeriod>,
    pub _self: SharedType<Self>,
    index: RefCell<i32>,
    kind: RefCell<Id010PtgranadVotingPeriod_KindTag>,
    start_position: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id010PtgranadVotingPeriod {
    type Root = Id010PtgranadVotingPeriod;
    type Parent = Id010PtgranadVotingPeriod;

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
        *self_rc.index.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.kind.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        *self_rc.start_position.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id010PtgranadVotingPeriod {
}

/**
 * The voting period's index. Starts at 0 with the first block of the Alpha family of protocols.
 */
impl Id010PtgranadVotingPeriod {
    pub fn index(&self) -> Ref<i32> {
        self.index.borrow()
    }
}

/**
 * One of the several kinds of periods in the voting procedure.
 */
impl Id010PtgranadVotingPeriod {
    pub fn kind(&self) -> Ref<Id010PtgranadVotingPeriod_KindTag> {
        self.kind.borrow()
    }
}

/**
 * The relative position of the first level of the period with respect to the first level of the Alpha family of protocols.
 */
impl Id010PtgranadVotingPeriod {
    pub fn start_position(&self) -> Ref<i32> {
        self.start_position.borrow()
    }
}
impl Id010PtgranadVotingPeriod {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id010PtgranadVotingPeriod_KindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for Id010PtgranadVotingPeriod_KindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id010PtgranadVotingPeriod_KindTag> {
        match flag {
            0 => Ok(Id010PtgranadVotingPeriod_KindTag::Proposal),
            1 => Ok(Id010PtgranadVotingPeriod_KindTag::Exploration),
            2 => Ok(Id010PtgranadVotingPeriod_KindTag::Cooldown),
            3 => Ok(Id010PtgranadVotingPeriod_KindTag::Promotion),
            4 => Ok(Id010PtgranadVotingPeriod_KindTag::Adoption),
            _ => Ok(Id010PtgranadVotingPeriod_KindTag::Unknown(flag)),
        }
    }
}

impl From<&Id010PtgranadVotingPeriod_KindTag> for i64 {
    fn from(v: &Id010PtgranadVotingPeriod_KindTag) -> Self {
        match *v {
            Id010PtgranadVotingPeriod_KindTag::Proposal => 0,
            Id010PtgranadVotingPeriod_KindTag::Exploration => 1,
            Id010PtgranadVotingPeriod_KindTag::Cooldown => 2,
            Id010PtgranadVotingPeriod_KindTag::Promotion => 3,
            Id010PtgranadVotingPeriod_KindTag::Adoption => 4,
            Id010PtgranadVotingPeriod_KindTag::Unknown(v) => v
        }
    }
}

impl Default for Id010PtgranadVotingPeriod_KindTag {
    fn default() -> Self { Id010PtgranadVotingPeriod_KindTag::Unknown(0) }
}

