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
pub struct Id016PtmumbaiBlockHeaderProtocolData {
    pub _root: SharedType<Id016PtmumbaiBlockHeaderProtocolData>,
    pub _parent: SharedType<Id016PtmumbaiBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_016__ptmumbai__block_header__alpha__signed_contents: RefCell<OptRc<Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiBlockHeaderProtocolData {
    type Root = Id016PtmumbaiBlockHeaderProtocolData;
    type Parent = Id016PtmumbaiBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_016__ptmumbai__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData {
}
impl Id016PtmumbaiBlockHeaderProtocolData {
    pub fn id_016__ptmumbai__block_header__alpha__signed_contents(&self) -> Ref<OptRc<Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents>> {
        self.id_016__ptmumbai__block_header__alpha__signed_contents.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id016PtmumbaiBlockHeaderProtocolData_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id016PtmumbaiBlockHeaderProtocolData_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id016PtmumbaiBlockHeaderProtocolData_Bool> {
        match flag {
            0 => Ok(Id016PtmumbaiBlockHeaderProtocolData_Bool::False),
            255 => Ok(Id016PtmumbaiBlockHeaderProtocolData_Bool::True),
            _ => Ok(Id016PtmumbaiBlockHeaderProtocolData_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id016PtmumbaiBlockHeaderProtocolData_Bool> for i64 {
    fn from(v: &Id016PtmumbaiBlockHeaderProtocolData_Bool) -> Self {
        match *v {
            Id016PtmumbaiBlockHeaderProtocolData_Bool::False => 0,
            Id016PtmumbaiBlockHeaderProtocolData_Bool::True => 255,
            Id016PtmumbaiBlockHeaderProtocolData_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id016PtmumbaiBlockHeaderProtocolData_Bool {
    fn default() -> Self { Id016PtmumbaiBlockHeaderProtocolData_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
    pub _root: SharedType<Id016PtmumbaiBlockHeaderProtocolData>,
    pub _parent: SharedType<Id016PtmumbaiBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_016__ptmumbai__block_header__alpha__unsigned_contents: RefCell<OptRc<Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
    type Root = Id016PtmumbaiBlockHeaderProtocolData;
    type Parent = Id016PtmumbaiBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_016__ptmumbai__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes_full()?.into();
        Ok(())
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
    pub fn id_016__ptmumbai__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents>> {
        self.id_016__ptmumbai__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id016PtmumbaiBlockHeaderProtocolData>,
    pub _parent: SharedType<Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id016PtmumbaiBlockHeaderProtocolData_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_toggle_vote: RefCell<i8>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    type Root = Id016PtmumbaiBlockHeaderProtocolData;
    type Parent = Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaSignedContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id016PtmumbaiBlockHeaderProtocolData_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_toggle_vote.borrow_mut() = _io.read_s1()?.into();
        Ok(())
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id016PtmumbaiBlockHeaderProtocolData_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_toggle_vote(&self) -> Ref<i8> {
        self.liquidity_baking_toggle_vote.borrow()
    }
}
impl Id016PtmumbaiBlockHeaderProtocolData_Id016PtmumbaiBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
