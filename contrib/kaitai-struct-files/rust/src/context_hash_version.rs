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
 * A version number for the context hash computation
 */

#[derive(Default, Debug, Clone)]
pub struct ContextHashVersion {
    pub _root: SharedType<ContextHashVersion>,
    pub _parent: SharedType<ContextHashVersion>,
    pub _self: SharedType<Self>,
    context_hash_version: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for ContextHashVersion {
    type Root = ContextHashVersion;
    type Parent = ContextHashVersion;

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
        *self_rc.context_hash_version.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl ContextHashVersion {
}
impl ContextHashVersion {
    pub fn context_hash_version(&self) -> Ref<u16> {
        self.context_hash_version.borrow()
    }
}
impl ContextHashVersion {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
