// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use std::str::FromStr;

use crate::error::Error;
use crate::error::StorageError::{GenesisAccountInitialisation, Path};
use crate::storage::EVMStorage;
use crate::L2Block;
use evm_execution::account_storage::account_path;
use evm_execution::account_storage::init_account_storage;
use evm_execution::account_storage::AccountStorageError;
use evm_execution::account_storage::EthereumAccountStorage;
use primitive_types::{H160, H256, U256};
use tezos_ethereum::transaction::TransactionReceipt;
use tezos_ethereum::transaction::TransactionStatus;
use tezos_ethereum::transaction::TransactionType;
use tezos_ethereum::transaction::TRANSACTION_HASH_SIZE;
use tezos_ethereum::transaction::{TransactionHash, TransactionObject};
use tezos_ethereum::wei::{self, Wei};
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::path::PathError;
use tezos_smart_rollup_host::runtime::Runtime;

struct MintAccount {
    mint_address: &'static str,
    genesis_tx_hash: TransactionHash,
    eth_amount: u64,
}

const GENESIS_ADDRESSS: [u8; 20] = [0; 20];

const GENESIS_LEVEL: U256 = U256::zero();

const MINT_ACCOUNTS_NUMBER: usize = 3;

const MINT_ACCOUNTS: [MintAccount; MINT_ACCOUNTS_NUMBER] = [
    MintAccount {
        mint_address: "6ce4d79d4e77402e1ef3417fdda433aa744c6e1c",
        genesis_tx_hash: [0; TRANSACTION_HASH_SIZE],
        eth_amount: 9999,
    },
    MintAccount {
        mint_address: "b53dc01974176e5dff2298c5a94343c2585e3c54",
        genesis_tx_hash: [1; TRANSACTION_HASH_SIZE],
        eth_amount: 9999,
    },
    MintAccount {
        mint_address: "9b49c988b5817be31dfb00f7a5a4671772dcce2b",
        genesis_tx_hash: [2; TRANSACTION_HASH_SIZE],
        eth_amount: 9999,
    },
];

fn forge_genesis_mint_account<Host: Runtime>(
    host: &mut Host,
    mint_address: &H160,
    balance: Wei,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<(), AccountStorageError> {
    let mut account =
        evm_account_storage.get_or_create(host, &account_path(mint_address)?)?;
    account.balance_add(host, balance)
}

fn collect_mint_transactions<T, E>(
    slice: [Result<T, E>; MINT_ACCOUNTS_NUMBER],
) -> Result<Vec<T>, E> {
    let mut new_vec = Vec::new();
    for v in slice.into_iter() {
        match v {
            Ok(v) => new_vec.push(v),
            Err(e) => return Err(e),
        }
    }
    Ok(new_vec)
}

fn bootstrap_genesis_accounts<Host: Runtime>(
    host: &mut Host,
) -> Result<Vec<TransactionHash>, Error> {
    let mut evm_account_storage =
        init_account_storage().map_err(|_| Error::Storage(Path(PathError::PathEmpty)))?;
    let transactions_hashes = MINT_ACCOUNTS.map(
        |MintAccount {
             mint_address,
             genesis_tx_hash,
             eth_amount,
         }| {
            let mint_address =
                H160::from_str(mint_address).map_err(|_| Error::InvalidConversion)?;
            forge_genesis_mint_account(
                host,
                &mint_address,
                wei::from_eth(eth_amount),
                &mut evm_account_storage,
            )
            .map_err(|_| Error::Storage(GenesisAccountInitialisation))?;
            Ok(genesis_tx_hash)
        },
    );

    collect_mint_transactions(transactions_hashes)
}

fn craft_mint_address(genesis_mint_address: &str) -> Option<H160> {
    let encoded_genesis_mint_address: Vec<u8> = hex::decode(genesis_mint_address).ok()?;
    let encoded_genesis_mint_address: [u8; 20] =
        encoded_genesis_mint_address.try_into().ok()?;
    Some(encoded_genesis_mint_address.into())
}

fn store_genesis_transaction_object<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    hash: &[u8; TRANSACTION_HASH_SIZE],
    index: u32,
    account: &MintAccount,
    genesis_address: &H160,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let object = TransactionObject {
        from: *genesis_address,
        hash: *hash,
        gas_used: U256::zero(),
        gas_price: U256::zero(),
        input: Vec::new(),
        // Since the genesis address is the only transaction producer in the
        // genesis block, it is consistent to consider the index of the
        // transaction in the block as the updated nonce for the address.
        nonce: index.into(),
        to: craft_mint_address(account.mint_address),
        index,
        value: wei::from_eth(account.eth_amount),
        v: U256::zero(),
        r: H256::zero(),
        s: H256::zero(),
    };

    let mut object_path = evm_storage.tx_object(host, &object.hash)?;
    object_path.store_tx_object(host, block.hash, block.number, &object)
}

fn store_genesis_transaction_receipt<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    hash: &[u8; TRANSACTION_HASH_SIZE],
    index: u32,
    account: &MintAccount,
    genesis_address: &H160,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let receipt = TransactionReceipt {
        hash: *hash,
        index,
        block_hash: block.hash,
        block_number: block.number,
        from: *genesis_address,
        to: craft_mint_address(account.mint_address),
        cumulative_gas_used: U256::zero(),
        effective_gas_price: U256::zero(),
        gas_used: U256::zero(),
        contract_address: None,
        type_: TransactionType::Legacy,
        status: TransactionStatus::Success,
    };

    let mut receipt_path = evm_storage.tx_receipt(host, &receipt.hash)?;
    receipt_path.store_tx_receipt(host, &receipt)
}

fn store_genesis_transactions<Host: Runtime>(
    host: &mut Host,
    genesis_block: L2Block,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let genesis_address: H160 = GENESIS_ADDRESSS.into();

    for (hash, index) in genesis_block.transactions.iter().zip(0u32..) {
        let mint_account = &MINT_ACCOUNTS[index as usize];

        store_genesis_transaction_object(
            host,
            &genesis_block,
            hash,
            index,
            mint_account,
            &genesis_address,
            evm_storage,
        )?;

        store_genesis_transaction_receipt(
            host,
            &genesis_block,
            hash,
            index,
            mint_account,
            &genesis_address,
            evm_storage,
        )?;
    }

    Ok(())
}

pub fn init_block<Host: Runtime>(
    host: &mut Host,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    // Forge the genesis' transactions that will mint the very first accounts
    let transaction_hashes = bootstrap_genesis_accounts(host)?;

    // Produce and store genesis' block
    evm_storage.storage.begin(host)?;
    let mut current_block_storage =
        evm_storage.set_and_get_current_block(host, &GENESIS_LEVEL)?;
    let genesis_block = L2Block::new(GENESIS_LEVEL, transaction_hashes);

    match current_block_storage.store_l2block(host, &genesis_block) {
        Ok(()) => match store_genesis_transactions(host, genesis_block, evm_storage) {
            Ok(()) => evm_storage.storage.commit(host),
            receipt_storage_error => {
                evm_storage.storage.rollback(host)?;
                receipt_storage_error
            }
        },
        block_storage_error => {
            evm_storage.storage.rollback(host)?;
            block_storage_error
        }
    }?;

    debug_msg!(host, "Genesis block was initialized.\n");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::storage::init_evm_storage;

    use tezos_ethereum::wei;
    use tezos_smart_rollup_host::runtime::ValueType;
    use tezos_smart_rollup_mock::MockHost;

    fn get_balance(
        host: &mut MockHost,
        evm_account_storage: &mut EthereumAccountStorage,
        address: &H160,
    ) -> U256 {
        let account = evm_account_storage
            .get_or_create(host, &account_path(address).unwrap())
            .unwrap();
        account.balance(host).unwrap()
    }

    #[test]
    // Test if the genesis block can be initialized and that the mint accounts
    // are initialized with the appropriate amounts.
    fn test_init_genesis_block() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();

        match init_block(&mut host, &mut evm_storage) {
            Ok(()) => (),
            Err(_) => panic!("The initialization of block genesis failed."),
        }

        for account in MINT_ACCOUNTS {
            let mint_address = H160::from_str(account.mint_address).unwrap();
            assert_eq!(
                get_balance(&mut host, &mut evm_account_storage, &mint_address),
                wei::from_eth(9999)
            );
        }
    }

    #[test]
    // Check that the transactions of the genesis block are correctly written in the
    // storage.
    fn test_genesis_transactions() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();

        match init_block(&mut host, &mut evm_storage) {
            Ok(()) => (),
            Err(_) => panic!("The initialization of block genesis failed."),
        }

        let mut current_block = evm_storage.current_block(&mut host).unwrap();

        let block = current_block.read_l2block(&mut host).unwrap();

        assert_eq!(block.number, U256::zero());

        for transaction in block.transactions {
            let object = evm_storage.tx_object(&mut host, &transaction).unwrap();
            assert_eq!(host.store_has(&object.path), Ok(Some(ValueType::Subtree)));
            let receipt = evm_storage.tx_receipt(&mut host, &transaction).unwrap();
            assert_eq!(host.store_has(&receipt.path), Ok(Some(ValueType::Subtree)));
        }
    }
}
