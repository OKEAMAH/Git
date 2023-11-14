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
pub struct AlphaBlockHeaderContents {
    pub _root: SharedType<AlphaBlockHeaderContents>,
    pub _parent: SharedType<AlphaBlockHeaderContents>,
    pub _self: SharedType<Self>,
    alpha__block_header__alpha__unsigned_contents: RefCell<OptRc<AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderContents {
    type Root = AlphaBlockHeaderContents;
    type Parent = AlphaBlockHeaderContents;

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
        let t = Self::read_into::<_, AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.alpha__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaBlockHeaderContents {
}
impl AlphaBlockHeaderContents {
    pub fn alpha__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents>> {
        self.alpha__block_header__alpha__unsigned_contents.borrow()
    }
}
impl AlphaBlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderContents_AlphaPerBlockVotesTag {
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

impl TryFrom<i64> for AlphaBlockHeaderContents_AlphaPerBlockVotesTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderContents_AlphaPerBlockVotesTag> {
        match flag {
            0 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case0),
            1 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case1),
            2 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case2),
            4 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case4),
            5 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case5),
            6 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case6),
            8 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case8),
            9 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case9),
            10 => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case10),
            _ => Ok(AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderContents_AlphaPerBlockVotesTag> for i64 {
    fn from(v: &AlphaBlockHeaderContents_AlphaPerBlockVotesTag) -> Self {
        match *v {
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case0 => 0,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case1 => 1,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case2 => 2,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case4 => 4,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case5 => 5,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case6 => 6,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case8 => 8,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case9 => 9,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Case10 => 10,
            AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderContents_AlphaPerBlockVotesTag {
    fn default() -> Self { AlphaBlockHeaderContents_AlphaPerBlockVotesTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaBlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderContents_Bool> {
        match flag {
            0 => Ok(AlphaBlockHeaderContents_Bool::False),
            255 => Ok(AlphaBlockHeaderContents_Bool::True),
            _ => Ok(AlphaBlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderContents_Bool> for i64 {
    fn from(v: &AlphaBlockHeaderContents_Bool) -> Self {
        match *v {
            AlphaBlockHeaderContents_Bool::False => 0,
            AlphaBlockHeaderContents_Bool::True => 255,
            AlphaBlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderContents_Bool {
    fn default() -> Self { AlphaBlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<AlphaBlockHeaderContents>,
    pub _parent: SharedType<AlphaBlockHeaderContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<AlphaBlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    per_block_votes: RefCell<AlphaBlockHeaderContents_AlphaPerBlockVotesTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    type Root = AlphaBlockHeaderContents;
    type Parent = AlphaBlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == AlphaBlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.per_block_votes.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<AlphaBlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn per_block_votes(&self) -> Ref<AlphaBlockHeaderContents_AlphaPerBlockVotesTag> {
        self.per_block_votes.borrow()
    }
}
impl AlphaBlockHeaderContents_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
