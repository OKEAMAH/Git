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
pub struct P2pPointId {
    pub _root: SharedType<P2pPointId>,
    pub _parent: SharedType<P2pPointId>,
    pub _self: SharedType<Self>,
    p2p_point__id: RefCell<OptRc<P2pPointId_P2pPointId>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pPointId {
    type Root = P2pPointId;
    type Parent = P2pPointId;

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
        let t = Self::read_into::<_, P2pPointId_P2pPointId>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.p2p_point__id.borrow_mut() = t;
        Ok(())
    }
}
impl P2pPointId {
}
impl P2pPointId {
    pub fn p2p_point__id(&self) -> Ref<OptRc<P2pPointId_P2pPointId>> {
        self.p2p_point__id.borrow()
    }
}
impl P2pPointId {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Identifier for a peer point
 */

#[derive(Default, Debug, Clone)]
pub struct P2pPointId_P2pPointId {
    pub _root: SharedType<P2pPointId>,
    pub _parent: SharedType<P2pPointId>,
    pub _self: SharedType<Self>,
    len_p2p_point__id: RefCell<i32>,
    p2p_point__id: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pPointId_P2pPointId {
    type Root = P2pPointId;
    type Parent = P2pPointId;

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
        *self_rc.len_p2p_point__id.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.p2p_point__id.borrow_mut() = _io.read_bytes(*self_rc.len_p2p_point__id() as usize)?.into();
        Ok(())
    }
}
impl P2pPointId_P2pPointId {
}
impl P2pPointId_P2pPointId {
    pub fn len_p2p_point__id(&self) -> Ref<i32> {
        self.len_p2p_point__id.borrow()
    }
}
impl P2pPointId_P2pPointId {
    pub fn p2p_point__id(&self) -> Ref<Vec<u8>> {
        self.p2p_point__id.borrow()
    }
}
impl P2pPointId_P2pPointId {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
