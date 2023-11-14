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
pub struct AlphaVotingPeriodKind {
    pub _root: SharedType<AlphaVotingPeriodKind>,
    pub _parent: SharedType<AlphaVotingPeriodKind>,
    pub _self: SharedType<Self>,
    alpha__voting_period__kind_tag: RefCell<AlphaVotingPeriodKind_AlphaVotingPeriodKindTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaVotingPeriodKind {
    type Root = AlphaVotingPeriodKind;
    type Parent = AlphaVotingPeriodKind;

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
        *self_rc.alpha__voting_period__kind_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaVotingPeriodKind {
}
impl AlphaVotingPeriodKind {
    pub fn alpha__voting_period__kind_tag(&self) -> Ref<AlphaVotingPeriodKind_AlphaVotingPeriodKindTag> {
        self.alpha__voting_period__kind_tag.borrow()
    }
}
impl AlphaVotingPeriodKind {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaVotingPeriodKind_AlphaVotingPeriodKindTag {
    Proposal,
    Exploration,
    Cooldown,
    Promotion,
    Adoption,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaVotingPeriodKind_AlphaVotingPeriodKindTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaVotingPeriodKind_AlphaVotingPeriodKindTag> {
        match flag {
            0 => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Proposal),
            1 => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Exploration),
            2 => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Cooldown),
            3 => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Promotion),
            4 => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Adoption),
            _ => Ok(AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaVotingPeriodKind_AlphaVotingPeriodKindTag> for i64 {
    fn from(v: &AlphaVotingPeriodKind_AlphaVotingPeriodKindTag) -> Self {
        match *v {
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Proposal => 0,
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Exploration => 1,
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Cooldown => 2,
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Promotion => 3,
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Adoption => 4,
            AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaVotingPeriodKind_AlphaVotingPeriodKindTag {
    fn default() -> Self { AlphaVotingPeriodKind_AlphaVotingPeriodKindTag::Unknown(0) }
}

