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
pub struct AlphaGas {
    pub _root: SharedType<AlphaGas>,
    pub _parent: SharedType<AlphaGas>,
    pub _self: SharedType<Self>,
    alpha__gas_tag: RefCell<AlphaGas_AlphaGasTag>,
    alpha__gas_limited: RefCell<OptRc<AlphaGas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaGas {
    type Root = AlphaGas;
    type Parent = AlphaGas;

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
        *self_rc.alpha__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.alpha__gas_tag() == AlphaGas_AlphaGasTag::Limited {
            let t = Self::read_into::<_, AlphaGas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.alpha__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl AlphaGas {
}
impl AlphaGas {
    pub fn alpha__gas_tag(&self) -> Ref<AlphaGas_AlphaGasTag> {
        self.alpha__gas_tag.borrow()
    }
}
impl AlphaGas {
    pub fn alpha__gas_limited(&self) -> Ref<OptRc<AlphaGas_Z>> {
        self.alpha__gas_limited.borrow()
    }
}
impl AlphaGas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum AlphaGas_AlphaGasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for AlphaGas_AlphaGasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<AlphaGas_AlphaGasTag> {
        match flag {
            0 => Ok(AlphaGas_AlphaGasTag::Limited),
            1 => Ok(AlphaGas_AlphaGasTag::Unaccounted),
            _ => Ok(AlphaGas_AlphaGasTag::Unknown(flag)),
        }
    }
}

impl From<&AlphaGas_AlphaGasTag> for i64 {
    fn from(v: &AlphaGas_AlphaGasTag) -> Self {
        match *v {
            AlphaGas_AlphaGasTag::Limited => 0,
            AlphaGas_AlphaGasTag::Unaccounted => 1,
            AlphaGas_AlphaGasTag::Unknown(v) => v
        }
    }
}

impl Default for AlphaGas_AlphaGasTag {
    fn default() -> Self { AlphaGas_AlphaGasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct AlphaGas_Z {
    pub _root: SharedType<AlphaGas>,
    pub _parent: SharedType<AlphaGas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<AlphaGas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaGas_Z {
    type Root = AlphaGas;
    type Parent = AlphaGas;

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
                    let t = Self::read_into::<_, AlphaGas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl AlphaGas_Z {
}
impl AlphaGas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl AlphaGas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl AlphaGas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaGas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<AlphaGas_NChunk>>> {
        self.tail.borrow()
    }
}
impl AlphaGas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaGas_NChunk {
    pub _root: SharedType<AlphaGas>,
    pub _parent: SharedType<AlphaGas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaGas_NChunk {
    type Root = AlphaGas;
    type Parent = AlphaGas_Z;

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
impl AlphaGas_NChunk {
}
impl AlphaGas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl AlphaGas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl AlphaGas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
