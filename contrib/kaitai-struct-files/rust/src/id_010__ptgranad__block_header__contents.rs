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
pub struct Id010PtgranadBlockHeaderContents {
    pub _root: SharedType<Id010PtgranadBlockHeaderContents>,
    pub _parent: SharedType<Id010PtgranadBlockHeaderContents>,
    pub _self: SharedType<Self>,
    id_010__ptgranad__block_header__alpha__unsigned_contents: RefCell<OptRc<Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id010PtgranadBlockHeaderContents {
    type Root = Id010PtgranadBlockHeaderContents;
    type Parent = Id010PtgranadBlockHeaderContents;

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
        let t = Self::read_into::<_, Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_010__ptgranad__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id010PtgranadBlockHeaderContents {
}
impl Id010PtgranadBlockHeaderContents {
    pub fn id_010__ptgranad__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents>> {
        self.id_010__ptgranad__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id010PtgranadBlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id010PtgranadBlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id010PtgranadBlockHeaderContents_Bool> {
        match flag {
            0 => Ok(Id010PtgranadBlockHeaderContents_Bool::False),
            255 => Ok(Id010PtgranadBlockHeaderContents_Bool::True),
            _ => Ok(Id010PtgranadBlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id010PtgranadBlockHeaderContents_Bool> for i64 {
    fn from(v: &Id010PtgranadBlockHeaderContents_Bool) -> Self {
        match *v {
            Id010PtgranadBlockHeaderContents_Bool::False => 0,
            Id010PtgranadBlockHeaderContents_Bool::True => 255,
            Id010PtgranadBlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id010PtgranadBlockHeaderContents_Bool {
    fn default() -> Self { Id010PtgranadBlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id010PtgranadBlockHeaderContents>,
    pub _parent: SharedType<Id010PtgranadBlockHeaderContents>,
    pub _self: SharedType<Self>,
    priority: RefCell<u16>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id010PtgranadBlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_escape_vote: RefCell<Id010PtgranadBlockHeaderContents_Bool>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    type Root = Id010PtgranadBlockHeaderContents;
    type Parent = Id010PtgranadBlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id010PtgranadBlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_escape_vote.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn priority(&self) -> Ref<u16> {
        self.priority.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id010PtgranadBlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_escape_vote(&self) -> Ref<Id010PtgranadBlockHeaderContents_Bool> {
        self.liquidity_baking_escape_vote.borrow()
    }
}
impl Id010PtgranadBlockHeaderContents_Id010PtgranadBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
