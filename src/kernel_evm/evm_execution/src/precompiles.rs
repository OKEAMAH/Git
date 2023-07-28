// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Precompiles for the EVM
//!
//! This module defines the set of precompiled function for the
//! EVM interpreter to use instead of calling contracts.
//! Unfortunately, we cannot use the standard `PrecompileSet`
//! provided by SputnikVM, as we require the Host type and object
//! for writing to the log.

use crate::handler::EvmHandler;
use crate::EthereumError;
use alloc::collections::btree_map::BTreeMap;
use debug::debug_msg;
use evm::executor::stack::Log;
use evm::{Context, ExitReason, ExitRevert, ExitSucceed, Transfer};
use host::runtime::Runtime;
use primitive_types::H160;
use ripemd::Ripemd160;
use sha2::{Digest, Sha256};
use tezos_ethereum::withdrawal::Withdrawal;

/// Outcome of executing a precompiled contract. Covers both successful
/// return, stop and revert and additionally, it covers contract execution
/// failures (malformed input etc.). This is encoded using the `ExitReason`
/// same as with normal contract calls.
#[derive(PartialEq, Debug)]
pub struct PrecompileOutcome {
    /// Status after execution. This has the same semantics as with normal
    /// contract calls.
    pub exit_status: ExitReason,
    /// The cost of executing the precompiled contract in gas units.
    pub cost: u64,
    /// The return value of the call.
    pub output: Vec<u8>,
    /// Any logs produced by the precompiled contract execution.
    pub logs: Vec<Log>,
    /// Any withdrawals produced by the precompiled contract. This encodes
    /// withdrawals to Tezos Layer 1.
    pub withdrawals: Vec<Withdrawal>,
}

/// Type for a single precompiled contract
pub type PrecompileFn<Host> = fn(
    _: &mut EvmHandler<Host>,
    _: &[u8],
    _: Option<u64>,
    _: &Context,
    _: bool,
    _: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError>;

/// Trait for encapsulating all precompiles
///
/// This is adapted from SputnikVM trait with same name. It has been
/// modified to take the Host into account, so that precompiles can
/// interact with log and durable storage and the rest of the kernel.
pub trait PrecompileSet<Host: Runtime> {
    /// Execute a single contract call to a precompiled contract. Should
    /// return None (and have no effect), if there is no precompiled contract
    /// at the address given.
    #[allow(clippy::too_many_arguments)]
    fn execute(
        &self,
        handler: &mut EvmHandler<Host>,
        address: H160,
        input: &[u8],
        gas_limit: Option<u64>,
        context: &Context,
        is_static: bool,
        transfer: Option<Transfer>,
    ) -> Option<Result<PrecompileOutcome, EthereumError>>;

    /// Check if there is a precompiled contract at the given address.
    fn is_precompile(&self, address: H160) -> bool;
}

/// One implementation for PrecompileSet above. Adapted from SputnikVM.
pub type PrecompileBTreeMap<Host> = BTreeMap<H160, PrecompileFn<Host>>;

impl<Host: Runtime> PrecompileSet<Host> for PrecompileBTreeMap<Host> {
    fn execute(
        &self,
        handler: &mut EvmHandler<Host>,
        address: H160,
        input: &[u8],
        gas_limit: Option<u64>,
        context: &Context,
        is_static: bool,
        transfer: Option<Transfer>,
    ) -> Option<Result<PrecompileOutcome, EthereumError>>
    where
        Host: Runtime,
    {
        self.get(&address).map(|precompile| {
            (*precompile)(handler, input, gas_limit, context, is_static, transfer)
        })
    }

    /// Check if the given address is a precompile. Should only be called to
    /// perform the check while not executing the precompile afterward, since
    /// `execute` already performs a check internally.
    fn is_precompile(&self, address: H160) -> bool {
        self.contains_key(&address)
    }
}

// implmenetation of 0x02 precompiled (identity)
fn identity_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _gas_limit: Option<u64>,
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    debug_msg!(handler.borrow_host(), "Calling identity precompile");

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        cost: 0u64,
        output: input.to_vec(),
        logs: vec![],
        withdrawals: vec![],
    })
}

// implmenetation of 0x03 precompiled (sha256)
fn sha256_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _gas_limit: Option<u64>,
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    debug_msg!(handler.borrow_host(), "Calling sha2-256 precompile");

    let output = Sha256::digest(input);

    let size = input.len() as u64;
    // nearest number of words rounded up
    let data_word_size = (31 + size) / 32;
    let cost = 60 + 12 * data_word_size;

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        cost,
        output: output.to_vec(),
        logs: vec![],
        withdrawals: vec![],
    })
}

// implmenetation of 0x04 precompiled (ripemd160)
fn ripemd160_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _gas_limit: Option<u64>,
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    debug_msg!(handler.borrow_host(), "Calling ripemd-160 precompile");

    let hash = Ripemd160::digest(input);
    // The 20-byte hash is returned right aligned to 32 bytes
    let mut output = [0u8; 32];
    output[12..].clone_from_slice(&hash);

    let size = input.len() as u64;
    // nearest number of words rounded up
    let data_word_size = (31 + size) / 32;
    let cost = 600 + 120 * data_word_size;

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        cost,
        output: output.to_vec(),
        logs: vec![],
        withdrawals: vec![],
    })
}

/// Xxx
fn withdrawal_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _gas_limit: Option<u64>,
    _context: &Context,
    _is_static: bool,
    transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    fn revert_withdrawal() -> PrecompileOutcome {
        PrecompileOutcome {
            exit_status: ExitReason::Revert(ExitRevert::Reverted),
            cost: 0,
            output: vec![],
            logs: vec![],
            withdrawals: vec![],
        }
    }

    let Some(transfer) = transfer else {
        debug_msg!(handler.borrow_host(), "Withdrawal precompiled contract: no transfer");
        return Ok(revert_withdrawal())
    };

    match input {
        [0x31, 0xfb, 0x67, 0xc2, rest @ ..] => {
            // TODO check size of input data and read first two 256-bit integers, et.c.
            if rest.len() < 100 {
                debug_msg!(
                    handler.borrow_host(),
                    "Withdrawal precompiled contract: invalid input argument data"
                );
                return Ok(revert_withdrawal());
            }

            let Some(address_str) = core::str::from_utf8(&rest[64..100]).ok() else {
                debug_msg!(handler.borrow_host(), "Withdeawal precompiled contract: unable to get address argument");
                return Ok(revert_withdrawal())
            };

            let Some(target) = Withdrawal::address_from_str(address_str) else {
                debug_msg!(handler.borrow_host(), "Withdrawal precompiled contract: invalid target address string");
                return Ok(revert_withdrawal())
            };

            // TODO we need to measure number of ticks and translate this number into
            // Ethereum gas units

            let cost = 0;

            let withdrawals = vec![Withdrawal {
                target,
                amount: transfer.value,
            }];

            Ok(PrecompileOutcome {
                exit_status: ExitReason::Succeed(ExitSucceed::Returned),
                cost,
                output: vec![],
                logs: vec![],
                withdrawals,
            })
        }
        _ => {
            debug_msg!(
                handler.borrow_host(),
                "Withdrawal precompiled contract: invalid function selector"
            );
            Ok(revert_withdrawal())
        }
    }
}

/// Factory function for generating the precompileset that the EVM kernel uses.
pub fn precompile_set<Host: Runtime>() -> PrecompileBTreeMap<Host> {
    BTreeMap::from([
        (
            H160::from_low_u64_be(2u64),
            sha256_precompile as PrecompileFn<Host>,
        ),
        (
            H160::from_low_u64_be(3u64),
            ripemd160_precompile as PrecompileFn<Host>,
        ),
        (
            H160::from_low_u64_be(4u64),
            identity_precompile as PrecompileFn<Host>,
        ),
        (
            H160::from_low_u64_be(11u64),
            withdrawal_precompile as PrecompileFn<Host>,
        ),
    ])
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::account_storage::init_account_storage as init_evm_account_storage;
    use evm::Config;
    use primitive_types::{H160, U256};
    use tezos_crypto_rs::hash::ContractTz1Hash;
    use tezos_ethereum::block::BlockConstants;
    use tezos_smart_rollup_encoding::contract::Contract;
    use tezos_smart_rollup_encoding::public_key_hash::PublicKeyHash;
    use tezos_smart_rollup_mock::MockHost;

    fn execute_precompiled(
        address: H160,
        input: &[u8],
        transfer: Option<Transfer>,
    ) -> Option<Result<PrecompileOutcome, EthereumError>> {
        let caller = H160::from_low_u64_be(118u64);
        let mut mock_runtime = MockHost::default();
        let block = BlockConstants::first_block(U256::zero());
        let mut evm_account_storage = init_evm_account_storage().unwrap();
        let precompiles = precompile_set::<MockHost>();
        let config = Config::london();
        let gas_limit = 1000_u64;

        let mut handler = EvmHandler::new(
            &mut mock_runtime,
            &mut evm_account_storage,
            caller,
            &block,
            &config,
            &precompiles,
            gas_limit,
        );
        let context = Context {
            address,
            caller,
            apparent_value: U256::zero(),
        };

        let gas_limit = Some(1_000_000_000);
        let is_static = true;

        precompiles.execute(
            &mut handler,
            address,
            input,
            gas_limit,
            &context,
            is_static,
            transfer,
        )
    }

    #[test]
    fn call_sha256() {
        // act
        let input: &[u8] = &[0xFF];
        let address = H160::from_low_u64_be(2u64);
        let result = execute_precompiled(address, input, None);

        // assert
        let expected_hash = hex::decode(
            "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89",
        )
        .expect("Result should be hex string");
        let expected_cost = 72;
        let expected = PrecompileOutcome {
            exit_status: ExitReason::Succeed(ExitSucceed::Returned),
            cost: expected_cost,
            output: expected_hash,
            logs: vec![],
            withdrawals: vec![],
        };

        assert_eq!(Some(Ok(expected)), result);
    }

    #[test]
    fn call_ripemd() {
        // act
        let input: &[u8] = &[0xFF];
        let address = H160::from_low_u64_be(3u64);
        let result = execute_precompiled(address, input, None);

        // assert
        let expected_hash = hex::decode(
            "0000000000000000000000002c0c45d3ecab80fe060e5f1d7057cd2f8de5e557",
        )
        .expect("Result should be hex string");
        let expected_cost = 720;
        let expected = PrecompileOutcome {
            exit_status: ExitReason::Succeed(ExitSucceed::Returned),
            cost: expected_cost,
            output: expected_hash,
            logs: vec![],
            withdrawals: vec![],
        };

        assert_eq!(Some(Ok(expected)), result);
    }

    #[test]
    fn call_withdraw() {
        // Format of input - generated by eg remix to match withdrawal ABI
        // 1. function identifier
        // 2. ???
        // 3. Number of bytes in string argument
        // 4. A Layer 1 contract address, hex-encoded
        // 5. Zero padding for hex-encoded address
        let input: &[u8] = &hex::decode(
            "31fb67c2\
                 0000000000000000000000000000000000000000000000000000000000000020\
                 0000000000000000000000000000000000000000000000000000000000000024\
                 747a31526a745a5556654c6841444648444c385577445a4136766a5757686f6a70753577\
                 00000000000000000000000000000000000000000000000000000000",
        )
        .unwrap();

        let source = H160::from_low_u64_be(117u64);
        let target = H160::from_low_u64_be(11u64);
        let value = U256::from(100);

        let transfer = Some(Transfer {
            source,
            target,
            value,
        });

        let result = execute_precompiled(target, input, transfer);

        let expected_cost = 0;
        let expected_output = vec![];

        let expected = PrecompileOutcome {
            exit_status: ExitReason::Succeed(ExitSucceed::Returned),
            cost: expected_cost,
            output: expected_output,
            logs: vec![],
            withdrawals: vec![Withdrawal {
                target: Contract::Implicit(PublicKeyHash::Ed25519(
                    ContractTz1Hash::from_base58_check(
                        "tz1RjtZUVeLhADFHDL8UwDZA6vjWWhojpu5w",
                    )
                    .unwrap(),
                )),
                amount: 100.into(),
            }],
        };

        assert_eq!(Some(Ok(expected)), result);
    }
}
