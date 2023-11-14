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
pub struct Id011Pthangz2Level {
    pub _root: SharedType<Id011Pthangz2Level>,
    pub _parent: SharedType<Id011Pthangz2Level>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    level_position: RefCell<i32>,
    cycle: RefCell<i32>,
    cycle_position: RefCell<i32>,
    expected_commitment: RefCell<Id011Pthangz2Level_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Level {
    type Root = Id011Pthangz2Level;
    type Parent = Id011Pthangz2Level;

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
        *self_rc.level_position.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycle.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cycle_position.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.expected_commitment.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id011Pthangz2Level {
}

/**
 * The level of the block relative to genesis. This is also the Shell's notion of level
 */
impl Id011Pthangz2Level {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}

/**
 * The level of the block relative to the block that starts protocol alpha. This is specific to the protocol alpha. Other protocols might or might not include a similar notion.
 */
impl Id011Pthangz2Level {
    pub fn level_position(&self) -> Ref<i32> {
        self.level_position.borrow()
    }
}

/**
 * The current cycle's number. Note that cycles are a protocol-specific notion. As a result, the cycle number starts at 0 with the first block of protocol alpha.
 */
impl Id011Pthangz2Level {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}

/**
 * The current level of the block relative to the first block of the current cycle.
 */
impl Id011Pthangz2Level {
    pub fn cycle_position(&self) -> Ref<i32> {
        self.cycle_position.borrow()
    }
}

/**
 * Tells whether the baker of this block has to commit a seed nonce hash.
 */
impl Id011Pthangz2Level {
    pub fn expected_commitment(&self) -> Ref<Id011Pthangz2Level_Bool> {
        self.expected_commitment.borrow()
    }
}
impl Id011Pthangz2Level {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2Level_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2Level_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2Level_Bool> {
        match flag {
            0 => Ok(Id011Pthangz2Level_Bool::False),
            255 => Ok(Id011Pthangz2Level_Bool::True),
            _ => Ok(Id011Pthangz2Level_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2Level_Bool> for i64 {
    fn from(v: &Id011Pthangz2Level_Bool) -> Self {
        match *v {
            Id011Pthangz2Level_Bool::False => 0,
            Id011Pthangz2Level_Bool::True => 255,
            Id011Pthangz2Level_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2Level_Bool {
    fn default() -> Self { Id011Pthangz2Level_Bool::Unknown(0) }
}

