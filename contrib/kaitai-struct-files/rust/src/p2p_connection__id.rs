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
 * The identifier for a p2p connection. It includes an address and a port number.
 */

#[derive(Default, Debug, Clone)]
pub struct P2pConnectionId {
    pub _root: SharedType<P2pConnectionId>,
    pub _parent: SharedType<P2pConnectionId>,
    pub _self: SharedType<Self>,
    addr: RefCell<OptRc<P2pConnectionId_P2pAddress>>,
    port_tag: RefCell<P2pConnectionId_Bool>,
    port: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pConnectionId {
    type Root = P2pConnectionId;
    type Parent = P2pConnectionId;

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
        let t = Self::read_into::<_, P2pConnectionId_P2pAddress>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.addr.borrow_mut() = t;
        *self_rc.port_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.port_tag() == P2pConnectionId_Bool::True {
            *self_rc.port.borrow_mut() = _io.read_u2be()?.into();
        }
        Ok(())
    }
}
impl P2pConnectionId {
}
impl P2pConnectionId {
    pub fn addr(&self) -> Ref<OptRc<P2pConnectionId_P2pAddress>> {
        self.addr.borrow()
    }
}
impl P2pConnectionId {
    pub fn port_tag(&self) -> Ref<P2pConnectionId_Bool> {
        self.port_tag.borrow()
    }
}
impl P2pConnectionId {
    pub fn port(&self) -> Ref<u16> {
        self.port.borrow()
    }
}
impl P2pConnectionId {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum P2pConnectionId_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for P2pConnectionId_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<P2pConnectionId_Bool> {
        match flag {
            0 => Ok(P2pConnectionId_Bool::False),
            255 => Ok(P2pConnectionId_Bool::True),
            _ => Ok(P2pConnectionId_Bool::Unknown(flag)),
        }
    }
}

impl From<&P2pConnectionId_Bool> for i64 {
    fn from(v: &P2pConnectionId_Bool) -> Self {
        match *v {
            P2pConnectionId_Bool::False => 0,
            P2pConnectionId_Bool::True => 255,
            P2pConnectionId_Bool::Unknown(v) => v
        }
    }
}

impl Default for P2pConnectionId_Bool {
    fn default() -> Self { P2pConnectionId_Bool::Unknown(0) }
}


/**
 * An address for locating peers.
 */

#[derive(Default, Debug, Clone)]
pub struct P2pConnectionId_P2pAddress {
    pub _root: SharedType<P2pConnectionId>,
    pub _parent: SharedType<P2pConnectionId>,
    pub _self: SharedType<Self>,
    len_p2p_address: RefCell<i32>,
    p2p_address: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pConnectionId_P2pAddress {
    type Root = P2pConnectionId;
    type Parent = P2pConnectionId;

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
        *self_rc.len_p2p_address.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.p2p_address.borrow_mut() = _io.read_bytes(*self_rc.len_p2p_address() as usize)?.into();
        Ok(())
    }
}
impl P2pConnectionId_P2pAddress {
}
impl P2pConnectionId_P2pAddress {
    pub fn len_p2p_address(&self) -> Ref<i32> {
        self.len_p2p_address.borrow()
    }
}
impl P2pConnectionId_P2pAddress {
    pub fn p2p_address(&self) -> Ref<Vec<u8>> {
        self.p2p_address.borrow()
    }
}
impl P2pConnectionId_P2pAddress {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
