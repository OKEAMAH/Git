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
 * Signed 16 bit integers
 */

#[derive(Default, Debug, Clone)]
pub struct GroundInt16 {
    pub _root: SharedType<GroundInt16>,
    pub _parent: SharedType<GroundInt16>,
    pub _self: SharedType<Self>,
    ground__int16: RefCell<i16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for GroundInt16 {
    type Root = GroundInt16;
    type Parent = GroundInt16;

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
        *self_rc.ground__int16.borrow_mut() = _io.read_s2be()?.into();
        Ok(())
    }
}
impl GroundInt16 {
}
impl GroundInt16 {
    pub fn ground__int16(&self) -> Ref<i16> {
        self.ground__int16.borrow()
    }
}
impl GroundInt16 {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
