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
 * A version number for the network protocol (includes distributed DB version and p2p version)
 */

#[derive(Default, Debug, Clone)]
pub struct NetworkVersion {
    pub _root: SharedType<NetworkVersion>,
    pub _parent: SharedType<NetworkVersion>,
    pub _self: SharedType<Self>,
    chain_name: RefCell<OptRc<NetworkVersion_DistributedDbVersionName>>,
    distributed_db_version: RefCell<u16>,
    p2p_version: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for NetworkVersion {
    type Root = NetworkVersion;
    type Parent = NetworkVersion;

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
        let t = Self::read_into::<_, NetworkVersion_DistributedDbVersionName>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.chain_name.borrow_mut() = t;
        *self_rc.distributed_db_version.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.p2p_version.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl NetworkVersion {
}
impl NetworkVersion {
    pub fn chain_name(&self) -> Ref<OptRc<NetworkVersion_DistributedDbVersionName>> {
        self.chain_name.borrow()
    }
}

/**
 * A version number for the distributed DB protocol
 */
impl NetworkVersion {
    pub fn distributed_db_version(&self) -> Ref<u16> {
        self.distributed_db_version.borrow()
    }
}

/**
 * A version number for the p2p layer.
 */
impl NetworkVersion {
    pub fn p2p_version(&self) -> Ref<u16> {
        self.p2p_version.borrow()
    }
}
impl NetworkVersion {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * A name for the distributed DB protocol
 */

#[derive(Default, Debug, Clone)]
pub struct NetworkVersion_DistributedDbVersionName {
    pub _root: SharedType<NetworkVersion>,
    pub _parent: SharedType<NetworkVersion>,
    pub _self: SharedType<Self>,
    len_distributed_db_version__name: RefCell<i32>,
    distributed_db_version__name: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for NetworkVersion_DistributedDbVersionName {
    type Root = NetworkVersion;
    type Parent = NetworkVersion;

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
        *self_rc.len_distributed_db_version__name.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.distributed_db_version__name.borrow_mut() = _io.read_bytes(*self_rc.len_distributed_db_version__name() as usize)?.into();
        Ok(())
    }
}
impl NetworkVersion_DistributedDbVersionName {
}
impl NetworkVersion_DistributedDbVersionName {
    pub fn len_distributed_db_version__name(&self) -> Ref<i32> {
        self.len_distributed_db_version__name.borrow()
    }
}
impl NetworkVersion_DistributedDbVersionName {
    pub fn distributed_db_version__name(&self) -> Ref<Vec<u8>> {
        self.distributed_db_version__name.borrow()
    }
}
impl NetworkVersion_DistributedDbVersionName {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
