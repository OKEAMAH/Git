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
pub struct Id015PtlimaptConstantsFixed {
    pub _root: SharedType<Id015PtlimaptConstantsFixed>,
    pub _parent: SharedType<Id015PtlimaptConstantsFixed>,
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
    sc_max_wrapped_proof_binary_size: RefCell<i32>,
    sc_rollup_message_size_limit: RefCell<i32>,
    _io: RefCell<BytesReader>,
}
impl KStruct for Id015PtlimaptConstantsFixed {
    type Root = Id015PtlimaptConstantsFixed;
    type Parent = Id015PtlimaptConstantsFixed;

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
        *self_rc.sc_max_wrapped_proof_binary_size.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.sc_rollup_message_size_limit.borrow_mut() = _io.read_s4be()?.into();
        Ok(())
    }
}
impl Id015PtlimaptConstantsFixed {
}
impl Id015PtlimaptConstantsFixed {
    pub fn proof_of_work_nonce_size(&self) -> Ref<u8> {
        self.proof_of_work_nonce_size.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn nonce_length(&self) -> Ref<u8> {
        self.nonce_length.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_anon_ops_per_block(&self) -> Ref<u8> {
        self.max_anon_ops_per_block.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_operation_data_length(&self) -> Ref<i32> {
        self.max_operation_data_length.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_proposals_per_delegate(&self) -> Ref<u8> {
        self.max_proposals_per_delegate.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_micheline_node_count(&self) -> Ref<i32> {
        self.max_micheline_node_count.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_micheline_bytes_limit(&self) -> Ref<i32> {
        self.max_micheline_bytes_limit.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn max_allowed_global_constants_depth(&self) -> Ref<i32> {
        self.max_allowed_global_constants_depth.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn cache_layout_size(&self) -> Ref<u8> {
        self.cache_layout_size.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn michelson_maximum_type_size(&self) -> Ref<u16> {
        self.michelson_maximum_type_size.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn sc_max_wrapped_proof_binary_size(&self) -> Ref<i32> {
        self.sc_max_wrapped_proof_binary_size.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn sc_rollup_message_size_limit(&self) -> Ref<i32> {
        self.sc_rollup_message_size_limit.borrow()
    }
}
impl Id015PtlimaptConstantsFixed {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
