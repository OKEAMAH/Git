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
pub struct Id018ProxfordLevel {
    pub _root: SharedType<Id018ProxfordLevel>,
    pub _parent: SharedType<Id018ProxfordLevel>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    level_position: RefCell<i32>,
    cycle: RefCell<i32>,
    cycle_position: RefCell<i32>,
    expected_commitment: RefCell<Id018ProxfordLevel_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id018ProxfordLevel {
    type Root = Id018ProxfordLevel;
    type Parent = Id018ProxfordLevel;

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
impl Id018ProxfordLevel {
}

/**
 * The level of the block relative to genesis. This is also the Shell's notion of level.
 */
impl Id018ProxfordLevel {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}

/**
 * The level of the block relative to the successor of the genesis block. More precisely, it is the position of the block relative to the block that starts the "Alpha family" of protocols, which includes all protocols except Genesis (that is, from 001 onwards).
 */
impl Id018ProxfordLevel {
    pub fn level_position(&self) -> Ref<i32> {
        self.level_position.borrow()
    }
}

/**
 * The current cycle's number. Note that cycles are a protocol-specific notion. As a result, the cycle number starts at 0 with the first block of the Alpha family of protocols.
 */
impl Id018ProxfordLevel {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}

/**
 * The current level of the block relative to the first block of the current cycle.
 */
impl Id018ProxfordLevel {
    pub fn cycle_position(&self) -> Ref<i32> {
        self.cycle_position.borrow()
    }
}

/**
 * Tells whether the baker of this block has to commit a seed nonce hash.
 */
impl Id018ProxfordLevel {
    pub fn expected_commitment(&self) -> Ref<Id018ProxfordLevel_Bool> {
        self.expected_commitment.borrow()
    }
}
impl Id018ProxfordLevel {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id018ProxfordLevel_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id018ProxfordLevel_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id018ProxfordLevel_Bool> {
        match flag {
            0 => Ok(Id018ProxfordLevel_Bool::False),
            255 => Ok(Id018ProxfordLevel_Bool::True),
            _ => Ok(Id018ProxfordLevel_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id018ProxfordLevel_Bool> for i64 {
    fn from(v: &Id018ProxfordLevel_Bool) -> Self {
        match *v {
            Id018ProxfordLevel_Bool::False => 0,
            Id018ProxfordLevel_Bool::True => 255,
            Id018ProxfordLevel_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id018ProxfordLevel_Bool {
    fn default() -> Self { Id018ProxfordLevel_Bool::Unknown(0) }
}

