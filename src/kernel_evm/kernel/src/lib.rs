// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::error::StorageError::Runtime as RuntimeError;
use primitive_types::U256;
use storage::{init_evm_storage, EVMStorage};
use tezos_ethereum::block::L2Block;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_entrypoint::kernel_entry;
use tezos_smart_rollup_host::runtime::Runtime;

use crate::blueprint::{fetch, Queue};
use crate::error::Error;
use crate::error::StorageError::AccountInitialisation;
use crate::storage::{read_smart_rollup_address, store_smart_rollup_address};
use evm_execution::account_storage::init_account_storage;

mod block;
mod blueprint;
mod error;
mod genesis;
mod inbox;
mod storage;

pub fn stage_one<Host: Runtime>(
    host: &mut Host,
    smart_rollup_address: [u8; 20],
) -> Result<Queue, Error> {
    let queue = fetch(host, smart_rollup_address)?;

    for (i, blueprint) in queue.proposals.iter().enumerate() {
        debug_msg!(
            host,
            "Blueprint {} contains {} transactions.\n",
            i,
            blueprint.transactions.len()
        );
    }

    Ok(queue)
}

pub fn stage_two<Host: Runtime>(
    host: &mut Host,
    queue: Queue,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    debug_msg!(host, "Stage two\n");
    let mut evm_account_storage =
        init_account_storage().map_err(|_| Error::Storage(AccountInitialisation))?;
    block::produce(host, queue, evm_storage, &mut evm_account_storage)
}

fn retrieve_smart_rollup_address<Host: Runtime>(
    host: &mut Host,
) -> Result<[u8; 20], Error> {
    match read_smart_rollup_address(host) {
        Ok(smart_rollup_address) => Ok(smart_rollup_address),
        Err(_) => {
            let rollup_metadata = Runtime::reveal_metadata(host);
            let address = rollup_metadata.raw_rollup_address;
            store_smart_rollup_address(host, &address)?;
            Ok(address)
        }
    }
}

fn genesis_initialisation<Host: Runtime>(
    host: &mut Host,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let evm_genesis_block = evm_storage.block(host, &U256::zero())?;
    match Runtime::store_has(host, &evm_genesis_block.path) {
        Ok(Some(_)) => Ok(()),
        Ok(None) => genesis::init_block(host, evm_storage),
        Err(e) => Err(Error::Storage(RuntimeError(e))),
    }
}

pub fn main<Host: Runtime>(
    host: &mut Host,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let smart_rollup_address = retrieve_smart_rollup_address(host)?;
    genesis_initialisation(host, evm_storage)?;

    let queue = stage_one(host, smart_rollup_address)?;

    stage_two(host, queue, evm_storage)
}

pub fn kernel_loop<Host: Runtime>(host: &mut Host) {
    let mut evm_storage =
        init_evm_storage().expect("EVM Storage initialisation must succeed.");
    evm_storage
        .storage
        .begin(host)
        .expect("Beginning step of the EVM transactional storage must succeed.");
    match main(host, &mut evm_storage) {
        Ok(()) => evm_storage
            .storage
            .commit(host)
            .expect("Committing step of the EVM transactional storage must succeed."),
        Err(e) => {
            evm_storage.storage.rollback(host).expect(
                "Rollbacking step of the EVM transactional storage must succeed.",
            );
            panic!("Kernel loop failed: {:?}", e)
        }
    }
}

kernel_entry!(kernel_loop);
