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
pub struct Id012PsithacaCycle {
    pub _root: SharedType<Id012PsithacaCycle>,
    pub _parent: SharedType<Id012PsithacaCycle>,
    pub _self: SharedType<Self>,
    id_012__psithaca__cycle: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaCycle {
    type Root = Id012PsithacaCycle;
    type Parent = Id012PsithacaCycle;

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
        *self_rc.id_012__psithaca__cycle.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id012PsithacaCycle {
}
impl Id012PsithacaCycle {
    pub fn id_012__psithaca__cycle(&self) -> Ref<i32> {
        self.id_012__psithaca__cycle.borrow()
    }
}
impl Id012PsithacaCycle {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
