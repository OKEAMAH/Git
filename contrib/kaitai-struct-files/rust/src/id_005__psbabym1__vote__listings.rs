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
pub struct Id005Psbabym1VoteListings {
    pub _root: SharedType<Id005Psbabym1VoteListings>,
    pub _parent: SharedType<Id005Psbabym1VoteListings>,
    pub _self: SharedType<Self>,
    len_id_005__psbabym1__vote__listings: RefCell<i32>,
    id_005__psbabym1__vote__listings: RefCell<Vec<OptRc<Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries>>>,
    _io: RefCell<BytesReader>,
    id_005__psbabym1__vote__listings_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id005Psbabym1VoteListings {
    type Root = Id005Psbabym1VoteListings;
    type Parent = Id005Psbabym1VoteListings;

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
        *self_rc.len_id_005__psbabym1__vote__listings.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.id_005__psbabym1__vote__listings.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.id_005__psbabym1__vote__listings_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_id_005__psbabym1__vote__listings() as usize)?.into());
                let id_005__psbabym1__vote__listings_raw = self_rc.id_005__psbabym1__vote__listings_raw.borrow();
                let io_id_005__psbabym1__vote__listings_raw = BytesReader::from(id_005__psbabym1__vote__listings_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries>(&io_id_005__psbabym1__vote__listings_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.id_005__psbabym1__vote__listings.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id005Psbabym1VoteListings {
}
impl Id005Psbabym1VoteListings {
    pub fn len_id_005__psbabym1__vote__listings(&self) -> Ref<i32> {
        self.len_id_005__psbabym1__vote__listings.borrow()
    }
}
impl Id005Psbabym1VoteListings {
    pub fn id_005__psbabym1__vote__listings(&self) -> Ref<Vec<OptRc<Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries>>> {
        self.id_005__psbabym1__vote__listings.borrow()
    }
}
impl Id005Psbabym1VoteListings {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id005Psbabym1VoteListings {
    pub fn id_005__psbabym1__vote__listings_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.id_005__psbabym1__vote__listings_raw.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id005Psbabym1VoteListings_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id005Psbabym1VoteListings_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id005Psbabym1VoteListings_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id005Psbabym1VoteListings_PublicKeyHashTag::Ed25519),
            1 => Ok(Id005Psbabym1VoteListings_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id005Psbabym1VoteListings_PublicKeyHashTag::P256),
            _ => Ok(Id005Psbabym1VoteListings_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id005Psbabym1VoteListings_PublicKeyHashTag> for i64 {
    fn from(v: &Id005Psbabym1VoteListings_PublicKeyHashTag) -> Self {
        match *v {
            Id005Psbabym1VoteListings_PublicKeyHashTag::Ed25519 => 0,
            Id005Psbabym1VoteListings_PublicKeyHashTag::Secp256k1 => 1,
            Id005Psbabym1VoteListings_PublicKeyHashTag::P256 => 2,
            Id005Psbabym1VoteListings_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id005Psbabym1VoteListings_PublicKeyHashTag {
    fn default() -> Self { Id005Psbabym1VoteListings_PublicKeyHashTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
    pub _root: SharedType<Id005Psbabym1VoteListings>,
    pub _parent: SharedType<Id005Psbabym1VoteListings>,
    pub _self: SharedType<Self>,
    pkh: RefCell<OptRc<Id005Psbabym1VoteListings_PublicKeyHash>>,
    rolls: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
    type Root = Id005Psbabym1VoteListings;
    type Parent = Id005Psbabym1VoteListings;

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
        let t = Self::read_into::<_, Id005Psbabym1VoteListings_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.pkh.borrow_mut() = t;
        *self_rc.rolls.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
}
impl Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
    pub fn pkh(&self) -> Ref<OptRc<Id005Psbabym1VoteListings_PublicKeyHash>> {
        self.pkh.borrow()
    }
}
impl Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
    pub fn rolls(&self) -> Ref<i32> {
        self.rolls.borrow()
    }
}
impl Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id005Psbabym1VoteListings_PublicKeyHash {
    pub _root: SharedType<Id005Psbabym1VoteListings>,
    pub _parent: SharedType<Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id005Psbabym1VoteListings_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id005Psbabym1VoteListings_PublicKeyHash {
    type Root = Id005Psbabym1VoteListings;
    type Parent = Id005Psbabym1VoteListings_Id005Psbabym1VoteListingsEntries;

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
        *self_rc.public_key_hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.public_key_hash_tag() == Id005Psbabym1VoteListings_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id005Psbabym1VoteListings_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id005Psbabym1VoteListings_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id005Psbabym1VoteListings_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id005Psbabym1VoteListings_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
