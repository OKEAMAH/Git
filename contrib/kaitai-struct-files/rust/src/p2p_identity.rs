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
 * The identity of a peer. This includes cryptographic keys as well as a proof-of-work.
 */

#[derive(Default, Debug, Clone)]
pub struct P2pIdentity {
    pub _root: SharedType<P2pIdentity>,
    pub _parent: SharedType<P2pIdentity>,
    pub _self: SharedType<Self>,
    peer_id_tag: RefCell<P2pIdentity_Bool>,
    peer_id: RefCell<Vec<u8>>,
    public_key: RefCell<Vec<u8>>,
    secret_key: RefCell<Vec<u8>>,
    proof_of_work_stamp: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for P2pIdentity {
    type Root = P2pIdentity;
    type Parent = P2pIdentity;

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
        *self_rc.peer_id_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.peer_id_tag() == P2pIdentity_Bool::True {
            *self_rc.peer_id.borrow_mut() = _io.read_bytes(16 as usize)?.into();
        }
        *self_rc.public_key.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.secret_key.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.proof_of_work_stamp.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        Ok(())
    }
}
impl P2pIdentity {
}
impl P2pIdentity {
    pub fn peer_id_tag(&self) -> Ref<P2pIdentity_Bool> {
        self.peer_id_tag.borrow()
    }
}
impl P2pIdentity {
    pub fn peer_id(&self) -> Ref<Vec<u8>> {
        self.peer_id.borrow()
    }
}
impl P2pIdentity {
    pub fn public_key(&self) -> Ref<Vec<u8>> {
        self.public_key.borrow()
    }
}
impl P2pIdentity {
    pub fn secret_key(&self) -> Ref<Vec<u8>> {
        self.secret_key.borrow()
    }
}
impl P2pIdentity {
    pub fn proof_of_work_stamp(&self) -> Ref<Vec<u8>> {
        self.proof_of_work_stamp.borrow()
    }
}
impl P2pIdentity {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum P2pIdentity_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for P2pIdentity_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<P2pIdentity_Bool> {
        match flag {
            0 => Ok(P2pIdentity_Bool::False),
            255 => Ok(P2pIdentity_Bool::True),
            _ => Ok(P2pIdentity_Bool::Unknown(flag)),
        }
    }
}

impl From<&P2pIdentity_Bool> for i64 {
    fn from(v: &P2pIdentity_Bool) -> Self {
        match *v {
            P2pIdentity_Bool::False => 0,
            P2pIdentity_Bool::True => 255,
            P2pIdentity_Bool::Unknown(v) => v
        }
    }
}

impl Default for P2pIdentity_Bool {
    fn default() -> Self { P2pIdentity_Bool::Unknown(0) }
}

