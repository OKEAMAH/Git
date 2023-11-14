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
 * Statistics about the p2p network.
 */

#[derive(Default, Debug, Clone)]
pub struct P2pStat {
    pub _root: SharedType<P2pStat>,
    pub _parent: SharedType<P2pStat>,
    pub _self: SharedType<Self>,
    total_sent: RefCell<i64>,
    total_recv: RefCell<i64>,
    current_inflow: RefCell<i32>,
    current_outflow: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pStat {
    type Root = P2pStat;
    type Parent = P2pStat;

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
        *self_rc.total_sent.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.total_recv.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.current_inflow.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.current_outflow.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl P2pStat {
}
impl P2pStat {
    pub fn total_sent(&self) -> Ref<i64> {
        self.total_sent.borrow()
    }
}
impl P2pStat {
    pub fn total_recv(&self) -> Ref<i64> {
        self.total_recv.borrow()
    }
}
impl P2pStat {
    pub fn current_inflow(&self) -> Ref<i32> {
        self.current_inflow.borrow()
    }
}
impl P2pStat {
    pub fn current_outflow(&self) -> Ref<i32> {
        self.current_outflow.borrow()
    }
}
impl P2pStat {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
