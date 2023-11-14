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
pub struct AlphaBlockHeaderProtocolData {
    pub _root: SharedType<AlphaBlockHeaderProtocolData>,
    pub _parent: SharedType<AlphaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    alpha__block_header__alpha__signed_contents: RefCell<OptRc<AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderProtocolData {
    type Root = AlphaBlockHeaderProtocolData;
    type Parent = AlphaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.alpha__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaBlockHeaderProtocolData {
}
impl AlphaBlockHeaderProtocolData {
    pub fn alpha__block_header__alpha__signed_contents(&self) -> Ref<OptRc<AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents>> {
        self.alpha__block_header__alpha__signed_contents.borrow()
    }
}
impl AlphaBlockHeaderProtocolData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag {
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

impl TryFrom<i64> for AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag> {
        match flag {
            0 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case0),
            1 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case1),
            2 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case2),
            4 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case4),
            5 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case5),
            6 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case6),
            8 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case8),
            9 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case9),
            10 => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case10),
            _ => Ok(AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag> for i64 {
    fn from(v: &AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag) -> Self {
        match *v {
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case0 => 0,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case1 => 1,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case2 => 2,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case4 => 4,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case5 => 5,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case6 => 6,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case8 => 8,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case9 => 9,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Case10 => 10,
            AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag {
    fn default() -> Self { AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderProtocolData_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaBlockHeaderProtocolData_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderProtocolData_Bool> {
        match flag {
            0 => Ok(AlphaBlockHeaderProtocolData_Bool::False),
            255 => Ok(AlphaBlockHeaderProtocolData_Bool::True),
            _ => Ok(AlphaBlockHeaderProtocolData_Bool::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderProtocolData_Bool> for i64 {
    fn from(v: &AlphaBlockHeaderProtocolData_Bool) -> Self {
        match *v {
            AlphaBlockHeaderProtocolData_Bool::False => 0,
            AlphaBlockHeaderProtocolData_Bool::True => 255,
            AlphaBlockHeaderProtocolData_Bool::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderProtocolData_Bool {
    fn default() -> Self { AlphaBlockHeaderProtocolData_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
    pub _root: SharedType<AlphaBlockHeaderProtocolData>,
    pub _parent: SharedType<AlphaBlockHeaderProtocolData>,
    pub _self: SharedType<Self>,
    alpha__block_header__alpha__unsigned_contents: RefCell<OptRc<AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
    type Root = AlphaBlockHeaderProtocolData;
    type Parent = AlphaBlockHeaderProtocolData;

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
        let t = Self::read_into::<_, AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.alpha__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes_full()?.into();
        Ok(())
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
    pub fn alpha__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents>> {
        self.alpha__block_header__alpha__unsigned_contents.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<AlphaBlockHeaderProtocolData>,
    pub _parent: SharedType<AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<AlphaBlockHeaderProtocolData_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    per_block_votes: RefCell<AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    type Root = AlphaBlockHeaderProtocolData;
    type Parent = AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaSignedContents;

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
        if *self_rc.seed_nonce_hash_tag() == AlphaBlockHeaderProtocolData_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.per_block_votes.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<AlphaBlockHeaderProtocolData_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn per_block_votes(&self) -> Ref<AlphaBlockHeaderProtocolData_AlphaPerBlockVotesTag> {
        self.per_block_votes.borrow()
    }
}
impl AlphaBlockHeaderProtocolData_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
