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
pub struct Id015PtlimaptBlockHeaderContents {
    pub _root: SharedType<Id015PtlimaptBlockHeaderContents>,
    pub _parent: SharedType<Id015PtlimaptBlockHeaderContents>,
    pub _self: SharedType<Self>,
    id_015__ptlimapt__block_header__alpha__unsigned_contents: RefCell<OptRc<Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptBlockHeaderContents {
    type Root = Id015PtlimaptBlockHeaderContents;
    type Parent = Id015PtlimaptBlockHeaderContents;

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
        let t = Self::read_into::<_, Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_015__ptlimapt__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id015PtlimaptBlockHeaderContents {
}
impl Id015PtlimaptBlockHeaderContents {
    pub fn id_015__ptlimapt__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents>> {
        self.id_015__ptlimapt__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id015PtlimaptBlockHeaderContents_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id015PtlimaptBlockHeaderContents_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id015PtlimaptBlockHeaderContents_Bool> {
        match flag {
            0 => Ok(Id015PtlimaptBlockHeaderContents_Bool::False),
            255 => Ok(Id015PtlimaptBlockHeaderContents_Bool::True),
            _ => Ok(Id015PtlimaptBlockHeaderContents_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id015PtlimaptBlockHeaderContents_Bool> for i64 {
    fn from(v: &Id015PtlimaptBlockHeaderContents_Bool) -> Self {
        match *v {
            Id015PtlimaptBlockHeaderContents_Bool::False => 0,
            Id015PtlimaptBlockHeaderContents_Bool::True => 255,
            Id015PtlimaptBlockHeaderContents_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id015PtlimaptBlockHeaderContents_Bool {
    fn default() -> Self { Id015PtlimaptBlockHeaderContents_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id015PtlimaptBlockHeaderContents>,
    pub _parent: SharedType<Id015PtlimaptBlockHeaderContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id015PtlimaptBlockHeaderContents_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_toggle_vote: RefCell<i8>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    type Root = Id015PtlimaptBlockHeaderContents;
    type Parent = Id015PtlimaptBlockHeaderContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id015PtlimaptBlockHeaderContents_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_toggle_vote.borrow_mut() = _io.read_s1()?.into();
        Ok(())
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id015PtlimaptBlockHeaderContents_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_toggle_vote(&self) -> Ref<i8> {
        self.liquidity_baking_toggle_vote.borrow()
    }
}
impl Id015PtlimaptBlockHeaderContents_Id015PtlimaptBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
