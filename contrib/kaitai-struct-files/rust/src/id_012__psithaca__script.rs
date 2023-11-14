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
pub struct Id012PsithacaScript {
    pub _root: SharedType<Id012PsithacaScript>,
    pub _parent: SharedType<Id012PsithacaScript>,
    pub _self: SharedType<Self>,
    id_012__psithaca__scripted__contracts: RefCell<OptRc<Id012PsithacaScript_Id012PsithacaScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaScript {
    type Root = Id012PsithacaScript;
    type Parent = Id012PsithacaScript;

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
        let t = Self::read_into::<_, Id012PsithacaScript_Id012PsithacaScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.id_012__psithaca__scripted__contracts.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaScript {
}
impl Id012PsithacaScript {
    pub fn id_012__psithaca__scripted__contracts(&self) -> Ref<OptRc<Id012PsithacaScript_Id012PsithacaScriptedContracts>> {
        self.id_012__psithaca__scripted__contracts.borrow()
    }
}
impl Id012PsithacaScript {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaScript_Id012PsithacaScriptedContracts {
    pub _root: SharedType<Id012PsithacaScript>,
    pub _parent: SharedType<Id012PsithacaScript>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<Id012PsithacaScript_Code>>,
    storage: RefCell<OptRc<Id012PsithacaScript_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaScript_Id012PsithacaScriptedContracts {
    type Root = Id012PsithacaScript;
    type Parent = Id012PsithacaScript;

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
        let t = Self::read_into::<_, Id012PsithacaScript_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, Id012PsithacaScript_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl Id012PsithacaScript_Id012PsithacaScriptedContracts {
}
impl Id012PsithacaScript_Id012PsithacaScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<Id012PsithacaScript_Code>> {
        self.code.borrow()
    }
}
impl Id012PsithacaScript_Id012PsithacaScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<Id012PsithacaScript_Storage>> {
        self.storage.borrow()
    }
}
impl Id012PsithacaScript_Id012PsithacaScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaScript_Storage {
    pub _root: SharedType<Id012PsithacaScript>,
    pub _parent: SharedType<Id012PsithacaScript_Id012PsithacaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaScript_Storage {
    type Root = Id012PsithacaScript;
    type Parent = Id012PsithacaScript_Id012PsithacaScriptedContracts;

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
impl Id012PsithacaScript_Storage {
}
impl Id012PsithacaScript_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl Id012PsithacaScript_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl Id012PsithacaScript_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaScript_Code {
    pub _root: SharedType<Id012PsithacaScript>,
    pub _parent: SharedType<Id012PsithacaScript_Id012PsithacaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaScript_Code {
    type Root = Id012PsithacaScript;
    type Parent = Id012PsithacaScript_Id012PsithacaScriptedContracts;

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
impl Id012PsithacaScript_Code {
}
impl Id012PsithacaScript_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl Id012PsithacaScript_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl Id012PsithacaScript_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
