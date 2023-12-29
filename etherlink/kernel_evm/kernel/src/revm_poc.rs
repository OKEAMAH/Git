// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use std::convert::Infallible;

use evm_execution::{
    account_storage::{account_path, EthereumAccount, EthereumAccountStorage},
    storage::blocks::get_block_hash,
};
use primitive_types::{H160, H256, U256};
use revm::primitives::db::Database;
use revm_primitives::{
    ruint::Uint, AccountInfo, Address, Bytecode, Bytes, FixedBytes, B256, U256 as RU256,
};
use tezos_ethereum::block::BlockConstants;
use tezos_smart_rollup_host::runtime::Runtime;

pub struct EtherlinkDB<'a, Host: Runtime> {
    pub host: &'a mut Host,
    pub evm_account_storage: &'a mut EthereumAccountStorage,
    pub block: BlockConstants,
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

fn ru256_to_u256(value: RU256) -> U256 {
    U256(*value.as_limbs())
}

fn u256_to_h256(value: U256) -> H256 {
    let mut ret = H256::zero();
    value.to_big_endian(ret.as_bytes_mut());
    ret
}

impl<'a, Host: Runtime> Database for EtherlinkDB<'a, Host> {
    type Error = Infallible;

    /// Get basic account information.
    fn basic(&mut self, address: Address) -> Result<Option<AccountInfo>, Self::Error> {
        let account_opt = get_account_opt(self, address);

        match account_opt {
            Some(account) => {
                let limbs = account.balance(self.host).unwrap().0;
                let balance: Uint<256, 4> = <Uint<256, 4>>::from_limbs(limbs);
                let nonce: u64 = account.nonce(self.host).unwrap().as_u64(); // can overflow
                let code_hash_bytes = account.code_hash(self.host).unwrap().0;
                let code_hash: FixedBytes<32> = <FixedBytes<32>>::from(code_hash_bytes);
                let code = account.code(self.host).unwrap();
                let code_bytes = Bytes::from(code);
                let code: Option<Bytecode> = Some(Bytecode::new_raw(code_bytes));
                let account_info = AccountInfo {
                    balance,
                    nonce,
                    code_hash,
                    code,
                };
                Ok(Some(account_info))
            }
            None => Ok(None),
        }
    }

    /// Get account code by its hash.
    fn code_by_hash(&mut self, code_hash: B256) -> Result<Bytecode, Self::Error> {
        Ok(Bytecode::new())
    }

    /// Get storage value of address at index.
    fn storage(&mut self, address: Address, index: RU256) -> Result<RU256, Self::Error> {
        let account_opt = get_account_opt(self, address);

        match account_opt {
            Some(account) => {
                let index = ru256_to_u256(index);
                let raw_storage = account
                    .get_storage(self.host, &u256_to_h256(index))
                    .unwrap();
                let storage_limbs = U256::from(raw_storage.as_bytes()).0;
                let storage = <Uint<256, 4>>::from_limbs(storage_limbs);
                Ok(storage)
            }
            None => Ok(RU256::ZERO),
        }
    }

    /// Get block hash by block number.
    fn block_hash(&mut self, number: RU256) -> Result<B256, Self::Error> {
        // return 0 when block number not in valid range
        // Ref. https://www.evm.codes/#40?fork=shanghai (opcode 0x40)

        let number = ru256_to_u256(number);

        match self.block.number.checked_sub(number) {
            Some(block_diff)
                if block_diff <= U256::from(256) && block_diff != U256::zero() =>
            {
                let block_hash = get_block_hash(self.host, number)
                    .unwrap_or_else(|_| H256::zero())
                    .0;
                Ok(B256::from(block_hash))
            }
            _ => Ok(B256::ZERO),
        }
    }
}
