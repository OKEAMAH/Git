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
 * User activated upgrades: at given level, switch to given protocol.
 */

#[derive(Default, Debug, Clone)]
pub struct UserActivatedUpgrades {
    pub _root: SharedType<UserActivatedUpgrades>,
    pub _parent: SharedType<UserActivatedUpgrades>,
    pub _self: SharedType<Self>,
    len_user_activated__upgrades: RefCell<i32>,
    user_activated__upgrades: RefCell<Vec<OptRc<UserActivatedUpgrades_UserActivatedUpgradesEntries>>>,
    _io: RefCell<BytesReader>,
    user_activated__upgrades_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for UserActivatedUpgrades {
    type Root = UserActivatedUpgrades;
    type Parent = UserActivatedUpgrades;

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
        *self_rc.len_user_activated__upgrades.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.user_activated__upgrades.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.user_activated__upgrades_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_user_activated__upgrades() as usize)?.into());
                let user_activated__upgrades_raw = self_rc.user_activated__upgrades_raw.borrow();
                let io_user_activated__upgrades_raw = BytesReader::from(user_activated__upgrades_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, UserActivatedUpgrades_UserActivatedUpgradesEntries>(&io_user_activated__upgrades_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.user_activated__upgrades.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl UserActivatedUpgrades {
}
impl UserActivatedUpgrades {
    pub fn len_user_activated__upgrades(&self) -> Ref<i32> {
        self.len_user_activated__upgrades.borrow()
    }
}
impl UserActivatedUpgrades {
    pub fn user_activated__upgrades(&self) -> Ref<Vec<OptRc<UserActivatedUpgrades_UserActivatedUpgradesEntries>>> {
        self.user_activated__upgrades.borrow()
    }
}
impl UserActivatedUpgrades {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl UserActivatedUpgrades {
    pub fn user_activated__upgrades_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.user_activated__upgrades_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct UserActivatedUpgrades_UserActivatedUpgradesEntries {
    pub _root: SharedType<UserActivatedUpgrades>,
    pub _parent: SharedType<UserActivatedUpgrades>,
    pub _self: SharedType<Self>,
    level: RefCell<i32>,
    replacement_protocol: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for UserActivatedUpgrades_UserActivatedUpgradesEntries {
    type Root = UserActivatedUpgrades;
    type Parent = UserActivatedUpgrades;

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
        *self_rc.level.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.replacement_protocol.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl UserActivatedUpgrades_UserActivatedUpgradesEntries {
}
impl UserActivatedUpgrades_UserActivatedUpgradesEntries {
    pub fn level(&self) -> Ref<i32> {
        self.level.borrow()
    }
}
impl UserActivatedUpgrades_UserActivatedUpgradesEntries {
    pub fn replacement_protocol(&self) -> Ref<Vec<u8>> {
        self.replacement_protocol.borrow()
    }
}
impl UserActivatedUpgrades_UserActivatedUpgradesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
