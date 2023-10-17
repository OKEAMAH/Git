use evm::backend::{ApplyBackend, Backend, Basic, Apply};
use host::runtime::Runtime;
use tezos_ethereum::block::BlockConstants;
use tezos_ethereum::Log;
use primitive_types::{H256, U256, H160};
use crate::evm_storage;

pub struct RollupBackend<'a, Host: Runtime> {
    host: &'a mut Host,
    block: &'a BlockConstants,
    origin: H160,
    simulate_only: bool,
    pub error: Option<anyhow::Error>,
}

impl<'a, H: Runtime> RollupBackend<'a, H> {
    pub fn new(
        host: &'a mut H,
        block: &'a BlockConstants,
        origin: H160,
        simulate_only: bool,
    ) -> Self {
        RollupBackend {
            host,
            block,
            origin,
            simulate_only,
            error: None,
        }
    }

    fn alert_error(&self, error: anyhow::Error) {
        todo!()
    }
}

impl<'a, Host: Runtime> Backend for RollupBackend<'a, Host> {
    fn gas_price(&self) -> U256 {
        self.block.gas_price
    }

    fn origin(&self) -> H160 {
        self.origin
    }

    fn block_hash(&self, number: U256) -> H256 {
        if self.block.number - number > U256::from(256) {
            H256::zero()
        } else {
            todo!()
        }
    }

    fn block_number(&self) -> U256 {
        self.block.number
    }

    fn block_coinbase(&self) -> H160 {
        self.block.coinbase
    }

    fn block_timestamp(&self) -> U256 {
        self.block.timestamp
    }

    fn block_difficulty(&self) -> U256 {
        U256::zero()
    }

    fn block_randomness(&self) -> Option<H256> {
        None // STUB - todo
    }

    fn block_gas_limit(&self) -> U256 {
        self.block.gas_limit.into()
    }

    fn block_base_fee_per_gas(&self) -> U256 {
        self.block.base_fee_per_gas
    }

    fn chain_id(&self) -> U256 {
        self.block.chain_id
    }

    fn exists(&self, address: H160) -> bool {
        match evm_storage::account_exists(self.host, &address) {
            Ok(value) => value,
            Err(err) => {
                self.alert_error(err);
                false
            }
        }
    }

    fn basic(&self, address: H160) -> Basic {
        match evm_storage::account_info(self.host, &address) {
            Ok(info) => info,
            Err(err) => {
                self.alert_error(err);
                Basic {
                    nonce: U256::zero(),
                    balance: U256::zero(),
                }
            }
        }
    }

    fn code(&self, address: H160) -> Vec<u8> {
        match evm_storage::get_code(self.host, &address) {
            Ok(code) => code,
            Err(err) => {
                self.alert_error(err);
                vec![]
            }
        }
    }

    fn storage(&self, address: H160, index: H256) -> H256 {
        match evm_storage::get_storage(self.host, &address, &index) {
            Ok(value) => value,
            Err(err) => {
                self.alert_error(err);
                H256::zero()
            }
        }
    }

    fn original_storage(&self, address: H160, index: H256) -> Option<H256> {
        match evm_storage::get_storage_opt(self.host, &address, &index) {
            Ok(value) => value,
            Err(err) => {
                self.alert_error(err);
                None
            }
        }
    }
}

impl<'a, H: Runtime> ApplyBackend for RollupBackend<'a, H> {
    fn apply<A, I, L>(&mut self, values: A, logs: L, delete_empty: bool)
        where A: IntoIterator<Item = Apply<I>>,
              I: IntoIterator<Item = (H256, H256)>,
              L: IntoIterator<Item = Log>,
    {
        if !self.simulate_only {
            for value in values {
                match value {
                    Apply::Modify { address, basic, code, storage, reset_storage } => {
                    }
                    Apply::Delete { address } => {
                    }
                }
            }

            for log in logs {
                todo!()
            }
        }
    }
}

