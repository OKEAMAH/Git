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
pub struct AlphaScript {
    pub _root: SharedType<AlphaScript>,
    pub _parent: SharedType<AlphaScript>,
    pub _self: SharedType<Self>,
    alpha__scripted__contracts: RefCell<OptRc<AlphaScript_AlphaScriptedContracts>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaScript {
    type Root = AlphaScript;
    type Parent = AlphaScript;

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
        let t = Self::read_into::<_, AlphaScript_AlphaScriptedContracts>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.alpha__scripted__contracts.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaScript {
}
impl AlphaScript {
    pub fn alpha__scripted__contracts(&self) -> Ref<OptRc<AlphaScript_AlphaScriptedContracts>> {
        self.alpha__scripted__contracts.borrow()
    }
}
impl AlphaScript {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaScript_AlphaScriptedContracts {
    pub _root: SharedType<AlphaScript>,
    pub _parent: SharedType<AlphaScript>,
    pub _self: SharedType<Self>,
    code: RefCell<OptRc<AlphaScript_Code>>,
    storage: RefCell<OptRc<AlphaScript_Storage>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaScript_AlphaScriptedContracts {
    type Root = AlphaScript;
    type Parent = AlphaScript;

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
        let t = Self::read_into::<_, AlphaScript_Code>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.code.borrow_mut() = t;
        let t = Self::read_into::<_, AlphaScript_Storage>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.storage.borrow_mut() = t;
        Ok(())
    }
}
impl AlphaScript_AlphaScriptedContracts {
}
impl AlphaScript_AlphaScriptedContracts {
    pub fn code(&self) -> Ref<OptRc<AlphaScript_Code>> {
        self.code.borrow()
    }
}
impl AlphaScript_AlphaScriptedContracts {
    pub fn storage(&self) -> Ref<OptRc<AlphaScript_Storage>> {
        self.storage.borrow()
    }
}
impl AlphaScript_AlphaScriptedContracts {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaScript_Storage {
    pub _root: SharedType<AlphaScript>,
    pub _parent: SharedType<AlphaScript_AlphaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_storage: RefCell<i32>,
    storage: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaScript_Storage {
    type Root = AlphaScript;
    type Parent = AlphaScript_AlphaScriptedContracts;

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
impl AlphaScript_Storage {
}
impl AlphaScript_Storage {
    pub fn len_storage(&self) -> Ref<i32> {
        self.len_storage.borrow()
    }
}
impl AlphaScript_Storage {
    pub fn storage(&self) -> Ref<Vec<u8>> {
        self.storage.borrow()
    }
}
impl AlphaScript_Storage {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct AlphaScript_Code {
    pub _root: SharedType<AlphaScript>,
    pub _parent: SharedType<AlphaScript_AlphaScriptedContracts>,
    pub _self: SharedType<Self>,
    len_code: RefCell<i32>,
    code: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaScript_Code {
    type Root = AlphaScript;
    type Parent = AlphaScript_AlphaScriptedContracts;

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
impl AlphaScript_Code {
}
impl AlphaScript_Code {
    pub fn len_code(&self) -> Ref<i32> {
        self.len_code.borrow()
    }
}
impl AlphaScript_Code {
    pub fn code(&self) -> Ref<Vec<u8>> {
        self.code.borrow()
    }
}
impl AlphaScript_Code {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
