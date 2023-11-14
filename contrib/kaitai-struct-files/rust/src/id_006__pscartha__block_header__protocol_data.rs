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
pub struct Id006PscarthaBlockHeaderProtocolData {
    pub _root: SharedType<Id006PscarthaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id006PscarthaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_006__pscartha__block_header__alpha__signed_contents: RefCell<OptRc<Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaBlockHeaderProtocolData {
    type Root = Id006PscarthaBlockHeaderProtocolData;
    type Parent = Id006PscarthaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_006__pscartha__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id006PscarthaBlockHeaderProtocolData {
}
impl Id006PscarthaBlockHeaderProtocolData {
    pub fn id_006__pscartha__block_header__alpha__signed_contents(&self) -> Ref<OptRc<Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents>> {
        self.id_006__pscartha__block_header__alpha__signed_contents.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id006PscarthaBlockHeaderProtocolData_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id006PscarthaBlockHeaderProtocolData_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id006PscarthaBlockHeaderProtocolData_Bool> {
        match flag {
            0 => Ok(Id006PscarthaBlockHeaderProtocolData_Bool::False),
            255 => Ok(Id006PscarthaBlockHeaderProtocolData_Bool::True),
            _ => Ok(Id006PscarthaBlockHeaderProtocolData_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id006PscarthaBlockHeaderProtocolData_Bool> for i64 {
    fn from(v: &Id006PscarthaBlockHeaderProtocolData_Bool) -> Self {
        match *v {
            Id006PscarthaBlockHeaderProtocolData_Bool::False => 0,
            Id006PscarthaBlockHeaderProtocolData_Bool::True => 255,
            Id006PscarthaBlockHeaderProtocolData_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id006PscarthaBlockHeaderProtocolData_Bool {
    fn default() -> Self { Id006PscarthaBlockHeaderProtocolData_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
    pub _root: SharedType<Id006PscarthaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id006PscarthaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_006__pscartha__block_header__alpha__unsigned_contents: RefCell<OptRc<Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
    type Root = Id006PscarthaBlockHeaderProtocolData;
    type Parent = Id006PscarthaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_006__pscartha__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        Ok(())
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
    pub fn id_006__pscartha__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents>> {
        self.id_006__pscartha__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id006PscarthaBlockHeaderProtocolData>,
    pub _parent: SharedType<Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    priority: RefCell<u16>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id006PscarthaBlockHeaderProtocolData_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    type Root = Id006PscarthaBlockHeaderProtocolData;
    type Parent = Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaSignedContents;

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
        *self_rc.priority.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.proof_of_work_nonce.borrow_mut() = _io.read_bytes(8 as usize)?.into();
        *self_rc.seed_nonce_hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.seed_nonce_hash_tag() == Id006PscarthaBlockHeaderProtocolData_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        Ok(())
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub fn priority(&self) -> Ref<u16> {
        self.priority.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id006PscarthaBlockHeaderProtocolData_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id006PscarthaBlockHeaderProtocolData_Id006PscarthaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
