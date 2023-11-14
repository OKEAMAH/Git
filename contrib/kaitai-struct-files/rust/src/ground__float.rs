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

/**
 * Floating point numbers
 */

#[derive(Default, Debug, Clone)]
pub struct GroundFloat {
    pub _root: SharedType<GroundFloat>,
    pub _parent: SharedType<GroundFloat>,
    pub _self: SharedType<Self>,
    ground__float: RefCell<f64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for GroundFloat {
    type Root = GroundFloat;
    type Parent = GroundFloat;

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
        *self_rc.ground__float.borrow_mut() = _io.read_f8be()?.into();
        Ok(())
    }
}
impl GroundFloat {
}
impl GroundFloat {
    pub fn ground__float(&self) -> Ref<f64> {
        self.ground__float.borrow()
    }
}
impl GroundFloat {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
