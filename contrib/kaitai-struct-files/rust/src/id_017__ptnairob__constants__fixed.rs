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
pub struct Id017PtnairobConstantsFixed {
    pub _root: SharedType<Id017PtnairobConstantsFixed>,
    pub _parent: SharedType<Id017PtnairobConstantsFixed>,
    pub _self: SharedType<Self>,
    proof_of_work_nonce_size: RefCell<u8>,
    nonce_length: RefCell<u8>,
    max_anon_ops_per_block: RefCell<u8>,
    max_operation_data_length: RefCell<i32>,
    max_proposals_per_delegate: RefCell<u8>,
    max_micheline_node_count: RefCell<i32>,
    max_micheline_bytes_limit: RefCell<i32>,
    max_allowed_global_constants_depth: RefCell<i32>,
    cache_layout_size: RefCell<u8>,
    michelson_maximum_type_size: RefCell<u16>,
    smart_rollup_max_wrapped_proof_binary_size: RefCell<i32>,
    smart_rollup_message_size_limit: RefCell<i32>,
    smart_rollup_max_number_of_messages_per_level: RefCell<OptRc<Id017PtnairobConstantsFixed_N>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstantsFixed {
    type Root = Id017PtnairobConstantsFixed;
    type Parent = Id017PtnairobConstantsFixed;

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
        *self_rc.cache_layout_size.borrow_mut() = _io.read_u1()?.into();
        *self_rc.michelson_maximum_type_size.borrow_mut() = _io.read_u2be()?.into();
        *self_rc.smart_rollup_max_wrapped_proof_binary_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.smart_rollup_message_size_limit.borrow_mut() = _io.read_s4be()?.into();
        let t = Self::read_into::<_, Id017PtnairobConstantsFixed_N>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.smart_rollup_max_number_of_messages_per_level.borrow_mut() = t;
        Ok(())
    }
}
impl Id017PtnairobConstantsFixed {
}
impl Id017PtnairobConstantsFixed {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn cache_layout_size(&self) -> Ref<u8> {
        self.cache_layout_size.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn smart_rollup_max_wrapped_proof_binary_size(&self) -> Ref<i32> {
        self.smart_rollup_max_wrapped_proof_binary_size.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn smart_rollup_message_size_limit(&self) -> Ref<i32> {
        self.smart_rollup_message_size_limit.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn smart_rollup_max_number_of_messages_per_level(&self) -> Ref<OptRc<Id017PtnairobConstantsFixed_N>> {
        self.smart_rollup_max_number_of_messages_per_level.borrow()
    }
}
impl Id017PtnairobConstantsFixed {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstantsFixed_N {
    pub _root: SharedType<Id017PtnairobConstantsFixed>,
    pub _parent: SharedType<Id017PtnairobConstantsFixed>,
    pub _self: SharedType<Self>,
    n: RefCell<Vec<OptRc<Id017PtnairobConstantsFixed_NChunk>>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstantsFixed_N {
    type Root = Id017PtnairobConstantsFixed;
    type Parent = Id017PtnairobConstantsFixed;

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
                let t = Self::read_into::<_, Id017PtnairobConstantsFixed_NChunk>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
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
impl Id017PtnairobConstantsFixed_N {
}
impl Id017PtnairobConstantsFixed_N {
    pub fn n(&self) -> Ref<Vec<OptRc<Id017PtnairobConstantsFixed_NChunk>>> {
        self.n.borrow()
    }
}
impl Id017PtnairobConstantsFixed_N {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct Id017PtnairobConstantsFixed_NChunk {
    pub _root: SharedType<Id017PtnairobConstantsFixed>,
    pub _parent: SharedType<Id017PtnairobConstantsFixed_N>,
    pub _self: SharedType<Self>,
    has_more: RefCell<bool>,
    payload: RefCell<u64>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id017PtnairobConstantsFixed_NChunk {
    type Root = Id017PtnairobConstantsFixed;
    type Parent = Id017PtnairobConstantsFixed_N;

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
impl Id017PtnairobConstantsFixed_NChunk {
}
impl Id017PtnairobConstantsFixed_NChunk {
    pub fn has_more(&self) -> Ref<bool> {
        self.has_more.borrow()
    }
}
impl Id017PtnairobConstantsFixed_NChunk {
    pub fn payload(&self) -> Ref<u64> {
        self.payload.borrow()
    }
}
impl Id017PtnairobConstantsFixed_NChunk {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
