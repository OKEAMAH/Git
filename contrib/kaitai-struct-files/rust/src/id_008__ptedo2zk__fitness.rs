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
pub struct Id008Ptedo2zkFitness {
    pub _root: SharedType<Id008Ptedo2zkFitness>,
    pub _parent: SharedType<Id008Ptedo2zkFitness>,
    pub _self: SharedType<Self>,
    fitness: RefCell<OptRc<Id008Ptedo2zkFitness_Fitness>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkFitness {
    type Root = Id008Ptedo2zkFitness;
    type Parent = Id008Ptedo2zkFitness;

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
        let t = Self::read_into::<_, Id008Ptedo2zkFitness_Fitness>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkFitness {
}
impl Id008Ptedo2zkFitness {
    pub fn fitness(&self) -> Ref<OptRc<Id008Ptedo2zkFitness_Fitness>> {
        self.fitness.borrow()
    }
}
impl Id008Ptedo2zkFitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Block fitness: The fitness, or score, of a block, that allow the Tezos to decide which chain is the best. A fitness value is a list of byte sequences. They are compared as follows: shortest lists are smaller; lists of the same length are compared according to the lexicographical order.
 */

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkFitness_Fitness {
    pub _root: SharedType<Id008Ptedo2zkFitness>,
    pub _parent: SharedType<Id008Ptedo2zkFitness>,
    pub _self: SharedType<Self>,
    len_fitness: RefCell<i32>,
    fitness: RefCell<Vec<OptRc<Id008Ptedo2zkFitness_FitnessEntries>>>,
    _io: RefCell<BytesReader>,
    fitness_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id008Ptedo2zkFitness_Fitness {
    type Root = Id008Ptedo2zkFitness;
    type Parent = Id008Ptedo2zkFitness;

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
                let t = Self::read_into::<BytesReader, Id008Ptedo2zkFitness_FitnessEntries>(&io_fitness_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.fitness.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id008Ptedo2zkFitness_Fitness {
}
impl Id008Ptedo2zkFitness_Fitness {
    pub fn len_fitness(&self) -> Ref<i32> {
        self.len_fitness.borrow()
    }
}
impl Id008Ptedo2zkFitness_Fitness {
    pub fn fitness(&self) -> Ref<Vec<OptRc<Id008Ptedo2zkFitness_FitnessEntries>>> {
        self.fitness.borrow()
    }
}
impl Id008Ptedo2zkFitness_Fitness {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id008Ptedo2zkFitness_Fitness {
    pub fn fitness_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.fitness_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkFitness_FitnessEntries {
    pub _root: SharedType<Id008Ptedo2zkFitness>,
    pub _parent: SharedType<Id008Ptedo2zkFitness_Fitness>,
    pub _self: SharedType<Self>,
    fitness__elem: RefCell<OptRc<Id008Ptedo2zkFitness_FitnessElem>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkFitness_FitnessEntries {
    type Root = Id008Ptedo2zkFitness;
    type Parent = Id008Ptedo2zkFitness_Fitness;

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
        let t = Self::read_into::<_, Id008Ptedo2zkFitness_FitnessElem>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fitness__elem.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkFitness_FitnessEntries {
}
impl Id008Ptedo2zkFitness_FitnessEntries {
    pub fn fitness__elem(&self) -> Ref<OptRc<Id008Ptedo2zkFitness_FitnessElem>> {
        self.fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkFitness_FitnessEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkFitness_FitnessElem {
    pub _root: SharedType<Id008Ptedo2zkFitness>,
    pub _parent: SharedType<Id008Ptedo2zkFitness_FitnessEntries>,
    pub _self: SharedType<Self>,
    len_fitness__elem: RefCell<i32>,
    fitness__elem: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkFitness_FitnessElem {
    type Root = Id008Ptedo2zkFitness;
    type Parent = Id008Ptedo2zkFitness_FitnessEntries;

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
impl Id008Ptedo2zkFitness_FitnessElem {
}
impl Id008Ptedo2zkFitness_FitnessElem {
    pub fn len_fitness__elem(&self) -> Ref<i32> {
        self.len_fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkFitness_FitnessElem {
    pub fn fitness__elem(&self) -> Ref<Vec<u8>> {
        self.fitness__elem.borrow()
    }
}
impl Id008Ptedo2zkFitness_FitnessElem {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
