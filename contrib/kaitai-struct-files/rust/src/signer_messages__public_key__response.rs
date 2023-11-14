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
pub struct SignerMessagesPublicKeyResponse {
    pub _root: SharedType<SignerMessagesPublicKeyResponse>,
    pub _parent: SharedType<SignerMessagesPublicKeyResponse>,
    pub _self: SharedType<Self>,
    pubkey: RefCell<OptRc<SignerMessagesPublicKeyResponse_PublicKey>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SignerMessagesPublicKeyResponse {
    type Root = SignerMessagesPublicKeyResponse;
    type Parent = SignerMessagesPublicKeyResponse;

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
        let t = Self::read_into::<_, SignerMessagesPublicKeyResponse_PublicKey>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.pubkey.borrow_mut() = t;
        Ok(())
    }
}
impl SignerMessagesPublicKeyResponse {
}
impl SignerMessagesPublicKeyResponse {
    pub fn pubkey(&self) -> Ref<OptRc<SignerMessagesPublicKeyResponse_PublicKey>> {
        self.pubkey.borrow()
    }
}
impl SignerMessagesPublicKeyResponse {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum SignerMessagesPublicKeyResponse_PublicKeyTag {
    Ed25519,
    Secp256k1,
    P256,
    Bls,
    Unknown(i64),
}

impl TryFrom<i64> for SignerMessagesPublicKeyResponse_PublicKeyTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<SignerMessagesPublicKeyResponse_PublicKeyTag> {
        match flag {
            0 => Ok(SignerMessagesPublicKeyResponse_PublicKeyTag::Ed25519),
            1 => Ok(SignerMessagesPublicKeyResponse_PublicKeyTag::Secp256k1),
            2 => Ok(SignerMessagesPublicKeyResponse_PublicKeyTag::P256),
            3 => Ok(SignerMessagesPublicKeyResponse_PublicKeyTag::Bls),
            _ => Ok(SignerMessagesPublicKeyResponse_PublicKeyTag::Unknown(flag)),
        }
    }
}

impl From<&SignerMessagesPublicKeyResponse_PublicKeyTag> for i64 {
    fn from(v: &SignerMessagesPublicKeyResponse_PublicKeyTag) -> Self {
        match *v {
            SignerMessagesPublicKeyResponse_PublicKeyTag::Ed25519 => 0,
            SignerMessagesPublicKeyResponse_PublicKeyTag::Secp256k1 => 1,
            SignerMessagesPublicKeyResponse_PublicKeyTag::P256 => 2,
            SignerMessagesPublicKeyResponse_PublicKeyTag::Bls => 3,
            SignerMessagesPublicKeyResponse_PublicKeyTag::Unknown(v) => v
        }
    }
}

impl Default for SignerMessagesPublicKeyResponse_PublicKeyTag {
    fn default() -> Self { SignerMessagesPublicKeyResponse_PublicKeyTag::Unknown(0) }
}


/**
 * A Ed25519, Secp256k1, or P256 public key
 */

#[derive(Default, Debug, Clone)]
pub struct SignerMessagesPublicKeyResponse_PublicKey {
    pub _root: SharedType<SignerMessagesPublicKeyResponse>,
    pub _parent: SharedType<SignerMessagesPublicKeyResponse>,
    pub _self: SharedType<Self>,
    public_key_tag: RefCell<SignerMessagesPublicKeyResponse_PublicKeyTag>,
    public_key_ed25519: RefCell<Vec<u8>>,
    public_key_secp256k1: RefCell<Vec<u8>>,
    public_key_p256: RefCell<Vec<u8>>,
    public_key_bls: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SignerMessagesPublicKeyResponse_PublicKey {
    type Root = SignerMessagesPublicKeyResponse;
    type Parent = SignerMessagesPublicKeyResponse;

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
        *self_rc.public_key_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.public_key_tag() == SignerMessagesPublicKeyResponse_PublicKeyTag::Ed25519 {
            *self_rc.public_key_ed25519.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        if *self_rc.public_key_tag() == SignerMessagesPublicKeyResponse_PublicKeyTag::Secp256k1 {
            *self_rc.public_key_secp256k1.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == SignerMessagesPublicKeyResponse_PublicKeyTag::P256 {
            *self_rc.public_key_p256.borrow_mut() = _io.read_bytes(33 as usize)?.into();
        }
        if *self_rc.public_key_tag() == SignerMessagesPublicKeyResponse_PublicKeyTag::Bls {
            *self_rc.public_key_bls.borrow_mut() = _io.read_bytes(48 as usize)?.into();
        }
        Ok(())
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn public_key_tag(&self) -> Ref<SignerMessagesPublicKeyResponse_PublicKeyTag> {
        self.public_key_tag.borrow()
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn public_key_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_ed25519.borrow()
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn public_key_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_secp256k1.borrow()
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn public_key_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_p256.borrow()
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn public_key_bls(&self) -> Ref<Vec<u8>> {
        self.public_key_bls.borrow()
    }
}
impl SignerMessagesPublicKeyResponse_PublicKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
