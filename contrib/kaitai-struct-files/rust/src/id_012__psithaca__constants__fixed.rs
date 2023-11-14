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
pub struct Id012PsithacaConstantsFixed {
    pub _root: SharedType<Id012PsithacaConstantsFixed>,
    pub _parent: SharedType<Id012PsithacaConstantsFixed>,
    pub _self: SharedType<Self>,
    proof_of_work_nonce_size: RefCell<u8>,
    nonce_length: RefCell<u8>,
    max_anon_ops_per_block: RefCell<u8>,
    max_operation_data_length: RefCell<i32>,
    max_proposals_per_delegate: RefCell<u8>,
    max_micheline_node_count: RefCell<i32>,
    max_micheline_bytes_limit: RefCell<i32>,
    max_allowed_global_constants_depth: RefCell<i32>,
    cache_layout: RefCell<OptRc<Id012PsithacaConstantsFixed_CacheLayout>>,
    michelson_maximum_type_size: RefCell<u16>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstantsFixed {
    type Root = Id012PsithacaConstantsFixed;
    type Parent = Id012PsithacaConstantsFixed;

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
        *self_rc.proof_of_work_nonce_size.borrow_mut() = _io.read_u1()?.into();
        *self_rc.nonce_length.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_anon_ops_per_block.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_operation_data_length.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_proposals_per_delegate.borrow_mut() = _io.read_u1()?.into();
        *self_rc.max_micheline_node_count.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_micheline_bytes_limit.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.max_allowed_global_constants_depth.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id012PsithacaConstantsFixed_CacheLayout>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.cache_layout.borrow_mut() = t;
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        Ok(())
    }
}
impl Id012PsithacaConstantsFixed {
}
impl Id012PsithacaConstantsFixed {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn cache_layout(&self) -> Ref<OptRc<Id012PsithacaConstantsFixed_CacheLayout>> {
        self.cache_layout.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id012PsithacaConstantsFixed {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstantsFixed_CacheLayout {
    pub _root: SharedType<Id012PsithacaConstantsFixed>,
    pub _parent: SharedType<Id012PsithacaConstantsFixed>,
    pub _self: SharedType<Self>,
    len_cache_layout: RefCell<i32>,
    cache_layout: RefCell<Vec<OptRc<Id012PsithacaConstantsFixed_CacheLayoutEntries>>>,
    _io: RefCell<BytesReader>,
    cache_layout_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for Id012PsithacaConstantsFixed_CacheLayout {
    type Root = Id012PsithacaConstantsFixed;
    type Parent = Id012PsithacaConstantsFixed;

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
        *self_rc.len_cache_layout.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.cache_layout.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.cache_layout_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_cache_layout() as usize)?.into());
                let cache_layout_raw = self_rc.cache_layout_raw.borrow();
                let io_cache_layout_raw = BytesReader::from(cache_layout_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, Id012PsithacaConstantsFixed_CacheLayoutEntries>(&io_cache_layout_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.cache_layout.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl Id012PsithacaConstantsFixed_CacheLayout {
}
impl Id012PsithacaConstantsFixed_CacheLayout {
    pub fn len_cache_layout(&self) -> Ref<i32> {
        self.len_cache_layout.borrow()
    }
}
impl Id012PsithacaConstantsFixed_CacheLayout {
    pub fn cache_layout(&self) -> Ref<Vec<OptRc<Id012PsithacaConstantsFixed_CacheLayoutEntries>>> {
        self.cache_layout.borrow()
    }
}
impl Id012PsithacaConstantsFixed_CacheLayout {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl Id012PsithacaConstantsFixed_CacheLayout {
    pub fn cache_layout_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.cache_layout_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id012PsithacaConstantsFixed_CacheLayoutEntries {
    pub _root: SharedType<Id012PsithacaConstantsFixed>,
    pub _parent: SharedType<Id012PsithacaConstantsFixed_CacheLayout>,
    pub _self: SharedType<Self>,
    cache_layout_elt: RefCell<i64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id012PsithacaConstantsFixed_CacheLayoutEntries {
    type Root = Id012PsithacaConstantsFixed;
    type Parent = Id012PsithacaConstantsFixed_CacheLayout;

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
        *self_rc.cache_layout_elt.borrow_mut() = _io.read_s8be()?.into();
        Ok(())
    }
}
impl Id012PsithacaConstantsFixed_CacheLayoutEntries {
}
impl Id012PsithacaConstantsFixed_CacheLayoutEntries {
    pub fn cache_layout_elt(&self) -> Ref<i64> {
        self.cache_layout_elt.borrow()
    }
}
impl Id012PsithacaConstantsFixed_CacheLayoutEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
