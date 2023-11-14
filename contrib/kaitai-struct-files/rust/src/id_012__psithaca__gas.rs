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
pub struct Id012PsithacaGas {
    pub _root: SharedType<Id012PsithacaGas>,
    pub _parent: SharedType<Id012PsithacaGas>,
    pub _self: SharedType<Self>,
    id_012__psithaca__gas_tag: RefCell<Id012PsithacaGas_Id012PsithacaGasTag>,
    id_012__psithaca__gas_limited: RefCell<OptRc<Id012PsithacaGas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaGas {
    type Root = Id012PsithacaGas;
    type Parent = Id012PsithacaGas;

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
        *self_rc.id_012__psithaca__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.id_012__psithaca__gas_tag() == Id012PsithacaGas_Id012PsithacaGasTag::Limited {
            let t = Self::read_into::<_, Id012PsithacaGas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.id_012__psithaca__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id012PsithacaGas {
}
impl Id012PsithacaGas {
    pub fn id_012__psithaca__gas_tag(&self) -> Ref<Id012PsithacaGas_Id012PsithacaGasTag> {
        self.id_012__psithaca__gas_tag.borrow()
    }
}
impl Id012PsithacaGas {
    pub fn id_012__psithaca__gas_limited(&self) -> Ref<OptRc<Id012PsithacaGas_Z>> {
        self.id_012__psithaca__gas_limited.borrow()
    }
}
impl Id012PsithacaGas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id012PsithacaGas_Id012PsithacaGasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for Id012PsithacaGas_Id012PsithacaGasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id012PsithacaGas_Id012PsithacaGasTag> {
        match flag {
            0 => Ok(Id012PsithacaGas_Id012PsithacaGasTag::Limited),
            1 => Ok(Id012PsithacaGas_Id012PsithacaGasTag::Unaccounted),
            _ => Ok(Id012PsithacaGas_Id012PsithacaGasTag::Unknown(flag)),
        }
    }
}

impl From<&Id012PsithacaGas_Id012PsithacaGasTag> for i64 {
    fn from(v: &Id012PsithacaGas_Id012PsithacaGasTag) -> Self {
        match *v {
            Id012PsithacaGas_Id012PsithacaGasTag::Limited => 0,
            Id012PsithacaGas_Id012PsithacaGasTag::Unaccounted => 1,
            Id012PsithacaGas_Id012PsithacaGasTag::Unknown(v) => v
        }
    }
}

impl Default for Id012PsithacaGas_Id012PsithacaGasTag {
    fn default() -> Self { Id012PsithacaGas_Id012PsithacaGasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaGas_Z {
    pub _root: SharedType<Id012PsithacaGas>,
    pub _parent: SharedType<Id012PsithacaGas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id012PsithacaGas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaGas_Z {
    type Root = Id012PsithacaGas;
    type Parent = Id012PsithacaGas;

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
                    let t = Self::read_into::<_, Id012PsithacaGas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id012PsithacaGas_Z {
}
impl Id012PsithacaGas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id012PsithacaGas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id012PsithacaGas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaGas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id012PsithacaGas_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id012PsithacaGas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaGas_NChunk {
    pub _root: SharedType<Id012PsithacaGas>,
    pub _parent: SharedType<Id012PsithacaGas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaGas_NChunk {
    type Root = Id012PsithacaGas;
    type Parent = Id012PsithacaGas_Z;

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
impl Id012PsithacaGas_NChunk {
}
impl Id012PsithacaGas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id012PsithacaGas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id012PsithacaGas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
