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
pub struct Id005Psbabym1Gas {
    pub _root: SharedType<Id005Psbabym1Gas>,
    pub _parent: SharedType<Id005Psbabym1Gas>,
    pub _self: SharedType<Self>,
    id_005__psbabym1__gas_tag: RefCell<Id005Psbabym1Gas_Id005Psbabym1GasTag>,
    id_005__psbabym1__gas_limited: RefCell<OptRc<Id005Psbabym1Gas_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id005Psbabym1Gas {
    type Root = Id005Psbabym1Gas;
    type Parent = Id005Psbabym1Gas;

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
        *self_rc.id_005__psbabym1__gas_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.id_005__psbabym1__gas_tag() == Id005Psbabym1Gas_Id005Psbabym1GasTag::Limited {
            let t = Self::read_into::<_, Id005Psbabym1Gas_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.id_005__psbabym1__gas_limited.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id005Psbabym1Gas {
}
impl Id005Psbabym1Gas {
    pub fn id_005__psbabym1__gas_tag(&self) -> Ref<Id005Psbabym1Gas_Id005Psbabym1GasTag> {
        self.id_005__psbabym1__gas_tag.borrow()
    }
}
impl Id005Psbabym1Gas {
    pub fn id_005__psbabym1__gas_limited(&self) -> Ref<OptRc<Id005Psbabym1Gas_Z>> {
        self.id_005__psbabym1__gas_limited.borrow()
    }
}
impl Id005Psbabym1Gas {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id005Psbabym1Gas_Id005Psbabym1GasTag {
    Limited,
    Unaccounted,
    Unknown(i64),
}

impl TryFrom<i64> for Id005Psbabym1Gas_Id005Psbabym1GasTag {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id005Psbabym1Gas_Id005Psbabym1GasTag> {
        match flag {
            0 => Ok(Id005Psbabym1Gas_Id005Psbabym1GasTag::Limited),
            1 => Ok(Id005Psbabym1Gas_Id005Psbabym1GasTag::Unaccounted),
            _ => Ok(Id005Psbabym1Gas_Id005Psbabym1GasTag::Unknown(flag)),
        }
    }
}

impl From<&Id005Psbabym1Gas_Id005Psbabym1GasTag> for i64 {
    fn from(v: &Id005Psbabym1Gas_Id005Psbabym1GasTag) -> Self {
        match *v {
            Id005Psbabym1Gas_Id005Psbabym1GasTag::Limited => 0,
            Id005Psbabym1Gas_Id005Psbabym1GasTag::Unaccounted => 1,
            Id005Psbabym1Gas_Id005Psbabym1GasTag::Unknown(v) => v
        }
    }
}

impl Default for Id005Psbabym1Gas_Id005Psbabym1GasTag {
    fn default() -> Self { Id005Psbabym1Gas_Id005Psbabym1GasTag::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id005Psbabym1Gas_Z {
    pub _root: SharedType<Id005Psbabym1Gas>,
    pub _parent: SharedType<Id005Psbabym1Gas>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id005Psbabym1Gas_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id005Psbabym1Gas_Z {
    type Root = Id005Psbabym1Gas;
    type Parent = Id005Psbabym1Gas;

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
                    let t = Self::read_into::<_, Id005Psbabym1Gas_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id005Psbabym1Gas_Z {
}
impl Id005Psbabym1Gas_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id005Psbabym1Gas_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id005Psbabym1Gas_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id005Psbabym1Gas_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id005Psbabym1Gas_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id005Psbabym1Gas_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id005Psbabym1Gas_NChunk {
    pub _root: SharedType<Id005Psbabym1Gas>,
    pub _parent: SharedType<Id005Psbabym1Gas_Z>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id005Psbabym1Gas_NChunk {
    type Root = Id005Psbabym1Gas;
    type Parent = Id005Psbabym1Gas_Z;

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
impl Id005Psbabym1Gas_NChunk {
}
impl Id005Psbabym1Gas_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id005Psbabym1Gas_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id005Psbabym1Gas_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
