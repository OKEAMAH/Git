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
pub struct Id012PsithacaBlockHeaderContents {
    pub _root: SharedType<Id012PsithacaBlockHeaderContents>,
    pub _parent: SharedType<Id012PsithacaBlockHeaderContents>,
    pub _self: SharedType<Self>,
    id_012__psithaca__block_header__alpha__unsigned_contents: RefCell<OptRc<Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaBlockHeaderContents {
    type Root = Id012PsithacaBlockHeaderContents;
    type Parent = Id012PsithacaBlockHeaderContents;

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
        let t = Self::read_into::<_, Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_012__psithaca__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaBlockHeaderContents {
}
impl Id012PsithacaBlockHeaderContents {
    pub fn id_012__psithaca__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents>> {
        self.id_012__psithaca__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaBlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaBlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaBlockHeaderContents_Bool> {
        match flag {
            0 => Ok(Id012PsithacaBlockHeaderContents_Bool::False),
            255 => Ok(Id012PsithacaBlockHeaderContents_Bool::True),
            _ => Ok(Id012PsithacaBlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaBlockHeaderContents_Bool> for i64 {
    fn from(v: &Id012PsithacaBlockHeaderContents_Bool) -> Self {
        match *v {
            Id012PsithacaBlockHeaderContents_Bool::False => 0,
            Id012PsithacaBlockHeaderContents_Bool::True => 255,
            Id012PsithacaBlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaBlockHeaderContents_Bool {
    fn default() -> Self { Id012PsithacaBlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id012PsithacaBlockHeaderContents>,
    pub _parent: SharedType<Id012PsithacaBlockHeaderContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id012PsithacaBlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_escape_vote: RefCell<Id012PsithacaBlockHeaderContents_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    type Root = Id012PsithacaBlockHeaderContents;
    type Parent = Id012PsithacaBlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id012PsithacaBlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_escape_vote.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id012PsithacaBlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_escape_vote(&self) -> Ref<Id012PsithacaBlockHeaderContents_Bool> {
        self.liquidity_baking_escape_vote.borrow()
    }
}
impl Id012PsithacaBlockHeaderContents_Id012PsithacaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
