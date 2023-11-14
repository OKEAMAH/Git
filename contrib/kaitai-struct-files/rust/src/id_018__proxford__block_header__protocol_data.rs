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
pub struct Id018ProxfordBlockHeaderProtocolData {
    pub _root: SharedType<Id018ProxfordBlockHeaderProtocolData>,
    pub _parent: SharedType<Id018ProxfordBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_018__proxford__block_header__alpha__signed_contents: RefCell<OptRc<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id018ProxfordBlockHeaderProtocolData {
    type Root = Id018ProxfordBlockHeaderProtocolData;
    type Parent = Id018ProxfordBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_018__proxford__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id018ProxfordBlockHeaderProtocolData {
}
impl Id018ProxfordBlockHeaderProtocolData {
    pub fn id_018__proxford__block_header__alpha__signed_contents(&self) -> Ref<OptRc<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents>> {
        self.id_018__proxford__block_header__alpha__signed_contents.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag {
    Case0,
    Case1,
    Case2,
    Case4,
    Case5,
    Case6,
    Case8,
    Case9,
    Case10,
    Unknown(i64),
}

impl TryFrom<i64> for Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag> {
        match flag {
            0 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case0),
            1 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case1),
            2 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case2),
            4 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case4),
            5 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case5),
            6 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case6),
            8 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case8),
            9 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case9),
            10 => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case10),
            _ => Ok(Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Unknown(flag)),
        }
    }
}

impl From<&Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag> for i64 {
    fn from(v: &Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag) -> Self {
        match *v {
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case0 => 0,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case1 => 1,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case2 => 2,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case4 => 4,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case5 => 5,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case6 => 6,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case8 => 8,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case9 => 9,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Case10 => 10,
            Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Unknown(v) => v
        }
    }
}

impl Default for Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag {
    fn default() -> Self { Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum Id018ProxfordBlockHeaderProtocolData_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id018ProxfordBlockHeaderProtocolData_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id018ProxfordBlockHeaderProtocolData_Bool> {
        match flag {
            0 => Ok(Id018ProxfordBlockHeaderProtocolData_Bool::False),
            255 => Ok(Id018ProxfordBlockHeaderProtocolData_Bool::True),
            _ => Ok(Id018ProxfordBlockHeaderProtocolData_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id018ProxfordBlockHeaderProtocolData_Bool> for i64 {
    fn from(v: &Id018ProxfordBlockHeaderProtocolData_Bool) -> Self {
        match *v {
            Id018ProxfordBlockHeaderProtocolData_Bool::False => 0,
            Id018ProxfordBlockHeaderProtocolData_Bool::True => 255,
            Id018ProxfordBlockHeaderProtocolData_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id018ProxfordBlockHeaderProtocolData_Bool {
    fn default() -> Self { Id018ProxfordBlockHeaderProtocolData_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
    pub _root: SharedType<Id018ProxfordBlockHeaderProtocolData>,
    pub _parent: SharedType<Id018ProxfordBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    id_018__proxford__block_header__alpha__unsigned_contents: RefCell<OptRc<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
    type Root = Id018ProxfordBlockHeaderProtocolData;
    type Parent = Id018ProxfordBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_018__proxford__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes_full()?.into();
        Ok(())
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
    pub fn id_018__proxford__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents>> {
        self.id_018__proxford__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id018ProxfordBlockHeaderProtocolData>,
    pub _parent: SharedType<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id018ProxfordBlockHeaderProtocolData_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    per_block_votes: RefCell<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    type Root = Id018ProxfordBlockHeaderProtocolData;
    type Parent = Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaSignedContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id018ProxfordBlockHeaderProtocolData_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.per_block_votes.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id018ProxfordBlockHeaderProtocolData_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn per_block_votes(&self) -> Ref<Id018ProxfordBlockHeaderProtocolData_Id018ProxfordPerBlockVotesTag> {
        self.per_block_votes.borrow()
    }
}
impl Id018ProxfordBlockHeaderProtocolData_Id018ProxfordBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
