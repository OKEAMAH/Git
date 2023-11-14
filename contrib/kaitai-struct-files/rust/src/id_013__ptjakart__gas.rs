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
pub struct Id013PtjakartGas {
    pub _root: SharedType<Id013PtjakartGas>,
    pub _parent: SharedType<Id013PtjakartGas>,
    pub _self: SharedType<Self>,
    id_013__ptjakart__gas_tag: RefCell<Id013PtjakartGas_Id013PtjakartGasTag>,
    id_013__ptjakart__gas_limited: RefCell<OptRc<Id013PtjakartGas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartGas {
    type Root = Id013PtjakartGas;
    type Parent = Id013PtjakartGas;

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
        *self_rc.id_013__ptjakart__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.id_013__ptjakart__gas_tag() == Id013PtjakartGas_Id013PtjakartGasTag::Limited {
            let t = Self::read_into::<_, Id013PtjakartGas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.id_013__ptjakart__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id013PtjakartGas {
}
impl Id013PtjakartGas {
    pub fn id_013__ptjakart__gas_tag(&self) -> Ref<Id013PtjakartGas_Id013PtjakartGasTag> {
        self.id_013__ptjakart__gas_tag.borrow()
    }
}
impl Id013PtjakartGas {
    pub fn id_013__ptjakart__gas_limited(&self) -> Ref<OptRc<Id013PtjakartGas_Z>> {
        self.id_013__ptjakart__gas_limited.borrow()
    }
}
impl Id013PtjakartGas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id013PtjakartGas_Id013PtjakartGasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for Id013PtjakartGas_Id013PtjakartGasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id013PtjakartGas_Id013PtjakartGasTag> {
        match flag {
            0 => Ok(Id013PtjakartGas_Id013PtjakartGasTag::Limited),
            1 => Ok(Id013PtjakartGas_Id013PtjakartGasTag::Unaccounted),
            _ => Ok(Id013PtjakartGas_Id013PtjakartGasTag::Unknown(flag)),
        }
    }
}

impl From<&Id013PtjakartGas_Id013PtjakartGasTag> for i64 {
    fn from(v: &Id013PtjakartGas_Id013PtjakartGasTag) -> Self {
        match *v {
            Id013PtjakartGas_Id013PtjakartGasTag::Limited => 0,
            Id013PtjakartGas_Id013PtjakartGasTag::Unaccounted => 1,
            Id013PtjakartGas_Id013PtjakartGasTag::Unknown(v) => v
        }
    }
}

impl Default for Id013PtjakartGas_Id013PtjakartGasTag {
    fn default() -> Self { Id013PtjakartGas_Id013PtjakartGasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id013PtjakartGas_Z {
    pub _root: SharedType<Id013PtjakartGas>,
    pub _parent: SharedType<Id013PtjakartGas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id013PtjakartGas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartGas_Z {
    type Root = Id013PtjakartGas;
    type Parent = Id013PtjakartGas;

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
                    let t = Self::read_into::<_, Id013PtjakartGas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id013PtjakartGas_Z {
}
impl Id013PtjakartGas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id013PtjakartGas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id013PtjakartGas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id013PtjakartGas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id013PtjakartGas_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id013PtjakartGas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id013PtjakartGas_NChunk {
    pub _root: SharedType<Id013PtjakartGas>,
    pub _parent: SharedType<Id013PtjakartGas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartGas_NChunk {
    type Root = Id013PtjakartGas;
    type Parent = Id013PtjakartGas_Z;

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
impl Id013PtjakartGas_NChunk {
}
impl Id013PtjakartGas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id013PtjakartGas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id013PtjakartGas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
