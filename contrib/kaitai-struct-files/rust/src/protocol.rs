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

/**
 * The environment a protocol relies on and the components a protocol is made of.
 */

#[derive(Default, Debug, Clone)]
pub struct Protocol {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol>,
    pub _self: SharedType<Self>,
    expected_env_version: RefCell<u16>,
    components: RefCell<OptRc<Protocol_Components>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Protocol {
    type Root = Protocol;
    type Parent = Protocol;

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
        *self_rc.expected_env_version.borrow_mut() = _io.read_u2be()?.into();
        let t = Self::read_into::<_, Protocol_Components>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.components.borrow_mut() = t;
        Ok(())
    }
}
impl Protocol {
}
impl Protocol {
    pub fn expected_env_version(&self) -> Ref<u16> {
        self.expected_env_version.borrow()
    }
}
impl Protocol {
    pub fn components(&self) -> Ref<OptRc<Protocol_Components>> {
        self.components.borrow()
    }
}
impl Protocol {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Protocol_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Protocol_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Protocol_Bool> {
        match flag {
            0 => Ok(Protocol_Bool::False),
            255 => Ok(Protocol_Bool::True),
            _ => Ok(Protocol_Bool::Unknown(flag)),
        }
    }
}

impl From<&Protocol_Bool> for i64 {
    fn from(v: &Protocol_Bool) -> Self {
        match *v {
            Protocol_Bool::False => 0,
            Protocol_Bool::True => 255,
            Protocol_Bool::Unknown(v) => v
        }
    }
}

impl Default for Protocol_Bool {
    fn default() -> Self { Protocol_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Protocol_Name {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol_ComponentsEntries>,
    pub _self: SharedType<Self>,
    len_name: RefCell<i32>,
    name: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Protocol_Name {
    type Root = Protocol;
    type Parent = Protocol_ComponentsEntries;

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
        *self_rc.len_name.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.name.borrow_mut() = _io.read_bytes(*self_rc.len_name() as usize)?.into();
        Ok(())
    }
}
impl Protocol_Name {
}
impl Protocol_Name {
    pub fn len_name(&self) -> Ref<i32> {
        self.len_name.borrow()
    }
}
impl Protocol_Name {
    pub fn name(&self) -> Ref<Vec<u8>> {
        self.name.borrow()
    }
}
impl Protocol_Name {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Protocol_Interface {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol_ComponentsEntries>,
    pub _self: SharedType<Self>,
    len_interface: RefCell<i32>,
    interface: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Protocol_Interface {
    type Root = Protocol;
    type Parent = Protocol_ComponentsEntries;

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
        *self_rc.len_interface.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.interface.borrow_mut() = _io.read_bytes(*self_rc.len_interface() as usize)?.into();
        Ok(())
    }
}
impl Protocol_Interface {
}
impl Protocol_Interface {
    pub fn len_interface(&self) -> Ref<i32> {
        self.len_interface.borrow()
    }
}
impl Protocol_Interface {
    pub fn interface(&self) -> Ref<Vec<u8>> {
        self.interface.borrow()
    }
}
impl Protocol_Interface {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Protocol_ComponentsEntries {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol_Components>,
    pub _self: SharedType<Self>,
    name: RefCell<OptRc<Protocol_Name>>,
    interface_tag: RefCell<Protocol_Bool>,
    interface: RefCell<OptRc<Protocol_Interface>>,
    implementation: RefCell<OptRc<Protocol_Implementation>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Protocol_ComponentsEntries {
    type Root = Protocol;
    type Parent = Protocol_Components;

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
        let t = Self::read_into::<_, Protocol_Name>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.name.borrow_mut() = t;
        *self_rc.interface_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.interface_tag() == Protocol_Bool::True {
            let t = Self::read_into::<_, Protocol_Interface>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.interface.borrow_mut() = t;
        }
        let t = Self::read_into::<_, Protocol_Implementation>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.implementation.borrow_mut() = t;
        Ok(())
    }
}
impl Protocol_ComponentsEntries {
}
impl Protocol_ComponentsEntries {
    pub fn name(&self) -> Ref<OptRc<Protocol_Name>> {
        self.name.borrow()
    }
}
impl Protocol_ComponentsEntries {
    pub fn interface_tag(&self) -> Ref<Protocol_Bool> {
        self.interface_tag.borrow()
    }
}
impl Protocol_ComponentsEntries {
    pub fn interface(&self) -> Ref<OptRc<Protocol_Interface>> {
        self.interface.borrow()
    }
}
impl Protocol_ComponentsEntries {
    pub fn implementation(&self) -> Ref<OptRc<Protocol_Implementation>> {
        self.implementation.borrow()
    }
}
impl Protocol_ComponentsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Protocol_Components {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol>,
    pub _self: SharedType<Self>,
    len_components: RefCell<i32>,
    components: RefCell<Vec<OptRc<Protocol_ComponentsEntries>>>,
    _io: RefCell<BytesReader>,
    components_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Protocol_Components {
    type Root = Protocol;
    type Parent = Protocol;

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
        *self_rc.len_components.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.components.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.components_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_components() as usize)?.into());
                let components_raw = self_rc.components_raw.borrow();
                let io_components_raw = BytesReader::from(components_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Protocol_ComponentsEntries>(&io_components_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.components.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Protocol_Components {
}
impl Protocol_Components {
    pub fn len_components(&self) -> Ref<i32> {
        self.len_components.borrow()
    }
}
impl Protocol_Components {
    pub fn components(&self) -> Ref<Vec<OptRc<Protocol_ComponentsEntries>>> {
        self.components.borrow()
    }
}
impl Protocol_Components {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Protocol_Components {
    pub fn components_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.components_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Protocol_Implementation {
    pub _root: SharedType<Protocol>,
    pub _parent: SharedType<Protocol_ComponentsEntries>,
    pub _self: SharedType<Self>,
    len_implementation: RefCell<i32>,
    implementation: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Protocol_Implementation {
    type Root = Protocol;
    type Parent = Protocol_ComponentsEntries;

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
        *self_rc.len_implementation.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.implementation.borrow_mut() = _io.read_bytes(*self_rc.len_implementation() as usize)?.into();
        Ok(())
    }
}
impl Protocol_Implementation {
}
impl Protocol_Implementation {
    pub fn len_implementation(&self) -> Ref<i32> {
        self.len_implementation.borrow()
    }
}
impl Protocol_Implementation {
    pub fn implementation(&self) -> Ref<Vec<u8>> {
        self.implementation.borrow()
    }
}
impl Protocol_Implementation {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
