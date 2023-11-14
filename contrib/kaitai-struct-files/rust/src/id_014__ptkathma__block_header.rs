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
pub struct Id014PtkathmaBlockHeader {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__block_header__alpha__full_header: RefCell<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_014__ptkathma__block_header__alpha__full_header.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader {
}
impl Id014PtkathmaBlockHeader {
    pub fn id_014__ptkathma__block_header__alpha__full_header(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader>> {
        self.id_014__ptkathma__block_header__alpha__full_header.borrow()
    }
}
impl Id014PtkathmaBlockHeader {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaBlockHeader_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaBlockHeader_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaBlockHeader_Bool> {
        match flag {
            0 => Ok(Id014PtkathmaBlockHeader_Bool::False),
            255 => Ok(Id014PtkathmaBlockHeader_Bool::True),
            _ => Ok(Id014PtkathmaBlockHeader_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaBlockHeader_Bool> for i64 {
    fn from(v: &Id014PtkathmaBlockHeader_Bool) -> Self {
        match *v {
            Id014PtkathmaBlockHeader_Bool::False => 0,
            Id014PtkathmaBlockHeader_Bool::True => 255,
            Id014PtkathmaBlockHeader_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaBlockHeader_Bool {
    fn default() -> Self { Id014PtkathmaBlockHeader_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_FitnessElem {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_FitnessEntries>,
    pub _self: SharedType<Self>,
    len_fitness__elem: RefCell<i32>,
    fitness__elem: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_FitnessElem {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_FitnessEntries;

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
        *self_rc.len_fitness__elem.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.fitness__elem.borrow_mut() = _io.read_bytes(*self_rc.len_fitness__elem() as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_FitnessElem {
}
impl Id014PtkathmaBlockHeader_FitnessElem {
    pub fn len_fitness__elem(&self) -> Ref<i32> {
        self.len_fitness__elem.borrow()
    }
}
impl Id014PtkathmaBlockHeader_FitnessElem {
    pub fn fitness__elem(&self) -> Ref<Vec<u8>> {
        self.fitness__elem.borrow()
    }
}
impl Id014PtkathmaBlockHeader_FitnessElem {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id014PtkathmaBlockHeader_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    liquidity_baking_toggle_vote: RefCell<i8>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents;

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
        if *self_rc.seed_nonce_hash_tag() == Id014PtkathmaBlockHeader_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.liquidity_baking_toggle_vote.borrow_mut() = _io.read_s1()?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id014PtkathmaBlockHeader_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn liquidity_baking_toggle_vote(&self) -> Ref<i8> {
        self.liquidity_baking_toggle_vote.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__block_header__alpha__unsigned_contents: RefCell<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_014__ptkathma__block_header__alpha__unsigned_contents.borrow_mut() = t;
        *self_rc.signature.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn id_014__ptkathma__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaUnsignedContents>> {
        self.id_014__ptkathma__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Shell header: Block header's shell-related content. It contains information such as the block level, its predecessor and timestamp.
 */

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    proto: RefCell<u8>,
    predecessor: RefCell<Vec<u8>>,
    timestamp: RefCell<i64>,
    validation_pass: RefCell<u8>,
    operations_hash: RefCell<Vec<u8>>,
    fitness: RefCell<OptRc<Id014PtkathmaBlockHeader_Fitness>>,
    context: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_BlockHeaderShell {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader;

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
        *self_rc.level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.proto.borrow_mut() = _io.read_u1()?.into();
        *self_rc.predecessor.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.timestamp.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.validation_pass.borrow_mut() = _io.read_u1()?.into();
        *self_rc.operations_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_Fitness>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness.borrow_mut() = t;
        *self_rc.context.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn proto(&self) -> Ref<u8> {
        self.proto.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn predecessor(&self) -> Ref<Vec<u8>> {
        self.predecessor.borrow()
    }
}

/**
 * A timestamp as seen by the protocol: second-level precision, epoch based.
 */
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn timestamp(&self) -> Ref<i64> {
        self.timestamp.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn validation_pass(&self) -> Ref<u8> {
        self.validation_pass.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn operations_hash(&self) -> Ref<Vec<u8>> {
        self.operations_hash.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn fitness(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_Fitness>> {
        self.fitness.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn context(&self) -> Ref<Vec<u8>> {
        self.context.borrow()
    }
}
impl Id014PtkathmaBlockHeader_BlockHeaderShell {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Block fitness: The fitness, or score, of a block, that allow the Tezos to decide which chain is the best. A fitness value is a list of byte sequences. They are compared as follows: shortest lists are smaller; lists of the same length are compared according to the lexicographical order.
 */

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_Fitness {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_BlockHeaderShell>,
    pub _self: SharedType<Self>,
    len_fitness: RefCell<i32>,
    fitness: RefCell<Vec<OptRc<Id014PtkathmaBlockHeader_FitnessEntries>>>,
    _io: RefCell<BytesReader>,
    fitness_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id014PtkathmaBlockHeader_Fitness {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_BlockHeaderShell;

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
        *self_rc.len_fitness.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.fitness.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.fitness_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_fitness() as usize)?.into());
                let fitness_raw = self_rc.fitness_raw.borrow();
                let io_fitness_raw = BytesReader::from(fitness_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id014PtkathmaBlockHeader_FitnessEntries>(&io_fitness_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.fitness.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_Fitness {
}
impl Id014PtkathmaBlockHeader_Fitness {
    pub fn len_fitness(&self) -> Ref<i32> {
        self.len_fitness.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Fitness {
    pub fn fitness(&self) -> Ref<Vec<OptRc<Id014PtkathmaBlockHeader_FitnessEntries>>> {
        self.fitness.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Fitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Fitness {
    pub fn fitness_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.fitness_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_FitnessEntries {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader_Fitness>,
    pub _self: SharedType<Self>,
    fitness__elem: RefCell<OptRc<Id014PtkathmaBlockHeader_FitnessElem>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_FitnessEntries {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader_Fitness;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_FitnessElem>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness__elem.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_FitnessEntries {
}
impl Id014PtkathmaBlockHeader_FitnessEntries {
    pub fn fitness__elem(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_FitnessElem>> {
        self.fitness__elem.borrow()
    }
}
impl Id014PtkathmaBlockHeader_FitnessEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
    pub _root: SharedType<Id014PtkathmaBlockHeader>,
    pub _parent: SharedType<Id014PtkathmaBlockHeader>,
    pub _self: SharedType<Self>,
    block_header__shell: RefCell<OptRc<Id014PtkathmaBlockHeader_BlockHeaderShell>>,
    id_014__ptkathma__block_header__alpha__signed_contents: RefCell<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
    type Root = Id014PtkathmaBlockHeader;
    type Parent = Id014PtkathmaBlockHeader;

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
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_BlockHeaderShell>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.block_header__shell.borrow_mut() = t;
        let t = Self::read_into::<_, Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_014__ptkathma__block_header__alpha__signed_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
    pub fn block_header__shell(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_BlockHeaderShell>> {
        self.block_header__shell.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
    pub fn id_014__ptkathma__block_header__alpha__signed_contents(&self) -> Ref<OptRc<Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaSignedContents>> {
        self.id_014__ptkathma__block_header__alpha__signed_contents.borrow()
    }
}
impl Id014PtkathmaBlockHeader_Id014PtkathmaBlockHeaderAlphaFullHeader {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
