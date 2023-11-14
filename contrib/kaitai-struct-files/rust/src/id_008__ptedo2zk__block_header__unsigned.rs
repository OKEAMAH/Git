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
pub struct Id008Ptedo2zkBlockHeaderUnsigned {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    block_header__shell: RefCell<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell>>,
    id_008__ptedo2zk__block_header__alpha__unsigned_contents: RefCell<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned;

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
        let t = Self::read_into::<_, Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.block_header__shell.borrow_mut() = t;
        let t = Self::read_into::<_, Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_008__ptedo2zk__block_header__alpha__unsigned_contents.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned {
}
impl Id008Ptedo2zkBlockHeaderUnsigned {
    pub fn block_header__shell(&self) -> Ref<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell>> {
        self.block_header__shell.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned {
    pub fn id_008__ptedo2zk__block_header__alpha__unsigned_contents(&self) -> Ref<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents>> {
        self.id_008__ptedo2zk__block_header__alpha__unsigned_contents.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id008Ptedo2zkBlockHeaderUnsigned_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id008Ptedo2zkBlockHeaderUnsigned_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id008Ptedo2zkBlockHeaderUnsigned_Bool> {
        match flag {
            0 => Ok(Id008Ptedo2zkBlockHeaderUnsigned_Bool::False),
            255 => Ok(Id008Ptedo2zkBlockHeaderUnsigned_Bool::True),
            _ => Ok(Id008Ptedo2zkBlockHeaderUnsigned_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id008Ptedo2zkBlockHeaderUnsigned_Bool> for i64 {
    fn from(v: &Id008Ptedo2zkBlockHeaderUnsigned_Bool) -> Self {
        match *v {
            Id008Ptedo2zkBlockHeaderUnsigned_Bool::False => 0,
            Id008Ptedo2zkBlockHeaderUnsigned_Bool::True => 255,
            Id008Ptedo2zkBlockHeaderUnsigned_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id008Ptedo2zkBlockHeaderUnsigned_Bool {
    fn default() -> Self { Id008Ptedo2zkBlockHeaderUnsigned_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries>,
    pub _self: SharedType<Self>,
    len_fitness__elem: RefCell<i32>,
    fitness__elem: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries;

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
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
    pub fn len_fitness__elem(&self) -> Ref<i32> {
        self.len_fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
    pub fn fitness__elem(&self) -> Ref<Vec<u8>> {
        self.fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    priority: RefCell<u16>,
    proof_of_work_nonce: RefCell<Vec<u8>>,
    seed_nonce_hash_tag: RefCell<Id008Ptedo2zkBlockHeaderUnsigned_Bool>,
    seed_nonce_hash: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned;

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
        if *self_rc.seed_nonce_hash_tag() == Id008Ptedo2zkBlockHeaderUnsigned_Bool::True {
            *self_rc.seed_nonce_hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn priority(&self) -> Ref<u16> {
        self.priority.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn proof_of_work_nonce(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_nonce.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash_tag(&self) -> Ref<Id008Ptedo2zkBlockHeaderUnsigned_Bool> {
        self.seed_nonce_hash_tag.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn seed_nonce_hash(&self) -> Ref<Vec<u8>> {
        self.seed_nonce_hash.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Id008Ptedo2zkBlockHeaderAlphaUnsignedContents {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Shell header: Block header's shell-related content. It contains information such as the block level, its predecessor and timestamp.
 */

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    proto: RefCell<u8>,
    predecessor: RefCell<Vec<u8>>,
    timestamp: RefCell<i64>,
    validation_pass: RefCell<u8>,
    operations_hash: RefCell<Vec<u8>>,
    fitness: RefCell<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_Fitness>>,
    context: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned;

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
        let t = Self::read_into::<_, Id008Ptedo2zkBlockHeaderUnsigned_Fitness>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness.borrow_mut() = t;
        *self_rc.context.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn proto(&self) -> Ref<u8> {
        self.proto.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn predecessor(&self) -> Ref<Vec<u8>> {
        self.predecessor.borrow()
    }
}

/**
 * A timestamp as seen by the protocol: second-level precision, epoch based.
 */
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn timestamp(&self) -> Ref<i64> {
        self.timestamp.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn validation_pass(&self) -> Ref<u8> {
        self.validation_pass.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn operations_hash(&self) -> Ref<Vec<u8>> {
        self.operations_hash.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn fitness(&self) -> Ref<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_Fitness>> {
        self.fitness.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn context(&self) -> Ref<Vec<u8>> {
        self.context.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Block fitness: The fitness, or score, of a block, that allow the Tezos to decide which chain is the best. A fitness value is a list of byte sequences. They are compared as follows: shortest lists are smaller; lists of the same length are compared according to the lexicographical order.
 */

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell>,
    pub _self: SharedType<Self>,
    len_fitness: RefCell<i32>,
    fitness: RefCell<Vec<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries>>>,
    _io: RefCell<BytesReader>,
    fitness_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned_BlockHeaderShell;

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
                let t = Self::read_into::<BytesReader, Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries>(&io_fitness_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.fitness.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    pub fn len_fitness(&self) -> Ref<i32> {
        self.len_fitness.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    pub fn fitness(&self) -> Ref<Vec<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries>>> {
        self.fitness.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_Fitness {
    pub fn fitness_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.fitness_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries {
    pub _root: SharedType<Id008Ptedo2zkBlockHeaderUnsigned>,
    pub _parent: SharedType<Id008Ptedo2zkBlockHeaderUnsigned_Fitness>,
    pub _self: SharedType<Self>,
    fitness__elem: RefCell<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries {
    type Root = Id008Ptedo2zkBlockHeaderUnsigned;
    type Parent = Id008Ptedo2zkBlockHeaderUnsigned_Fitness;

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
        let t = Self::read_into::<_, Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness__elem.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries {
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries {
    pub fn fitness__elem(&self) -> Ref<OptRc<Id008Ptedo2zkBlockHeaderUnsigned_FitnessElem>> {
        self.fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkBlockHeaderUnsigned_FitnessEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
