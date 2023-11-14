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
pub struct SignerMessagesSupportsDeterministicNoncesResponse {
    pub _root: SharedType<SignerMessagesSupportsDeterministicNoncesResponse>,
    pub _parent: SharedType<SignerMessagesSupportsDeterministicNoncesResponse>,
    pub _self: SharedType<Self>,
    bool: RefCell<SignerMessagesSupportsDeterministicNoncesResponse_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SignerMessagesSupportsDeterministicNoncesResponse {
    type Root = SignerMessagesSupportsDeterministicNoncesResponse;
    type Parent = SignerMessagesSupportsDeterministicNoncesResponse;

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
        *self_rc.bool.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl SignerMessagesSupportsDeterministicNoncesResponse {
}
impl SignerMessagesSupportsDeterministicNoncesResponse {
    pub fn bool(&self) -> Ref<SignerMessagesSupportsDeterministicNoncesResponse_Bool> {
        self.bool.borrow()
    }
}
impl SignerMessagesSupportsDeterministicNoncesResponse {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum SignerMessagesSupportsDeterministicNoncesResponse_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for SignerMessagesSupportsDeterministicNoncesResponse_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<SignerMessagesSupportsDeterministicNoncesResponse_Bool> {
        match flag {
            0 => Ok(SignerMessagesSupportsDeterministicNoncesResponse_Bool::False),
            255 => Ok(SignerMessagesSupportsDeterministicNoncesResponse_Bool::True),
            _ => Ok(SignerMessagesSupportsDeterministicNoncesResponse_Bool::Unknown(flag)),
        }
    }
}

impl From<&SignerMessagesSupportsDeterministicNoncesResponse_Bool> for i64 {
    fn from(v: &SignerMessagesSupportsDeterministicNoncesResponse_Bool) -> Self {
        match *v {
            SignerMessagesSupportsDeterministicNoncesResponse_Bool::False => 0,
            SignerMessagesSupportsDeterministicNoncesResponse_Bool::True => 255,
            SignerMessagesSupportsDeterministicNoncesResponse_Bool::Unknown(v) => v
        }
    }
}

impl Default for SignerMessagesSupportsDeterministicNoncesResponse_Bool {
    fn default() -> Self { SignerMessagesSupportsDeterministicNoncesResponse_Bool::Unknown(0) }
}

