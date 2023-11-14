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
pub struct AlphaVoteListings {
    pub _root: SharedType<AlphaVoteListings>,
    pub _parent: SharedType<AlphaVoteListings>,
    pub _self: SharedType<Self>,
    len_alpha__vote__listings: RefCell<i32>,
    alpha__vote__listings: RefCell<Vec<OptRc<AlphaVoteListings_AlphaVoteListingsEntries>>>,
    _io: RefCell<BytesReader>,
    alpha__vote__listings_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for AlphaVoteListings {
    type Root = AlphaVoteListings;
    type Parent = AlphaVoteListings;

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
        *self_rc.len_alpha__vote__listings.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.alpha__vote__listings.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.alpha__vote__listings_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_alpha__vote__listings() as usize)?.into());
                let alpha__vote__listings_raw = self_rc.alpha__vote__listings_raw.borrow();
                let io_alpha__vote__listings_raw = BytesReader::from(alpha__vote__listings_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, AlphaVoteListings_AlphaVoteListingsEntries>(&io_alpha__vote__listings_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.alpha__vote__listings.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl AlphaVoteListings {
}
impl AlphaVoteListings {
    pub fn len_alpha__vote__listings(&self) -> Ref<i32> {
        self.len_alpha__vote__listings.borrow()
    }
}
impl AlphaVoteListings {
    pub fn alpha__vote__listings(&self) -> Ref<Vec<OptRc<AlphaVoteListings_AlphaVoteListingsEntries>>> {
        self.alpha__vote__listings.borrow()
    }
}
impl AlphaVoteListings {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl AlphaVoteListings {
    pub fn alpha__vote__listings_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.alpha__vote__listings_raw.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaVoteListings_PublicKeyHashTag {
    Ed25519,
    Secp256k1,
    P256,
    Bls,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaVoteListings_PublicKeyHashTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaVoteListings_PublicKeyHashTag> {
        match flag {
            0 => Ok(AlphaVoteListings_PublicKeyHashTag::Ed25519),
            1 => Ok(AlphaVoteListings_PublicKeyHashTag::Secp256k1),
            2 => Ok(AlphaVoteListings_PublicKeyHashTag::P256),
            3 => Ok(AlphaVoteListings_PublicKeyHashTag::Bls),
            _ => Ok(AlphaVoteListings_PublicKeyHashTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaVoteListings_PublicKeyHashTag> for i64 {
    fn from(v: &AlphaVoteListings_PublicKeyHashTag) -> Self {
        match *v {
            AlphaVoteListings_PublicKeyHashTag::Ed25519 => 0,
            AlphaVoteListings_PublicKeyHashTag::Secp256k1 => 1,
            AlphaVoteListings_PublicKeyHashTag::P256 => 2,
            AlphaVoteListings_PublicKeyHashTag::Bls => 3,
            AlphaVoteListings_PublicKeyHashTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaVoteListings_PublicKeyHashTag {
    fn default() -> Self { AlphaVoteListings_PublicKeyHashTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaVoteListings_AlphaVoteListingsEntries {
    pub _root: SharedType<AlphaVoteListings>,
    pub _parent: SharedType<AlphaVoteListings>,
    pub _self: SharedType<Self>,
    pkh: RefCell<OptRc<AlphaVoteListings_PublicKeyHash>>,
    voting_power: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaVoteListings_AlphaVoteListingsEntries {
    type Root = AlphaVoteListings;
    type Parent = AlphaVoteListings;

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
        let t = Self::read_into::<_, AlphaVoteListings_PublicKeyHash>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.pkh.borrow_mut() = t;
        *self_rc.voting_power.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl AlphaVoteListings_AlphaVoteListingsEntries {
}
impl AlphaVoteListings_AlphaVoteListingsEntries {
    pub fn pkh(&self) -> Ref<OptRc<AlphaVoteListings_PublicKeyHash>> {
        self.pkh.borrow()
    }
}
impl AlphaVoteListings_AlphaVoteListingsEntries {
    pub fn voting_power(&self) -> Ref<i64> {
        self.voting_power.borrow()
    }
}
impl AlphaVoteListings_AlphaVoteListingsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A Ed25519, Secp256k1, P256, or BLS public key hash
 */

#[derive(Default, Debug, Clone)]
pub struct AlphaVoteListings_PublicKeyHash {
    pub _root: SharedType<AlphaVoteListings>,
    pub _parent: SharedType<AlphaVoteListings_AlphaVoteListingsEntries>,
    pub _self: SharedType<Self>,
    public_key_hash_tag: RefCell<AlphaVoteListings_PublicKeyHashTag>,
    public_key_hash_ed25519: RefCell<Vec<u8>>,
    public_key_hash_secp256k1: RefCell<Vec<u8>>,
    public_key_hash_p256: RefCell<Vec<u8>>,
    public_key_hash_bls: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaVoteListings_PublicKeyHash {
    type Root = AlphaVoteListings;
    type Parent = AlphaVoteListings_AlphaVoteListingsEntries;

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
        if *self_rc.public_key_hash_tag() == AlphaVoteListings_PublicKeyHashTag::Ed25519 {
            *self_rc.public_key_hash_ed25519.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaVoteListings_PublicKeyHashTag::Secp256k1 {
            *self_rc.public_key_hash_secp256k1.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaVoteListings_PublicKeyHashTag::P256 {
            *self_rc.public_key_hash_p256.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        if *self_rc.public_key_hash_tag() == AlphaVoteListings_PublicKeyHashTag::Bls {
            *self_rc.public_key_hash_bls.borrow_mut() = _io.read_bytes(20 as usize)?.into();
        }
        Ok(())
    }
}
impl AlphaVoteListings_PublicKeyHash {
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn public_key_hash_tag(&self) -> Ref<AlphaVoteListings_PublicKeyHashTag> {
        self.public_key_hash_tag.borrow()
    }
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn public_key_hash_ed25519(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_ed25519.borrow()
    }
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn public_key_hash_secp256k1(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_secp256k1.borrow()
    }
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn public_key_hash_p256(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_p256.borrow()
    }
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn public_key_hash_bls(&self) -> Ref<Vec<u8>> {
        self.public_key_hash_bls.borrow()
    }
}
impl AlphaVoteListings_PublicKeyHash {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
