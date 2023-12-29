// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use std::convert::Infallible;

use evm_execution::account_storage::{
    account_path, EthereumAccount, EthereumAccountStorage,
};
use primitive_types::H160;
use revm::primitives::db::Database;
use revm_primitives::{AccountInfo, Address, Bytecode, B256, U256};
use tezos_smart_rollup_host::runtime::Runtime;

pub struct EtherlinkDB<'a, Host: Runtime> {
    pub host: &'a mut Host,
    pub evm_account_storage: &'a mut EthereumAccountStorage,
}

fn get_account_opt<Host: Runtime>(
    db: &mut EtherlinkDB<'_, Host>,
    address: Address,
) -> Option<EthereumAccount> {
    let raw_address: [u8; 20] = <[u8; 20]>::from(address.0);
    let address = H160::from(raw_address);

    if let Ok(path) = account_path(&address) {
        db.evm_account_storage.get_or_create(db.host, &path).ok()
    } else {
        None
    }
}

impl<'a, Host: Runtime> Database for EtherlinkDB<'a, Host> {
    type Error = Infallible;

    /// Get basic account information.
    fn basic(&mut self, address: Address) -> Result<Option<AccountInfo>, Self::Error> {
        Ok(None)
    }

    /// Get account code by its hash.
    fn code_by_hash(&mut self, code_hash: B256) -> Result<Bytecode, Self::Error> {
        Ok(Bytecode::new())
    }

    /// Get storage value of address at index.
    fn storage(&mut self, address: Address, index: U256) -> Result<U256, Self::Error> {
        Ok(U256::ZERO)
    }

    /// Get block hash by block number.
    fn block_hash(&mut self, number: U256) -> Result<B256, Self::Error> {
        Ok(B256::ZERO)
    }
}
