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
 * A span of time, as seen by the local computer.
 */

#[derive(Default, Debug, Clone)]
pub struct TimespanSystem {
    pub _root: SharedType<TimespanSystem>,
    pub _parent: SharedType<TimespanSystem>,
    pub _self: SharedType<Self>,
    timespan__system: RefCell<f64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for TimespanSystem {
    type Root = TimespanSystem;
    type Parent = TimespanSystem;

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
        *self_rc.timespan__system.borrow_mut() = _io.read_f8be()?.into();
        Ok(())
    }
}
impl TimespanSystem {
}
impl TimespanSystem {
    pub fn timespan__system(&self) -> Ref<f64> {
        self.timespan__system.borrow()
    }
}
impl TimespanSystem {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
