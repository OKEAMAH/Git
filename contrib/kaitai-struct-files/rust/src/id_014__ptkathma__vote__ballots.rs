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
pub struct Id014PtkathmaVoteBallots {
    pub _root: SharedType<Id014PtkathmaVoteBallots>,
    pub _parent: SharedType<Id014PtkathmaVoteBallots>,
    pub _self: SharedType<Self>,
    yay: RefCell<i64>,
    nay: RefCell<i64>,
    pass: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id014PtkathmaVoteBallots {
    type Root = Id014PtkathmaVoteBallots;
    type Parent = Id014PtkathmaVoteBallots;

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
        *self_rc.yay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.nay.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.pass.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id014PtkathmaVoteBallots {
}
impl Id014PtkathmaVoteBallots {
    pub fn yay(&self) -> Ref<i64> {
        self.yay.borrow()
    }
}
impl Id014PtkathmaVoteBallots {
    pub fn nay(&self) -> Ref<i64> {
        self.nay.borrow()
    }
}
impl Id014PtkathmaVoteBallots {
    pub fn pass(&self) -> Ref<i64> {
        self.pass.borrow()
    }
}
impl Id014PtkathmaVoteBallots {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
