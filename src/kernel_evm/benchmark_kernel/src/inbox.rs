// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Processing external inbox messages - withdrawals & transactions.

use crate::error::ApplicationError;
use debug::debug_msg;
use evm_execution::basic::{H256, U256};
use evm_execution::block::BlockConstants;
use evm_execution::precompiles::PrecompileBTreeMap;
use evm_execution::signatures::EthereumTransactionCommon;
use evm_execution::{account_storage::EthereumAccountStorage, EthereumError};
use host::runtime::Runtime;
use rlp::{Decodable, Rlp};

use tezos_smart_rollup_encoding::inbox::{
    InboxMessage, InfoPerLevel, InternalInboxMessage, Transfer,
};
use tezos_smart_rollup_encoding::michelson::ticket::StringTicket;
use tezos_smart_rollup_encoding::michelson::{MichelsonPair, MichelsonString};

/// Process external message
///
/// An external message is a batch of transactions. Each transaction
/// may be either a series of signed operations or a single Ethereum
/// transaction.
/// TODO: remove tx_account_storage

pub fn process_inbox_message<'a, Host: Runtime>(
    host: &mut Host,
    evm_account_storage: &mut EthereumAccountStorage,
    level: u32,
    message: &'a [u8],
) -> Result<(), ApplicationError<'a>> {
    // debug_msg!(host, "Processing an inbox message at level {}", level);

    let precompiles = evm_execution::precompiles::precompile_set();

    let (_remaining, message) =
        InboxMessage::<MichelsonPair<MichelsonString, StringTicket>>::parse(message)
            .map_err(ApplicationError::MalformedInboxMessage)?;

    match message {
        InboxMessage::Internal(InternalInboxMessage::Transfer(Transfer { .. })) => Ok(()),
        InboxMessage::Internal(InternalInboxMessage::InfoPerLevel(info)) => {
            debug_msg!(host, "InfoPerLevel: {}", info);
            process_info(host, level, info)
        }

        InboxMessage::Internal(
            msg @ (InternalInboxMessage::StartOfLevel | InternalInboxMessage::EndOfLevel),
        ) => {
            debug_msg!(host, "InboxMetadata: {}", msg);
            Ok(())
        }
        InboxMessage::External(message) => {
            debug_msg!(host, "Got an external message");
            let current_block = BlockConstants::from_storage::<Host>(host);
            // decoding
            let decoder = Rlp::new(message);
            let ethereum_transaction = EthereumTransactionCommon::decode(&decoder)
                .map_err(ApplicationError::MalformedRlpTransaction)?;
            process_ethereum_transaction(
                host,
                evm_account_storage,
                &current_block,
                &precompiles,
                ethereum_transaction,
            )
            .map_err(ApplicationError::EthereumError)
        }
    }
}

fn process_info<'a, Host: Runtime>(
    host: &mut Host,
    level: u32,
    info: InfoPerLevel,
) -> Result<(), ApplicationError<'a>> {
    Runtime::reveal_metadata(host)
        .map_err(ApplicationError::FailedToFetchRollupMetadata)
        .and_then(|metadata| {
            // Origination level considered to be block level with number 0
            // Next one is with number 1
            let block_level: u64 = u64::from(level - metadata.origination_level);
            let block_number = U256::from(block_level).into();
            evm_execution::storage::blocks::add_new_block(
                host,
                block_number,
                H256::from(info.predecessor).into(),
                U256::from(info.predecessor_timestamp).into(),
            )
            .map_err(ApplicationError::EvmStorage)
        })
}

/// Process one Ethereum transaction
fn process_ethereum_transaction<'a, Host: Runtime>(
    host: &mut Host,
    evm_account_storage: &mut EthereumAccountStorage,
    block: &'a BlockConstants,
    precompiles: &'a PrecompileBTreeMap<Host>,
    e: EthereumTransactionCommon,
) -> Result<(), EthereumError> {
    let outcome = evm_execution::run_transaction(
        host,
        block,
        evm_account_storage,
        precompiles,
        e.to.into(),
        e.caller().into(),
        e.data,
        Some(e.gas_limit.to_u64()?),
        Some(e.value.value.into()),
    )?;

    debug_msg!(host, "Transaction executed, gas used: {}", outcome.gas_used);

    Ok(())
}
