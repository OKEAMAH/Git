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
 * Protocol metadata: the hash of the protocol, the expected environment version and the list of modules comprising the protocol.
 */

#[derive(Default, Debug, Clone)]
pub struct ProtocolMeta {
    pub _root: SharedType<ProtocolMeta>,
    pub _parent: SharedType<ProtocolMeta>,
    pub _self: SharedType<Self>,
    hash_tag: RefCell<ProtocolMeta_Bool>,
    hash: RefCell<Vec<u8>>,
    expected_env_version_tag: RefCell<ProtocolMeta_Bool>,
    expected_env_version: RefCell<u16>,
    modules: RefCell<OptRc<ProtocolMeta_Modules>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for ProtocolMeta {
    type Root = ProtocolMeta;
    type Parent = ProtocolMeta;

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
        *self_rc.hash_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.hash_tag() == ProtocolMeta_Bool::True {
            *self_rc.hash.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        }
        *self_rc.expected_env_version_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.expected_env_version_tag() == ProtocolMeta_Bool::True {
            *self_rc.expected_env_version.borrow_mut() = _io.read_u2be()?.into();
        }
        let t = Self::read_into::<_, ProtocolMeta_Modules>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.modules.borrow_mut() = t;
        Ok(())
    }
}
impl ProtocolMeta {
}
impl ProtocolMeta {
    pub fn hash_tag(&self) -> Ref<ProtocolMeta_Bool> {
        self.hash_tag.borrow()
    }
}

/**
 * Used to force the hash of the protocol
 */
impl ProtocolMeta {
    pub fn hash(&self) -> Ref<Vec<u8>> {
        self.hash.borrow()
    }
}
impl ProtocolMeta {
    pub fn expected_env_version_tag(&self) -> Ref<ProtocolMeta_Bool> {
        self.expected_env_version_tag.borrow()
    }
}
impl ProtocolMeta {
    pub fn expected_env_version(&self) -> Ref<u16> {
        self.expected_env_version.borrow()
    }
}

/**
 * Modules comprising the protocol
 */
impl ProtocolMeta {
    pub fn modules(&self) -> Ref<OptRc<ProtocolMeta_Modules>> {
        self.modules.borrow()
    }
}
impl ProtocolMeta {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum ProtocolMeta_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for ProtocolMeta_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<ProtocolMeta_Bool> {
        match flag {
            0 => Ok(ProtocolMeta_Bool::False),
            255 => Ok(ProtocolMeta_Bool::True),
            _ => Ok(ProtocolMeta_Bool::Unknown(flag)),
        }
    }
}

impl From<&ProtocolMeta_Bool> for i64 {
    fn from(v: &ProtocolMeta_Bool) -> Self {
        match *v {
            ProtocolMeta_Bool::False => 0,
            ProtocolMeta_Bool::True => 255,
            ProtocolMeta_Bool::Unknown(v) => v
        }
    }
}

impl Default for ProtocolMeta_Bool {
    fn default() -> Self { ProtocolMeta_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct ProtocolMeta_Modules {
    pub _root: SharedType<ProtocolMeta>,
    pub _parent: SharedType<ProtocolMeta>,
    pub _self: SharedType<Self>,
    len_modules: RefCell<i32>,
    modules: RefCell<Vec<OptRc<ProtocolMeta_ModulesEntries>>>,
    _io: RefCell<BytesReader>,
    modules_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for ProtocolMeta_Modules {
    type Root = ProtocolMeta;
    type Parent = ProtocolMeta;

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
        *self_rc.len_modules.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.modules.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.modules_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_modules() as usize)?.into());
                let modules_raw = self_rc.modules_raw.borrow();
                let io_modules_raw = BytesReader::from(modules_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, ProtocolMeta_ModulesEntries>(&io_modules_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.modules.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl ProtocolMeta_Modules {
}
impl ProtocolMeta_Modules {
    pub fn len_modules(&self) -> Ref<i32> {
        self.len_modules.borrow()
    }
}
impl ProtocolMeta_Modules {
    pub fn modules(&self) -> Ref<Vec<OptRc<ProtocolMeta_ModulesEntries>>> {
        self.modules.borrow()
    }
}
impl ProtocolMeta_Modules {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl ProtocolMeta_Modules {
    pub fn modules_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.modules_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct ProtocolMeta_ModulesEntries {
    pub _root: SharedType<ProtocolMeta>,
    pub _parent: SharedType<ProtocolMeta_Modules>,
    pub _self: SharedType<Self>,
    len_modules_elt: RefCell<i32>,
    modules_elt: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for ProtocolMeta_ModulesEntries {
    type Root = ProtocolMeta;
    type Parent = ProtocolMeta_Modules;

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
        *self_rc.len_modules_elt.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.modules_elt.borrow_mut() = _io.read_bytes(*self_rc.len_modules_elt() as usize)?.into();
        Ok(())
    }
}
impl ProtocolMeta_ModulesEntries {
}
impl ProtocolMeta_ModulesEntries {
    pub fn len_modules_elt(&self) -> Ref<i32> {
        self.len_modules_elt.borrow()
    }
}
impl ProtocolMeta_ModulesEntries {
    pub fn modules_elt(&self) -> Ref<Vec<u8>> {
        self.modules_elt.borrow()
    }
}
impl ProtocolMeta_ModulesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
