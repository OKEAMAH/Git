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
pub struct AlphaBlockHeaderUnsigned {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    block_header__shell: RefCell<OptRc<AlphaBlockHeaderUnsigned_BlockHeaderShell>>,
    alpha__block_header__alpha__unsigned_contents: RefCell<OptRc<AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderUnsigned {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned;

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
        let t = Self::read_into::<_, AlphaBlockHeaderUnsigned_BlockHeaderShell>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.block_header__shell.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.alpha__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaBlockHeaderUnsigned {
}
impl AlphaBlockHeaderUnsigned {
    pub fn block_header__shell(&self) -> Ref<OptRc<AlphaBlockHeaderUnsigned_BlockHeaderShell>> {
        self.block_header__shell.borrow()
    }
}
impl AlphaBlockHeaderUnsigned {
    pub fn alpha__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents>> {
        self.alpha__block_header__alpha__unsigned_contents.borrow()
    }
}
impl AlphaBlockHeaderUnsigned {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag {
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

impl TryFrom<i64> for AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag> {
        match flag {
            0 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case0),
            1 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case1),
            2 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case2),
            4 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case4),
            5 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case5),
            6 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case6),
            8 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case8),
            9 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case9),
            10 => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case10),
            _ => Ok(AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag> for i64 {
    fn from(v: &AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag) -> Self {
        match *v {
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case0 => 0,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case1 => 1,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case2 => 2,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case4 => 4,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case5 => 5,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case6 => 6,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case8 => 8,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case9 => 9,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Case10 => 10,
            AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag {
    fn default() -> Self { AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag::Unknown(0) }
}

#[derive(Debug, PartialEq, Clone)]
pub enum AlphaBlockHeaderUnsigned_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaBlockHeaderUnsigned_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaBlockHeaderUnsigned_Bool> {
        match flag {
            0 => Ok(AlphaBlockHeaderUnsigned_Bool::False),
            255 => Ok(AlphaBlockHeaderUnsigned_Bool::True),
            _ => Ok(AlphaBlockHeaderUnsigned_Bool::Unknown(flag)),
        }
    }
}

impl From<&AlphaBlockHeaderUnsigned_Bool> for i64 {
    fn from(v: &AlphaBlockHeaderUnsigned_Bool) -> Self {
        match *v {
            AlphaBlockHeaderUnsigned_Bool::False => 0,
            AlphaBlockHeaderUnsigned_Bool::True => 255,
            AlphaBlockHeaderUnsigned_Bool::Unknown(v) => v
        }
    }
}

impl Default for AlphaBlockHeaderUnsigned_Bool {
    fn default() -> Self { AlphaBlockHeaderUnsigned_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderUnsigned_FitnessElem {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned_FitnessEntries>,
    pub _self: SharedType<Self>,
    len_fitness__elem: RefCell<i32>,
    fitness__elem: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderUnsigned_FitnessElem {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned_FitnessEntries;

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
impl AlphaBlockHeaderUnsigned_FitnessElem {
}
impl AlphaBlockHeaderUnsigned_FitnessElem {
    pub fn len_fitness__elem(&self) -> Ref<i32> {
        self.len_fitness__elem.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_FitnessElem {
    pub fn fitness__elem(&self) -> Ref<Vec<u8>> {
        self.fitness__elem.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_FitnessElem {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Shell header: Block header's shell-related content. It contains information such as the block level, its predecessor and timestamp.
 */

#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    proto: RefCell<u8>,
    predecessor: RefCell<Vec<u8>>,
    timestamp: RefCell<i64>,
    validation_pass: RefCell<u8>,
    operations_hash: RefCell<Vec<u8>>,
    fitness: RefCell<OptRc<AlphaBlockHeaderUnsigned_Fitness>>,
    context: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderUnsigned_BlockHeaderShell {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned;

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
        let t = Self::read_into::<_, AlphaBlockHeaderUnsigned_Fitness>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness.borrow_mut() = t;
        *self_rc.context.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn proto(&self) -> Ref<u8> {
        self.proto.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn predecessor(&self) -> Ref<Vec<u8>> {
        self.predecessor.borrow()
    }
}

/**
 * A timestamp as seen by the protocol: second-level precision, epoch based.
 */
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn timestamp(&self) -> Ref<i64> {
        self.timestamp.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn validation_pass(&self) -> Ref<u8> {
        self.validation_pass.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn operations_hash(&self) -> Ref<Vec<u8>> {
        self.operations_hash.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn fitness(&self) -> Ref<OptRc<AlphaBlockHeaderUnsigned_Fitness>> {
        self.fitness.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn context(&self) -> Ref<Vec<u8>> {
        self.context.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_BlockHeaderShell {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Block fitness: The fitness, or score, of a block, that allow the Tezos to decide which chain is the best. A fitness value is a list of byte sequences. They are compared as follows: shortest lists are smaller; lists of the same length are compared according to the lexicographical order.
 */

#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderUnsigned_Fitness {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned_BlockHeaderShell>,
    pub _self: SharedType<Self>,
    len_fitness: RefCell<i32>,
    fitness: RefCell<Vec<OptRc<AlphaBlockHeaderUnsigned_FitnessEntries>>>,
    _io: RefCell<BytesReader>,
    fitness_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for AlphaBlockHeaderUnsigned_Fitness {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned_BlockHeaderShell;

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
                let t = Self::read_into::<BytesReader, AlphaBlockHeaderUnsigned_FitnessEntries>(&io_fitness_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.fitness.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl AlphaBlockHeaderUnsigned_Fitness {
}
impl AlphaBlockHeaderUnsigned_Fitness {
    pub fn len_fitness(&self) -> Ref<i32> {
        self.len_fitness.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_Fitness {
    pub fn fitness(&self) -> Ref<Vec<OptRc<AlphaBlockHeaderUnsigned_FitnessEntries>>> {
        self.fitness.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_Fitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_Fitness {
    pub fn fitness_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.fitness_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    payload_hash: RefCell<Vec<u8>>,
    payload_round: RefCell<i32>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<AlphaBlockHeaderUnsigned_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    per_block_votes: RefCell<AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned;

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
        if *self_rc.seed_nonce_hash_tag() == AlphaBlockHeaderUnsigned_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.per_block_votes.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        Ok(())
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_hash(&self) -> Ref<Vec<u8>> {
        self.payload_hash.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn payload_round(&self) -> Ref<i32> {
        self.payload_round.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<AlphaBlockHeaderUnsigned_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn per_block_votes(&self) -> Ref<AlphaBlockHeaderUnsigned_AlphaPerBlockVotesTag> {
        self.per_block_votes.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_AlphaBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaBlockHeaderUnsigned_FitnessEntries {
    pub _root: SharedType<AlphaBlockHeaderUnsigned>,
    pub _parent: SharedType<AlphaBlockHeaderUnsigned_Fitness>,
    pub _self: SharedType<Self>,
    fitness__elem: RefCell<OptRc<AlphaBlockHeaderUnsigned_FitnessElem>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaBlockHeaderUnsigned_FitnessEntries {
    type Root = AlphaBlockHeaderUnsigned;
    type Parent = AlphaBlockHeaderUnsigned_Fitness;

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
        let t = Self::read_into::<_, AlphaBlockHeaderUnsigned_FitnessElem>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness__elem.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaBlockHeaderUnsigned_FitnessEntries {
}
impl AlphaBlockHeaderUnsigned_FitnessEntries {
    pub fn fitness__elem(&self) -> Ref<OptRc<AlphaBlockHeaderUnsigned_FitnessElem>> {
        self.fitness__elem.borrow()
    }
}
impl AlphaBlockHeaderUnsigned_FitnessEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
