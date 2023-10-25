// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

use crate::inbox::Transaction;

/// Tick model constants
///
/// Some of the following values were estimated using benchmarking, and should
/// be updated only when the benchmarks are executed.
/// This doesn't apply to inherited constants from the PVM, e.g. maximum
/// number of reboots.
pub mod constants {

    /// Maximum number of ticks for a kernel run as set by the PVM
    pub(crate) const MAX_TICKS: u64 = 11_000_000_000;

    /// Maximum number of allowed ticks for a kernel run. We consider a safety
    /// margin and an incompressible initilisation overhead.
    pub const MAX_ALLOWED_TICKS: u64 =
        MAX_TICKS - SAFETY_MARGIN - INITIALISATION_OVERHEAD;

    /// Maximum number of reboots for a level as set by the PVM.
    pub(crate) const _MAX_NUMBER_OF_REBOOTS: u32 = 1_000;

    /// Overapproximation of the amount of ticks for a deposit.
    pub const TICKS_FOR_DEPOSIT: u64 = TICKS_FOR_CRYPTO;

    /// Overapproximation of the amount of ticks per gas unit.
    pub const TICKS_PER_GAS: u64 = 2000;

    // Overapproximation of ticks used in signature verification.
    pub const TICKS_FOR_CRYPTO: u64 = 25_000_000;

    /// Overapproximation of the ticks used by the kernel to process a transaction
    /// before checking or execution.
    pub const TRANSACTION_OVERHEAD: u64 = 1_000_000;

    /// Safety margin the kernel enforce to avoid approaching the maximum number
    /// of ticks.
    pub const SAFETY_MARGIN: u64 = 2_000_000_000;

    /// Overapproximation of the number of ticks the kernel uses to initialise and
    /// reload its state
    pub const INITIALISATION_OVERHEAD: u64 = 1_000_000_000;

    /// The minimum amount of gas for an ethereum transaction.
    pub const BASE_GAS: u64 = crate::CONFIG.gas_transaction_call;

    /// The maximum gas limit allowed for a transaction. We need to set a limit
    /// on the gas so we can consider the transaction in a reboot. If we don't
    /// set a limit, we could reboot again and again until the transaction
    /// fits in a reboot, which will never happen.
    pub const MAX_TRANSACTION_GAS_LIMIT: u64 = MAX_ALLOWED_TICKS / TICKS_PER_GAS;
}

pub fn estimate_ticks_for_transaction(transaction: &Transaction) -> u64 {
    match &transaction.content {
        crate::inbox::TransactionContent::Deposit(_) => {
            ticks_of_deposit(constants::TICKS_FOR_DEPOSIT)
        }
        crate::inbox::TransactionContent::Ethereum(eth) => {
            average_ticks_of_gas(eth.gas_limit)
        }
    }
}

pub fn estimate_remaining_ticks_for_transaction_execution(ticks: u64) -> u64 {
    constants::MAX_ALLOWED_TICKS
        .saturating_sub(constants::TRANSACTION_OVERHEAD)
        .saturating_sub(ticks)
}

fn ticks_of_deposit(resulting_ticks: u64) -> u64 {
    resulting_ticks.saturating_add(constants::TRANSACTION_OVERHEAD)
}

pub fn average_ticks_of_gas(gas: u64) -> u64 {
    gas.saturating_mul(constants::TICKS_PER_GAS)
        .saturating_add(constants::TRANSACTION_OVERHEAD)
}

/// Check that a transaction can fit inside the tick limit
pub fn estimate_would_overflow(estimated_ticks: u64, transaction: &Transaction) -> bool {
    estimate_ticks_for_transaction(transaction).saturating_add(estimated_ticks)
        > constants::MAX_ALLOWED_TICKS
}

/// An invalid transaction could not be transmitted to the VM, eg. the nonce
/// was wrong, or the signature verification failed.
pub fn ticks_of_invalid_transaction() -> u64 {
    // If the transaction is invalid, only the base cost is considered.
    constants::BASE_GAS
        .saturating_mul(constants::TICKS_PER_GAS)
        .saturating_add(constants::TRANSACTION_OVERHEAD)
}

/// Adds the possible overhead this is not accounted during the validation of
/// the transaction. Transaction evaluation (the interpreter) accounts for the
/// ticks itself.
pub fn ticks_of_valid_transaction(
    transaction: &Transaction,
    resulting_ticks: u64,
) -> u64 {
    match &transaction.content {
        crate::inbox::TransactionContent::Ethereum(_) => {
            ticks_of_valid_transaction_ethereum(resulting_ticks)
        }
        // Ticks are already spent during the validation of the transaction (see
        // apply.rs).
        crate::inbox::TransactionContent::Deposit(_) => ticks_of_deposit(resulting_ticks),
    }
}

/// A valid transaction is a transaction that could be transmitted to
/// evm_execution. It can succeed (with or without effect on the state)
/// or fail (if the VM encountered an error).
pub fn ticks_of_valid_transaction_ethereum(resulting_ticks: u64) -> u64 {
    resulting_ticks
        .saturating_add(constants::TICKS_FOR_CRYPTO)
        .saturating_add(constants::TRANSACTION_OVERHEAD)
}
