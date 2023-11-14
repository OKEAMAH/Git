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
pub struct Id014PtkathmaBlockHeaderProtocolData {
    pub _root: SharedType<Id014PtkathmaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id014PtkathmaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__block_header__alpha__signed_contents: RefCell<OptRc<Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeaderProtocolData {
    type Root = Id014PtkathmaBlockHeaderProtocolData;
    type Parent = Id014PtkathmaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_014__ptkathma__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaBlockHeaderProtocolData {
}
impl Id014PtkathmaBlockHeaderProtocolData {
    pub fn id_014__ptkathma__block_header__alpha__signed_contents(&self) -> Ref<OptRc<Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents>> {
        self.id_014__ptkathma__block_header__alpha__signed_contents.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaBlockHeaderProtocolData_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaBlockHeaderProtocolData_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaBlockHeaderProtocolData_Bool> {
        match flag {
            0 => Ok(Id014PtkathmaBlockHeaderProtocolData_Bool::False),
            255 => Ok(Id014PtkathmaBlockHeaderProtocolData_Bool::True),
            _ => Ok(Id014PtkathmaBlockHeaderProtocolData_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaBlockHeaderProtocolData_Bool> for i64 {
    fn from(v: &Id014PtkathmaBlockHeaderProtocolData_Bool) -> Self {
        match *v {
            Id014PtkathmaBlockHeaderProtocolData_Bool::False => 0,
            Id014PtkathmaBlockHeaderProtocolData_Bool::True => 255,
            Id014PtkathmaBlockHeaderProtocolData_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaBlockHeaderProtocolData_Bool {
    fn default() -> Self { Id014PtkathmaBlockHeaderProtocolData_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub _root: SharedType<Id014PtkathmaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id014PtkathmaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__block_header__alpha__unsigned_contents: RefCell<OptRc<Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
    type Root = Id014PtkathmaBlockHeaderProtocolData;
    type Parent = Id014PtkathmaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_014__ptkathma__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn id_014__ptkathma__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents>> {
        self.id_014__ptkathma__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id014PtkathmaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id014PtkathmaBlockHeaderProtocolData_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_toggle_vote: RefCell<i8>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    type Root = Id014PtkathmaBlockHeaderProtocolData;
    type Parent = Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaSignedContents;

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
        *self_rc.payload_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.payload_round.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.proof_of_work_nonce.borrow_mut() = _io.read_bytes(8 as usize)?.into();
        *self_rc.seed_nonce_hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.seed_nonce_hash_tag() == Id014PtkathmaBlockHeaderProtocolData_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_toggle_vote.borrow_mut() = _io.read_s1()?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id014PtkathmaBlockHeaderProtocolData_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_toggle_vote(&self) -> Ref<i8> {
        self.liquidity_baking_toggle_vote.borrow()
    }
}
impl Id014PtkathmaBlockHeaderProtocolData_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
