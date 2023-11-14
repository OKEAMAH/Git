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
 * Signed 8 bit integers
 */

#[derive(Default, Debug, Clone)]
pub struct GroundInt8 {
    pub _root: SharedType<GroundInt8>,
    pub _parent: SharedType<GroundInt8>,
    pub _self: SharedType<Self>,
    ground__int8: RefCell<i8>,
    _io: RefCell<BytesReader>,
}
impl KStruct for GroundInt8 {
    type Root = GroundInt8;
    type Parent = GroundInt8;

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
        *self_rc.ground__int8.borrow_mut() = _io.read_s1()?.into();
        Ok(())
    }
}
impl GroundInt8 {
}
impl GroundInt8 {
    pub fn ground__int8(&self) -> Ref<i8> {
        self.ground__int8.borrow()
    }
}
impl GroundInt8 {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
