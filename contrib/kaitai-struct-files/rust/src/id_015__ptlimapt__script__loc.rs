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
pub struct Id015PtlimaptScriptLoc {
    pub _root: SharedType<Id015PtlimaptScriptLoc>,
    pub _parent: SharedType<Id015PtlimaptScriptLoc>,
    pub _self: SharedType<Self>,
    micheline__location: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptScriptLoc {
    type Root = Id015PtlimaptScriptLoc;
    type Parent = Id015PtlimaptScriptLoc;

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
        *self_rc.micheline__location.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id015PtlimaptScriptLoc {
}

/**
 * Canonical location in a Micheline expression: The location of a node in a Micheline expression tree in prefix order, with zero being the root and adding one for every basic node, sequence and primitive application.
 */
impl Id015PtlimaptScriptLoc {
    pub fn micheline__location(&self) -> Ref<i32> {
        self.micheline__location.borrow()
    }
}
impl Id015PtlimaptScriptLoc {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
