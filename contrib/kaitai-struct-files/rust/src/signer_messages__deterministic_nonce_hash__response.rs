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
pub struct SignerMessagesDeterministicNonceHashResponse {
    pub _root: SharedType<SignerMessagesDeterministicNonceHashResponse>,
    pub _parent: SharedType<SignerMessagesDeterministicNonceHashResponse>,
    pub _self: SharedType<Self>,
    deterministic_nonce_hash: RefCell<OptRc<SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SignerMessagesDeterministicNonceHashResponse {
    type Root = SignerMessagesDeterministicNonceHashResponse;
    type Parent = SignerMessagesDeterministicNonceHashResponse;

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
        let t = Self::read_into::<_, SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.deterministic_nonce_hash.borrow_mut() = t;
        Ok(())
    }
}
impl SignerMessagesDeterministicNonceHashResponse {
}
impl SignerMessagesDeterministicNonceHashResponse {
    pub fn deterministic_nonce_hash(&self) -> Ref<OptRc<SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash>> {
        self.deterministic_nonce_hash.borrow()
    }
}
impl SignerMessagesDeterministicNonceHashResponse {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
    pub _root: SharedType<SignerMessagesDeterministicNonceHashResponse>,
    pub _parent: SharedType<SignerMessagesDeterministicNonceHashResponse>,
    pub _self: SharedType<Self>,
    len_deterministic_nonce_hash: RefCell<i32>,
    deterministic_nonce_hash: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
    type Root = SignerMessagesDeterministicNonceHashResponse;
    type Parent = SignerMessagesDeterministicNonceHashResponse;

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
        *self_rc.len_deterministic_nonce_hash.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.deterministic_nonce_hash.borrow_mut() = _io.read_bytes(*self_rc.len_deterministic_nonce_hash() as usize)?.into();
        Ok(())
    }
}
impl SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
}
impl SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
    pub fn len_deterministic_nonce_hash(&self) -> Ref<i32> {
        self.len_deterministic_nonce_hash.borrow()
    }
}
impl SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
    pub fn deterministic_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.deterministic_nonce_hash.borrow()
    }
}
impl SignerMessagesDeterministicNonceHashResponse_DeterministicNonceHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
