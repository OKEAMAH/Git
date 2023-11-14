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
pub struct Id007Psdelph1Script {
    pub _root: SharedType<Id007Psdelph1Script>,
    pub _parent: SharedType<Id007Psdelph1Script>,
    pub _self: SharedType<Self>,
    id_007__psdelph1__scripted__contracts: RefCell<OptRc<Id007Psdelph1Script_Id007Psdelph1ScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Script {
    type Root = Id007Psdelph1Script;
    type Parent = Id007Psdelph1Script;

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
        let t = Self::read_into::<_, Id007Psdelph1Script_Id007Psdelph1ScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_007__psdelph1__scripted__contracts.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1Script {
}
impl Id007Psdelph1Script {
    pub fn id_007__psdelph1__scripted__contracts(&self) -> Ref<OptRc<Id007Psdelph1Script_Id007Psdelph1ScriptedContracts>> {
        self.id_007__psdelph1__scripted__contracts.borrow()
    }
}
impl Id007Psdelph1Script {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
    pub _root: SharedType<Id007Psdelph1Script>,
    pub _parent: SharedType<Id007Psdelph1Script>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id007Psdelph1Script_Code>>,
    storage: RefCell<OptRc<Id007Psdelph1Script_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
    type Root = Id007Psdelph1Script;
    type Parent = Id007Psdelph1Script;

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
        let t = Self::read_into::<_, Id007Psdelph1Script_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1Script_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
}
impl Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id007Psdelph1Script_Code>> {
        self.code.borrow()
    }
}
impl Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id007Psdelph1Script_Storage>> {
        self.storage.borrow()
    }
}
impl Id007Psdelph1Script_Id007Psdelph1ScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1Script_Storage {
    pub _root: SharedType<Id007Psdelph1Script>,
    pub _parent: SharedType<Id007Psdelph1Script_Id007Psdelph1ScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Script_Storage {
    type Root = Id007Psdelph1Script;
    type Parent = Id007Psdelph1Script_Id007Psdelph1ScriptedContracts;

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
impl Id007Psdelph1Script_Storage {
}
impl Id007Psdelph1Script_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id007Psdelph1Script_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id007Psdelph1Script_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1Script_Code {
    pub _root: SharedType<Id007Psdelph1Script>,
    pub _parent: SharedType<Id007Psdelph1Script_Id007Psdelph1ScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1Script_Code {
    type Root = Id007Psdelph1Script;
    type Parent = Id007Psdelph1Script_Id007Psdelph1ScriptedContracts;

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
impl Id007Psdelph1Script_Code {
}
impl Id007Psdelph1Script_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id007Psdelph1Script_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id007Psdelph1Script_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
