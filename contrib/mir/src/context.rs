use crate::ast::big_map::{InMemoryLazyStorage, LazyStorage};
use crate::ast::michelson_address::AddressHash;
use crate::gas::Gas;

pub struct Ctx<'a> {
    pub gas: Gas,
    pub amount: i64,
    pub chain_id: tezos_crypto_rs::hash::ChainId,
    pub self_address: AddressHash,
    // NB: lifetime is mandatory if we want to use types implementing with
    // references inside for LazyStorage, and we do due to how Runtime is passed
    // as &mut
    pub big_map_storage: Box<dyn LazyStorage + 'a>,
    operation_counter: u128,
}

impl Ctx<'_> {
    pub fn operation_counter(&mut self) -> u128 {
        self.operation_counter += 1;
        self.operation_counter
    }

    pub fn set_operation_counter(&mut self, v: u128) {
        self.operation_counter = v;
    }
}

impl Default for Ctx<'_> {
    fn default() -> Self {
        Ctx {
            gas: Gas::default(),
            amount: 0,
            // the default chain id is NetXynUjJNZm7wi, which is also the default chain id of octez-client in mockup mode
            chain_id: tezos_crypto_rs::hash::ChainId(vec![0xf3, 0xd4, 0x85, 0x54]),
            self_address: "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi".try_into().unwrap(),
            big_map_storage: Box::new(InMemoryLazyStorage::new()),
            operation_counter: 0,
        }
    }
}
