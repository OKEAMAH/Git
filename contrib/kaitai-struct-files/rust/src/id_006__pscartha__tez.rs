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
pub struct Id006PscarthaTez {
    pub _root: SharedType<Id006PscarthaTez>,
    pub _parent: SharedType<Id006PscarthaTez>,
    pub _self: SharedType<Self>,
    id_006__pscartha__mutez: RefCell<OptRc<Id006PscarthaTez_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaTez {
    type Root = Id006PscarthaTez;
    type Parent = Id006PscarthaTez;

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
        let t = Self::read_into::<_, Id006PscarthaTez_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_006__pscartha__mutez.borrow_mut() = t;
        Ok(())
    }
}
impl Id006PscarthaTez {
}
impl Id006PscarthaTez {
    pub fn id_006__pscartha__mutez(&self) -> Ref<OptRc<Id006PscarthaTez_N>> {
        self.id_006__pscartha__mutez.borrow()
    }
}
impl Id006PscarthaTez {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaTez_N {
    pub _root: SharedType<Id006PscarthaTez>,
    pub _parent: SharedType<Id006PscarthaTez>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id006PscarthaTez_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaTez_N {
    type Root = Id006PscarthaTez;
    type Parent = Id006PscarthaTez;

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
        *self_rc.n.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while {
                let t = Self::read_into::<_, Id006PscarthaTez_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.n.borrow_mut().push(t);
                let _t_n = self_rc.n.borrow();
                let _tmpa = _t_n.last().unwrap();
                _i += 1;
                let x = !(!((*_tmpa.has_more() as bool)));
                x
            } {}
        }
        Ok(())
    }
}
impl Id006PscarthaTez_N {
}
impl Id006PscarthaTez_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id006PscarthaTez_NChunk>>> {
        self.n.borrow()
    }
}
impl Id006PscarthaTez_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaTez_NChunk {
    pub _root: SharedType<Id006PscarthaTez>,
    pub _parent: SharedType<Id006PscarthaTez_N>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaTez_NChunk {
    type Root = Id006PscarthaTez;
    type Parent = Id006PscarthaTez_N;

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
impl Id006PscarthaTez_NChunk {
}
impl Id006PscarthaTez_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id006PscarthaTez_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id006PscarthaTez_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
