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
pub struct Id016PtmumbaiFa12TokenTransfer {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    token_contract: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_TokenContract>>,
    destination: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_Destination>>,
    amount: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_Z>>,
    tez__amount_tag: RefCell<Id016PtmumbaiFa12TokenTransfer_Bool>,
    tez__amount: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_TezAmount>>,
    fee_tag: RefCell<Id016PtmumbaiFa12TokenTransfer_Bool>,
    fee: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_Fee>>,
    gas__limit_tag: RefCell<Id016PtmumbaiFa12TokenTransfer_Bool>,
    gas__limit: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_N>>,
    storage__limit_tag: RefCell<Id016PtmumbaiFa12TokenTransfer_Bool>,
    storage__limit: RefCell<OptRc<Id016PtmumbaiFa12TokenTransfer_Z>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_TokenContract>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.token_contract.borrow_mut() = t;
        let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_Destination>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.destination.borrow_mut() = t;
        let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.amount.borrow_mut() = t;
        *self_rc.tez__amount_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.tez__amount_tag() == Id016PtmumbaiFa12TokenTransfer_Bool::True {
            let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_TezAmount>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.tez__amount.borrow_mut() = t;
        }
        *self_rc.fee_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.fee_tag() == Id016PtmumbaiFa12TokenTransfer_Bool::True {
            let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_Fee>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.fee.borrow_mut() = t;
        }
        *self_rc.gas__limit_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.gas__limit_tag() == Id016PtmumbaiFa12TokenTransfer_Bool::True {
            let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.gas__limit.borrow_mut() = t;
        }
        *self_rc.storage__limit_tag.borrow_mut() = (_io.read_u1()? as i64).try_into()?;
        if *self_rc.storage__limit_tag() == Id016PtmumbaiFa12TokenTransfer_Bool::True {
            let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_Z>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
            *self_rc.storage__limit.borrow_mut() = t;
        }
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn token_contract(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_TokenContract>> {
        self.token_contract.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn destination(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_Destination>> {
        self.destination.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn amount(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_Z>> {
        self.amount.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn tez__amount_tag(&self) -> Ref<Id016PtmumbaiFa12TokenTransfer_Bool> {
        self.tez__amount_tag.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn tez__amount(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_TezAmount>> {
        self.tez__amount.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn fee_tag(&self) -> Ref<Id016PtmumbaiFa12TokenTransfer_Bool> {
        self.fee_tag.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn fee(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_Fee>> {
        self.fee.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn gas__limit_tag(&self) -> Ref<Id016PtmumbaiFa12TokenTransfer_Bool> {
        self.gas__limit_tag.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn gas__limit(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_N>> {
        self.gas__limit.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn storage__limit_tag(&self) -> Ref<Id016PtmumbaiFa12TokenTransfer_Bool> {
        self.storage__limit_tag.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn storage__limit(&self) -> Ref<OptRc<Id016PtmumbaiFa12TokenTransfer_Z>> {
        self.storage__limit.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
#[derive(Debug, PartialEq, Clone)]
pub enum Id016PtmumbaiFa12TokenTransfer_Bool {
    False,
    True,
    Unknown(i64),
}

impl TryFrom<i64> for Id016PtmumbaiFa12TokenTransfer_Bool {
    type Error = KError;
    fn try_from(flag: i64) -> KResult<Id016PtmumbaiFa12TokenTransfer_Bool> {
        match flag {
            0 => Ok(Id016PtmumbaiFa12TokenTransfer_Bool::False),
            255 => Ok(Id016PtmumbaiFa12TokenTransfer_Bool::True),
            _ => Ok(Id016PtmumbaiFa12TokenTransfer_Bool::Unknown(flag)),
        }
    }
}

impl From<&Id016PtmumbaiFa12TokenTransfer_Bool> for i64 {
    fn from(v: &Id016PtmumbaiFa12TokenTransfer_Bool) -> Self {
        match *v {
            Id016PtmumbaiFa12TokenTransfer_Bool::False => 0,
            Id016PtmumbaiFa12TokenTransfer_Bool::True => 255,
            Id016PtmumbaiFa12TokenTransfer_Bool::Unknown(v) => v
        }
    }
}

impl Default for Id016PtmumbaiFa12TokenTransfer_Bool {
    fn default() -> Self { Id016PtmumbaiFa12TokenTransfer_Bool::Unknown(0) }
}


#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_N {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id016PtmumbaiFa12TokenTransfer_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_N {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
                let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
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
impl Id016PtmumbaiFa12TokenTransfer_N {
}
impl Id016PtmumbaiFa12TokenTransfer_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id016PtmumbaiFa12TokenTransfer_NChunk>>> {
        self.n.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_TokenContract {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    len_token_contract: RefCell<i32>,
    token_contract: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_TokenContract {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        *self_rc.len_token_contract.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.token_contract.borrow_mut() = _io.read_bytes(*self_rc.len_token_contract() as usize)?.into();
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TokenContract {
}
impl Id016PtmumbaiFa12TokenTransfer_TokenContract {
    pub fn len_token_contract(&self) -> Ref<i32> {
        self.len_token_contract.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TokenContract {
    pub fn token_contract(&self) -> Ref<Vec<u8>> {
        self.token_contract.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TokenContract {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_TezAmount {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    len_tez__amount: RefCell<i32>,
    tez__amount: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_TezAmount {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        *self_rc.len_tez__amount.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.tez__amount.borrow_mut() = _io.read_bytes(*self_rc.len_tez__amount() as usize)?.into();
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TezAmount {
}
impl Id016PtmumbaiFa12TokenTransfer_TezAmount {
    pub fn len_tez__amount(&self) -> Ref<i32> {
        self.len_tez__amount.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TezAmount {
    pub fn tez__amount(&self) -> Ref<Vec<u8>> {
        self.tez__amount.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_TezAmount {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_NChunk {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<KStructUnit>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_NChunk {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = KStructUnit;

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
impl Id016PtmumbaiFa12TokenTransfer_NChunk {
}
impl Id016PtmumbaiFa12TokenTransfer_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_Destination {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    len_destination: RefCell<i32>,
    destination: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_Destination {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        *self_rc.len_destination.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.destination.borrow_mut() = _io.read_bytes(*self_rc.len_destination() as usize)?.into();
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Destination {
}
impl Id016PtmumbaiFa12TokenTransfer_Destination {
    pub fn len_destination(&self) -> Ref<i32> {
        self.len_destination.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Destination {
    pub fn destination(&self) -> Ref<Vec<u8>> {
        self.destination.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Destination {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_Z {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    has_tail: RefCell<bool>,
    sign: RefCell<bool>,
    payload: RefCell<u64>,
    tail: RefCell<Vec<OptRc<Id016PtmumbaiFa12TokenTransfer_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_Z {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        *self_rc.has_tail.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.sign.borrow_mut() = _io.read_bits_int_be(1)? != 0;
        *self_rc.payload.borrow_mut() = _io.read_bits_int_be(6)?;
        _io.align_to_byte()?;
        if (*self_rc.has_tail() as bool) {
            *self_rc.tail.borrow_mut() = Vec::new();
            {
                let mut _i = 0;
                while {
                    let t = Self::read_into::<_, Id016PtmumbaiFa12TokenTransfer_NChunk>(&*_io, Some(self_rc._root.clone()), None)?.into();
                    self_rc.tail.borrow_mut().push(t);
                    let _t_tail = self_rc.tail.borrow();
                    let _tmpa = _t_tail.last().unwrap();
                    _i += 1;
                    let x = !(!((*_tmpa.has_more() as bool)));
                    x
                } {}
            }
        }
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
    pub fn has_tail(&self) -> Ref<bool> {
        self.has_tail.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
    pub fn sign(&self) -> Ref<bool> {
        self.sign.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
    pub fn tail(&self) -> Ref<Vec<OptRc<Id016PtmumbaiFa12TokenTransfer_NChunk>>> {
        self.tail.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Z {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id016PtmumbaiFa12TokenTransfer_Fee {
    pub _root: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _parent: SharedType<Id016PtmumbaiFa12TokenTransfer>,
    pub _self: SharedType<Self>,
    len_fee: RefCell<i32>,
    fee: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id016PtmumbaiFa12TokenTransfer_Fee {
    type Root = Id016PtmumbaiFa12TokenTransfer;
    type Parent = Id016PtmumbaiFa12TokenTransfer;

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
        *self_rc.len_fee.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.fee.borrow_mut() = _io.read_bytes(*self_rc.len_fee() as usize)?.into();
        Ok(())
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Fee {
}
impl Id016PtmumbaiFa12TokenTransfer_Fee {
    pub fn len_fee(&self) -> Ref<i32> {
        self.len_fee.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Fee {
    pub fn fee(&self) -> Ref<Vec<u8>> {
        self.fee.borrow()
    }
}
impl Id016PtmumbaiFa12TokenTransfer_Fee {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
