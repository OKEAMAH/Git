// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use anyhow::Context;
use evm_execution::Config;
use primitive_types::U256;
use storage::{
    read_chain_id, read_kernel_version, read_last_info_per_level_timestamp,
    read_last_info_per_level_timestamp_stats, read_ticketer, store_chain_id,
    store_kernel_upgrade_nonce, store_kernel_version, store_storage_version,
    STORAGE_VERSION, STORAGE_VERSION_PATH,
};
use tezos_crypto_rs::hash::ContractKt1Hash;
use tezos_smart_rollup_encoding::timestamp::Timestamp;
use tezos_smart_rollup_entrypoint::kernel_entry;
use tezos_smart_rollup_host::path::{concat, OwnedPath, RefPath};
use tezos_smart_rollup_host::runtime::Runtime;

use tezos_evm_logging::{log, Level::*};

use crate::inbox::KernelUpgrade;
use crate::migration::storage_migration;
use crate::safe_storage::{SafeStorage, TMP_PATH};

use crate::blueprint::{fetch, Queue};
use crate::error::Error;
use crate::error::UpgradeProcessError::Fallback;
use crate::storage::{read_smart_rollup_address, store_smart_rollup_address};
use crate::upgrade::upgrade_kernel;
use crate::Error::UpgradeError;

mod apply;
mod block;
mod block_in_progress;
mod blueprint;
mod error;
mod inbox;
mod indexable_storage;
mod migration;
mod parsing;
mod safe_storage;
mod simulation;
mod storage;
mod tick_model;
mod upgrade;

/// The chain id will need to be unique when the EVM rollup is deployed in
/// production.
pub const CHAIN_ID: u32 = 1337;

/// The configuration for the EVM execution.
pub const CONFIG: Config = Config::london();

const KERNEL_VERSION: &str = env!("GIT_HASH");

pub fn stage_zero<Host: Runtime>(host: &mut Host) -> Result<(), Error> {
    log!(host, Info, "Entering stage zero.");
    init_storage_versioning(host)?;
    storage_migration(host)
}

/// Returns the current timestamp for the execution. Based on the last
/// info per level read (or default timestamp if it was not set), plus the
/// artifical average block time.
pub fn current_timestamp<Host: Runtime>(host: &mut Host) -> Timestamp {
    let timestamp =
        read_last_info_per_level_timestamp(host).unwrap_or_else(|_| Timestamp::from(0));
    let (numbers, total) =
        read_last_info_per_level_timestamp_stats(host).unwrap_or((1i64, 0i64));
    let average_block_time = total / numbers;
    let seconds = timestamp.i64() + average_block_time;

    Timestamp::from(seconds)
}

pub fn stage_one<Host: Runtime>(
    host: &mut Host,
    smart_rollup_address: [u8; 20],
    chain_id: U256,
    ticketer: Option<ContractKt1Hash>,
) -> Result<Queue, Error> {
    log!(host, Info, "Entering stage one.");
    match &ticketer {
        Some(ref ticketer) => log!(host, Info, "Ticketer is {}.", ticketer),
        None => log!(
            host,
            Info,
            "Ticketer not specified, the kernel ignores internal transfers."
        ),
    }
    // TODO: https://gitlab.com/tezos/tezos/-/issues/5873
    // if rebooted, don't fetch inbox
    let queue = fetch(host, smart_rollup_address, chain_id, ticketer)?;

    for (i, queue_elt) in queue.proposals.iter().enumerate() {
        match queue_elt {
            blueprint::QueueElement::Blueprint(b) => log!(
                host,
                Info,
                "Blueprint {} contains {} transactions.",
                i,
                b.transactions.len()
            ),
            blueprint::QueueElement::BlockInProgress(bip) => log!(
                host,
                Info,
                "Block in progress {} has {} transactions left.",
                i,
                bip.queue_length()
            ),
        }
    }

    Ok(queue)
}

fn produce_and_upgrade<Host: Runtime>(
    host: &mut Host,
    queue: Queue,
    kernel_upgrade: KernelUpgrade,
) -> Result<(), anyhow::Error> {
    // Since a kernel upgrade was detected, in case an error is thrown
    // by the block production, we exceptionally "recover" from it and
    // still process the kernel upgrade.
    if let Err(e) = block::produce(host, queue) {
        log!(
            host,
            Error,
            "{:?} happened during block production but a kernel upgrade was detected.",
            e
        );
    }
    let upgrade_status = upgrade_kernel(host, kernel_upgrade.preimage_hash)
        .context("Failed to upgrade kernel");
    if upgrade_status.is_ok() {
        let kernel_upgrade_nonce = u16::from_le_bytes(kernel_upgrade.nonce);
        store_kernel_upgrade_nonce(host, kernel_upgrade_nonce)
            .context("Failed to store kernel upgrade nonce")?;
    }
    upgrade_status
}

pub fn stage_two<Host: Runtime>(
    host: &mut Host,
    queue: Queue,
) -> Result<(), anyhow::Error> {
    log!(host, Info, "Entering stage two.");
    let kernel_upgrade = queue.kernel_upgrade.clone();
    if let Some(kernel_upgrade) = kernel_upgrade {
        produce_and_upgrade(host, queue, kernel_upgrade)
    } else {
        block::produce(host, queue)
    }
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

fn set_kernel_version<Host: Runtime>(host: &mut Host) -> Result<(), Error> {
    match read_kernel_version(host) {
        Ok(kernel_version) => {
            if kernel_version != KERNEL_VERSION {
                store_kernel_version(host, &kernel_version)?
            };
            Ok(())
        }
        Err(_) => store_kernel_version(host, KERNEL_VERSION),
    }
}

fn init_storage_versioning<Host: Runtime>(host: &mut Host) -> Result<(), Error> {
    match host.store_read(&STORAGE_VERSION_PATH, 0, 0) {
        Ok(_) => Ok(()),
        Err(_) => store_storage_version(host, STORAGE_VERSION),
    }
}

fn retrieve_chain_id<Host: Runtime>(host: &mut Host) -> Result<U256, Error> {
    match read_chain_id(host) {
        Ok(chain_id) => Ok(chain_id),
        Err(_) => {
            let chain_id = U256::from(CHAIN_ID);
            store_chain_id(host, chain_id)?;
            Ok(chain_id)
        }
    }
}

fn fetch_queue_left<Host: Runtime>(host: &mut Host) -> Result<Queue, anyhow::Error> {
    let mut queue = Queue::new();
    // fetch rest of queue
    // TODO: https://gitlab.com/tezos/tezos/-/issues/5873
    // reload the queue

    // fetch Bip
    let bip = storage::read_block_in_progress(host)?;
    queue.proposals = vec![blueprint::QueueElement::BlockInProgress(bip)];
    Ok(queue)
}

pub fn main<Host: Runtime>(host: &mut Host) -> Result<(), anyhow::Error> {
    let queue = if storage::was_rebooted(host)? {
        // kernel was rebooted
        log!(
            host,
            Info,
            "Kernel was rebooted. Reboot left: {}\n",
            host.reboot_left()?
        );
        storage::delete_reboot_flag(host)?;
        fetch_queue_left(host)?
    } else {
        // first kernel run of the level
        stage_zero(host)?;
        set_kernel_version(host)?;
        let smart_rollup_address = retrieve_smart_rollup_address(host)
            .context("Failed to retrieve smart rollup address")?;
        let chain_id = retrieve_chain_id(host).context("Failed to retrieve chain id")?;
        let ticketer = read_ticketer(host);

        stage_one(host, smart_rollup_address, chain_id, ticketer)
            .context("Failed during stage 1")?
    };

    stage_two(host, queue).context("Failed during stage 2")
}

const EVM_PATH: RefPath = RefPath::assert_from(b"/evm");

const ERRORS_PATH: RefPath = RefPath::assert_from(b"/errors");

fn log_error<Host: Runtime>(
    host: &mut Host,
    err: &anyhow::Error,
) -> Result<(), anyhow::Error> {
    let current_level = storage::read_current_block_number(host).unwrap_or_default();
    let err_msg = format!("Error during block {}: {:?}", current_level, err);

    let nb_errors = host.store_count_subkeys(&ERRORS_PATH)?;
    let raw_error_path: Vec<u8> = format!("/{}", nb_errors + 1).into();
    let error_path = OwnedPath::try_from(raw_error_path)?;
    let error_path = concat(&ERRORS_PATH, &error_path)?;

    host.store_write_all(&error_path, err_msg.as_bytes())?;
    Ok(())
}

pub fn kernel_loop<Host: Runtime>(host: &mut Host) {
    // In order to setup the temporary directory, we need to move something
    // from /evm to /tmp, so /evm must be non empty, this only happen
    // at the first run.
    let evm_subkeys = host
        .store_count_subkeys(&EVM_PATH)
        .expect("The kernel failed to read the number of /evm subkeys");
    if evm_subkeys == 0 {
        host.store_write(&EVM_PATH, "Un festival de GADT".as_bytes(), 0)
            .unwrap();
    }

    host.store_copy(&EVM_PATH, &TMP_PATH)
        .expect("The kernel failed to create the temporary directory");

    let mut host = SafeStorage(host);
    match main(&mut host) {
        Ok(()) => {
            host.promote_upgrade()
                .expect("Potential kernel upgrade promotion failed");
            host.promote(&EVM_PATH)
                .expect("The kernel failed to promote the temporary directory")
        }
        Err(e) => {
            if let Some(UpgradeError(Fallback)) = e.downcast_ref::<Error>() {
                // All the changes from the failed migration are reverted.
                host.revert()
                    .expect("The kernel failed to delete the temporary directory");
                host.fallback_backup_kernel()
                    .expect("Fallback mechanism failed");
            } else {
                log_error(host.0, &e).expect("The kernel failed to write the error");
                log!(host, Error, "The kernel produced an error: {:?}", e);
                log!(
                    host,
                    Error,
                    "The temporarily modified durable storage is discarded"
                );

                // TODO: https://gitlab.com/tezos/tezos/-/issues/5766
                // If an input is consumed then an error happens, the input
                // will be lost, this cannot happen in production.

                host.revert()
                    .expect("The kernel failed to delete the temporary directory")
            }
        }
    }
}

kernel_entry!(kernel_loop);
