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
pub struct GroundString {
    pub _root: SharedType<GroundString>,
    pub _parent: SharedType<GroundString>,
    pub _self: SharedType<Self>,
    len_ground__string: RefCell<i32>,
    ground__string: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for GroundString {
    type Root = GroundString;
    type Parent = GroundString;

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
        *self_rc.len_ground__string.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.ground__string.borrow_mut() = _io.read_bytes(*self_rc.len_ground__string() as usize)?.into();
        Ok(())
    }
}
impl GroundString {
}
impl GroundString {
    pub fn len_ground__string(&self) -> Ref<i32> {
        self.len_ground__string.borrow()
    }
}
impl GroundString {
    pub fn ground__string(&self) -> Ref<Vec<u8>> {
        self.ground__string.borrow()
    }
}
impl GroundString {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
