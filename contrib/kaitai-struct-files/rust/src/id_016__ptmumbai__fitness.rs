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
pub struct Id016PtmumbaiFitness {
    pub _root: SharedType<Id016PtmumbaiFitness>,
    pub _parent: SharedType<Id016PtmumbaiFitness>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    locked_round: RefCell<OptRc<Id016PtmumbaiFitness_LockedRound>>,
    predecessor_round: RefCell<i32>,
    round: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFitness {
    type Root = Id016PtmumbaiFitness;
    type Parent = Id016PtmumbaiFitness;

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
        *self_rc.level.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id016PtmumbaiFitness_LockedRound>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.locked_round.borrow_mut() = t;
        *self_rc.predecessor_round.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.round.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id016PtmumbaiFitness {
}
impl Id016PtmumbaiFitness {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}
impl Id016PtmumbaiFitness {
    pub fn locked_round(&self) -> Ref<OptRc<Id016PtmumbaiFitness_LockedRound>> {
        self.locked_round.borrow()
    }
}
impl Id016PtmumbaiFitness {
    pub fn predecessor_round(&self) -> Ref<i32> {
        self.predecessor_round.borrow()
    }
}
impl Id016PtmumbaiFitness {
    pub fn round(&self) -> Ref<i32> {
        self.round.borrow()
    }
}
impl Id016PtmumbaiFitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id016PtmumbaiFitness_LockedRoundTag {
    None,
    Some,
    Unknown(i64),
}

impl TryFrom<i64> for Id016PtmumbaiFitness_LockedRoundTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id016PtmumbaiFitness_LockedRoundTag> {
        match flag {
            0 => Ok(Id016PtmumbaiFitness_LockedRoundTag::None),
            1 => Ok(Id016PtmumbaiFitness_LockedRoundTag::Some),
            _ => Ok(Id016PtmumbaiFitness_LockedRoundTag::Unknown(flag)),
        }
    }
}

impl From<&Id016PtmumbaiFitness_LockedRoundTag> for i64 {
    fn from(v: &Id016PtmumbaiFitness_LockedRoundTag) -> Self {
        match *v {
            Id016PtmumbaiFitness_LockedRoundTag::None => 0,
            Id016PtmumbaiFitness_LockedRoundTag::Some => 1,
            Id016PtmumbaiFitness_LockedRoundTag::Unknown(v) => v
        }
    }
}

impl Default for Id016PtmumbaiFitness_LockedRoundTag {
    fn default() -> Self { Id016PtmumbaiFitness_LockedRoundTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFitness_LockedRound {
    pub _root: SharedType<Id016PtmumbaiFitness>,
    pub _parent: SharedType<Id016PtmumbaiFitness>,
    pub _self: SharedType<Self>,
    locked_round_tag: RefCell<Id016PtmumbaiFitness_LockedRoundTag>,
    locked_round_some: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFitness_LockedRound {
    type Root = Id016PtmumbaiFitness;
    type Parent = Id016PtmumbaiFitness;

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
        *self_rc.locked_round_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.locked_round_tag() == Id016PtmumbaiFitness_LockedRoundTag::Some {
            *self_rc.locked_round_some.borrow_mut() = _io.read_s4be()?.into();
        }
        Ok(())
    }
}
impl Id016PtmumbaiFitness_LockedRound {
}
impl Id016PtmumbaiFitness_LockedRound {
    pub fn locked_round_tag(&self) -> Ref<Id016PtmumbaiFitness_LockedRoundTag> {
        self.locked_round_tag.borrow()
    }
}
impl Id016PtmumbaiFitness_LockedRound {
    pub fn locked_round_some(&self) -> Ref<i32> {
        self.locked_round_some.borrow()
    }
}
impl Id016PtmumbaiFitness_LockedRound {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
