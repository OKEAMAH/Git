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
 * Input of a transaction
 */

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionInput {
    pub _root: SharedType<SaplingTransactionInput>,
    pub _parent: SharedType<SaplingTransactionInput>,
    pub _self: SharedType<Self>,
    cv: RefCell<Vec<u8>>,
    nf: RefCell<Vec<u8>>,
    rk: RefCell<Vec<u8>>,
    proof_i: RefCell<Vec<u8>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionInput {
    type Root = SaplingTransactionInput;
    type Parent = SaplingTransactionInput;

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
        *self_rc.cv.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.nf.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.rk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.proof_i.borrow_mut() = _io.read_bytes(192 as usize)?.into();
        *self_rc.signature.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionInput {
}
impl SaplingTransactionInput {
    pub fn cv(&self) -> Ref<Vec<u8>> {
        self.cv.borrow()
    }
}
impl SaplingTransactionInput {
    pub fn nf(&self) -> Ref<Vec<u8>> {
        self.nf.borrow()
    }
}
impl SaplingTransactionInput {
    pub fn rk(&self) -> Ref<Vec<u8>> {
        self.rk.borrow()
    }
}
impl SaplingTransactionInput {
    pub fn proof_i(&self) -> Ref<Vec<u8>> {
        self.proof_i.borrow()
    }
}
impl SaplingTransactionInput {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl SaplingTransactionInput {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
