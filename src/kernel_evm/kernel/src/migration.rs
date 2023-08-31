// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::error::UpgradeProcessError::Fallback;
use crate::error::{Error, StorageError};
use crate::storage::{
    init_transaction_hashes_index, read_storage_version, receipt_path,
    store_storage_version, STORAGE_VERSION,
};
use primitive_types::H256;
use rlp::Encodable;
use tezos_ethereum::transaction::TransactionReceipt;
use tezos_smart_rollup_host::runtime::{Runtime, RuntimeError};

// The workflow for migration is the following:
//
// - bump `storage::STORAGE_VERSION` by one
// - fill the scope inside the conditional in `storage_migration` with all the
//   needed migration functions
// - compile the kernel and run all the E2E migration tests to make sure all the
//   data is still available from the EVM proxy-node.
fn migration<Host: Runtime>(host: &mut Host) -> Result<(), Error> {
    let current_version = read_storage_version(host)?;
    if STORAGE_VERSION == current_version + 1 {
        // MIGRATION CODE - START
        let mut transaction_hashes_index = init_transaction_hashes_index()?;
        let transactions_n = match transaction_hashes_index.read_length(host) {
            // Transaction index hasn't been initialized yet, hence empty
            Err(StorageError::Runtime(RuntimeError::PathNotFound)) => Ok(0),
            x => x,
        }?;
        for i in 0..transactions_n {
            let tx_hash_raw = transaction_hashes_index.read_value(host, i)?;
            let tx_hash = H256::from_slice(&tx_hash_raw).to_fixed_bytes();
            let receipt_path = receipt_path(&tx_hash)?;
            let bytes = host.store_read_all(&receipt_path)?;
            let receipt = TransactionReceipt::rlp_decode_deprecated(&bytes)?;
            host.store_write_all(&receipt_path, &receipt.rlp_bytes())?;
        }
        // MIGRATION CODE - END
        store_storage_version(host, STORAGE_VERSION)?
    }
    Ok(())
}

pub fn storage_migration<Host: Runtime>(host: &mut Host) -> Result<(), Error> {
    if migration(host).is_err() {
        // Something went wrong during the migration.
        // The fallback mechanism is triggered to retrograde to the previous kernel.
        Err(Error::UpgradeError(Fallback))?
    }
    Ok(())
}
