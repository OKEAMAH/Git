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
pub struct Id011Pthangz2BlockHeaderContents {
    pub _root: SharedType<Id011Pthangz2BlockHeaderContents>,
    pub _parent: SharedType<Id011Pthangz2BlockHeaderContents>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__block_header__alpha__unsigned_contents: RefCell<OptRc<Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2BlockHeaderContents {
    type Root = Id011Pthangz2BlockHeaderContents;
    type Parent = Id011Pthangz2BlockHeaderContents;

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
        let t = Self::read_into::<_, Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_011__pthangz2__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id011Pthangz2BlockHeaderContents {
}
impl Id011Pthangz2BlockHeaderContents {
    pub fn id_011__pthangz2__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents>> {
        self.id_011__pthangz2__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id011Pthangz2BlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id011Pthangz2BlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id011Pthangz2BlockHeaderContents_Bool> {
        match flag {
            0 => Ok(Id011Pthangz2BlockHeaderContents_Bool::False),
            255 => Ok(Id011Pthangz2BlockHeaderContents_Bool::True),
            _ => Ok(Id011Pthangz2BlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id011Pthangz2BlockHeaderContents_Bool> for i64 {
    fn from(v: &Id011Pthangz2BlockHeaderContents_Bool) -> Self {
        match *v {
            Id011Pthangz2BlockHeaderContents_Bool::False => 0,
            Id011Pthangz2BlockHeaderContents_Bool::True => 255,
            Id011Pthangz2BlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id011Pthangz2BlockHeaderContents_Bool {
    fn default() -> Self { Id011Pthangz2BlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id011Pthangz2BlockHeaderContents>,
    pub _parent: SharedType<Id011Pthangz2BlockHeaderContents>,
    pub _self: SharedType<Self>,
    priority: RefCell<u16>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id011Pthangz2BlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_escape_vote: RefCell<Id011Pthangz2BlockHeaderContents_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    type Root = Id011Pthangz2BlockHeaderContents;
    type Parent = Id011Pthangz2BlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id011Pthangz2BlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_escape_vote.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn priority(&self) -> Ref<u16> {
        self.priority.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id011Pthangz2BlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_escape_vote(&self) -> Ref<Id011Pthangz2BlockHeaderContents_Bool> {
        self.liquidity_baking_escape_vote.borrow()
    }
}
impl Id011Pthangz2BlockHeaderContents_Id011Pthangz2BlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
