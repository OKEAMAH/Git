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
 * User activated protocol overrides: activate a protocol instead of another.
 */

#[derive(Default, Debug, Clone)]
pub struct UserActivatedProtocolOverrides {
    pub _root: SharedType<UserActivatedProtocolOverrides>,
    pub _parent: SharedType<UserActivatedProtocolOverrides>,
    pub _self: SharedType<Self>,
    len_user_activated__protocol_overrides: RefCell<i32>,
    user_activated__protocol_overrides: RefCell<Vec<OptRc<UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries>>>,
    _io: RefCell<BytesReader>,
    user_activated__protocol_overrides_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for UserActivatedProtocolOverrides {
    type Root = UserActivatedProtocolOverrides;
    type Parent = UserActivatedProtocolOverrides;

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
        *self_rc.len_user_activated__protocol_overrides.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.user_activated__protocol_overrides.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.user_activated__protocol_overrides_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_user_activated__protocol_overrides() as usize)?.into());
                let user_activated__protocol_overrides_raw = self_rc.user_activated__protocol_overrides_raw.borrow();
                let io_user_activated__protocol_overrides_raw = BytesReader::from(user_activated__protocol_overrides_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries>(&io_user_activated__protocol_overrides_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.user_activated__protocol_overrides.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl UserActivatedProtocolOverrides {
}
impl UserActivatedProtocolOverrides {
    pub fn len_user_activated__protocol_overrides(&self) -> Ref<i32> {
        self.len_user_activated__protocol_overrides.borrow()
    }
}
impl UserActivatedProtocolOverrides {
    pub fn user_activated__protocol_overrides(&self) -> Ref<Vec<OptRc<UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries>>> {
        self.user_activated__protocol_overrides.borrow()
    }
}
impl UserActivatedProtocolOverrides {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl UserActivatedProtocolOverrides {
    pub fn user_activated__protocol_overrides_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.user_activated__protocol_overrides_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
    pub _root: SharedType<UserActivatedProtocolOverrides>,
    pub _parent: SharedType<UserActivatedProtocolOverrides>,
    pub _self: SharedType<Self>,
    replaced_protocol: RefCell<Vec<u8>>,
    replacement_protocol: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
    type Root = UserActivatedProtocolOverrides;
    type Parent = UserActivatedProtocolOverrides;

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
        *self_rc.replaced_protocol.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.replacement_protocol.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        Ok(())
    }
}
impl UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
}
impl UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
    pub fn replaced_protocol(&self) -> Ref<Vec<u8>> {
        self.replaced_protocol.borrow()
    }
}
impl UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
    pub fn replacement_protocol(&self) -> Ref<Vec<u8>> {
        self.replacement_protocol.borrow()
    }
}
impl UserActivatedProtocolOverrides_UserActivatedProtocolOverridesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
