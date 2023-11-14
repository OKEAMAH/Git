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
pub struct SaplingTransactionCommitmentValue {
    pub _root: SharedType<SaplingTransactionCommitmentValue>,
    pub _parent: SharedType<SaplingTransactionCommitmentValue>,
    pub _self: SharedType<Self>,
    sapling__transaction__commitment_value: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransactionCommitmentValue {
    type Root = SaplingTransactionCommitmentValue;
    type Parent = SaplingTransactionCommitmentValue;

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
        *self_rc.sapling__transaction__commitment_value.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransactionCommitmentValue {
}
impl SaplingTransactionCommitmentValue {
    pub fn sapling__transaction__commitment_value(&self) -> Ref<Vec<u8>> {
        self.sapling__transaction__commitment_value.borrow()
    }
}
impl SaplingTransactionCommitmentValue {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
