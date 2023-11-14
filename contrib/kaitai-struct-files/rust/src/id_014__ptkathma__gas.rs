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
pub struct Id014PtkathmaGas {
    pub _root: SharedType<Id014PtkathmaGas>,
    pub _parent: SharedType<Id014PtkathmaGas>,
    pub _self: SharedType<Self>,
    id_014__ptkathma__gas_tag: RefCell<Id014PtkathmaGas_Id014PtkathmaGasTag>,
    id_014__ptkathma__gas_limited: RefCell<OptRc<Id014PtkathmaGas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaGas {
    type Root = Id014PtkathmaGas;
    type Parent = Id014PtkathmaGas;

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
        *self_rc.id_014__ptkathma__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.id_014__ptkathma__gas_tag() == Id014PtkathmaGas_Id014PtkathmaGasTag::Limited {
            let t = Self::read_into::<_, Id014PtkathmaGas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.id_014__ptkathma__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id014PtkathmaGas {
}
impl Id014PtkathmaGas {
    pub fn id_014__ptkathma__gas_tag(&self) -> Ref<Id014PtkathmaGas_Id014PtkathmaGasTag> {
        self.id_014__ptkathma__gas_tag.borrow()
    }
}
impl Id014PtkathmaGas {
    pub fn id_014__ptkathma__gas_limited(&self) -> Ref<OptRc<Id014PtkathmaGas_Z>> {
        self.id_014__ptkathma__gas_limited.borrow()
    }
}
impl Id014PtkathmaGas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id014PtkathmaGas_Id014PtkathmaGasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for Id014PtkathmaGas_Id014PtkathmaGasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id014PtkathmaGas_Id014PtkathmaGasTag> {
        match flag {
            0 => Ok(Id014PtkathmaGas_Id014PtkathmaGasTag::Limited),
            1 => Ok(Id014PtkathmaGas_Id014PtkathmaGasTag::Unaccounted),
            _ => Ok(Id014PtkathmaGas_Id014PtkathmaGasTag::Unknown(flag)),
        }
    }
}

impl From<&Id014PtkathmaGas_Id014PtkathmaGasTag> for i64 {
    fn from(v: &Id014PtkathmaGas_Id014PtkathmaGasTag) -> Self {
        match *v {
            Id014PtkathmaGas_Id014PtkathmaGasTag::Limited => 0,
            Id014PtkathmaGas_Id014PtkathmaGasTag::Unaccounted => 1,
            Id014PtkathmaGas_Id014PtkathmaGasTag::Unknown(v) => v
        }
    }
}

impl Default for Id014PtkathmaGas_Id014PtkathmaGasTag {
    fn default() -> Self { Id014PtkathmaGas_Id014PtkathmaGasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaGas_Z {
    pub _root: SharedType<Id014PtkathmaGas>,
    pub _parent: SharedType<Id014PtkathmaGas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id014PtkathmaGas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaGas_Z {
    type Root = Id014PtkathmaGas;
    type Parent = Id014PtkathmaGas;

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
                    let t = Self::read_into::<_, Id014PtkathmaGas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id014PtkathmaGas_Z {
}
impl Id014PtkathmaGas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id014PtkathmaGas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id014PtkathmaGas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id014PtkathmaGas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id014PtkathmaGas_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id014PtkathmaGas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id014PtkathmaGas_NChunk {
    pub _root: SharedType<Id014PtkathmaGas>,
    pub _parent: SharedType<Id014PtkathmaGas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaGas_NChunk {
    type Root = Id014PtkathmaGas;
    type Parent = Id014PtkathmaGas_Z;

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
impl Id014PtkathmaGas_NChunk {
}
impl Id014PtkathmaGas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id014PtkathmaGas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id014PtkathmaGas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
