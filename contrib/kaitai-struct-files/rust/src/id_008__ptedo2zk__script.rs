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
pub struct Id008Ptedo2zkScript {
    pub _root: SharedType<Id008Ptedo2zkScript>,
    pub _parent: SharedType<Id008Ptedo2zkScript>,
    pub _self: SharedType<Self>,
    id_008__ptedo2zk__scripted__contracts: RefCell<OptRc<Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkScript {
    type Root = Id008Ptedo2zkScript;
    type Parent = Id008Ptedo2zkScript;

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
        let t = Self::read_into::<_, Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_008__ptedo2zk__scripted__contracts.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkScript {
}
impl Id008Ptedo2zkScript {
    pub fn id_008__ptedo2zk__scripted__contracts(&self) -> Ref<OptRc<Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts>> {
        self.id_008__ptedo2zk__scripted__contracts.borrow()
    }
}
impl Id008Ptedo2zkScript {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
    pub _root: SharedType<Id008Ptedo2zkScript>,
    pub _parent: SharedType<Id008Ptedo2zkScript>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id008Ptedo2zkScript_Code>>,
    storage: RefCell<OptRc<Id008Ptedo2zkScript_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
    type Root = Id008Ptedo2zkScript;
    type Parent = Id008Ptedo2zkScript;

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
        let t = Self::read_into::<_, Id008Ptedo2zkScript_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id008Ptedo2zkScript_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
}
impl Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id008Ptedo2zkScript_Code>> {
        self.code.borrow()
    }
}
impl Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id008Ptedo2zkScript_Storage>> {
        self.storage.borrow()
    }
}
impl Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkScript_Storage {
    pub _root: SharedType<Id008Ptedo2zkScript>,
    pub _parent: SharedType<Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkScript_Storage {
    type Root = Id008Ptedo2zkScript;
    type Parent = Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts;

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
        *self_rc.len_storage.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.storage.borrow_mut() = _io.read_bytes(*self_rc.len_storage() as usize)?.into();
        Ok(())
    }
}
impl Id008Ptedo2zkScript_Storage {
}
impl Id008Ptedo2zkScript_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id008Ptedo2zkScript_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id008Ptedo2zkScript_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkScript_Code {
    pub _root: SharedType<Id008Ptedo2zkScript>,
    pub _parent: SharedType<Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkScript_Code {
    type Root = Id008Ptedo2zkScript;
    type Parent = Id008Ptedo2zkScript_Id008Ptedo2zkScriptedContracts;

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
        *self_rc.len_code.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.code.borrow_mut() = _io.read_bytes(*self_rc.len_code() as usize)?.into();
        Ok(())
    }
}
impl Id008Ptedo2zkScript_Code {
}
impl Id008Ptedo2zkScript_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id008Ptedo2zkScript_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id008Ptedo2zkScript_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
