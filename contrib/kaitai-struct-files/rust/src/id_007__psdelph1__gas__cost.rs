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
pub struct Id007Psdelph1GasCost {
    pub _root: SharedType<Id007Psdelph1GasCost>,
    pub _parent: SharedType<Id007Psdelph1GasCost>,
    pub _self: SharedType<Self>,
    id_007__psdelph1__gas__cost: RefCell<OptRc<Id007Psdelph1GasCost_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1GasCost {
    type Root = Id007Psdelph1GasCost;
    type Parent = Id007Psdelph1GasCost;

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
        let t = Self::read_into::<_, Id007Psdelph1GasCost_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_007__psdelph1__gas__cost.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1GasCost {
}
impl Id007Psdelph1GasCost {
    pub fn id_007__psdelph1__gas__cost(&self) -> Ref<OptRc<Id007Psdelph1GasCost_Z>> {
        self.id_007__psdelph1__gas__cost.borrow()
    }
}
impl Id007Psdelph1GasCost {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1GasCost_Z {
    pub _root: SharedType<Id007Psdelph1GasCost>,
    pub _parent: SharedType<Id007Psdelph1GasCost>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id007Psdelph1GasCost_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1GasCost_Z {
    type Root = Id007Psdelph1GasCost;
    type Parent = Id007Psdelph1GasCost;

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
                    let t = Self::read_into::<_, Id007Psdelph1GasCost_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id007Psdelph1GasCost_Z {
}
impl Id007Psdelph1GasCost_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id007Psdelph1GasCost_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id007Psdelph1GasCost_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id007Psdelph1GasCost_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id007Psdelph1GasCost_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id007Psdelph1GasCost_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1GasCost_NChunk {
    pub _root: SharedType<Id007Psdelph1GasCost>,
    pub _parent: SharedType<Id007Psdelph1GasCost_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1GasCost_NChunk {
    type Root = Id007Psdelph1GasCost;
    type Parent = Id007Psdelph1GasCost_Z;

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
impl Id007Psdelph1GasCost_NChunk {
}
impl Id007Psdelph1GasCost_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id007Psdelph1GasCost_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id007Psdelph1GasCost_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
