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
pub struct Id013PtjakartScript {
    pub _root: SharedType<Id013PtjakartScript>,
    pub _parent: SharedType<Id013PtjakartScript>,
    pub _self: SharedType<Self>,
    id_013__ptjakart__scripted__contracts: RefCell<OptRc<Id013PtjakartScript_Id013PtjakartScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartScript {
    type Root = Id013PtjakartScript;
    type Parent = Id013PtjakartScript;

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
        let t = Self::read_into::<_, Id013PtjakartScript_Id013PtjakartScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_013__ptjakart__scripted__contracts.borrow_mut() = t;
        Ok(())
    }
}
impl Id013PtjakartScript {
}
impl Id013PtjakartScript {
    pub fn id_013__ptjakart__scripted__contracts(&self) -> Ref<OptRc<Id013PtjakartScript_Id013PtjakartScriptedContracts>> {
        self.id_013__ptjakart__scripted__contracts.borrow()
    }
}
impl Id013PtjakartScript {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id013PtjakartScript_Id013PtjakartScriptedContracts {
    pub _root: SharedType<Id013PtjakartScript>,
    pub _parent: SharedType<Id013PtjakartScript>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id013PtjakartScript_Code>>,
    storage: RefCell<OptRc<Id013PtjakartScript_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartScript_Id013PtjakartScriptedContracts {
    type Root = Id013PtjakartScript;
    type Parent = Id013PtjakartScript;

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
        let t = Self::read_into::<_, Id013PtjakartScript_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id013PtjakartScript_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id013PtjakartScript_Id013PtjakartScriptedContracts {
}
impl Id013PtjakartScript_Id013PtjakartScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id013PtjakartScript_Code>> {
        self.code.borrow()
    }
}
impl Id013PtjakartScript_Id013PtjakartScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id013PtjakartScript_Storage>> {
        self.storage.borrow()
    }
}
impl Id013PtjakartScript_Id013PtjakartScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id013PtjakartScript_Storage {
    pub _root: SharedType<Id013PtjakartScript>,
    pub _parent: SharedType<Id013PtjakartScript_Id013PtjakartScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartScript_Storage {
    type Root = Id013PtjakartScript;
    type Parent = Id013PtjakartScript_Id013PtjakartScriptedContracts;

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
impl Id013PtjakartScript_Storage {
}
impl Id013PtjakartScript_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id013PtjakartScript_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id013PtjakartScript_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id013PtjakartScript_Code {
    pub _root: SharedType<Id013PtjakartScript>,
    pub _parent: SharedType<Id013PtjakartScript_Id013PtjakartScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id013PtjakartScript_Code {
    type Root = Id013PtjakartScript;
    type Parent = Id013PtjakartScript_Id013PtjakartScriptedContracts;

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
impl Id013PtjakartScript_Code {
}
impl Id013PtjakartScript_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id013PtjakartScript_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id013PtjakartScript_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
