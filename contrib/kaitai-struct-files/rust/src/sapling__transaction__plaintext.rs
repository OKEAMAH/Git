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
pub struct SaplingTransactionPlaintext {
    pub _root: SharedType<SaplingTransactionPlaintext>,
    pub _parent: SharedType<SaplingTransactionPlaintext>,
    pub _self: SharedType<Self>,
    diversifier: RefCell<Vec<u8>>,
    amount: RefCell<i64>,
    rcm: RefCell<Vec<u8>>,
    memo: RefCell<OptRc<SaplingTransactionPlaintext_Memo>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionPlaintext {
    type Root = SaplingTransactionPlaintext;
    type Parent = SaplingTransactionPlaintext;

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
        *self_rc.diversifier.borrow_mut() = _io.read_bytes(11 as usize)?.into();
        *self_rc.amount.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.rcm.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransactionPlaintext_Memo>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.memo.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransactionPlaintext {
}
impl SaplingTransactionPlaintext {
    pub fn diversifier(&self) -> Ref<Vec<u8>> {
        self.diversifier.borrow()
    }
}
impl SaplingTransactionPlaintext {
    pub fn amount(&self) -> Ref<i64> {
        self.amount.borrow()
    }
}
impl SaplingTransactionPlaintext {
    pub fn rcm(&self) -> Ref<Vec<u8>> {
        self.rcm.borrow()
    }
}
impl SaplingTransactionPlaintext {
    pub fn memo(&self) -> Ref<OptRc<SaplingTransactionPlaintext_Memo>> {
        self.memo.borrow()
    }
}
impl SaplingTransactionPlaintext {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransactionPlaintext_Memo {
    pub _root: SharedType<SaplingTransactionPlaintext>,
    pub _parent: SharedType<SaplingTransactionPlaintext>,
    pub _self: SharedType<Self>,
    len_memo: RefCell<i32>,
    memo: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionPlaintext_Memo {
    type Root = SaplingTransactionPlaintext;
    type Parent = SaplingTransactionPlaintext;

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
        *self_rc.len_memo.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.memo.borrow_mut() = _io.read_bytes(*self_rc.len_memo() as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionPlaintext_Memo {
}
impl SaplingTransactionPlaintext_Memo {
    pub fn len_memo(&self) -> Ref<i32> {
        self.len_memo.borrow()
    }
}
impl SaplingTransactionPlaintext_Memo {
    pub fn memo(&self) -> Ref<Vec<u8>> {
        self.memo.borrow()
    }
}
impl SaplingTransactionPlaintext_Memo {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
