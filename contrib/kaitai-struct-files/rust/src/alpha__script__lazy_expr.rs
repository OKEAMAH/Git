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
pub struct AlphaScriptLazyExpr {
    pub _root: SharedType<AlphaScriptLazyExpr>,
    pub _parent: SharedType<AlphaScriptLazyExpr>,
    pub _self: SharedType<Self>,
    len_alpha__script__lazy_expr: RefCell<i32>,
    alpha__script__lazy_expr: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for AlphaScriptLazyExpr {
    type Root = AlphaScriptLazyExpr;
    type Parent = AlphaScriptLazyExpr;

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
        *self_rc.len_alpha__script__lazy_expr.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.alpha__script__lazy_expr.borrow_mut() = _io.read_bytes(*self_rc.len_alpha__script__lazy_expr() as usize)?.into();
        Ok(())
    }
}
impl AlphaScriptLazyExpr {
}
impl AlphaScriptLazyExpr {
    pub fn len_alpha__script__lazy_expr(&self) -> Ref<i32> {
        self.len_alpha__script__lazy_expr.borrow()
    }
}
impl AlphaScriptLazyExpr {
    pub fn alpha__script__lazy_expr(&self) -> Ref<Vec<u8>> {
        self.alpha__script__lazy_expr.borrow()
    }
}
impl AlphaScriptLazyExpr {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
