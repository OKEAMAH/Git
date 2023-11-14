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
pub struct SaplingWalletSpendingKey {
    pub _root: SharedType<SaplingWalletSpendingKey>,
    pub _parent: SharedType<SaplingWalletSpendingKey>,
    pub _self: SharedType<Self>,
    depth: RefCell<Vec<u8>>,
    parent_fvk_tag: RefCell<Vec<u8>>,
    child_index: RefCell<Vec<u8>>,
    chain_code: RefCell<Vec<u8>>,
    expsk: RefCell<OptRc<SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey>>,
    dk: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingWalletSpendingKey {
    type Root = SaplingWalletSpendingKey;
    type Parent = SaplingWalletSpendingKey;

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
        *self_rc.depth.borrow_mut() = _io.read_bytes(1 as usize)?.into();
        *self_rc.parent_fvk_tag.borrow_mut() = _io.read_bytes(4 as usize)?.into();
        *self_rc.child_index.borrow_mut() = _io.read_bytes(4 as usize)?.into();
        *self_rc.chain_code.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.expsk.borrow_mut() = t;
        *self_rc.dk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl SaplingWalletSpendingKey {
}
impl SaplingWalletSpendingKey {
    pub fn depth(&self) -> Ref<Vec<u8>> {
        self.depth.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn parent_fvk_tag(&self) -> Ref<Vec<u8>> {
        self.parent_fvk_tag.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn child_index(&self) -> Ref<Vec<u8>> {
        self.child_index.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn chain_code(&self) -> Ref<Vec<u8>> {
        self.chain_code.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn expsk(&self) -> Ref<OptRc<SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey>> {
        self.expsk.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn dk(&self) -> Ref<Vec<u8>> {
        self.dk.borrow()
    }
}
impl SaplingWalletSpendingKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    pub _root: SharedType<SaplingWalletSpendingKey>,
    pub _parent: SharedType<SaplingWalletSpendingKey>,
    pub _self: SharedType<Self>,
    ask: RefCell<Vec<u8>>,
    nsk: RefCell<Vec<u8>>,
    ovk: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    type Root = SaplingWalletSpendingKey;
    type Parent = SaplingWalletSpendingKey;

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
        *self_rc.ask.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.nsk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.ovk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
}
impl SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    pub fn ask(&self) -> Ref<Vec<u8>> {
        self.ask.borrow()
    }
}
impl SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    pub fn nsk(&self) -> Ref<Vec<u8>> {
        self.nsk.borrow()
    }
}
impl SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    pub fn ovk(&self) -> Ref<Vec<u8>> {
        self.ovk.borrow()
    }
}
impl SaplingWalletSpendingKey_SaplingWalletExpandedSpendingKey {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
