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
pub struct Id008Ptedo2zkBlockHeaderContents {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderContents>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderContents>,
    pub _self: SharedType<Self>,
    id_008__ptedo2zk__block_header__alpha__unsigned_contents: RefCell<OptRc<Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderContents {
    type Root = Id008Ptedo2zkBlockHeaderContents;
    type Parent = Id008Ptedo2zkBlockHeaderContents;

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
        let t = Self::read_into::<_, Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_008__ptedo2zk__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderContents {
}
impl Id008Ptedo2zkBlockHeaderContents {
    pub fn id_008__ptedo2zk__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>> {
        self.id_008__ptedo2zk__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id008Ptedo2zkBlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id008Ptedo2zkBlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id008Ptedo2zkBlockHeaderContents_Bool> {
        match flag {
            0 => Ok(Id008Ptedo2zkBlockHeaderContents_Bool::False),
            255 => Ok(Id008Ptedo2zkBlockHeaderContents_Bool::True),
            _ => Ok(Id008Ptedo2zkBlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id008Ptedo2zkBlockHeaderContents_Bool> for i64 {
    fn from(v: &Id008Ptedo2zkBlockHeaderContents_Bool) -> Self {
        match *v {
            Id008Ptedo2zkBlockHeaderContents_Bool::False => 0,
            Id008Ptedo2zkBlockHeaderContents_Bool::True => 255,
            Id008Ptedo2zkBlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id008Ptedo2zkBlockHeaderContents_Bool {
    fn default() -> Self { Id008Ptedo2zkBlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderContents>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderContents>,
    pub _self: SharedType<Self>,
    priority: RefCell<u16>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id008Ptedo2zkBlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    type Root = Id008Ptedo2zkBlockHeaderContents;
    type Parent = Id008Ptedo2zkBlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id008Ptedo2zkBlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn priority(&self) -> Ref<u16> {
        self.priority.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id008Ptedo2zkBlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderContents_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
