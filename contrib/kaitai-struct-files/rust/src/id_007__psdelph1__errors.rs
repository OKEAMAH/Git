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
 * The full list of RPC errors would be too long to include.It is
 * available through the RPC `/errors` (GET).
 */

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1Errors {
    pub _root: SharedType<Id007Psdelph1Errors>,
    pub _parent: SharedType<Id007Psdelph1Errors>,
    pub _self: SharedType<Self>,
    len_id_007__psdelph1__errors: RefCell<i32>,
    id_007__psdelph1__errors: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Errors {
    type Root = Id007Psdelph1Errors;
    type Parent = Id007Psdelph1Errors;

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
        *self_rc.len_id_007__psdelph1__errors.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.id_007__psdelph1__errors.borrow_mut() = _io.read_bytes(*self_rc.len_id_007__psdelph1__errors() as usize)?.into();
        Ok(())
    }
}
impl Id007Psdelph1Errors {
}
impl Id007Psdelph1Errors {
    pub fn len_id_007__psdelph1__errors(&self) -> Ref<i32> {
        self.len_id_007__psdelph1__errors.borrow()
    }
}
impl Id007Psdelph1Errors {
    pub fn id_007__psdelph1__errors(&self) -> Ref<Vec<u8>> {
        self.id_007__psdelph1__errors.borrow()
    }
}
impl Id007Psdelph1Errors {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
