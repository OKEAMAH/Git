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

/**
 * Boolean values
 */

#[derive(Default, Debug, Clone)]
pub struct GroundBool {
    pub _root: SharedType<GroundBool>,
    pub _parent: SharedType<GroundBool>,
    pub _self: SharedType<Self>,
    ground__bool: RefCell<GroundBool_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for GroundBool {
    type Root = GroundBool;
    type Parent = GroundBool;

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
        *self_rc.ground__bool.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl GroundBool {
}
impl GroundBool {
    pub fn ground__bool(&self) -> Ref<GroundBool_Bool> {
        self.ground__bool.borrow()
    }
}
impl GroundBool {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum GroundBool_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for GroundBool_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<GroundBool_Bool> {
        match flag {
            0 => Ok(GroundBool_Bool::False),
            255 => Ok(GroundBool_Bool::True),
            _ => Ok(GroundBool_Bool::Unknown(flag)),
        }
    }
}

impl From<&GroundBool_Bool> for i64 {
    fn from(v: &GroundBool_Bool) -> Self {
        match *v {
            GroundBool_Bool::False => 0,
            GroundBool_Bool::True => 255,
            GroundBool_Bool::Unknown(v) => v
        }
    }
}

impl Default for GroundBool_Bool {
    fn default() -> Self { GroundBool_Bool::Unknown(0) }
}

