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
pub struct Id014PtkathmaVoteListings {
    pub _root: SharedType<Id014PtkathmaVoteListings>,
    pub _parent: SharedType<Id014PtkathmaVoteListings>,
    pub _self: SharedType<Self>,
    len_id_014__ptkathma__vote__listings: RefCell<i32>,
    id_014__ptkathma__vote__listings: RefCell<Vec<OptRc<Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries>>>,
    _io: RefCell<BytesReader>,
    id_014__ptkathma__vote__listings_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id014PtkathmaVoteListings {
    type Root = Id014PtkathmaVoteListings;
    type Parent = Id014PtkathmaVoteListings;

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
        *self_rc.len_id_014__ptkathma__vote__listings.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.id_014__ptkathma__vote__listings.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.id_014__ptkathma__vote__listings_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_id_014__ptkathma__vote__listings() as usize)?.into());
                let id_014__ptkathma__vote__listings_raw = self_rc.id_014__ptkathma__vote__listings_raw.borrow();
                let io_id_014__ptkathma__vote__listings_raw = BytesReader::from(id_014__ptkathma__vote__listings_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries>(&io_id_014__ptkathma__vote__listings_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.id_014__ptkathma__vote__listings.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id014PtkathmaVoteListings {
}
impl Id014PtkathmaVoteListings {
    pub fn len_id_014__ptkathma__vote__listings(&self) -> Ref<i32> {
        self.len_id_014__ptkathma__vote__listings.borrow()
    }
}
impl Id014PtkathmaVoteListings {
    pub fn id_014__ptkathma__vote__listings(&self) -> Ref<Vec<OptRc<Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries>>> {
        self.id_014__ptkathma__vote__listings.borrow()
    }
}
impl Id014PtkathmaVoteListings {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id014PtkathmaVoteListings {
    pub fn id_014__ptkathma__vote__listings_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.id_014__ptkathma__vote__listings_raw.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaVoteListings_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaVoteListings_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaVoteListings_PublicKeyHashTag> {
        match flag {
            0 => Ok(Id014PtkathmaVoteListings_PublicKeyHashTag::Ed25519),
            1 => Ok(Id014PtkathmaVoteListings_PublicKeyHashTag::Secp256k1),
            2 => Ok(Id014PtkathmaVoteListings_PublicKeyHashTag::P256),
            _ => Ok(Id014PtkathmaVoteListings_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaVoteListings_PublicKeyHashTag> for i64 {
    fn from(v: &Id014PtkathmaVoteListings_PublicKeyHashTag) -> Self {
        match *v {
            Id014PtkathmaVoteListings_PublicKeyHashTag::Ed25519 => 0,
            Id014PtkathmaVoteListings_PublicKeyHashTag::Secp256k1 => 1,
            Id014PtkathmaVoteListings_PublicKeyHashTag::P256 => 2,
            Id014PtkathmaVoteListings_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaVoteListings_PublicKeyHashTag {
    fn default() -> Self { Id014PtkathmaVoteListings_PublicKeyHashTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
    pub _root: SharedType<Id014PtkathmaVoteListings>,
    pub _parent: SharedType<Id014PtkathmaVoteListings>,
    pub _self: SharedType<Self>,
    pkh: RefCell<OptRc<Id014PtkathmaVoteListings_PublicKeyHash>>,
    voting_power: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
    type Root = Id014PtkathmaVoteListings;
    type Parent = Id014PtkathmaVoteListings;

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
        let t = Self::read_into::<_, Id014PtkathmaVoteListings_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.pkh.borrow_mut() = t;
        *self_rc.voting_power.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
}
impl Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
    pub fn pkh(&self) -> Ref<OptRc<Id014PtkathmaVoteListings_PublicKeyHash>> {
        self.pkh.borrow()
    }
}
impl Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
    pub fn voting_power(&self) -> Ref<i64> {
        self.voting_power.borrow()
    }
}
impl Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, or P256 public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaVoteListings_PublicKeyHash {
    pub _root: SharedType<Id014PtkathmaVoteListings>,
    pub _parent: SharedType<Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<Id014PtkathmaVoteListings_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaVoteListings_PublicKeyHash {
    type Root = Id014PtkathmaVoteListings;
    type Parent = Id014PtkathmaVoteListings_Id014PtkathmaVoteListingsEntries;

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
        if *self_rc.public_key_hash_tag() == Id014PtkathmaVoteListings_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id014PtkathmaVoteListings_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == Id014PtkathmaVoteListings_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<Id014PtkathmaVoteListings_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl Id014PtkathmaVoteListings_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
