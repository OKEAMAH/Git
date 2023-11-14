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
pub struct Id013PtjakartLevel {
    pub _root: SharedType<Id013PtjakartLevel>,
    pub _parent: SharedType<Id013PtjakartLevel>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    level_position: RefCell<i32>,
    cycle: RefCell<i32>,
    cycle_position: RefCell<i32>,
    expected_commitment: RefCell<Id013PtjakartLevel_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartLevel {
    type Root = Id013PtjakartLevel;
    type Parent = Id013PtjakartLevel;

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
impl Id013PtjakartLevel {
}

/**
 * The level of the block relative to genesis. This is also the Shell's notion of level.
 */
impl Id013PtjakartLevel {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}

/**
 * The level of the block relative to the successor of the genesis block. More precisely, it is the position of the block relative to the block that starts the "Alpha family" of protocols, which includes all protocols except Genesis (that is, from 001 onwards).
 */
impl Id013PtjakartLevel {
    pub fn level_position(&self) -> Ref<i32> {
        self.level_position.borrow()
    }
}

/**
 * The current cycle's number. Note that cycles are a protocol-specific notion. As a result, the cycle number starts at 0 with the first block of the Alpha family of protocols.
 */
impl Id013PtjakartLevel {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}

/**
 * The current level of the block relative to the first block of the current cycle.
 */
impl Id013PtjakartLevel {
    pub fn cycle_position(&self) -> Ref<i32> {
        self.cycle_position.borrow()
    }
}

/**
 * Tells whether the baker of this block has to commit a seed nonce hash.
 */
impl Id013PtjakartLevel {
    pub fn expected_commitment(&self) -> Ref<Id013PtjakartLevel_Bool> {
        self.expected_commitment.borrow()
    }
}
impl Id013PtjakartLevel {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id013PtjakartLevel_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id013PtjakartLevel_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id013PtjakartLevel_Bool> {
        match flag {
            0 => Ok(Id013PtjakartLevel_Bool::False),
            255 => Ok(Id013PtjakartLevel_Bool::True),
            _ => Ok(Id013PtjakartLevel_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id013PtjakartLevel_Bool> for i64 {
    fn from(v: &Id013PtjakartLevel_Bool) -> Self {
        match *v {
            Id013PtjakartLevel_Bool::False => 0,
            Id013PtjakartLevel_Bool::True => 255,
            Id013PtjakartLevel_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id013PtjakartLevel_Bool {
    fn default() -> Self { Id013PtjakartLevel_Bool::Unknown(0) }
}

