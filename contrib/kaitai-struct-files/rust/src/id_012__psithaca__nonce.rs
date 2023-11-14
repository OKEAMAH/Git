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
pub struct Id012PsithacaNonce {
    pub _root: SharedType<Id012PsithacaNonce>,
    pub _parent: SharedType<Id012PsithacaNonce>,
    pub _self: SharedType<Self>,
    id_012__psithaca__nonce: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaNonce {
    type Root = Id012PsithacaNonce;
    type Parent = Id012PsithacaNonce;

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
        *self_rc.id_012__psithaca__nonce.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl Id012PsithacaNonce {
}
impl Id012PsithacaNonce {
    pub fn id_012__psithaca__nonce(&self) -> Ref<Vec<u8>> {
        self.id_012__psithaca__nonce.borrow()
    }
}
impl Id012PsithacaNonce {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
