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
pub struct Id008Ptedo2zkRawLevel {
    pub _root: SharedType<Id008Ptedo2zkRawLevel>,
    pub _parent: SharedType<Id008Ptedo2zkRawLevel>,
    pub _self: SharedType<Self>,
    id_008__ptedo2zk__raw_level: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkRawLevel {
    type Root = Id008Ptedo2zkRawLevel;
    type Parent = Id008Ptedo2zkRawLevel;

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
        *self_rc.id_008__ptedo2zk__raw_level.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id008Ptedo2zkRawLevel {
}
impl Id008Ptedo2zkRawLevel {
    pub fn id_008__ptedo2zk__raw_level(&self) -> Ref<i32> {
        self.id_008__ptedo2zk__raw_level.borrow()
    }
}
impl Id008Ptedo2zkRawLevel {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
