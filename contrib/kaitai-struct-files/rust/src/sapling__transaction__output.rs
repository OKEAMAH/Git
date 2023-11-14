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
 * Output of a transaction
 */

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionOutput {
    pub _root: SharedType<SaplingTransactionOutput>,
    pub _parent: SharedType<SaplingTransactionOutput>,
    pub _self: SharedType<Self>,
    cm: RefCell<Vec<u8>>,
    proof_o: RefCell<Vec<u8>>,
    ciphertext: RefCell<OptRc<SaplingTransactionOutput_SaplingTransactionCiphertext>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionOutput {
    type Root = SaplingTransactionOutput;
    type Parent = SaplingTransactionOutput;

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
        *self_rc.cm.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.proof_o.borrow_mut() = _io.read_bytes(192 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransactionOutput_SaplingTransactionCiphertext>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ciphertext.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransactionOutput {
}
impl SaplingTransactionOutput {
    pub fn cm(&self) -> Ref<Vec<u8>> {
        self.cm.borrow()
    }
}
impl SaplingTransactionOutput {
    pub fn proof_o(&self) -> Ref<Vec<u8>> {
        self.proof_o.borrow()
    }
}
impl SaplingTransactionOutput {
    pub fn ciphertext(&self) -> Ref<OptRc<SaplingTransactionOutput_SaplingTransactionCiphertext>> {
        self.ciphertext.borrow()
    }
}
impl SaplingTransactionOutput {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub _root: SharedType<SaplingTransactionOutput>,
    pub _parent: SharedType<SaplingTransactionOutput>,
    pub _self: SharedType<Self>,
    cv: RefCell<Vec<u8>>,
    epk: RefCell<Vec<u8>>,
    payload_enc: RefCell<OptRc<SaplingTransactionOutput_PayloadEnc>>,
    nonce_enc: RefCell<Vec<u8>>,
    payload_out: RefCell<Vec<u8>>,
    nonce_out: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionOutput_SaplingTransactionCiphertext {
    type Root = SaplingTransactionOutput;
    type Parent = SaplingTransactionOutput;

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
        let t = Self::read_into::<_, SaplingTransactionOutput_PayloadEnc>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.payload_enc.borrow_mut() = t;
        *self_rc.nonce_enc.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        *self_rc.payload_out.borrow_mut() = _io.read_bytes(80 as usize)?.into();
        *self_rc.nonce_out.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn cv(&self) -> Ref<Vec<u8>> {
        self.cv.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn epk(&self) -> Ref<Vec<u8>> {
        self.epk.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn payload_enc(&self) -> Ref<OptRc<SaplingTransactionOutput_PayloadEnc>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn nonce_enc(&self) -> Ref<Vec<u8>> {
        self.nonce_enc.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn payload_out(&self) -> Ref<Vec<u8>> {
        self.payload_out.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn nonce_out(&self) -> Ref<Vec<u8>> {
        self.nonce_out.borrow()
    }
}
impl SaplingTransactionOutput_SaplingTransactionCiphertext {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionOutput_PayloadEnc {
    pub _root: SharedType<SaplingTransactionOutput>,
    pub _parent: SharedType<SaplingTransactionOutput_SaplingTransactionCiphertext>,
    pub _self: SharedType<Self>,
    len_payload_enc: RefCell<i32>,
    payload_enc: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionOutput_PayloadEnc {
    type Root = SaplingTransactionOutput;
    type Parent = SaplingTransactionOutput_SaplingTransactionCiphertext;

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
impl SaplingTransactionOutput_PayloadEnc {
}
impl SaplingTransactionOutput_PayloadEnc {
    pub fn len_payload_enc(&self) -> Ref<i32> {
        self.len_payload_enc.borrow()
    }
}
impl SaplingTransactionOutput_PayloadEnc {
    pub fn payload_enc(&self) -> Ref<Vec<u8>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransactionOutput_PayloadEnc {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
