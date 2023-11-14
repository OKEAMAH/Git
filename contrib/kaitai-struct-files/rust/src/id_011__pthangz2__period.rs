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
pub struct Id011Pthangz2Period {
    pub _root: SharedType<Id011Pthangz2Period>,
    pub _parent: SharedType<Id011Pthangz2Period>,
    pub _self: SharedType<Self>,
    id_011__pthangz2__period: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id011Pthangz2Period {
    type Root = Id011Pthangz2Period;
    type Parent = Id011Pthangz2Period;

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
        *self_rc.id_011__pthangz2__period.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id011Pthangz2Period {
}
impl Id011Pthangz2Period {
    pub fn id_011__pthangz2__period(&self) -> Ref<i64> {
        self.id_011__pthangz2__period.borrow()
    }
}
impl Id011Pthangz2Period {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
