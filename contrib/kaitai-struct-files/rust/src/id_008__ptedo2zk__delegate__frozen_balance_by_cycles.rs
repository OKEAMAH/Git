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
pub struct Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    pub _root: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _self: SharedType<Self>,
    len_id_008__ptedo2zk__delegate__frozen_balance_by_cycles: RefCell<i32>,
    id_008__ptedo2zk__delegate__frozen_balance_by_cycles: RefCell<Vec<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries>>>,
    _io: RefCell<BytesReader>,
    id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    type Root = Id008Ptedo2zkDelegateFrozenBalanceByCycles;
    type Parent = Id008Ptedo2zkDelegateFrozenBalanceByCycles;

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
        *self_rc.len_id_008__ptedo2zk__delegate__frozen_balance_by_cycles.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.id_008__ptedo2zk__delegate__frozen_balance_by_cycles.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_id_008__ptedo2zk__delegate__frozen_balance_by_cycles() as usize)?.into());
                let id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw = self_rc.id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw.borrow();
                let io_id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw = BytesReader::from(id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries>(&io_id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.id_008__ptedo2zk__delegate__frozen_balance_by_cycles.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles {
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    pub fn len_id_008__ptedo2zk__delegate__frozen_balance_by_cycles(&self) -> Ref<i32> {
        self.len_id_008__ptedo2zk__delegate__frozen_balance_by_cycles.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    pub fn id_008__ptedo2zk__delegate__frozen_balance_by_cycles(&self) -> Ref<Vec<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries>>> {
        self.id_008__ptedo2zk__delegate__frozen_balance_by_cycles.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles {
    pub fn id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.id_008__ptedo2zk__delegate__frozen_balance_by_cycles_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub _root: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _self: SharedType<Self>,
    cycle: RefCell<i32>,
    deposit: RefCell<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>>,
    fees: RefCell<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>>,
    rewards: RefCell<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    type Root = Id008Ptedo2zkDelegateFrozenBalanceByCycles;
    type Parent = Id008Ptedo2zkDelegateFrozenBalanceByCycles;

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
        *self_rc.cycle.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fees.borrow_mut() = t;
        let t = Self::read_into::<_, Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.rewards.borrow_mut() = t;
        Ok(())
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub fn deposit(&self) -> Ref<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>> {
        self.deposit.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub fn fees(&self) -> Ref<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>> {
        self.fees.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub fn rewards(&self) -> Ref<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>> {
        self.rewards.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkDelegateFrozenBalanceByCycles_N {
    pub _root: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkDelegateFrozenBalanceByCycles_N {
    type Root = Id008Ptedo2zkDelegateFrozenBalanceByCycles;
    type Parent = Id008Ptedo2zkDelegateFrozenBalanceByCycles_Id008Ptedo2zkDelegateFrozenBalanceByCyclesEntries;

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
        *self_rc.n.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while {
                let t = Self::read_into::<_, Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.n.borrow_mut().push(t);
                let _t_n = self_rc.n.borrow();
                let _tmpa = _t_n.last().unwrap();
                _i += 1;
                let x = !(!((*_tmpa.has_more() as bool)));
                x
            } {}
        }
        Ok(())
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_N {
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk>>> {
        self.n.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
    pub _root: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id008Ptedo2zkDelegateFrozenBalanceByCycles_N>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
    type Root = Id008Ptedo2zkDelegateFrozenBalanceByCycles;
    type Parent = Id008Ptedo2zkDelegateFrozenBalanceByCycles_N;

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
        *self_rc.has_more.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(7)?;
        Ok(())
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id008Ptedo2zkDelegateFrozenBalanceByCycles_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
