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
pub struct Id007Psdelph1Level {
    pub _root: SharedType<Id007Psdelph1Level>,
    pub _parent: SharedType<Id007Psdelph1Level>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    level_position: RefCell<i32>,
    cycle: RefCell<i32>,
    cycle_position: RefCell<i32>,
    voting_period: RefCell<i32>,
    voting_period_position: RefCell<i32>,
    expected_commitment: RefCell<Id007Psdelph1Level_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Level {
    type Root = Id007Psdelph1Level;
    type Parent = Id007Psdelph1Level;

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
        *self_rc.voting_period.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.voting_period_position.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.expected_commitment.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id007Psdelph1Level {
}

/**
 * The level of the block relative to genesis. This is also the Shell's notion of level
 */
impl Id007Psdelph1Level {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}

/**
 * The level of the block relative to the block that starts protocol alpha. This is specific to the protocol alpha. Other protocols might or might not include a similar notion.
 */
impl Id007Psdelph1Level {
    pub fn level_position(&self) -> Ref<i32> {
        self.level_position.borrow()
    }
}

/**
 * The current cycle's number. Note that cycles are a protocol-specific notion. As a result, the cycle number starts at 0 with the first block of protocol alpha.
 */
impl Id007Psdelph1Level {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}

/**
 * The current level of the block relative to the first block of the current cycle.
 */
impl Id007Psdelph1Level {
    pub fn cycle_position(&self) -> Ref<i32> {
        self.cycle_position.borrow()
    }
}

/**
 * The current voting period's index. Note that cycles are a protocol-specific notion. As a result, the voting period index starts at 0 with the first block of protocol alpha.
 */
impl Id007Psdelph1Level {
    pub fn voting_period(&self) -> Ref<i32> {
        self.voting_period.borrow()
    }
}

/**
 * The current level of the block relative to the first block of the current voting period.
 */
impl Id007Psdelph1Level {
    pub fn voting_period_position(&self) -> Ref<i32> {
        self.voting_period_position.borrow()
    }
}

/**
 * Tells wether the baker of this block has to commit a seed nonce hash.
 */
impl Id007Psdelph1Level {
    pub fn expected_commitment(&self) -> Ref<Id007Psdelph1Level_Bool> {
        self.expected_commitment.borrow()
    }
}
impl Id007Psdelph1Level {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id007Psdelph1Level_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id007Psdelph1Level_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id007Psdelph1Level_Bool> {
        match flag {
            0 => Ok(Id007Psdelph1Level_Bool::False),
            255 => Ok(Id007Psdelph1Level_Bool::True),
            _ => Ok(Id007Psdelph1Level_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id007Psdelph1Level_Bool> for i64 {
    fn from(v: &Id007Psdelph1Level_Bool) -> Self {
        match *v {
            Id007Psdelph1Level_Bool::False => 0,
            Id007Psdelph1Level_Bool::True => 255,
            Id007Psdelph1Level_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id007Psdelph1Level_Bool {
    fn default() -> Self { Id007Psdelph1Level_Bool::Unknown(0) }
}

