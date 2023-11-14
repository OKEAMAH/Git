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
pub struct Id007Psdelph1DelegateFrozenBalanceByCycles {
    pub _root: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _self: SharedType<Self>,
    len_id_007__psdelph1__delegate__frozen_balance_by_cycles: RefCell<i32>,
    id_007__psdelph1__delegate__frozen_balance_by_cycles: RefCell<Vec<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries>>>,
    _io: RefCell<BytesReader>,
    id_007__psdelph1__delegate__frozen_balance_by_cycles_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id007Psdelph1DelegateFrozenBalanceByCycles {
    type Root = Id007Psdelph1DelegateFrozenBalanceByCycles;
    type Parent = Id007Psdelph1DelegateFrozenBalanceByCycles;

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
        *self_rc.len_id_007__psdelph1__delegate__frozen_balance_by_cycles.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.id_007__psdelph1__delegate__frozen_balance_by_cycles.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.id_007__psdelph1__delegate__frozen_balance_by_cycles_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_id_007__psdelph1__delegate__frozen_balance_by_cycles() as usize)?.into());
                let id_007__psdelph1__delegate__frozen_balance_by_cycles_raw = self_rc.id_007__psdelph1__delegate__frozen_balance_by_cycles_raw.borrow();
                let io_id_007__psdelph1__delegate__frozen_balance_by_cycles_raw = BytesReader::from(id_007__psdelph1__delegate__frozen_balance_by_cycles_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries>(&io_id_007__psdelph1__delegate__frozen_balance_by_cycles_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.id_007__psdelph1__delegate__frozen_balance_by_cycles.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles {
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles {
    pub fn len_id_007__psdelph1__delegate__frozen_balance_by_cycles(&self) -> Ref<i32> {
        self.len_id_007__psdelph1__delegate__frozen_balance_by_cycles.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles {
    pub fn id_007__psdelph1__delegate__frozen_balance_by_cycles(&self) -> Ref<Vec<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries>>> {
        self.id_007__psdelph1__delegate__frozen_balance_by_cycles.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles {
    pub fn id_007__psdelph1__delegate__frozen_balance_by_cycles_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.id_007__psdelph1__delegate__frozen_balance_by_cycles_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub _root: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _self: SharedType<Self>,
    cycle: RefCell<i32>,
    deposit: RefCell<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>>,
    fees: RefCell<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>>,
    rewards: RefCell<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    type Root = Id007Psdelph1DelegateFrozenBalanceByCycles;
    type Parent = Id007Psdelph1DelegateFrozenBalanceByCycles;

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
        let t = Self::read_into::<_, Id007Psdelph1DelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.deposit.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1DelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.fees.borrow_mut() = t;
        let t = Self::read_into::<_, Id007Psdelph1DelegateFrozenBalanceByCycles_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.rewards.borrow_mut() = t;
        Ok(())
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub fn cycle(&self) -> Ref<i32> {
        self.cycle.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub fn deposit(&self) -> Ref<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>> {
        self.deposit.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub fn fees(&self) -> Ref<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>> {
        self.fees.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub fn rewards(&self) -> Ref<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_N>> {
        self.rewards.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1DelegateFrozenBalanceByCycles_N {
    pub _root: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1DelegateFrozenBalanceByCycles_N {
    type Root = Id007Psdelph1DelegateFrozenBalanceByCycles;
    type Parent = Id007Psdelph1DelegateFrozenBalanceByCycles_Id007Psdelph1DelegateFrozenBalanceByCyclesEntries;

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
                let t = Self::read_into::<_, Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id007Psdelph1DelegateFrozenBalanceByCycles_N {
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk>>> {
        self.n.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
    pub _root: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles>,
    pub _parent: SharedType<Id007Psdelph1DelegateFrozenBalanceByCycles_N>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
    type Root = Id007Psdelph1DelegateFrozenBalanceByCycles;
    type Parent = Id007Psdelph1DelegateFrozenBalanceByCycles_N;

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
impl Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id007Psdelph1DelegateFrozenBalanceByCycles_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
