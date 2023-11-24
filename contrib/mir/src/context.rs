use crate::ast::michelson_address::AddressHash;
use crate::gas::Gas;

#[derive(Debug)]
pub struct Ctx {
    pub gas: Gas,
    pub amount: i64,
    pub chain_id: tezos_crypto_rs::hash::ChainId,
    pub self_address: AddressHash,
    pub _operation_counter: u128,
}

impl Ctx {
    pub fn operation_counter(&mut self) -> u128 {
        self._operation_counter += 1;
        self._operation_counter
    }
}

impl Default for Ctx {
    fn default() -> Self {
        Ctx {
            gas: Gas::default(),
            amount: 0,
            // the default chain id is NetXynUjJNZm7wi, which is also the default chain id of octez-client in mockup mode
            chain_id: tezos_crypto_rs::hash::ChainId(vec![0xf3, 0xd4, 0x85, 0x54]),
            self_address: "KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi".try_into().unwrap(),
            _operation_counter: 0,
        }
    }
}
