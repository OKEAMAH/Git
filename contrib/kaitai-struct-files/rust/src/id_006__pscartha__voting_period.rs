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
pub struct Id006PscarthaVotingPeriod {
    pub _root: SharedType<Id006PscarthaVotingPeriod>,
    pub _parent: SharedType<Id006PscarthaVotingPeriod>,
    pub _self: SharedType<Self>,
    id_006__pscartha__voting_period: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id006PscarthaVotingPeriod {
    type Root = Id006PscarthaVotingPeriod;
    type Parent = Id006PscarthaVotingPeriod;

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
        *self_rc.id_006__pscartha__voting_period.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id006PscarthaVotingPeriod {
}
impl Id006PscarthaVotingPeriod {
    pub fn id_006__pscartha__voting_period(&self) -> Ref<i32> {
        self.id_006__pscartha__voting_period.borrow()
    }
}
impl Id006PscarthaVotingPeriod {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
