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
pub struct Id006PscarthaGasCost {
    pub _root: SharedType<Id006PscarthaGasCost>,
    pub _parent: SharedType<Id006PscarthaGasCost>,
    pub _self: SharedType<Self>,
    allocations: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    steps: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    reads: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    writes: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    bytes_read: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    bytes_written: RefCell<OptRc<Id006PscarthaGasCost_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGasCost {
    type Root = Id006PscarthaGasCost;
    type Parent = Id006PscarthaGasCost;

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
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.allocations.borrow_mut() = t;
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.steps.borrow_mut() = t;
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.reads.borrow_mut() = t;
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.writes.borrow_mut() = t;
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bytes_read.borrow_mut() = t;
        let t = Self::read_into::<_, Id006PscarthaGasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bytes_written.borrow_mut() = t;
        Ok(())
    }
}
impl Id006PscarthaGasCost {
}
impl Id006PscarthaGasCost {
    pub fn allocations(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.allocations.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn steps(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.steps.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn reads(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.reads.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn writes(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.writes.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn bytes_read(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.bytes_read.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn bytes_written(&self) -> Ref<OptRc<Id006PscarthaGasCost_Z>> {
        self.bytes_written.borrow()
    }
}
impl Id006PscarthaGasCost {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaGasCost_Z {
    pub _root: SharedType<Id006PscarthaGasCost>,
    pub _parent: SharedType<Id006PscarthaGasCost>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id006PscarthaGasCost_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGasCost_Z {
    type Root = Id006PscarthaGasCost;
    type Parent = Id006PscarthaGasCost;

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
        *self_rc.has_tail.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.sign.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(6)?;
        _io.align_to_byte()?;
        if (*self_rc.has_tail() as bool) {
            *self_rc.tail.borrow_mut() = Vec::new();
            {
                let mut _i = 0;
                while {
                    let t = Self::read_into::<_, Id006PscarthaGasCost_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                    self_rc.tail.borrow_mut().push(t);
                    let _t_tail = self_rc.tail.borrow();
                    let _tmpa = _t_tail.last().unwrap();
                    _i += 1;
                    let x = !(!((*_tmpa.has_more() as bool)));
                    x
                } {}
            }
        }
        Ok(())
    }
}
impl Id006PscarthaGasCost_Z {
}
impl Id006PscarthaGasCost_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id006PscarthaGasCost_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id006PscarthaGasCost_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id006PscarthaGasCost_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id006PscarthaGasCost_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id006PscarthaGasCost_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaGasCost_NChunk {
    pub _root: SharedType<Id006PscarthaGasCost>,
    pub _parent: SharedType<Id006PscarthaGasCost_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGasCost_NChunk {
    type Root = Id006PscarthaGasCost;
    type Parent = Id006PscarthaGasCost_Z;

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
        *self_rc.has_more.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(7)?;
        Ok(())
    }
}
impl Id006PscarthaGasCost_NChunk {
}
impl Id006PscarthaGasCost_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id006PscarthaGasCost_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id006PscarthaGasCost_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
