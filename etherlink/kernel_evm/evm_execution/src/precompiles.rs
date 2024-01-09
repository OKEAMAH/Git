// SPDX-FileCopyrightText: 2022-2024 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2024 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

//! Precompiles for the EVM
//!
//! This module defines the set of precompiled function for the
//! EVM interpreter to use instead of calling contracts.
//! Unfortunately, we cannot use the standard `PrecompileSet`
//! provided by SputnikVM, as we require the Host type and object
//! for writing to the log.

use std::{cmp::min, str::FromStr, vec};

use crate::eip152;
use crate::handler::EvmHandler;
use crate::EthereumError;
use crate::{abi, modexp::modexp_precompile};
use alloc::collections::btree_map::BTreeMap;
use evm::{Context, ExitReason, ExitRevert, ExitSucceed, Transfer};
use host::runtime::Runtime;
use libsecp256k1::{curve::Scalar, recover, Message, RecoveryId, Signature};
use primitive_types::{H160, U256};
use ripemd::Ripemd160;
use sha2::{Digest, Sha256};
use sha3::Keccak256;
use tezos_ethereum::withdrawal::Withdrawal;
use tezos_evm_logging::{log, Level::*};

/// Outcome of executing a precompiled contract. Covers both successful
/// return, stop and revert and additionally, it covers contract execution
/// failures (malformed input etc.). This is encoded using the `ExitReason`
/// same as with normal contract calls.
#[derive(PartialEq, Debug)]
pub struct PrecompileOutcome {
    /// Status after execution. This has the same semantics as with normal
    /// contract calls.
    pub exit_status: ExitReason,
    /// The return value of the call.
    pub output: Vec<u8>,
    /// Any withdrawals produced by the precompiled contract. This encodes
    /// withdrawals to Tezos Layer 1.
    pub withdrawals: Vec<Withdrawal>,
    /// Number of ticks estimated by the tick model of the precompiled contract.
    /// Note that the implementation of the contract is responsible for failing
    /// with EthereumError::OutOfTicks if the number of tricks would make the
    /// total number of ticks of the Handler go over the allocated number of
    /// ticks.
    pub estimated_ticks: u64,
}

/// Type for a single precompiled contract
pub type PrecompileFn<Host> = fn(
    _: &mut EvmHandler<Host>,
    _: &[u8],
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
        context: &Context,
        is_static: bool,
        transfer: Option<Transfer>,
    ) -> Option<Result<PrecompileOutcome, EthereumError>>
    where
        Host: Runtime,
    {
        self.get(&address)
            .map(|precompile| (*precompile)(handler, input, context, is_static, transfer))
    }

    /// Check if the given address is a precompile. Should only be called to
    /// perform the check while not executing the precompile afterward, since
    /// `execute` already performs a check internally.
    fn is_precompile(&self, address: H160) -> bool {
        self.contains_key(&address)
    }
}

#[macro_export]
macro_rules! fail_if_too_much {
    ($estimated_ticks : expr, $handler: expr) => {
        if $estimated_ticks + $handler.estimated_ticks_used > $handler.ticks_allocated {
            return Err(EthereumError::OutOfTicks);
        } else {
            $estimated_ticks
        }
    };
}

fn erec_output_for_wrong_input() -> PrecompileOutcome {
    PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: vec![],
        withdrawals: vec![],
        estimated_ticks: 0,
    }
}

macro_rules! unwrap {
    ($expr : expr) => {
        match $expr {
            Ok(x) => x,
            Err(_) => return Ok(erec_output_for_wrong_input()),
        }
    };
}

fn erec_parse_inputs(input: &[u8]) -> ([u8; 32], u8, [u8; 32], [u8; 32]) {
    // input is padded with 0 on the right
    let mut clean_input: [u8; 128] = [0; 128];
    // and truncated if too large
    let input_size = min(128, input.len());
    clean_input[..input_size].copy_from_slice(&input[..input_size]);

    // extract values
    let mut hash = [0; 32];
    let mut v_array = [0; 32];
    let mut r_array = [0; 32];
    let mut s_array = [0; 32];
    hash.copy_from_slice(&clean_input[0..32]);
    v_array.copy_from_slice(&clean_input[32..64]);
    r_array.copy_from_slice(&clean_input[64..96]);
    s_array.copy_from_slice(&clean_input[96..128]);
    // v is encoding of 1 byte nb over 32 bytes
    (hash, v_array[31], r_array, s_array)
}

// implementation of 0x01 ECDSA recover
fn ecrecover_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    log!(handler.borrow_host(), Info, "Calling ecrecover precompile");

    // check that enough resources to execute (gas / ticks) are available
    let estimated_ticks = fail_if_too_much!(tick_model::ticks_of_ecrecover(), handler);
    let cost = 3000;
    if let Err(err) = handler.record_cost(cost) {
        log!(
            handler.borrow_host(),
            Info,
            "Couldn't record the cost of ecrecover {:?}",
            err
        );
        return Ok(PrecompileOutcome {
            exit_status: ExitReason::Error(err),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks,
        });
    }
    log!(
        handler.borrow_host(),
        Debug,
        "Input is {:?}",
        hex::encode(input)
    );

    // parse inputs
    let (hash, v_raw, r_array, s_array) = erec_parse_inputs(input);
    let v = match v_raw.checked_sub(27) {
        Some(v) => v,
        None => return Ok(erec_output_for_wrong_input()),
    };
    // wrappers needed by ecdsa crate
    let mut r = Scalar::default();
    let _ = r.set_b32(&r_array);
    let mut s = Scalar::default();
    let _ = s.set_b32(&s_array);
    let ri = unwrap!(RecoveryId::parse(v));

    // check signature
    let pubk = unwrap!(recover(&Message::parse(&hash), &Signature { r, s }, &ri));
    let kec = Keccak256::digest(&pubk.serialize()[1..]);
    let address: Result<[u8; 20], _> = kec.as_slice()[12..].try_into();
    let add = unwrap!(address);

    // format output
    let mut output = vec![0; 32];
    output[12..].copy_from_slice(&add);
    log!(
        handler.borrow_host(),
        Debug,
        "Output is {:?}",
        hex::encode(&output)
    );
    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output,
        withdrawals: vec![],
        estimated_ticks,
    })
}

// implementation of 0x02 precompiled (identity)
fn identity_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    log!(handler.borrow_host(), Info, "Calling identity precompile");
    let estimated_ticks =
        fail_if_too_much!(tick_model::ticks_of_identity(input.len())?, handler);

    let size = input.len() as u64;
    let data_word_size = (size + 31) / 32;
    let static_gas = 15;
    let dynamic_gas = 3 * data_word_size;
    let cost = static_gas + dynamic_gas;

    if let Err(err) = handler.record_cost(cost) {
        return Ok(PrecompileOutcome {
            exit_status: ExitReason::Error(err),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks,
        });
    }

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: input.to_vec(),
        withdrawals: vec![],
        estimated_ticks,
    })
}

// implmenetation of 0x03 precompiled (sha256)
fn sha256_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    log!(handler.borrow_host(), Info, "Calling sha2-256 precompile");
    let estimated_ticks =
        fail_if_too_much!(tick_model::ticks_of_sha256(input.len())?, handler);

    let size = input.len() as u64;
    let data_word_size = (31 + size) / 32;
    let cost = 60 + 12 * data_word_size;

    if let Err(err) = handler.record_cost(cost) {
        return Ok(PrecompileOutcome {
            exit_status: ExitReason::Error(err),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks,
        });
    }

    let output = Sha256::digest(input);

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: output.to_vec(),
        withdrawals: vec![],
        estimated_ticks,
    })
}

// implmenetation of 0x04 precompiled (ripemd160)
fn ripemd160_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    log!(handler.borrow_host(), Info, "Calling ripemd-160 precompile");
    let estimated_ticks =
        fail_if_too_much!(tick_model::ticks_of_ripemd160(input.len())?, handler);

    let size = input.len() as u64;
    let data_word_size = (31 + size) / 32;
    let cost = 600 + 120 * data_word_size;

    if let Err(err) = handler.record_cost(cost) {
        return Ok(PrecompileOutcome {
            exit_status: ExitReason::Error(err),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks,
        });
    }

    let hash = Ripemd160::digest(input);
    // The 20-byte hash is returned right aligned to 32 bytes
    let mut output = [0u8; 32];
    output[12..].clone_from_slice(&hash);

    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: output.to_vec(),
        withdrawals: vec![],
        estimated_ticks,
    })
}

fn blake2f_output_for_wrong_input() -> PrecompileOutcome {
    PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: vec![],
        withdrawals: vec![],
        estimated_ticks: 0,
    }
}

trait Decodable {
    fn decode_from_le_slice(&mut self, source: &[u8]);
}

impl<const N: usize> Decodable for [u64; N] {
    fn decode_from_le_slice(&mut self, src: &[u8]) {
        for (i, word) in self.iter_mut().enumerate() {
            let mut word_buf = [0_u8; 8];
            word_buf.copy_from_slice(&src[i * 8..(i + 1) * 8]);
            *word = u64::from_le_bytes(word_buf);
        }
    }
}

fn blake2f_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    _transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    log!(handler.borrow_host(), Info, "Calling blake2f precompile");

    // The precompile requires 6 inputs tightly encoded, taking exactly 213 bytes
    if input.len() != 213 {
        return Ok(blake2f_output_for_wrong_input());
    }

    // the number of rounds - 32-bit unsigned big-endian word
    let mut rounds_buf = [0_u8; 4];
    rounds_buf.copy_from_slice(&input[0..4]);
    let rounds: u32 = u32::from_be_bytes(rounds_buf);

    // check that enough ressources to execute (gas / ticks) are available
    let estimated_ticks =
        fail_if_too_much!(tick_model::ticks_of_blake2f(rounds), handler);
    let cost = 0 + rounds as u64 * 1; // static_gas + dynamic_gas
    if let Err(err) = handler.record_cost(cost) {
        log!(
            handler.borrow_host(),
            Info,
            "Couldn't record the cost of blake2f {:?}",
            err
        );
        return Ok(PrecompileOutcome {
            exit_status: ExitReason::Error(err),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks,
        });
    }
    log!(
        handler.borrow_host(),
        Debug,
        "Input is {:?}",
        hex::encode(input)
    );

    // parse inputs
    // the state vector - 8 unsigned 64-bit little-endian words
    let mut h = [0_u64; 8];
    h.decode_from_le_slice(&input[4..68]);

    // the message block vector - 16 unsigned 64-bit little-endian words
    let mut m = [0_u64; 16];
    m.decode_from_le_slice(&input[68..196]);

    // offset counters - 2 unsigned 64-bit little-endian words
    let mut t = [0_u64; 2];
    t.decode_from_le_slice(&input[196..212]);

    // the final block indicator flag - 8-bit word (true if 1 or false if 0)
    let f = match input[212] {
        1 => true,
        0 => false,
        _ => return Ok(blake2f_output_for_wrong_input()),
    };

    eip152::compress(&mut h, m, t, f, rounds as usize);

    let mut output = [0_u8; u64::BITS as usize];
    for (i, state_word) in h.iter().enumerate() {
        output[i * 8..(i + 1) * 8].copy_from_slice(&state_word.to_le_bytes());
    }
    log!(
        handler.borrow_host(),
        Debug,
        "Output is {:?}",
        hex::encode(&output)
    );
    Ok(PrecompileOutcome {
        exit_status: ExitReason::Succeed(ExitSucceed::Returned),
        output: output.to_vec(),
        withdrawals: vec![],
        estimated_ticks,
    })
}

/// Implementation of Etherelink specific withdrawals precompiled contract.
fn withdrawal_precompile<Host: Runtime>(
    handler: &mut EvmHandler<Host>,
    input: &[u8],
    _context: &Context,
    _is_static: bool,
    transfer: Option<Transfer>,
) -> Result<PrecompileOutcome, EthereumError> {
    let estimated_ticks = fail_if_too_much!(tick_model::ticks_of_withdraw(), handler);
    fn revert_withdrawal() -> PrecompileOutcome {
        PrecompileOutcome {
            exit_status: ExitReason::Revert(ExitRevert::Reverted),
            output: vec![],
            withdrawals: vec![],
            estimated_ticks: tick_model::ticks_of_withdraw(),
        }
    }

    // TODO check gas_limit if it can't cover the cost, bail out

    let Some(transfer) = transfer else {
        log!(handler.borrow_host(), Info, "Withdrawal precompiled contract: no transfer");
        return Ok(revert_withdrawal())
    };

    if U256::is_zero(&transfer.value) {
        log!(
            handler.borrow_host(),
            Info,
            "Withdrawal precompiled contract: transfer of 0"
        );
        return Ok(revert_withdrawal());
    }

    match input {
        [0xcd, 0xa4, 0xfe, 0xe2, rest @ ..] => {
            let Some(address_str) = abi::string_parameter(rest, 0) else {
                log!(handler.borrow_host(), Info, "Withdrawal precompiled contract: unable to get address argument");
                return Ok(revert_withdrawal())
            };

            log!(
                handler.borrow_host(),
                Info,
                "Withdrawal to {:?}\n",
                address_str
            );

            let Some(target) = Withdrawal::address_from_str(address_str) else {
                log!(handler.borrow_host(), Info, "Withdrawal precompiled contract: invalid target address string");
                return Ok(revert_withdrawal())
            };

            // TODO Check that the outbox ain't full yet

            // TODO we need to measure number of ticks and translate this number into
            // Ethereum gas units

            let withdrawals = vec![Withdrawal {
                target,
                amount: transfer.value,
            }];

            Ok(PrecompileOutcome {
                exit_status: ExitReason::Succeed(ExitSucceed::Returned),
                output: vec![],
                withdrawals,
                estimated_ticks,
            })
        }
        // TODO A contract "function" to do withdrawal to byte encoded address
        _ => {
            log!(
                handler.borrow_host(),
                Info,
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
            H160::from_low_u64_be(1u64),
            ecrecover_precompile as PrecompileFn<Host>,
        ),
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
            H160::from_low_u64_be(5u64),
            modexp_precompile as PrecompileFn<Host>,
        ),
        (
            // Prefixed by 'ff' to make sure we will not conflict with any
            // upcoming Ethereum upgrades.
            // NB: The `unwrap()` here is safe.
            H160::from_str("ff00000000000000000000000000000000000001").unwrap(),
            withdrawal_precompile as PrecompileFn<Host>,
        ),
    ])
}
mod tick_model {
    use super::*;
    pub fn ticks_of_sha256(data_size: usize) -> Result<u64, EthereumError> {
        let size = data_size as u64;
        Ok(75_000 + 30_000 * (size.div_euclid(64)))
    }
    pub fn ticks_of_ripemd160(data_size: usize) -> Result<u64, EthereumError> {
        let size = data_size as u64;

        Ok(70_000 + 20_000 * (size.div_euclid(64)))
    }
    pub fn ticks_of_identity(data_size: usize) -> Result<u64, EthereumError> {
        let size = data_size as u64;

        Ok(42_000 + 35 * size)
    }
    pub fn ticks_of_withdraw() -> u64 {
        1_000_000
    }

    pub fn ticks_of_ecrecover() -> u64 {
        30_000_000
    }

    pub fn ticks_of_blake2f(rounds: u32) -> u64 {
        1_000_000 * rounds as u64 // TODO: determine the number of ticks
    }
}

#[cfg(test)]
mod tests {

    use super::*;
    use crate::account_storage::account_path;
    use crate::account_storage::init_account_storage as init_evm_account_storage;
    use crate::handler::ExecutionOutcome;
    use crate::EthereumAccountStorage;
    use evm::Config;
    use primitive_types::{H160, U256};
    use tezos_ethereum::block::BlockConstants;
    use tezos_ethereum::block::BlockFees;
    use tezos_smart_rollup_encoding::contract::Contract;
    use tezos_smart_rollup_mock::MockHost;

    const DUMMY_ALLOCATED_TICKS: u64 = 100_000_000;

    fn set_balance(
        host: &mut MockHost,
        evm_account_storage: &mut EthereumAccountStorage,
        address: &H160,
        balance: U256,
    ) {
        let mut account = evm_account_storage
            .get_or_create(host, &account_path(address).unwrap())
            .unwrap();
        let current_balance = account.balance(host).unwrap();
        if current_balance > balance {
            account
                .balance_remove(host, current_balance - balance)
                .unwrap();
        } else {
            account
                .balance_add(host, balance - current_balance)
                .unwrap();
        }
    }

    fn execute_precompiled(
        address: H160,
        input: &[u8],
        transfer: Option<Transfer>,
        gas_limit: Option<u64>,
    ) -> Result<ExecutionOutcome, EthereumError> {
        let caller = H160::from_low_u64_be(118u64);
        let mut mock_runtime = MockHost::default();
        let block_fees = BlockFees::new(U256::from(21000));
        let block = BlockConstants::first_block(U256::zero(), U256::one(), block_fees);
        let mut evm_account_storage = init_evm_account_storage().unwrap();
        let precompiles = precompile_set::<MockHost>();
        let config = Config::shanghai();
        let gas_price = U256::from(21000);

        if let Some(Transfer { source, value, .. }) = transfer {
            set_balance(
                &mut mock_runtime,
                &mut evm_account_storage,
                &source,
                value
                    + gas_limit
                        .map(U256::from)
                        .unwrap_or_default()
                        .saturating_mul(gas_price),
            );
        }

        let mut handler = EvmHandler::new(
            &mut mock_runtime,
            &mut evm_account_storage,
            caller,
            &block,
            &config,
            &precompiles,
            DUMMY_ALLOCATED_TICKS,
            gas_price,
        );

        let is_static = true;
        let value = transfer.map(|t| t.value);

        handler.call_contract(
            caller,
            address,
            value,
            input.to_vec(),
            gas_limit,
            is_static,
        )
    }

    #[test]
    fn call_sha256() {
        // act
        let input: &[u8] = &[0xFF];
        let address = H160::from_low_u64_be(2u64);
        let result = execute_precompiled(address, input, None, Some(22000));

        // assert
        let expected_hash = hex::decode(
            "a8100ae6aa1940d0b663bb31cd466142ebbdbd5187131b92d93818987832eb89",
        )
        .expect("Result should be hex string");

        let expected_gas = 21000 // base cost
            + 72 // sha256 cost
            + 16; // transaction data cost

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            is_success: true,
            reason: ExitReason::Succeed(ExitSucceed::Returned),
            new_address: None,
            logs: vec![],
            result: Some(expected_hash),
            withdrawals: vec![],
            estimated_ticks_used: 75_000,
        };

        assert_eq!(Ok(expected), result);
    }

    #[test]
    fn call_ripemd() {
        // act
        let input: &[u8] = &[0xFF];
        let address = H160::from_low_u64_be(3u64);
        let result = execute_precompiled(address, input, None, Some(22000));

        // assert
        let expected_hash = hex::decode(
            "0000000000000000000000002c0c45d3ecab80fe060e5f1d7057cd2f8de5e557",
        )
        .expect("Result should be hex string");

        let expected_gas = 21000 // base cost
        + 600 + 120// ripeMD cost
        + 16; // transaction data cost

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            is_success: true,
            reason: ExitReason::Succeed(ExitSucceed::Returned),
            new_address: None,
            logs: vec![],
            result: Some(expected_hash),
            withdrawals: vec![],
            estimated_ticks_used: 70_000,
        };

        assert_eq!(Ok(expected), result);
    }

    #[test]
    fn call_withdraw_with_implicit_address() {
        // Format of input - generated by eg remix to match withdrawal ABI
        // 1. function identifier (_not_ the parameter block)
        // 2. location of first parameter (measured from start of parameter block)
        // 3. Number of bytes in string argument
        // 4. A Layer 1 contract address, hex-encoded
        // 5. Zero padding for hex-encoded address

        let input: &[u8] = &hex::decode(
            "cda4fee2\
                 0000000000000000000000000000000000000000000000000000000000000020\
                 0000000000000000000000000000000000000000000000000000000000000024\
                 747a31526a745a5556654c6841444648444c385577445a4136766a5757686f6a70753577\
                 00000000000000000000000000000000000000000000000000000000",
        )
        .unwrap();

        let source = H160::from_low_u64_be(118u64);
        let target = H160::from_str("ff00000000000000000000000000000000000001").unwrap();
        let value = U256::from(100);

        let transfer = Some(Transfer {
            source,
            target,
            value,
        });

        let result = execute_precompiled(target, input, transfer, Some(25000));

        let expected_output = vec![];
        let expected_target =
            Contract::from_b58check("tz1RjtZUVeLhADFHDL8UwDZA6vjWWhojpu5w").unwrap();

        let expected_gas = 21000 // base cost, no additional cost for withdrawal
        + 1032; // transaction data cost (90 zero bytes + 42 non zero bytes)

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            reason: ExitReason::Succeed(ExitSucceed::Returned),
            is_success: true,
            new_address: None,
            logs: vec![],
            result: Some(expected_output),
            withdrawals: vec![Withdrawal {
                target: expected_target,
                amount: 100.into(),
            }],
            estimated_ticks_used: 1_000_000,
        };

        assert_eq!(Ok(expected), result);
    }

    #[test]
    fn call_withdraw_with_kt1_address() {
        // Format of input - generated by eg remix to match withdrawal ABI
        // 1. function identifier (_not_ the parameter block)
        // 2. location of first parameter (measured from start of parameter block)
        // 3. Number of bytes in string argument
        // 4. A Layer 1 contract address, hex-encoded
        // 5. Zero padding for hex-encoded address

        let input: &[u8] = &hex::decode(
            "cda4fee2\
                 0000000000000000000000000000000000000000000000000000000000000020\
                 0000000000000000000000000000000000000000000000000000000000000024\
                 4b54314275455a7462363863315134796a74636b634e6a47454c71577435365879657363\
                 00000000000000000000000000000000000000000000000000000000",
        )
        .unwrap();

        let source = H160::from_low_u64_be(118u64);
        let target = H160::from_str("ff00000000000000000000000000000000000001").unwrap();
        let value = U256::from(100);

        let transfer = Some(Transfer {
            source,
            target,
            value,
        });

        let result = execute_precompiled(target, input, transfer, Some(25000));

        let expected_output = vec![];

        let expected_target =
            Contract::from_b58check("KT1BuEZtb68c1Q4yjtckcNjGELqWt56Xyesc").unwrap();

        let expected_gas = 21000 // base cost, no additional cost for withdrawal
        + 1032; // transaction data cost (90 zero bytes + 42 non zero bytes)

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            reason: ExitReason::Succeed(ExitSucceed::Returned),
            is_success: true,
            new_address: None,
            logs: vec![],
            result: Some(expected_output),
            withdrawals: vec![Withdrawal {
                target: expected_target,
                amount: 100.into(),
            }],
            // TODO (#6426): estimate the ticks consumption of precompiled contracts
            estimated_ticks_used: 1_000_000,
        };

        assert_eq!(Ok(expected), result);
    }

    #[test]
    fn call_withdrawal_fails_without_transfer() {
        let input: &[u8] = &hex::decode(
            "cda4fee2\
                 0000000000000000000000000000000000000000000000000000000000000020\
                 0000000000000000000000000000000000000000000000000000000000000024\
                 747a31526a745a5556654c6841444648444c385577445a4136766a5757686f6a70753577\
                 00000000000000000000000000000000000000000000000000000000",
        )
        .unwrap();

        // 1. Fails with no transfer

        let target = H160::from_str("ff00000000000000000000000000000000000001").unwrap();

        let transfer: Option<Transfer> = None;

        let result = execute_precompiled(target, input, transfer, Some(25000));

        let expected_gas = 21000 // base cost, no additional cost for withdrawal
        + 1032; // transaction data cost (90 zero bytes + 42 non zero bytes)

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            reason: ExitReason::Revert(ExitRevert::Reverted),
            is_success: false,
            new_address: None,
            logs: vec![],
            result: Some(vec![]),
            withdrawals: vec![],
            estimated_ticks_used: 1_000_000,
        };

        assert_eq!(Ok(expected), result);

        // 2. Fails with transfer of 0 amount.

        let source = H160::from_low_u64_be(118u64);

        let transfer: Option<Transfer> = Some(Transfer {
            target,
            source,
            value: U256::zero(),
        });

        let expected = ExecutionOutcome {
            gas_used: expected_gas,
            reason: ExitReason::Revert(ExitRevert::Reverted),
            is_success: false,
            new_address: None,
            logs: vec![],
            result: Some(vec![]),
            withdrawals: vec![],
            estimated_ticks_used: 1_000_000,
        };

        let result = execute_precompiled(target, input, transfer, Some(25000));

        assert_eq!(Ok(expected), result);
    }

    #[test]
    fn test_ercover_parse_input_padding() {
        let (h, v, r, s) = erec_parse_inputs(&[1u8]);
        assert_eq!(1, h[0]);
        assert_eq!([0; 31], h[1..]);
        assert_eq!(0, v);
        assert_eq!([0; 32], r);
        assert_eq!([0; 32], s);
    }

    #[test]
    fn test_ercover_parse_input_order() {
        let input = [[1; 32], [2; 32], [3; 32], [4; 32]].join(&[0u8; 0][..]);
        let (h, v, r, s) = erec_parse_inputs(&input);
        assert_eq!([1; 32], h);
        assert_eq!(2, v);
        assert_eq!([3; 32], r);
        assert_eq!([4; 32], s);
    }

    #[test]
    fn test_ercover_parse_input_ignore_right_padding() {
        let input = [[1; 32], [2; 32], [3; 32], [4; 32], [5; 32]].join(&[0u8; 0][..]);
        let (h, v, r, s) = erec_parse_inputs(&input);
        assert_eq!([1; 32], h);
        assert_eq!(2, v);
        assert_eq!([3; 32], r);
        assert_eq!([4; 32], s);
    }

    #[test]
    fn test_ecrecover_invalid_empty() {
        // act
        let input: [u8; 0] = [0; 0];
        let result =
            execute_precompiled(H160::from_low_u64_be(1), &input, None, Some(25000));

        // assert
        // expected outcome is OK and empty output

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(Some(vec![]), outcome.result);
    }

    #[test]
    fn test_ecrecover_invalid_zero() {
        // act
        let input: [u8; 128] = [0; 128];
        let result =
            execute_precompiled(H160::from_low_u64_be(1), &input, None, Some(25000));

        // assert
        // expected outcome is OK but empty output

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(Some(vec![]), outcome.result);
    }

    fn assemble_input(h: &str, v: &str, r: &str, s: &str) -> [u8; 128] {
        let mut data_str = "".to_owned();
        data_str.push_str(h);
        data_str.push_str(v);
        data_str.push_str(r);
        data_str.push_str(s);
        let data = hex::decode(data_str).unwrap();
        let mut input: [u8; 128] = [0; 128];
        input.copy_from_slice(&data);
        input
    }

    fn input_legacy() -> (&'static str, &'static str, &'static str, &'static str) {
        // Obtain by signing a transaction tx_legacy.json (even though it doesn't need to be)
        // address: 0xf0affc80a5f69f4a9a3ee01a640873b6ba53e539
        // privateKey: 0x84e147b8bc36d99cc6b1676318a0635d8febc9f02897b0563ad27358589ee502
        // publicKey: 0x08a4681ba8c520aaab2308957d401ffded69155b358246596846f87c0728e76f618f9772f16687ed5a2854234b037b71e4c3bc92cad78e575fb12c8df8b8dae5
        // node etherlink/kernel_evm/benchmarks/scripts/sign_tx.js $(pwd)/src/kernel_evm/benchmarks/scripts/transactions_example/tx_legacy.json 0x84e147b8bc36d99cc6b1676318a0635d8febc9f02897b0563ad27358589ee502
        let hash = "3c74ed8cf6d9695ac4de8e5dda38ac3719b3f42e913e0109344a5fcbd1ff8562";
        let r = "b17daf010e907d83f0235467faac96f346c4cc46600477d1b5f543ced8c986b7";
        let s = "70221fd3c40e0cbaef013e9bb62cf8adc70c77a5c313954c03897f3f08f90726";
        // v = 27 -> 1b, is encoded as 32 bytes
        let v = "000000000000000000000000000000000000000000000000000000000000001b";
        (hash, v, r, s)
    }

    fn input_spec() -> (&'static str, &'static str, &'static str, &'static str) {
        // taken from https://www.evm.codes/precompiled?fork=shanghai
        let hash = "456e9aea5e197a1f1af7a3e85a3212fa4049a3ba34c2289b4c860fc0b0c64ef3";
        let r = "9242685bf161793cc25603c231bc2f568eb630ea16aa137d2664ac8038825608";
        let s = "4f8ae3bd7535248d0bd448298cc2e2071e56992d0774dc340c368ae950852ada";
        // v = 28 -> 1c, is encoded as 32 bytes
        let v = "000000000000000000000000000000000000000000000000000000000000001c";
        (hash, v, r, s)
    }

    #[test]
    fn test_ercover_parse_input_real() {
        let (hash, v, r, s) = input_legacy();
        let input: [u8; 128] = assemble_input(hash, v, r, s);
        let (ho, vo, ro, so) = erec_parse_inputs(&input);
        assert_eq!(hex::decode(hash).unwrap(), ho);
        assert_eq!(27, vo);
        assert_eq!(hex::decode(r).unwrap(), ro);
        assert_eq!(hex::decode(s).unwrap(), so);
    }

    #[test]
    fn test_ercover_parse_input_spec() {
        let (hash, v, r, s) = input_spec();
        let input: [u8; 128] = assemble_input(hash, v, r, s);
        let (ho, vo, ro, so) = erec_parse_inputs(&input);
        assert_eq!(hex::decode(hash).unwrap(), ho);
        assert_eq!(28, vo);
        assert_eq!(hex::decode(r).unwrap(), ro);
        assert_eq!(hex::decode(s).unwrap(), so);
    }

    #[test]
    fn test_ecrecover_input_real() {
        // setup
        let (hash, v, r, s) = input_legacy();
        let input: [u8; 128] = assemble_input(hash, v, r, s);
        let mut expected_address: Vec<u8> =
            hex::decode("f0affc80a5f69f4a9a3ee01a640873b6ba53e539").unwrap();
        let mut expected_output = [0u8; 12].to_vec();
        expected_output.append(&mut expected_address);

        // act
        let result =
            execute_precompiled(H160::from_low_u64_be(1), &input, None, Some(35000));

        // assert
        // expected outcome is OK and address over 32 bytes

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(
            hex::encode(expected_output),
            hex::encode(outcome.result.unwrap())
        );
    }

    #[test]
    fn test_ecrecover_input_spec() {
        let (hash, v, r, s) = input_spec();
        let input: [u8; 128] = assemble_input(hash, v, r, s);

        let mut expected_address: Vec<u8> =
            hex::decode("7156526fbd7a3c72969b54f64e42c10fbb768c8a").unwrap();
        let mut expected_output = [0u8; 12].to_vec();
        expected_output.append(&mut expected_address);

        // act
        let result =
            execute_precompiled(H160::from_low_u64_be(1), &input, None, Some(35000));

        // assert
        // expected outcome is OK and address over 32 bytes

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(
            hex::encode(expected_output),
            hex::encode(outcome.result.unwrap())
        );
    }

    #[test]
    fn test_blake2f_invalid_empty() {
        // act
        let input = [0; 0];
        let result =
            execute_precompiled(H160::from_low_u64_be(9), &input, None, Some(25000));

        // assert
        // expected outcome is OK and empty output

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(Some(vec![]), outcome.result);
    }

    #[test]
    fn text_blake2f_invalid_flag() {
        let input = hex::decode(
            "0000000c48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbab\
            d9831f79217e1319cde05b616263000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\
            0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\
            0000000000000000000000000000000000000000000000000300000000000000000000000000000002"
        ).unwrap();

        let result =
            execute_precompiled(H160::from_low_u64_be(9), &input, None, Some(25000));

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);
        assert_eq!(Some(vec![]), outcome.result);
    }

    #[test]
    fn test_blake2f_input_spec() {
        let input = hex::decode(
            "0000000c\
            48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e\
            511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b\
            616263000000000000000000000000000000000000000000000000000000000000000000000000\
            000000000000000000000000000000000000000000000000000000000000000000000000000000\
            000000000000000000000000000000000000000000000000000000000000000000000000000000\
            0000000000000000000000\
            03000000000000000000000000000000\
            01"
                ).unwrap();
        let result =
            execute_precompiled(H160::from_low_u64_be(9), &input, None, Some(25000));

        assert!(result.is_ok());
        let outcome = result.unwrap();
        println!("{}", outcome.gas_used);
        assert!(outcome.is_success);

        let expected = hex::decode(
                "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923"
                    );

        assert_eq!(expected.ok(), outcome.result);
    }

    struct ModexpTestCase {
        input: &'static str,
        expected: &'static str,
        _name: &'static str, // Used as a comment and debugging if needed.
    }

    const MODEXP_TESTS: [ModexpTestCase; 19] = [
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000064\
            0000000000000000000000000000000000000000000000000000000000000064\
            0000000000000000000000000000000000000000000000000000000000000064\
            5442ddc2b70f66c1f6d2b296c0a875be7eddd0a80958cbc7425f1899ccf90511\
            a5c318226e48ee23f130b44dc17a691ce66be5da18b85ed7943535b205aa125e\
            9f59294a00f05155c23e97dac6b3a00b0c63c8411bf815fc183b420b4d9dc5f7\
            15040d5c60957f52d334b843197adec58c131c907cd96059fc5adce9dda351b5\
            df3d666fcf3eb63c46851c1816e323f2119ebdf5ef35",
            expected: "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            _name: "eth_tests_modexp_modsize0_returndatasizeFiller",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000001\
            0000000000000000000000000000000000000000000000000000000000000020\
            0000000000000000000000000000000000000000000000000000000000000020\
            03\
            fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e\
            ffffffffffffffffffffffffffffffffffffffffff2f",
            expected: "162ead82cadefaeaf6e9283248fdf2f2845f6396f6f17c4d5a39f820b6f6b5f9",
            _name: "eth_tests_create2callPrecompiles_test0_berlin",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000001\
            0000000000000000000000000000000000000000000000000000000000000020\
            0000000000000000000000000000000000000000000000000000000000000020\
            03\
            fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e\
            fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
            expected: "0000000000000000000000000000000000000000000000000000000000000001",
            _name: "eip198_example_1",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000000\
            0000000000000000000000000000000000000000000000000000000000000020\
            0000000000000000000000000000000000000000000000000000000000000020\
            fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e\
            fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
            expected: "0000000000000000000000000000000000000000000000000000000000000000",
            _name: "eip198_example_2",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000040\
            0000000000000000000000000000000000000000000000000000000000000001\
            0000000000000000000000000000000000000000000000000000000000000040\
            e09ad9675465c53a109fac66a445c91b292d2bb2c5268addb30cd82f80fcb003\
            3ff97c80a5fc6f39193ae969c6ede6710a6b7ac27078a06d90ef1c72e5c85fb5\
            02fc9e1f6beb81516545975218075ec2af118cd8798df6e08a147c60fd6095ac\
            2bb02c2908cf4dd7c81f11c289e4bce98f3553768f392a80ce22bf5c4f4a248c\
            6b",
            expected: "60008f1614cc01dcfb6bfb09c625cf90b47d4468db81b5f8b7a39d42f332eab9b2da8f2d95311648a8f243f4bb13cfb3d8f7f2a3c014122ebb3ed41b02783adc",
            _name: "nagydani_1_square",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000040\
            0000000000000000000000000000000000000000000000000000000000000001\
            0000000000000000000000000000000000000000000000000000000000000040\
            e09ad9675465c53a109fac66a445c91b292d2bb2c5268addb30cd82f80fcb003\
            3ff97c80a5fc6f39193ae969c6ede6710a6b7ac27078a06d90ef1c72e5c85fb5\
            03fc9e1f6beb81516545975218075ec2af118cd8798df6e08a147c60fd6095ac\
            2bb02c2908cf4dd7c81f11c289e4bce98f3553768f392a80ce22bf5c4f4a248c\
            6b",
            expected: "4834a46ba565db27903b1c720c9d593e84e4cbd6ad2e64b31885d944f68cd801f92225a8961c952ddf2797fa4701b330c85c4b363798100b921a1a22a46a7fec",
            _name: "nagydani_1_qube"
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000040\
            0000000000000000000000000000000000000000000000000000000000000003\
            0000000000000000000000000000000000000000000000000000000000000040\
            e09ad9675465c53a109fac66a445c91b292d2bb2c5268addb30cd82f80fcb003\
            3ff97c80a5fc6f39193ae969c6ede6710a6b7ac27078a06d90ef1c72e5c85fb5\
            010001fc9e1f6beb81516545975218075ec2af118cd8798df6e08a147c60fd60\
            95ac2bb02c2908cf4dd7c81f11c289e4bce98f3553768f392a80ce22bf5c4f4a\
            248c6b",
            expected: "c36d804180c35d4426b57b50c5bfcca5c01856d104564cd513b461d3c8b8409128a5573e416d0ebe38f5f736766d9dc27143e4da981dfa4d67f7dc474cbee6d2",
            _name: "nagydani_1_pow0x10001",
        },
        ModexpTestCase {
            input: "\
            0000000000000000000000000000000000000000000000000000000000000080\
            0000000000000000000000000000000000000000000000000000000000000001\
            0000000000000000000000000000000000000000000000000000000000000080\
            cad7d991a00047dd54d3399b6b0b937c718abddef7917c75b6681f40cc15e2be\
            0003657d8d4c34167b2f0bbbca0ccaa407c2a6a07d50f1517a8f22979ce12a81\
            dcaf707cc0cebfc0ce2ee84ee7f77c38b9281b9822a8d3de62784c089c9b18dc\
            b9a2a5eecbede90ea788a862a9ddd9d609c2c52972d63e289e28f6a590ffbf51\
            02e6d893b80aeed5e6e9ce9afa8a5d5675c93a32ac05554cb20e9951b2c140e3\
            ef4e433068cf0fb73bc9f33af1853f64aa27a0028cbf570d7ac9048eae5dc7b2\
            8c87c31e5810f1e7fa2cda6adf9f1076dbc1ec1238560071e7efc4e9565c49be\
            9e7656951985860a558a754594115830bcdb421f741408346dd5997bb01c2870\
            87",
            expected: "981dd99c3b113fae3e3eaa9435c0dc96779a23c12a53d1084b4f67b0b053a27560f627b873e3f16ad78f28c94f14b6392def26e4d8896c5e3c984e50fa0b3aa44f1da78b913187c6128baa9340b1e9c9a0fd02cb78885e72576da4a8f7e5a113e173a7a2889fde9d407bd9f06eb05bc8fc7b4229377a32941a02bf4edcc06d70",
            _name: "nagydani_2_square",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000080cad7d991a00047dd54d3399b6b0b937c718abddef7917c75b6681f40cc15e2be0003657d8d4c34167b2f0bbbca0ccaa407c2a6a07d50f1517a8f22979ce12a81dcaf707cc0cebfc0ce2ee84ee7f77c38b9281b9822a8d3de62784c089c9b18dcb9a2a5eecbede90ea788a862a9ddd9d609c2c52972d63e289e28f6a590ffbf5103e6d893b80aeed5e6e9ce9afa8a5d5675c93a32ac05554cb20e9951b2c140e3ef4e433068cf0fb73bc9f33af1853f64aa27a0028cbf570d7ac9048eae5dc7b28c87c31e5810f1e7fa2cda6adf9f1076dbc1ec1238560071e7efc4e9565c49be9e7656951985860a558a754594115830bcdb421f741408346dd5997bb01c287087",
            expected: "d89ceb68c32da4f6364978d62aaa40d7b09b59ec61eb3c0159c87ec3a91037f7dc6967594e530a69d049b64adfa39c8fa208ea970cfe4b7bcd359d345744405afe1cbf761647e32b3184c7fbe87cee8c6c7ff3b378faba6c68b83b6889cb40f1603ee68c56b4c03d48c595c826c041112dc941878f8c5be828154afd4a16311f",
            _name: "nagydani_2_qube",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000080cad7d991a00047dd54d3399b6b0b937c718abddef7917c75b6681f40cc15e2be0003657d8d4c34167b2f0bbbca0ccaa407c2a6a07d50f1517a8f22979ce12a81dcaf707cc0cebfc0ce2ee84ee7f77c38b9281b9822a8d3de62784c089c9b18dcb9a2a5eecbede90ea788a862a9ddd9d609c2c52972d63e289e28f6a590ffbf51010001e6d893b80aeed5e6e9ce9afa8a5d5675c93a32ac05554cb20e9951b2c140e3ef4e433068cf0fb73bc9f33af1853f64aa27a0028cbf570d7ac9048eae5dc7b28c87c31e5810f1e7fa2cda6adf9f1076dbc1ec1238560071e7efc4e9565c49be9e7656951985860a558a754594115830bcdb421f741408346dd5997bb01c287087",
            expected: "ad85e8ef13fd1dd46eae44af8b91ad1ccae5b7a1c92944f92a19f21b0b658139e0cabe9c1f679507c2de354bf2c91ebd965d1e633978a830d517d2f6f8dd5fd58065d58559de7e2334a878f8ec6992d9b9e77430d4764e863d77c0f87beede8f2f7f2ab2e7222f85cc9d98b8467f4bb72e87ef2882423ebdb6daf02dddac6db2",
            _name: "nagydani_2_pow0x10001",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000100c9130579f243e12451760976261416413742bd7c91d39ae087f46794062b8c239f2a74abf3918605a0e046a7890e049475ba7fbb78f5de6490bd22a710cc04d30088179a919d86c2da62cf37f59d8f258d2310d94c24891be2d7eeafaa32a8cb4b0cfe5f475ed778f45907dc8916a73f03635f233f7a77a00a3ec9ca6761a5bbd558a2318ecd0caa1c5016691523e7e1fa267dd35e70c66e84380bdcf7c0582f540174e572c41f81e93da0b757dff0b0fe23eb03aa19af0bdec3afb474216febaacb8d0381e631802683182b0fe72c28392539850650b70509f54980241dc175191a35d967288b532a7a8223ce2440d010615f70df269501944d4ec16fe4a3cb02d7a85909174757835187cb52e71934e6c07ef43b4c46fc30bbcd0bc72913068267c54a4aabebb493922492820babdeb7dc9b1558fcf7bd82c37c82d3147e455b623ab0efa752fe0b3a67ca6e4d126639e645a0bf417568adbb2a6a4eef62fa1fa29b2a5a43bebea1f82193a7dd98eb483d09bb595af1fa9c97c7f41f5649d976aee3e5e59e2329b43b13bea228d4a93f16ba139ccb511de521ffe747aa2eca664f7c9e33da59075cc335afcd2bf3ae09765f01ab5a7c3e3938ec168b74724b5074247d200d9970382f683d6059b94dbc336603d1dfee714e4b447ac2fa1d99ecb4961da2854e03795ed758220312d101e1e3d87d5313a6d052aebde75110363d",
            expected: "affc7507ea6d84751ec6b3f0d7b99dbcc263f33330e450d1b3ff0bc3d0874320bf4edd57debd587306988157958cb3cfd369cc0c9c198706f635c9e0f15d047df5cb44d03e2727f26b083c4ad8485080e1293f171c1ed52aef5993a5815c35108e848c951cf1e334490b4a539a139e57b68f44fee583306f5b85ffa57206b3ee5660458858534e5386b9584af3c7f67806e84c189d695e5eb96e1272d06ec2df5dc5fabc6e94b793718c60c36be0a4d031fc84cd658aa72294b2e16fc240aef70cb9e591248e38bd49c5a554d1afa01f38dab72733092f7555334bbef6c8c430119840492380aa95fa025dcf699f0a39669d812b0c6946b6091e6e235337b6f8",
            _name: "nagydani_3_square",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000100c9130579f243e12451760976261416413742bd7c91d39ae087f46794062b8c239f2a74abf3918605a0e046a7890e049475ba7fbb78f5de6490bd22a710cc04d30088179a919d86c2da62cf37f59d8f258d2310d94c24891be2d7eeafaa32a8cb4b0cfe5f475ed778f45907dc8916a73f03635f233f7a77a00a3ec9ca6761a5bbd558a2318ecd0caa1c5016691523e7e1fa267dd35e70c66e84380bdcf7c0582f540174e572c41f81e93da0b757dff0b0fe23eb03aa19af0bdec3afb474216febaacb8d0381e631802683182b0fe72c28392539850650b70509f54980241dc175191a35d967288b532a7a8223ce2440d010615f70df269501944d4ec16fe4a3cb03d7a85909174757835187cb52e71934e6c07ef43b4c46fc30bbcd0bc72913068267c54a4aabebb493922492820babdeb7dc9b1558fcf7bd82c37c82d3147e455b623ab0efa752fe0b3a67ca6e4d126639e645a0bf417568adbb2a6a4eef62fa1fa29b2a5a43bebea1f82193a7dd98eb483d09bb595af1fa9c97c7f41f5649d976aee3e5e59e2329b43b13bea228d4a93f16ba139ccb511de521ffe747aa2eca664f7c9e33da59075cc335afcd2bf3ae09765f01ab5a7c3e3938ec168b74724b5074247d200d9970382f683d6059b94dbc336603d1dfee714e4b447ac2fa1d99ecb4961da2854e03795ed758220312d101e1e3d87d5313a6d052aebde75110363d",
            expected: "1b280ecd6a6bf906b806d527c2a831e23b238f89da48449003a88ac3ac7150d6a5e9e6b3be4054c7da11dd1e470ec29a606f5115801b5bf53bc1900271d7c3ff3cd5ed790d1c219a9800437a689f2388ba1a11d68f6a8e5b74e9a3b1fac6ee85fc6afbac599f93c391f5dc82a759e3c6c0ab45ce3f5d25d9b0c1bf94cf701ea6466fc9a478dacc5754e593172b5111eeba88557048bceae401337cd4c1182ad9f700852bc8c99933a193f0b94cf1aedbefc48be3bc93ef5cb276d7c2d5462ac8bb0c8fe8923a1db2afe1c6b90d59c534994a6a633f0ead1d638fdc293486bb634ff2c8ec9e7297c04241a61c37e3ae95b11d53343d4ba2b4cc33d2cfa7eb705e",
            _name: "nagydani_3_qube",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000100c9130579f243e12451760976261416413742bd7c91d39ae087f46794062b8c239f2a74abf3918605a0e046a7890e049475ba7fbb78f5de6490bd22a710cc04d30088179a919d86c2da62cf37f59d8f258d2310d94c24891be2d7eeafaa32a8cb4b0cfe5f475ed778f45907dc8916a73f03635f233f7a77a00a3ec9ca6761a5bbd558a2318ecd0caa1c5016691523e7e1fa267dd35e70c66e84380bdcf7c0582f540174e572c41f81e93da0b757dff0b0fe23eb03aa19af0bdec3afb474216febaacb8d0381e631802683182b0fe72c28392539850650b70509f54980241dc175191a35d967288b532a7a8223ce2440d010615f70df269501944d4ec16fe4a3cb010001d7a85909174757835187cb52e71934e6c07ef43b4c46fc30bbcd0bc72913068267c54a4aabebb493922492820babdeb7dc9b1558fcf7bd82c37c82d3147e455b623ab0efa752fe0b3a67ca6e4d126639e645a0bf417568adbb2a6a4eef62fa1fa29b2a5a43bebea1f82193a7dd98eb483d09bb595af1fa9c97c7f41f5649d976aee3e5e59e2329b43b13bea228d4a93f16ba139ccb511de521ffe747aa2eca664f7c9e33da59075cc335afcd2bf3ae09765f01ab5a7c3e3938ec168b74724b5074247d200d9970382f683d6059b94dbc336603d1dfee714e4b447ac2fa1d99ecb4961da2854e03795ed758220312d101e1e3d87d5313a6d052aebde75110363d",
            expected: "37843d7c67920b5f177372fa56e2a09117df585f81df8b300fba245b1175f488c99476019857198ed459ed8d9799c377330e49f4180c4bf8e8f66240c64f65ede93d601f957b95b83efdee1e1bfde74169ff77002eaf078c71815a9220c80b2e3b3ff22c2f358111d816ebf83c2999026b6de50bfc711ff68705d2f40b753424aefc9f70f08d908b5a20276ad613b4ab4309a3ea72f0c17ea9df6b3367d44fb3acab11c333909e02e81ea2ed404a712d3ea96bba87461720e2d98723e7acd0520ac1a5212dbedcd8dc0c1abf61d4719e319ff4758a774790b8d463cdfe131d1b2dcfee52d002694e98e720cb6ae7ccea353bc503269ba35f0f63bf8d7b672a76",
            _name: "nagydani_3_pow0x10001",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000200db34d0e438249c0ed685c949cc28776a05094e1c48691dc3f2dca5fc3356d2a0663bd376e4712839917eb9a19c670407e2c377a2de385a3ff3b52104f7f1f4e0c7bf7717fb913896693dc5edbb65b760ef1b00e42e9d8f9af17352385e1cd742c9b006c0f669995cb0bb21d28c0aced2892267637b6470d8cee0ab27fc5d42658f6e88240c31d6774aa60a7ebd25cd48b56d0da11209f1928e61005c6eb709f3e8e0aaf8d9b10f7d7e296d772264dc76897ccdddadc91efa91c1903b7232a9e4c3b941917b99a3bc0c26497dedc897c25750af60237aa67934a26a2bc491db3dcc677491944bc1f51d3e5d76b8d846a62db03dedd61ff508f91a56d71028125035c3a44cbb041497c83bf3e4ae2a9613a401cc721c547a2afa3b16a2969933d3626ed6d8a7428648f74122fd3f2a02a20758f7f693892c8fd798b39abac01d18506c45e71432639e9f9505719ee822f62ccbf47f6850f096ff77b5afaf4be7d772025791717dbe5abf9b3f40cff7d7aab6f67e38f62faf510747276e20a42127e7500c444f9ed92baf65ade9e836845e39c4316d9dce5f8e2c8083e2c0acbb95296e05e51aab13b6b8f53f06c9c4276e12b0671133218cc3ea907da3bd9a367096d9202128d14846cc2e20d56fc8473ecb07cecbfb8086919f3971926e7045b853d85a69d026195c70f9f7a823536e2a8f4b3e12e94d9b53a934353451094b8102df3143a0057457d75e8c708b6337a6f5a4fd1a06727acf9fb93e2993c62f3378b37d56c85e7b1e00f0145ebf8e4095bd723166293c60b6ac1252291ef65823c9e040ddad14969b3b340a4ef714db093a587c37766d68b8d6b5016e741587e7e6bf7e763b44f0247e64bae30f994d248bfd20541a333e5b225ef6a61199e301738b1e688f70ec1d7fb892c183c95dc543c3e12adf8a5e8b9ca9d04f9445cced3ab256f29e998e69efaa633a7b60e1db5a867924ccab0a171d9d6e1098dfa15acde9553de599eaa56490c8f411e4985111f3d40bddfc5e301edb01547b01a886550a61158f7e2033c59707789bf7c854181d0c2e2a42a93cf09209747d7082e147eb8544de25c3eb14f2e35559ea0c0f5877f2f3fc92132c0ae9da4e45b2f6c866a224ea6d1f28c05320e287750fbc647368d41116e528014cc1852e5531d53e4af938374daba6cee4baa821ed07117253bb3601ddd00d59a3d7fb2ef1f5a2fbba7c429f0cf9a5b3462410fd833a69118f8be9c559b1000cc608fd877fb43f8e65c2d1302622b944462579056874b387208d90623fcdaf93920ca7a9e4ba64ea208758222ad868501cc2c345e2d3a5ea2a17e5069248138c8a79c0251185d29ee73e5afab5354769142d2bf0cb6712727aa6bf84a6245fcdae66e4938d84d1b9dd09a884818622080ff5f98942fb20acd7e0c916c2d5ea7ce6f7e173315384518f",
            expected: "8a5aea5f50dcc03dc7a7a272b5aeebc040554dbc1ffe36753c4fc75f7ed5f6c2cc0de3a922bf96c78bf0643a73025ad21f45a4a5cadd717612c511ab2bff1190fe5f1ae05ba9f8fe3624de1de2a817da6072ddcdb933b50216811dbe6a9ca79d3a3c6b3a476b079fd0d05f04fb154e2dd3e5cb83b148a006f2bcbf0042efb2ae7b916ea81b27aac25c3bf9a8b6d35440062ad8eae34a83f3ffa2cc7b40346b62174a4422584f72f95316f6b2bee9ff232ba9739301c97c99a9ded26c45d72676eb856ad6ecc81d36a6de36d7f9dafafee11baa43a4b0d5e4ecffa7b9b7dcefd58c397dd373e6db4acd2b2c02717712e6289bed7c813b670c4a0c6735aa7f3b0f1ce556eae9fcc94b501b2c8781ba50a8c6220e8246371c3c7359fe4ef9da786ca7d98256754ca4e496be0a9174bedbecb384bdf470779186d6a833f068d2838a88d90ef3ad48ff963b67c39cc5a3ee123baf7bf3125f64e77af7f30e105d72c4b9b5b237ed251e4c122c6d8c1405e736299c3afd6db16a28c6a9cfa68241e53de4cd388271fe534a6a9b0dbea6171d170db1b89858468885d08fecbd54c8e471c3e25d48e97ba450b96d0d87e00ac732aaa0d3ce4309c1064bd8a4c0808a97e0143e43a24cfa847635125cd41c13e0574487963e9d725c01375db99c31da67b4cf65eff555f0c0ac416c727ff8d438ad7c42030551d68c2e7adda0abb1ca7c10",
            _name: "nagydani_4_square",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000200db34d0e438249c0ed685c949cc28776a05094e1c48691dc3f2dca5fc3356d2a0663bd376e4712839917eb9a19c670407e2c377a2de385a3ff3b52104f7f1f4e0c7bf7717fb913896693dc5edbb65b760ef1b00e42e9d8f9af17352385e1cd742c9b006c0f669995cb0bb21d28c0aced2892267637b6470d8cee0ab27fc5d42658f6e88240c31d6774aa60a7ebd25cd48b56d0da11209f1928e61005c6eb709f3e8e0aaf8d9b10f7d7e296d772264dc76897ccdddadc91efa91c1903b7232a9e4c3b941917b99a3bc0c26497dedc897c25750af60237aa67934a26a2bc491db3dcc677491944bc1f51d3e5d76b8d846a62db03dedd61ff508f91a56d71028125035c3a44cbb041497c83bf3e4ae2a9613a401cc721c547a2afa3b16a2969933d3626ed6d8a7428648f74122fd3f2a02a20758f7f693892c8fd798b39abac01d18506c45e71432639e9f9505719ee822f62ccbf47f6850f096ff77b5afaf4be7d772025791717dbe5abf9b3f40cff7d7aab6f67e38f62faf510747276e20a42127e7500c444f9ed92baf65ade9e836845e39c4316d9dce5f8e2c8083e2c0acbb95296e05e51aab13b6b8f53f06c9c4276e12b0671133218cc3ea907da3bd9a367096d9202128d14846cc2e20d56fc8473ecb07cecbfb8086919f3971926e7045b853d85a69d026195c70f9f7a823536e2a8f4b3e12e94d9b53a934353451094b8103df3143a0057457d75e8c708b6337a6f5a4fd1a06727acf9fb93e2993c62f3378b37d56c85e7b1e00f0145ebf8e4095bd723166293c60b6ac1252291ef65823c9e040ddad14969b3b340a4ef714db093a587c37766d68b8d6b5016e741587e7e6bf7e763b44f0247e64bae30f994d248bfd20541a333e5b225ef6a61199e301738b1e688f70ec1d7fb892c183c95dc543c3e12adf8a5e8b9ca9d04f9445cced3ab256f29e998e69efaa633a7b60e1db5a867924ccab0a171d9d6e1098dfa15acde9553de599eaa56490c8f411e4985111f3d40bddfc5e301edb01547b01a886550a61158f7e2033c59707789bf7c854181d0c2e2a42a93cf09209747d7082e147eb8544de25c3eb14f2e35559ea0c0f5877f2f3fc92132c0ae9da4e45b2f6c866a224ea6d1f28c05320e287750fbc647368d41116e528014cc1852e5531d53e4af938374daba6cee4baa821ed07117253bb3601ddd00d59a3d7fb2ef1f5a2fbba7c429f0cf9a5b3462410fd833a69118f8be9c559b1000cc608fd877fb43f8e65c2d1302622b944462579056874b387208d90623fcdaf93920ca7a9e4ba64ea208758222ad868501cc2c345e2d3a5ea2a17e5069248138c8a79c0251185d29ee73e5afab5354769142d2bf0cb6712727aa6bf84a6245fcdae66e4938d84d1b9dd09a884818622080ff5f98942fb20acd7e0c916c2d5ea7ce6f7e173315384518f",
            expected: "5a2664252aba2d6e19d9600da582cdd1f09d7a890ac48e6b8da15ae7c6ff1856fc67a841ac2314d283ffa3ca81a0ecf7c27d89ef91a5a893297928f5da0245c99645676b481b7e20a566ee6a4f2481942bee191deec5544600bb2441fd0fb19e2ee7d801ad8911c6b7750affec367a4b29a22942c0f5f4744a4e77a8b654da2a82571037099e9c6d930794efe5cdca73c7b6c0844e386bdca8ea01b3d7807146bb81365e2cdc6475f8c23e0ff84463126189dc9789f72bbce2e3d2d114d728a272f1345122de23df54c922ec7a16e5c2a8f84da8871482bd258c20a7c09bbcd64c7a96a51029bbfe848736a6ba7bf9d931a9b7de0bcaf3635034d4958b20ae9ab3a95a147b0421dd5f7ebff46c971010ebfc4adbbe0ad94d5498c853e7142c450d8c71de4b2f84edbf8acd2e16d00c8115b150b1c30e553dbb82635e781379fe2a56360420ff7e9f70cc64c00aba7e26ed13c7c19622865ae07248daced36416080f35f8cc157a857ed70ea4f347f17d1bee80fa038abd6e39b1ba06b97264388b21364f7c56e192d4b62d9b161405f32ab1e2594e86243e56fcf2cb30d21adef15b9940f91af681da24328c883d892670c6aa47940867a81830a82b82716895db810df1b834640abefb7db2092dd92912cb9a735175bc447be40a503cf22dfe565b4ed7a3293ca0dfd63a507430b323ee248ec82e843b673c97ad730728cebc",
            _name: "nagydani_4_qube",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000200db34d0e438249c0ed685c949cc28776a05094e1c48691dc3f2dca5fc3356d2a0663bd376e4712839917eb9a19c670407e2c377a2de385a3ff3b52104f7f1f4e0c7bf7717fb913896693dc5edbb65b760ef1b00e42e9d8f9af17352385e1cd742c9b006c0f669995cb0bb21d28c0aced2892267637b6470d8cee0ab27fc5d42658f6e88240c31d6774aa60a7ebd25cd48b56d0da11209f1928e61005c6eb709f3e8e0aaf8d9b10f7d7e296d772264dc76897ccdddadc91efa91c1903b7232a9e4c3b941917b99a3bc0c26497dedc897c25750af60237aa67934a26a2bc491db3dcc677491944bc1f51d3e5d76b8d846a62db03dedd61ff508f91a56d71028125035c3a44cbb041497c83bf3e4ae2a9613a401cc721c547a2afa3b16a2969933d3626ed6d8a7428648f74122fd3f2a02a20758f7f693892c8fd798b39abac01d18506c45e71432639e9f9505719ee822f62ccbf47f6850f096ff77b5afaf4be7d772025791717dbe5abf9b3f40cff7d7aab6f67e38f62faf510747276e20a42127e7500c444f9ed92baf65ade9e836845e39c4316d9dce5f8e2c8083e2c0acbb95296e05e51aab13b6b8f53f06c9c4276e12b0671133218cc3ea907da3bd9a367096d9202128d14846cc2e20d56fc8473ecb07cecbfb8086919f3971926e7045b853d85a69d026195c70f9f7a823536e2a8f4b3e12e94d9b53a934353451094b81010001df3143a0057457d75e8c708b6337a6f5a4fd1a06727acf9fb93e2993c62f3378b37d56c85e7b1e00f0145ebf8e4095bd723166293c60b6ac1252291ef65823c9e040ddad14969b3b340a4ef714db093a587c37766d68b8d6b5016e741587e7e6bf7e763b44f0247e64bae30f994d248bfd20541a333e5b225ef6a61199e301738b1e688f70ec1d7fb892c183c95dc543c3e12adf8a5e8b9ca9d04f9445cced3ab256f29e998e69efaa633a7b60e1db5a867924ccab0a171d9d6e1098dfa15acde9553de599eaa56490c8f411e4985111f3d40bddfc5e301edb01547b01a886550a61158f7e2033c59707789bf7c854181d0c2e2a42a93cf09209747d7082e147eb8544de25c3eb14f2e35559ea0c0f5877f2f3fc92132c0ae9da4e45b2f6c866a224ea6d1f28c05320e287750fbc647368d41116e528014cc1852e5531d53e4af938374daba6cee4baa821ed07117253bb3601ddd00d59a3d7fb2ef1f5a2fbba7c429f0cf9a5b3462410fd833a69118f8be9c559b1000cc608fd877fb43f8e65c2d1302622b944462579056874b387208d90623fcdaf93920ca7a9e4ba64ea208758222ad868501cc2c345e2d3a5ea2a17e5069248138c8a79c0251185d29ee73e5afab5354769142d2bf0cb6712727aa6bf84a6245fcdae66e4938d84d1b9dd09a884818622080ff5f98942fb20acd7e0c916c2d5ea7ce6f7e173315384518f",
            expected: "bed8b970c4a34849fc6926b08e40e20b21c15ed68d18f228904878d4370b56322d0da5789da0318768a374758e6375bfe4641fca5285ec7171828922160f48f5ca7efbfee4d5148612c38ad683ae4e3c3a053d2b7c098cf2b34f2cb19146eadd53c86b2d7ccf3d83b2c370bfb840913ee3879b1057a6b4e07e110b6bcd5e958bc71a14798c91d518cc70abee264b0d25a4110962a764b364ac0b0dd1ee8abc8426d775ec0f22b7e47b32576afaf1b5a48f64573ed1c5c29f50ab412188d9685307323d990802b81dacc06c6e05a1e901830ba9fcc67688dc29c5e27bde0a6e845ca925f5454b6fb3747edfaa2a5820838fb759eadf57f7cb5cec57fc213ddd8a4298fa079c3c0f472b07fb15aa6a7f0a3780bd296ff6a62e58ef443870b02260bd4fd2bbc98255674b8e1f1f9f8d33c7170b0ebbea4523b695911abbf26e41885344823bd0587115fdd83b721a4e8457a31c9a84b3d3520a07e0e35df7f48e5a9d534d0ec7feef1ff74de6a11e7f93eab95175b6ce22c68d78a642ad642837897ec11349205d8593ac19300207572c38d29ca5dfa03bc14cdbc32153c80e5cc3e739403d34c75915e49beb43094cc6dcafb3665b305ddec9286934ae66ec6b777ca528728c851318eb0f207b39f1caaf96db6eeead6b55ed08f451939314577d42bcc9f97c0b52d0234f88fd07e4c1d7780fdebc025cfffcb572cb27a8c33963",
            _name: "nagydani_4_pow0x10001",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000400c5a1611f8be90071a43db23cc2fe01871cc4c0e8ab5743f6378e4fef77f7f6db0095c0727e20225beb665645403453e325ad5f9aeb9ba99bf3c148f63f9c07cf4fe8847ad5242d6b7d4499f93bd47056ddab8f7dee878fc2314f344dbee2a7c41a5d3db91eff372c730c2fdd3a141a4b61999e36d549b9870cf2f4e632c4d5df5f024f81c028000073a0ed8847cfb0593d36a47142f578f05ccbe28c0c06aeb1b1da027794c48db880278f79ba78ae64eedfea3c07d10e0562668d839749dc95f40467d15cf65b9cfc52c7c4bcef1cda3596dd52631aac942f146c7cebd46065131699ce8385b0db1874336747ee020a5698a3d1a1082665721e769567f579830f9d259cec1a836845109c21cf6b25da572512bf3c42fd4b96e43895589042ab60dd41f497db96aec102087fe784165bb45f942859268fd2ff6c012d9d00c02ba83eace047cc5f7b2c392c2955c58a49f0338d6fc58749c9db2155522ac17914ec216ad87f12e0ee95574613942fa615898c4d9e8a3be68cd6afa4e7a003dedbdf8edfee31162b174f965b20ae752ad89c967b3068b6f722c16b354456ba8e280f987c08e0a52d40a2e8f3a59b94d590aeef01879eb7a90b3ee7d772c839c85519cbeaddc0c193ec4874a463b53fcaea3271d80ebfb39b33489365fc039ae549a17a9ff898eea2f4cb27b8dbee4c17b998438575b2b8d107e4a0d66ba7fca85b41a58a8d51f191a35c856dfbe8aef2b00048a694bbccff832d23c8ca7a7ff0b6c0b3011d00b97c86c0628444d267c951d9e4fb8f83e154b8f74fb51aa16535e498235c5597dac9606ed0be3173a3836baa4e7d756ffe1e2879b415d3846bccd538c05b847785699aefde3e305decb600cd8fb0e7d8de5efc26971a6ad4e6d7a2d91474f1023a0ac4b78dc937da0ce607a45974d2cac1c33a2631ff7fe6144a3b2e5cf98b531a9627dea92c1dc82204d09db0439b6a11dd64b484e1263aa45fd9539b6020b55e3baece3986a8bffc1003406348f5c61265099ed43a766ee4f93f5f9c5abbc32a0fd3ac2b35b87f9ec26037d88275bd7dd0a54474995ee34ed3727f3f97c48db544b1980193a4b76a8a3ddab3591ce527f16d91882e67f0103b5cda53f7da54d489fc4ac08b6ab358a5a04aa9daa16219d50bd672a7cb804ed769d218807544e5993f1c27427104b349906a0b654df0bf69328afd3013fbe430155339c39f236df5557bf92f1ded7ff609a8502f49064ec3d1dbfb6c15d3a4c11a4f8acd12278cbf68acd5709463d12e3338a6eddb8c112f199645e23154a8e60879d2a654e3ed9296aa28f134168619691cd2c6b9e2eba4438381676173fc63c2588a3c5910dc149cf3760f0aa9fa9c3f5faa9162b0bf1aac9dd32b706a60ef53cbdb394b6b40222b5bc80eea82ba8958386672564cae3794f977871ab62337cf02e30049201ec12937e7ce79d0f55d9c810e20acf52212aca1d3888949e0e4830aad88d804161230eb89d4d329cc83570fe257217d2119134048dd2ed167646975fc7d77136919a049ea74cf08ddd2b896890bb24a0ba18094a22baa351bf29ad96c66bbb1a598f2ca391749620e62d61c3561a7d3653ccc8892c7b99baaf76bf836e2991cb06d6bc0514568ff0d1ec8bb4b3d6984f5eaefb17d3ea2893722375d3ddb8e389a8eef7d7d198f8e687d6a513983df906099f9a2d23f4f9dec6f8ef2f11fc0a21fac45353b94e00486f5e17d386af42502d09db33cf0cf28310e049c07e88682aeeb00cb833c5174266e62407a57583f1f88b304b7c6e0c84bbe1c0fd423072d37a5bd0aacf764229e5c7cd02473460ba3645cd8e8ae144065bf02d0dd238593d8e230354f67e0b2f23012c23274f80e3ee31e35e2606a4a3f31d94ab755e6d163cff52cbb36b6d0cc67ffc512aeed1dce4d7a0d70ce82f2baba12e8d514dc92a056f994adfb17b5b9712bd5186f27a2fda1f7039c5df2c8587fdc62f5627580c13234b55be4df3056050e2d1ef3218f0dd66cb05265fe1acfb0989d8213f2c19d1735a7cf3fa65d88dad5af52dc2bba22b7abf46c3bc77b5091baab9e8f0ddc4d5e581037de91a9f8dcbc69309be29cc815cf19a20a7585b8b3073edf51fc9baeb3e509b97fa4ecfd621e0fd57bd61cac1b895c03248ff12bdbc57509250df3517e8a3fe1d776836b34ab352b973d932ef708b14f7418f9eceb1d87667e61e3e758649cb083f01b133d37ab2f5afa96d6c84bcacf4efc3851ad308c1e7d9113624fce29fab460ab9d2a48d92cdb281103a5250ad44cb2ff6e67ac670c02fdafb3e0f1353953d6d7d5646ca1568dea55275a050ec501b7c6250444f7219f1ba7521ba3b93d089727ca5f3bbe0d6c1300b423377004954c5628fdb65770b18ced5c9b23a4a5a6d6ef25fe01b4ce278de0bcc4ed86e28a0a68818ffa40970128cf2c38740e80037984428c1bd5113f40ff47512ee6f4e4d8f9b8e8e1b3040d2928d003bd1c1329dc885302fbce9fa81c23b4dc49c7c82d29b52957847898676c89aa5d32b5b0e1c0d5a2b79a19d67562f407f19425687971a957375879d90c5f57c857136c17106c9ab1b99d80e69c8c954ed386493368884b55c939b8d64d26f643e800c56f90c01079d7c534e3b2b7ae352cefd3016da55f6a85eb803b85e2304915fd2001f77c74e28746293c46e4f5f0fd49cf988aafd0026b8e7a3bab2da5cdce1ea26c2e29ec03f4807fac432662b2d6c060be1c7be0e5489de69d0a6e03a4b9117f9244b34a0f1ecba89884f781c6320412413a00c4980287409a2a78c2cd7e65cecebbe4ec1c28cac4dd95f6998e78fc6f1392384331c9436aa10e10e2bf8ad2c4eafbcf276aa7bae64b74428911b3269c749338b0fc5075ad",
            expected: "d61fe4e3f32ac260915b5b03b78a86d11bfc41d973fce5b0cc59035cf8289a8a2e3878ea15fa46565b0d806e2f85b53873ea20ed653869b688adf83f3ef444535bf91598ff7e80f334fb782539b92f39f55310cc4b35349ab7b278346eda9bc37c0d8acd3557fae38197f412f8d9e57ce6a76b7205c23564cab06e5615be7c6f05c3d05ec690cba91da5e89d55b152ff8dd2157dc5458190025cf94b1ad98f7cbe64e9482faba95e6b33844afc640892872b44a9932096508f4a782a4805323808f23e54b6ff9b841dbfa87db3505ae4f687972c18ea0f0d0af89d36c1c2a5b14560c153c3fee406f5cf15cfd1c0bb45d767426d465f2f14c158495069d0c5955a00150707862ecaae30624ebacdd8ac33e4e6aab3ff90b6ba445a84689386b9e945d01823a65874444316e83767290fcff630d2477f49d5d8ffdd200e08ee1274270f86ed14c687895f6caf5ce528bd970c20d2408a9ba66216324c6a011ac4999098362dbd98a038129a2d40c8da6ab88318aa3046cb660327cc44236d9e5d2163bd0959062195c51ed93d0088b6f92051fc99050ece2538749165976233697ab4b610385366e5ce0b02ad6b61c168ecfbedcdf74278a38de340fd7a5fead8e588e294795f9b011e2e60377a89e25c90e145397cdeabc60fd32444a6b7642a611a83c464d8b8976666351b4865c37b02e6dc21dbcdf5f930341707b618cc0f03c3122646b3385c9df9f2ec730eec9d49e7dfc9153b6e6289da8c4f0ebea9ccc1b751948e3bb7171c9e4d57423b0eeeb79095c030cb52677b3f7e0b45c30f645391f3f9c957afa549c4e0b2465b03c67993cd200b1af01035962edbc4c9e89b31c82ac121987d6529dafdeef67a132dc04b6dc68e77f22862040b75e2ceb9ff16da0fca534e6db7bd12fa7b7f51b6c08c1e23dfcdb7acbd2da0b51c87ffbced065a612e9b1c8bba9b7e2d8d7a2f04fcc4aaf355b60d764879a76b5e16762d5f2f55d585d0c8e82df6940960cddfb72c91dfa71f6b4e1c6ca25dfc39a878e998a663c04fe29d5e83b9586d047b4d7ff70a9f0d44f127e7d741685ca75f11629128d916a0ffef4be586a30c4b70389cc746e84ebf177c01ee8a4511cfbb9d1ecf7f7b33c7dd8177896e10bbc82f838dcd6db7ac67de62bf46b6a640fb580c5d1d2708f3862e3d2b645d0d18e49ef088053e3a220adc0e033c2afcfe61c90e32151152eb3caaf746c5e377d541cafc6cbb0cc0fa48b5caf1728f2e1957f5addfc234f1a9d89e40d49356c9172d0561a695fce6dab1d412321bbf407f63766ffd7b6b3d79bcfa07991c5a9709849c1008689e3b47c50d613980bec239fb64185249d055b30375ccb4354d71fe4d05648fbf6c80634dfc3575f2f24abb714c1e4c95e8896763bf4316e954c7ad19e5780ab7a040ca6fb9271f90a8b22ae738daf6cb",
            _name: "nagydani_5_square",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000400c5a1611f8be90071a43db23cc2fe01871cc4c0e8ab5743f6378e4fef77f7f6db0095c0727e20225beb665645403453e325ad5f9aeb9ba99bf3c148f63f9c07cf4fe8847ad5242d6b7d4499f93bd47056ddab8f7dee878fc2314f344dbee2a7c41a5d3db91eff372c730c2fdd3a141a4b61999e36d549b9870cf2f4e632c4d5df5f024f81c028000073a0ed8847cfb0593d36a47142f578f05ccbe28c0c06aeb1b1da027794c48db880278f79ba78ae64eedfea3c07d10e0562668d839749dc95f40467d15cf65b9cfc52c7c4bcef1cda3596dd52631aac942f146c7cebd46065131699ce8385b0db1874336747ee020a5698a3d1a1082665721e769567f579830f9d259cec1a836845109c21cf6b25da572512bf3c42fd4b96e43895589042ab60dd41f497db96aec102087fe784165bb45f942859268fd2ff6c012d9d00c02ba83eace047cc5f7b2c392c2955c58a49f0338d6fc58749c9db2155522ac17914ec216ad87f12e0ee95574613942fa615898c4d9e8a3be68cd6afa4e7a003dedbdf8edfee31162b174f965b20ae752ad89c967b3068b6f722c16b354456ba8e280f987c08e0a52d40a2e8f3a59b94d590aeef01879eb7a90b3ee7d772c839c85519cbeaddc0c193ec4874a463b53fcaea3271d80ebfb39b33489365fc039ae549a17a9ff898eea2f4cb27b8dbee4c17b998438575b2b8d107e4a0d66ba7fca85b41a58a8d51f191a35c856dfbe8aef2b00048a694bbccff832d23c8ca7a7ff0b6c0b3011d00b97c86c0628444d267c951d9e4fb8f83e154b8f74fb51aa16535e498235c5597dac9606ed0be3173a3836baa4e7d756ffe1e2879b415d3846bccd538c05b847785699aefde3e305decb600cd8fb0e7d8de5efc26971a6ad4e6d7a2d91474f1023a0ac4b78dc937da0ce607a45974d2cac1c33a2631ff7fe6144a3b2e5cf98b531a9627dea92c1dc82204d09db0439b6a11dd64b484e1263aa45fd9539b6020b55e3baece3986a8bffc1003406348f5c61265099ed43a766ee4f93f5f9c5abbc32a0fd3ac2b35b87f9ec26037d88275bd7dd0a54474995ee34ed3727f3f97c48db544b1980193a4b76a8a3ddab3591ce527f16d91882e67f0103b5cda53f7da54d489fc4ac08b6ab358a5a04aa9daa16219d50bd672a7cb804ed769d218807544e5993f1c27427104b349906a0b654df0bf69328afd3013fbe430155339c39f236df5557bf92f1ded7ff609a8502f49064ec3d1dbfb6c15d3a4c11a4f8acd12278cbf68acd5709463d12e3338a6eddb8c112f199645e23154a8e60879d2a654e3ed9296aa28f134168619691cd2c6b9e2eba4438381676173fc63c2588a3c5910dc149cf3760f0aa9fa9c3f5faa9162b0bf1aac9dd32b706a60ef53cbdb394b6b40222b5bc80eea82ba8958386672564cae3794f977871ab62337cf03e30049201ec12937e7ce79d0f55d9c810e20acf52212aca1d3888949e0e4830aad88d804161230eb89d4d329cc83570fe257217d2119134048dd2ed167646975fc7d77136919a049ea74cf08ddd2b896890bb24a0ba18094a22baa351bf29ad96c66bbb1a598f2ca391749620e62d61c3561a7d3653ccc8892c7b99baaf76bf836e2991cb06d6bc0514568ff0d1ec8bb4b3d6984f5eaefb17d3ea2893722375d3ddb8e389a8eef7d7d198f8e687d6a513983df906099f9a2d23f4f9dec6f8ef2f11fc0a21fac45353b94e00486f5e17d386af42502d09db33cf0cf28310e049c07e88682aeeb00cb833c5174266e62407a57583f1f88b304b7c6e0c84bbe1c0fd423072d37a5bd0aacf764229e5c7cd02473460ba3645cd8e8ae144065bf02d0dd238593d8e230354f67e0b2f23012c23274f80e3ee31e35e2606a4a3f31d94ab755e6d163cff52cbb36b6d0cc67ffc512aeed1dce4d7a0d70ce82f2baba12e8d514dc92a056f994adfb17b5b9712bd5186f27a2fda1f7039c5df2c8587fdc62f5627580c13234b55be4df3056050e2d1ef3218f0dd66cb05265fe1acfb0989d8213f2c19d1735a7cf3fa65d88dad5af52dc2bba22b7abf46c3bc77b5091baab9e8f0ddc4d5e581037de91a9f8dcbc69309be29cc815cf19a20a7585b8b3073edf51fc9baeb3e509b97fa4ecfd621e0fd57bd61cac1b895c03248ff12bdbc57509250df3517e8a3fe1d776836b34ab352b973d932ef708b14f7418f9eceb1d87667e61e3e758649cb083f01b133d37ab2f5afa96d6c84bcacf4efc3851ad308c1e7d9113624fce29fab460ab9d2a48d92cdb281103a5250ad44cb2ff6e67ac670c02fdafb3e0f1353953d6d7d5646ca1568dea55275a050ec501b7c6250444f7219f1ba7521ba3b93d089727ca5f3bbe0d6c1300b423377004954c5628fdb65770b18ced5c9b23a4a5a6d6ef25fe01b4ce278de0bcc4ed86e28a0a68818ffa40970128cf2c38740e80037984428c1bd5113f40ff47512ee6f4e4d8f9b8e8e1b3040d2928d003bd1c1329dc885302fbce9fa81c23b4dc49c7c82d29b52957847898676c89aa5d32b5b0e1c0d5a2b79a19d67562f407f19425687971a957375879d90c5f57c857136c17106c9ab1b99d80e69c8c954ed386493368884b55c939b8d64d26f643e800c56f90c01079d7c534e3b2b7ae352cefd3016da55f6a85eb803b85e2304915fd2001f77c74e28746293c46e4f5f0fd49cf988aafd0026b8e7a3bab2da5cdce1ea26c2e29ec03f4807fac432662b2d6c060be1c7be0e5489de69d0a6e03a4b9117f9244b34a0f1ecba89884f781c6320412413a00c4980287409a2a78c2cd7e65cecebbe4ec1c28cac4dd95f6998e78fc6f1392384331c9436aa10e10e2bf8ad2c4eafbcf276aa7bae64b74428911b3269c749338b0fc5075ad",
            expected: "5f9c70ec884926a89461056ad20ac4c30155e817f807e4d3f5bb743d789c83386762435c3627773fa77da5144451f2a8aad8adba88e0b669f5377c5e9bad70e45c86fe952b613f015a9953b8a5de5eaee4566acf98d41e327d93a35bd5cef4607d025e58951167957df4ff9b1627649d3943805472e5e293d3efb687cfd1e503faafeb2840a3e3b3f85d016051a58e1c9498aab72e63b748d834b31eb05d85dcde65e27834e266b85c75cc4ec0135135e0601cb93eeeb6e0010c8ceb65c4c319623c5e573a2c8c9fbbf7df68a930beb412d3f4dfd146175484f45d7afaa0d2e60684af9b34730f7c8438465ad3e1d0c3237336722f2aa51095bd5759f4b8ab4dda111b684aa3dac62a761722e7ae43495b7709933512c81c4e3c9133a51f7ce9f2b51fcec064f65779666960b4e45df3900f54311f5613e8012dd1b8efd359eda31a778264c72aa8bb419d862734d769076bce2810011989a45374e5c5d8729fec21427f0bf397eacbb4220f603cf463a4b0c94efd858ffd9768cd60d6ce68d755e0fbad007ce5c2223d70c7018345a102e4ab3c60a13a9e7794303156d4c2063e919f2153c13961fb324c80b240742f47773a7a8e25b3e3fb19b00ce839346c6eb3c732fbc6b888df0b1fe0a3d07b053a2e9402c267b2d62f794d8a2840526e3ade15ce2264496ccd7519571dfde47f7a4bb16292241c20b2be59f3f8fb4f6383f232d838c5a22d8c95b6834d9d2ca493f5a505ebe8899503b0e8f9b19e6e2dd81c1628b80016d02097e0134de51054c4e7674824d4d758760fc52377d2cad145e259aa2ffaf54139e1a66b1e0c1c191e32ac59474c6b526f5b3ba07d3e5ec286eddf531fcd5292869be58c9f22ef91026159f7cf9d05ef66b4299f4da48cc1635bf2243051d342d378a22c83390553e873713c0454ce5f3234397111ac3fe3207b86f0ed9fc025c81903e1748103692074f83824fda6341be4f95ff00b0a9a208c267e12fa01825054cc0513629bf3dbb56dc5b90d4316f87654a8be18227978ea0a8a522760cad620d0d14fd38920fb7321314062914275a5f99f677145a6979b156bd82ecd36f23f8e1273cc2759ecc0b2c69d94dad5211d1bed939dd87ed9e07b91d49713a6e16ade0a98aea789f04994e318e4ff2c8a188cd8d43aeb52c6daa3bc29b4af50ea82a247c5cd67b573b34cbadcc0a376d3bbd530d50367b42705d870f2e27a8197ef46070528bfe408360faa2ebb8bf76e9f388572842bcb119f4d84ee34ae31f5cc594f23705a49197b181fb78ed1ec99499c690f843a4d0cf2e226d118e9372271054fbabdcc5c92ae9fefaef0589cd0e722eaf30c1703ec4289c7fd81beaa8a455ccee5298e31e2080c10c366a6fcf56f7d13582ad0bcad037c612b710fc595b70fbefaaca23623b60c6c39b11beb8e5843b6b3dac60f",
            _name: "nagydani_5_qube",
        },
        ModexpTestCase {
            input: "000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000400c5a1611f8be90071a43db23cc2fe01871cc4c0e8ab5743f6378e4fef77f7f6db0095c0727e20225beb665645403453e325ad5f9aeb9ba99bf3c148f63f9c07cf4fe8847ad5242d6b7d4499f93bd47056ddab8f7dee878fc2314f344dbee2a7c41a5d3db91eff372c730c2fdd3a141a4b61999e36d549b9870cf2f4e632c4d5df5f024f81c028000073a0ed8847cfb0593d36a47142f578f05ccbe28c0c06aeb1b1da027794c48db880278f79ba78ae64eedfea3c07d10e0562668d839749dc95f40467d15cf65b9cfc52c7c4bcef1cda3596dd52631aac942f146c7cebd46065131699ce8385b0db1874336747ee020a5698a3d1a1082665721e769567f579830f9d259cec1a836845109c21cf6b25da572512bf3c42fd4b96e43895589042ab60dd41f497db96aec102087fe784165bb45f942859268fd2ff6c012d9d00c02ba83eace047cc5f7b2c392c2955c58a49f0338d6fc58749c9db2155522ac17914ec216ad87f12e0ee95574613942fa615898c4d9e8a3be68cd6afa4e7a003dedbdf8edfee31162b174f965b20ae752ad89c967b3068b6f722c16b354456ba8e280f987c08e0a52d40a2e8f3a59b94d590aeef01879eb7a90b3ee7d772c839c85519cbeaddc0c193ec4874a463b53fcaea3271d80ebfb39b33489365fc039ae549a17a9ff898eea2f4cb27b8dbee4c17b998438575b2b8d107e4a0d66ba7fca85b41a58a8d51f191a35c856dfbe8aef2b00048a694bbccff832d23c8ca7a7ff0b6c0b3011d00b97c86c0628444d267c951d9e4fb8f83e154b8f74fb51aa16535e498235c5597dac9606ed0be3173a3836baa4e7d756ffe1e2879b415d3846bccd538c05b847785699aefde3e305decb600cd8fb0e7d8de5efc26971a6ad4e6d7a2d91474f1023a0ac4b78dc937da0ce607a45974d2cac1c33a2631ff7fe6144a3b2e5cf98b531a9627dea92c1dc82204d09db0439b6a11dd64b484e1263aa45fd9539b6020b55e3baece3986a8bffc1003406348f5c61265099ed43a766ee4f93f5f9c5abbc32a0fd3ac2b35b87f9ec26037d88275bd7dd0a54474995ee34ed3727f3f97c48db544b1980193a4b76a8a3ddab3591ce527f16d91882e67f0103b5cda53f7da54d489fc4ac08b6ab358a5a04aa9daa16219d50bd672a7cb804ed769d218807544e5993f1c27427104b349906a0b654df0bf69328afd3013fbe430155339c39f236df5557bf92f1ded7ff609a8502f49064ec3d1dbfb6c15d3a4c11a4f8acd12278cbf68acd5709463d12e3338a6eddb8c112f199645e23154a8e60879d2a654e3ed9296aa28f134168619691cd2c6b9e2eba4438381676173fc63c2588a3c5910dc149cf3760f0aa9fa9c3f5faa9162b0bf1aac9dd32b706a60ef53cbdb394b6b40222b5bc80eea82ba8958386672564cae3794f977871ab62337cf010001e30049201ec12937e7ce79d0f55d9c810e20acf52212aca1d3888949e0e4830aad88d804161230eb89d4d329cc83570fe257217d2119134048dd2ed167646975fc7d77136919a049ea74cf08ddd2b896890bb24a0ba18094a22baa351bf29ad96c66bbb1a598f2ca391749620e62d61c3561a7d3653ccc8892c7b99baaf76bf836e2991cb06d6bc0514568ff0d1ec8bb4b3d6984f5eaefb17d3ea2893722375d3ddb8e389a8eef7d7d198f8e687d6a513983df906099f9a2d23f4f9dec6f8ef2f11fc0a21fac45353b94e00486f5e17d386af42502d09db33cf0cf28310e049c07e88682aeeb00cb833c5174266e62407a57583f1f88b304b7c6e0c84bbe1c0fd423072d37a5bd0aacf764229e5c7cd02473460ba3645cd8e8ae144065bf02d0dd238593d8e230354f67e0b2f23012c23274f80e3ee31e35e2606a4a3f31d94ab755e6d163cff52cbb36b6d0cc67ffc512aeed1dce4d7a0d70ce82f2baba12e8d514dc92a056f994adfb17b5b9712bd5186f27a2fda1f7039c5df2c8587fdc62f5627580c13234b55be4df3056050e2d1ef3218f0dd66cb05265fe1acfb0989d8213f2c19d1735a7cf3fa65d88dad5af52dc2bba22b7abf46c3bc77b5091baab9e8f0ddc4d5e581037de91a9f8dcbc69309be29cc815cf19a20a7585b8b3073edf51fc9baeb3e509b97fa4ecfd621e0fd57bd61cac1b895c03248ff12bdbc57509250df3517e8a3fe1d776836b34ab352b973d932ef708b14f7418f9eceb1d87667e61e3e758649cb083f01b133d37ab2f5afa96d6c84bcacf4efc3851ad308c1e7d9113624fce29fab460ab9d2a48d92cdb281103a5250ad44cb2ff6e67ac670c02fdafb3e0f1353953d6d7d5646ca1568dea55275a050ec501b7c6250444f7219f1ba7521ba3b93d089727ca5f3bbe0d6c1300b423377004954c5628fdb65770b18ced5c9b23a4a5a6d6ef25fe01b4ce278de0bcc4ed86e28a0a68818ffa40970128cf2c38740e80037984428c1bd5113f40ff47512ee6f4e4d8f9b8e8e1b3040d2928d003bd1c1329dc885302fbce9fa81c23b4dc49c7c82d29b52957847898676c89aa5d32b5b0e1c0d5a2b79a19d67562f407f19425687971a957375879d90c5f57c857136c17106c9ab1b99d80e69c8c954ed386493368884b55c939b8d64d26f643e800c56f90c01079d7c534e3b2b7ae352cefd3016da55f6a85eb803b85e2304915fd2001f77c74e28746293c46e4f5f0fd49cf988aafd0026b8e7a3bab2da5cdce1ea26c2e29ec03f4807fac432662b2d6c060be1c7be0e5489de69d0a6e03a4b9117f9244b34a0f1ecba89884f781c6320412413a00c4980287409a2a78c2cd7e65cecebbe4ec1c28cac4dd95f6998e78fc6f1392384331c9436aa10e10e2bf8ad2c4eafbcf276aa7bae64b74428911b3269c749338b0fc5075ad",
            expected: "5a0eb2bdf0ac1cae8e586689fa16cd4b07dfdedaec8a110ea1fdb059dd5253231b6132987598dfc6e11f86780428982d50cf68f67ae452622c3b336b537ef3298ca645e8f89ee39a26758206a5a3f6409afc709582f95274b57b71fae5c6b74619ae6f089a5393c5b79235d9caf699d23d88fb873f78379690ad8405e34c19f5257d596580c7a6a7206a3712825afe630c76b31cdb4a23e7f0632e10f14f4e282c81a66451a26f8df2a352b5b9f607a7198449d1b926e27036810368e691a74b91c61afa73d9d3b99453e7c8b50fd4f09c039a2f2feb5c419206694c31b92df1d9586140cb3417b38d0c503c7b508cc2ed12e813a1c795e9829eb39ee78eeaf360a169b491a1d4e419574e712402de9d48d54c1ae5e03739b7156615e8267e1fb0a897f067afd11fb33f6e24182d7aaaaa18fe5bc1982f20d6b871e5a398f0f6f718181d31ec225cfa9a0a70124ed9a70031bdf0c1c7829f708b6e17d50419ef361cf77d99c85f44607186c8d683106b8bd38a49b5d0fb503b397a83388c5678dcfcc737499d84512690701ed621a6f0172aecf037184ddf0f2453e4053024018e5ab2e30d6d5363b56e8b41509317c99042f517247474ab3abc848e00a07f69c254f46f2a05cf6ed84e5cc906a518fdcfdf2c61ce731f24c5264f1a25fc04934dc28aec112134dd523f70115074ca34e3807aa4cb925147f3a0ce152d323bd8c675ace446d0fd1ae30c4b57f0eb2c23884bc18f0964c0114796c5b6d080c3d89175665fbf63a6381a6a9da39ad070b645c8bb1779506da14439a9f5b5d481954764ea114fac688930bc68534d403cff4210673b6a6ff7ae416b7cd41404c3d3f282fcd193b86d0f54d0006c2a503b40d5c3930da980565b8f9630e9493a79d1c03e74e5f93ac8e4dc1a901ec5e3b3e57049124c7b72ea345aa359e782285d9e6a5c144a378111dd02c40855ff9c2be9b48425cb0b2fd62dc8678fd151121cf26a65e917d65d8e0dacfae108eb5508b601fb8ffa370be1f9a8b749a2d12eeab81f41079de87e2d777994fa4d28188c579ad327f9957fb7bdecec5c680844dd43cb57cf87aeb763c003e65011f73f8c63442df39a92b946a6bd968a1c1e4d5fa7d88476a68bd8e20e5b70a99259c7d3f85fb1b65cd2e93972e6264e74ebf289b8b6979b9b68a85cd5b360c1987f87235c3c845d62489e33acf85d53fa3561fe3a3aee18924588d9c6eba4edb7a4d106b31173e42929f6f0c48c80ce6a72d54eca7c0fe870068b7a7c89c63cdda593f5b32d3cb4ea8a32c39f00ab449155757172d66763ed9527019d6de6c9f2416aa6203f4d11c9ebee1e1d3845099e55504446448027212616167eb36035726daa7698b075286f5379cd3e93cb3e0cf4f9cb8d017facbb5550ed32d5ec5400ae57e47e2bf78d1eaeff9480cc765ceff39db500",
            _name: "nagydani_5_pow0x10001",
        }
    ];

    #[test]
    fn test_modexp_inputs() {
        for test in MODEXP_TESTS.iter() {
            let input = hex::decode(test.input).unwrap();

            let result = execute_precompiled(
                H160::from_low_u64_be(5),
                &input,
                None,
                Some(100_000_000),
            );

            assert!(result.is_ok());
            let outcome = result.unwrap();
            assert!(outcome.is_success);
            assert_eq!(hex::encode(outcome.result.unwrap()), test.expected,);
        }
    }

    #[test]
    fn test_modexp_empty_input() {
        let result =
            execute_precompiled(H160::from_low_u64_be(5), &[], None, Some(100_000));

        assert!(result.is_ok());
        let outcome = result.unwrap();
        assert!(outcome.is_success);

        assert_eq!("", hex::encode(outcome.result.unwrap()));
    }
}
