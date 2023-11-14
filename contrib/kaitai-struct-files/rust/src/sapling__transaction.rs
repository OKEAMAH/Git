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
 * A Sapling transaction with inputs, outputs, balance, root, bound_data and binding sig.
 */

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction>,
    pub _self: SharedType<Self>,
    inputs: RefCell<OptRc<SaplingTransaction_Inputs>>,
    outputs: RefCell<OptRc<SaplingTransaction_Outputs>>,
    binding_sig: RefCell<Vec<u8>>,
    balance: RefCell<i64>,
    root: RefCell<Vec<u8>>,
    bound_data: RefCell<OptRc<SaplingTransaction_BoundData>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction;

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
        let t = Self::read_into::<_, SaplingTransaction_Inputs>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.inputs.borrow_mut() = t;
        let t = Self::read_into::<_, SaplingTransaction_Outputs>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.outputs.borrow_mut() = t;
        *self_rc.binding_sig.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        *self_rc.balance.borrow_mut() = _io.read_s8be()?.into();
        *self_rc.root.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransaction_BoundData>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.bound_data.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransaction {
}
impl SaplingTransaction {
    pub fn inputs(&self) -> Ref<OptRc<SaplingTransaction_Inputs>> {
        self.inputs.borrow()
    }
}
impl SaplingTransaction {
    pub fn outputs(&self) -> Ref<OptRc<SaplingTransaction_Outputs>> {
        self.outputs.borrow()
    }
}

/**
 * Binding signature of a transaction
 */
impl SaplingTransaction {
    pub fn binding_sig(&self) -> Ref<Vec<u8>> {
        self.binding_sig.borrow()
    }
}
impl SaplingTransaction {
    pub fn balance(&self) -> Ref<i64> {
        self.balance.borrow()
    }
}
impl SaplingTransaction {
    pub fn root(&self) -> Ref<Vec<u8>> {
        self.root.borrow()
    }
}
impl SaplingTransaction {
    pub fn bound_data(&self) -> Ref<OptRc<SaplingTransaction_BoundData>> {
        self.bound_data.borrow()
    }
}
impl SaplingTransaction {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Output of a transaction
 */

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_SaplingTransactionOutput {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_OutputsEntries>,
    pub _self: SharedType<Self>,
    cm: RefCell<Vec<u8>>,
    proof_o: RefCell<Vec<u8>>,
    ciphertext: RefCell<OptRc<SaplingTransaction_SaplingTransactionCiphertext>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_SaplingTransactionOutput {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_OutputsEntries;

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
        *self_rc.cm.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.proof_o.borrow_mut() = _io.read_bytes(192 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransaction_SaplingTransactionCiphertext>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.ciphertext.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransaction_SaplingTransactionOutput {
}
impl SaplingTransaction_SaplingTransactionOutput {
    pub fn cm(&self) -> Ref<Vec<u8>> {
        self.cm.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionOutput {
    pub fn proof_o(&self) -> Ref<Vec<u8>> {
        self.proof_o.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionOutput {
    pub fn ciphertext(&self) -> Ref<OptRc<SaplingTransaction_SaplingTransactionCiphertext>> {
        self.ciphertext.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionOutput {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_SaplingTransactionCiphertext {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_SaplingTransactionOutput>,
    pub _self: SharedType<Self>,
    cv: RefCell<Vec<u8>>,
    epk: RefCell<Vec<u8>>,
    payload_enc: RefCell<OptRc<SaplingTransaction_PayloadEnc>>,
    nonce_enc: RefCell<Vec<u8>>,
    payload_out: RefCell<Vec<u8>>,
    nonce_out: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_SaplingTransactionCiphertext {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_SaplingTransactionOutput;

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
        *self_rc.cv.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.epk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        let t = Self::read_into::<_, SaplingTransaction_PayloadEnc>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.payload_enc.borrow_mut() = t;
        *self_rc.nonce_enc.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        *self_rc.payload_out.borrow_mut() = _io.read_bytes(80 as usize)?.into();
        *self_rc.nonce_out.borrow_mut() = _io.read_bytes(24 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn cv(&self) -> Ref<Vec<u8>> {
        self.cv.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn epk(&self) -> Ref<Vec<u8>> {
        self.epk.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn payload_enc(&self) -> Ref<OptRc<SaplingTransaction_PayloadEnc>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn nonce_enc(&self) -> Ref<Vec<u8>> {
        self.nonce_enc.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn payload_out(&self) -> Ref<Vec<u8>> {
        self.payload_out.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn nonce_out(&self) -> Ref<Vec<u8>> {
        self.nonce_out.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionCiphertext {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_Outputs {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction>,
    pub _self: SharedType<Self>,
    len_outputs: RefCell<i32>,
    outputs: RefCell<Vec<OptRc<SaplingTransaction_OutputsEntries>>>,
    _io: RefCell<BytesReader>,
    outputs_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for SaplingTransaction_Outputs {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction;

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
        *self_rc.len_outputs.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.outputs.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.outputs_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_outputs() as usize)?.into());
                let outputs_raw = self_rc.outputs_raw.borrow();
                let io_outputs_raw = BytesReader::from(outputs_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, SaplingTransaction_OutputsEntries>(&io_outputs_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.outputs.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl SaplingTransaction_Outputs {
}
impl SaplingTransaction_Outputs {
    pub fn len_outputs(&self) -> Ref<i32> {
        self.len_outputs.borrow()
    }
}
impl SaplingTransaction_Outputs {
    pub fn outputs(&self) -> Ref<Vec<OptRc<SaplingTransaction_OutputsEntries>>> {
        self.outputs.borrow()
    }
}
impl SaplingTransaction_Outputs {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl SaplingTransaction_Outputs {
    pub fn outputs_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.outputs_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_InputsEntries {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_Inputs>,
    pub _self: SharedType<Self>,
    sapling__transaction__input: RefCell<OptRc<SaplingTransaction_SaplingTransactionInput>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_InputsEntries {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_Inputs;

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
        let t = Self::read_into::<_, SaplingTransaction_SaplingTransactionInput>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.sapling__transaction__input.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransaction_InputsEntries {
}
impl SaplingTransaction_InputsEntries {
    pub fn sapling__transaction__input(&self) -> Ref<OptRc<SaplingTransaction_SaplingTransactionInput>> {
        self.sapling__transaction__input.borrow()
    }
}
impl SaplingTransaction_InputsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_Inputs {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction>,
    pub _self: SharedType<Self>,
    len_inputs: RefCell<i32>,
    inputs: RefCell<Vec<OptRc<SaplingTransaction_InputsEntries>>>,
    _io: RefCell<BytesReader>,
    inputs_raw: RefCell<Vec<Vec<u8>>>,
}
impl KStruct for SaplingTransaction_Inputs {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction;

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
        *self_rc.len_inputs.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.inputs.borrow_mut() = Vec::new();
        {
            let mut _i = 0;
            while !_io.is_eof() {
                self_rc.inputs_raw.borrow_mut().push(_io.read_bytes(*self_rc.len_inputs() as usize)?.into());
                let inputs_raw = self_rc.inputs_raw.borrow();
                let io_inputs_raw = BytesReader::from(inputs_raw.last().unwrap().clone());
                let t = Self::read_into::<BytesReader, SaplingTransaction_InputsEntries>(&io_inputs_raw, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
                self_rc.inputs.borrow_mut().push(t);
                _i += 1;
            }
        }
        Ok(())
    }
}
impl SaplingTransaction_Inputs {
}
impl SaplingTransaction_Inputs {
    pub fn len_inputs(&self) -> Ref<i32> {
        self.len_inputs.borrow()
    }
}
impl SaplingTransaction_Inputs {
    pub fn inputs(&self) -> Ref<Vec<OptRc<SaplingTransaction_InputsEntries>>> {
        self.inputs.borrow()
    }
}
impl SaplingTransaction_Inputs {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
impl SaplingTransaction_Inputs {
    pub fn inputs_raw(&self) -> Ref<Vec<Vec<u8>>> {
        self.inputs_raw.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_PayloadEnc {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_SaplingTransactionCiphertext>,
    pub _self: SharedType<Self>,
    len_payload_enc: RefCell<i32>,
    payload_enc: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_PayloadEnc {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_SaplingTransactionCiphertext;

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
        *self_rc.len_payload_enc.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.payload_enc.borrow_mut() = _io.read_bytes(*self_rc.len_payload_enc() as usize)?.into();
        Ok(())
    }
}
impl SaplingTransaction_PayloadEnc {
}
impl SaplingTransaction_PayloadEnc {
    pub fn len_payload_enc(&self) -> Ref<i32> {
        self.len_payload_enc.borrow()
    }
}
impl SaplingTransaction_PayloadEnc {
    pub fn payload_enc(&self) -> Ref<Vec<u8>> {
        self.payload_enc.borrow()
    }
}
impl SaplingTransaction_PayloadEnc {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_BoundData {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction>,
    pub _self: SharedType<Self>,
    len_bound_data: RefCell<i32>,
    bound_data: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_BoundData {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction;

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
        *self_rc.len_bound_data.borrow_mut() = _io.read_s4be()?.into();
        *self_rc.bound_data.borrow_mut() = _io.read_bytes(*self_rc.len_bound_data() as usize)?.into();
        Ok(())
    }
}
impl SaplingTransaction_BoundData {
}
impl SaplingTransaction_BoundData {
    pub fn len_bound_data(&self) -> Ref<i32> {
        self.len_bound_data.borrow()
    }
}
impl SaplingTransaction_BoundData {
    pub fn bound_data(&self) -> Ref<Vec<u8>> {
        self.bound_data.borrow()
    }
}
impl SaplingTransaction_BoundData {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

/**
 * Input of a transaction
 */

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_SaplingTransactionInput {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_InputsEntries>,
    pub _self: SharedType<Self>,
    cv: RefCell<Vec<u8>>,
    nf: RefCell<Vec<u8>>,
    rk: RefCell<Vec<u8>>,
    proof_i: RefCell<Vec<u8>>,
    signature: RefCell<Vec<u8>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_SaplingTransactionInput {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_InputsEntries;

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
        *self_rc.cv.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.nf.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.rk.borrow_mut() = _io.read_bytes(32 as usize)?.into();
        *self_rc.proof_i.borrow_mut() = _io.read_bytes(192 as usize)?.into();
        *self_rc.signature.borrow_mut() = _io.read_bytes(64 as usize)?.into();
        Ok(())
    }
}
impl SaplingTransaction_SaplingTransactionInput {
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn cv(&self) -> Ref<Vec<u8>> {
        self.cv.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn nf(&self) -> Ref<Vec<u8>> {
        self.nf.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn rk(&self) -> Ref<Vec<u8>> {
        self.rk.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn proof_i(&self) -> Ref<Vec<u8>> {
        self.proof_i.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn signature(&self) -> Ref<Vec<u8>> {
        self.signature.borrow()
    }
}
impl SaplingTransaction_SaplingTransactionInput {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}

#[derive(Default, Debug, Clone)]
pub struct SaplingTransaction_OutputsEntries {
    pub _root: SharedType<SaplingTransaction>,
    pub _parent: SharedType<SaplingTransaction_Outputs>,
    pub _self: SharedType<Self>,
    sapling__transaction__output: RefCell<OptRc<SaplingTransaction_SaplingTransactionOutput>>,
    _io: RefCell<BytesReader>,
}
impl KStruct for SaplingTransaction_OutputsEntries {
    type Root = SaplingTransaction;
    type Parent = SaplingTransaction_Outputs;

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
        let t = Self::read_into::<_, SaplingTransaction_SaplingTransactionOutput>(&*_io, Some(self_rc._root.clone()), Some(self_rc._self.clone()))?.into();
        *self_rc.sapling__transaction__output.borrow_mut() = t;
        Ok(())
    }
}
impl SaplingTransaction_OutputsEntries {
}
impl SaplingTransaction_OutputsEntries {
    pub fn sapling__transaction__output(&self) -> Ref<OptRc<SaplingTransaction_SaplingTransactionOutput>> {
        self.sapling__transaction__output.borrow()
    }
}
impl SaplingTransaction_OutputsEntries {
    pub fn _io(&self) -> Ref<BytesReader> {
        self._io.borrow()
    }
}
