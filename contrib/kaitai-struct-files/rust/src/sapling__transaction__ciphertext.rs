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
pub struct SaplingTransactionCiphertext {
    pub _root: SharedType<SaplingTransactionCiphertext>,
    pub _parent: SharedType<SaplingTransactionCiphertext>,
    pub _self: SharedType<Self>,
    cv: RefCell<Vec<u8>>,
    epk: RefCell<Vec<u8>>,
    payload_enc: RefCell<OptRc<SaplingTransactionCiphertext_PayloadEnc>>,
    nonce_enc: RefCell<Vec<u8>>,
    payload_out: RefCell<Vec<u8>>,
    nonce_out: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionCiphertext {
    type Root = SaplingTransactionCiphertext;
    type Parent = SaplingTransactionCiphertext;

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
        *self_rc.epk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransactionCiphertext_PayloadEnc>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.payload_enc.borrow_mut() = t;
        *self_rc.nonce_enc.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        *self_rc.payload_out.borrow_mut() = _io.read_bytes(80 as usize)?.into();
        *self_rc.nonce_out.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionCiphertext {
}
impl SaplingTransactionCiphertext {
    pub fn cv(&self) -> Ref<Vec<u8>> {
        self.cv.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn epk(&self) -> Ref<Vec<u8>> {
        self.epk.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn payload_enc(&self) -> Ref<OptRc<SaplingTransactionCiphertext_PayloadEnc>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn nonce_enc(&self) -> Ref<Vec<u8>> {
        self.nonce_enc.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn payload_out(&self) -> Ref<Vec<u8>> {
        self.payload_out.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn nonce_out(&self) -> Ref<Vec<u8>> {
        self.nonce_out.borrow()
    }
}
impl SaplingTransactionCiphertext {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionCiphertext_PayloadEnc {
    pub _root: SharedType<SaplingTransactionCiphertext>,
    pub _parent: SharedType<SaplingTransactionCiphertext>,
    pub _self: SharedType<Self>,
    len_payload_enc: RefCell<i32>,
    payload_enc: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionCiphertext_PayloadEnc {
    type Root = SaplingTransactionCiphertext;
    type Parent = SaplingTransactionCiphertext;

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
        *self_rc.len_payload_enc.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.payload_enc.borrow_mut() = _io.read_bytes(*self_rc.len_payload_enc() as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionCiphertext_PayloadEnc {
}
impl SaplingTransactionCiphertext_PayloadEnc {
    pub fn len_payload_enc(&self) -> Ref<i32> {
        self.len_payload_enc.borrow()
    }
}
impl SaplingTransactionCiphertext_PayloadEnc {
    pub fn payload_enc(&self) -> Ref<Vec<u8>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransactionCiphertext_PayloadEnc {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
