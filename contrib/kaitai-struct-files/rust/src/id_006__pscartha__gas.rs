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
pub struct Id006PscarthaGas {
    pub _root: SharedType<Id006PscarthaGas>,
    pub _parent: SharedType<Id006PscarthaGas>,
    pub _self: SharedType<Self>,
    id_006__pscartha__gas_tag: RefCell<Id006PscarthaGas_Id006PscarthaGasTag>,
    id_006__pscartha__gas_limited: RefCell<OptRc<Id006PscarthaGas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGas {
    type Root = Id006PscarthaGas;
    type Parent = Id006PscarthaGas;

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
        *self_rc.id_006__pscartha__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.id_006__pscartha__gas_tag() == Id006PscarthaGas_Id006PscarthaGasTag::Limited {
            let t = Self::read_into::<_, Id006PscarthaGas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.id_006__pscartha__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id006PscarthaGas {
}
impl Id006PscarthaGas {
    pub fn id_006__pscartha__gas_tag(&self) -> Ref<Id006PscarthaGas_Id006PscarthaGasTag> {
        self.id_006__pscartha__gas_tag.borrow()
    }
}
impl Id006PscarthaGas {
    pub fn id_006__pscartha__gas_limited(&self) -> Ref<OptRc<Id006PscarthaGas_Z>> {
        self.id_006__pscartha__gas_limited.borrow()
    }
}
impl Id006PscarthaGas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id006PscarthaGas_Id006PscarthaGasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for Id006PscarthaGas_Id006PscarthaGasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id006PscarthaGas_Id006PscarthaGasTag> {
        match flag {
            0 => Ok(Id006PscarthaGas_Id006PscarthaGasTag::Limited),
            1 => Ok(Id006PscarthaGas_Id006PscarthaGasTag::Unaccounted),
            _ => Ok(Id006PscarthaGas_Id006PscarthaGasTag::Unknown(flag)),
        }
    }
}

impl From<&Id006PscarthaGas_Id006PscarthaGasTag> for i64 {
    fn from(v: &Id006PscarthaGas_Id006PscarthaGasTag) -> Self {
        match *v {
            Id006PscarthaGas_Id006PscarthaGasTag::Limited => 0,
            Id006PscarthaGas_Id006PscarthaGasTag::Unaccounted => 1,
            Id006PscarthaGas_Id006PscarthaGasTag::Unknown(v) => v
        }
    }
}

impl Default for Id006PscarthaGas_Id006PscarthaGasTag {
    fn default() -> Self { Id006PscarthaGas_Id006PscarthaGasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaGas_Z {
    pub _root: SharedType<Id006PscarthaGas>,
    pub _parent: SharedType<Id006PscarthaGas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id006PscarthaGas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGas_Z {
    type Root = Id006PscarthaGas;
    type Parent = Id006PscarthaGas;

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
                    let t = Self::read_into::<_, Id006PscarthaGas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id006PscarthaGas_Z {
}
impl Id006PscarthaGas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id006PscarthaGas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id006PscarthaGas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id006PscarthaGas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id006PscarthaGas_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id006PscarthaGas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id006PscarthaGas_NChunk {
    pub _root: SharedType<Id006PscarthaGas>,
    pub _parent: SharedType<Id006PscarthaGas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaGas_NChunk {
    type Root = Id006PscarthaGas;
    type Parent = Id006PscarthaGas_Z;

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
impl Id006PscarthaGas_NChunk {
}
impl Id006PscarthaGas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id006PscarthaGas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id006PscarthaGas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
