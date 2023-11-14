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
pub struct Id011Pthangz2OperationRaw {
    pub _root: SharedType<Id011Pthangz2OperationRaw>,
    pub _parent: SharedType<Id011Pthangz2OperationRaw>,
    pub _self: SharedType<Self>,
    operation: RefCell<OptRc<Id011Pthangz2OperationRaw_Operation>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2OperationRaw {
    type Root = Id011Pthangz2OperationRaw;
    type Parent = Id011Pthangz2OperationRaw;

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
        let t = Self::read_into::<_, Id011Pthangz2OperationRaw_Operation>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.operation.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2OperationRaw {
}
impl Id011Pthangz2OperationRaw {
    pub fn operation(&self) -> Ref<OptRc<Id011Pthangz2OperationRaw_Operation>> {
        self.operation.borrow()
    }
}
impl Id011Pthangz2OperationRaw {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * An operation. The shell_header part indicates a block an operation is meant to apply on top of. The proto part is protocol-specific and appears as a binary blob.
 */

#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2OperationRaw_Operation {
    pub _root: SharedType<Id011Pthangz2OperationRaw>,
    pub _parent: SharedType<Id011Pthangz2OperationRaw>,
    pub _self: SharedType<Self>,
    branch: RefCell<Vec<u8>>,
    data: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2OperationRaw_Operation {
    type Root = Id011Pthangz2OperationRaw;
    type Parent = Id011Pthangz2OperationRaw;

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
        *self_rc.branch.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.data.borrow_mut() = _io.read_bytes_full()?.into();
        Ok(())
    }
}
impl Id011Pthangz2OperationRaw_Operation {
}

/**
 * An operation's shell header.
 */
impl Id011Pthangz2OperationRaw_Operation {
    pub fn branch(&self) -> Ref<Vec<u8>> {
        self.branch.borrow()
    }
}
impl Id011Pthangz2OperationRaw_Operation {
    pub fn data(&self) -> Ref<Vec<u8>> {
        self.data.borrow()
    }
}
impl Id011Pthangz2OperationRaw_Operation {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
