// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Adjustments & calculation of fees, over-and-above the execution gas fee.
//!
//! Users submit transactions which contain three values related to fees:
//! - `gas_limit`
//! - `max_fee_per_gas`
//! - `max_priority_fee_per_gas`
//!
//! We ignore `tx.max_priority_fee_per_gas` completely. For every transaction, we act as if the
//! user set `tx.max_priority_fee_per_gas = 0`. We therefore only care about `tx.gas_limit` and
//! `tx.max_fee_per_gas`.

use evm_execution::account_storage::{account_path, EthereumAccountStorage};
use evm_execution::handler::ExecutionOutcome;
use primitive_types::{H160, U256};
use tezos_ethereum::block::BlockFees;
use tezos_ethereum::tx_common::EthereumTransactionCommon;
use tezos_smart_rollup_host::runtime::Runtime;

        use tezos_evm_logging::{log, Level::*};

/// Instructions for 'balancing the books'.
#[derive(Debug)]
pub struct FeeUpdates {
    pub overall_gas_price: U256,
    pub overall_gas_used: U256,
    pub burn_amount: U256,
    pub charge_user_amount: U256,
    pub compensate_sequencer_amount: U256,
}

impl FeeUpdates {
    ///
    pub fn for_deposit(gas_used: U256) -> Self {
        Self {
            overall_gas_used: gas_used,
            overall_gas_price: U256::zero(),
            burn_amount: U256::zero(),
            charge_user_amount: U256::zero(),
            compensate_sequencer_amount: U256::zero(),
        }
    }

    /// Returns fee updates of the transaction.
    ///
    /// *NB* this is not the gas price used _for execution_, but rather the gas price that
    /// should be reported in the transaction receipt.
    ///
    /// # Prerequisites
    /// The user must have already paid for 'execution gas fees'.
    pub fn for_tx(
        host: &impl Runtime,
        tx: &EthereumTransactionCommon,
        block_fees: &BlockFees,
        execution_gas_used: U256,
    ) -> Self {
        let execution_gas_fees = execution_gas_used * block_fees.base_fee_per_gas();
        let initial_added_fees = block_fees.flat_fee();
        let initial_total_fees = initial_added_fees + execution_gas_fees;

        log!(host, Debug, "tx: {tx:?}");
        log!(host, Debug, "block_fees: {block_fees:?}");
        log!(host, Debug, "egf: {execution_gas_fees} iaf: {initial_added_fees}, itf: {initial_total_fees}");

        // first, we find the price of gas (with all fees), for the given gas used
        let mut gas_price = match initial_added_fees.div_mod(execution_gas_used) {
            (price, rem) if rem.is_zero() => price + block_fees.base_fee_per_gas(),
            (price, _) => price + block_fees.base_fee_per_gas() + 1,
        };

        let gas_used = if gas_price > tx.max_fee_per_gas {
            // We can't charge more than `max_fee_per_gas`, so bump the gas limit too.
            // added_gas = initial_total_fee / mgp - execution_gas
            gas_price = tx.max_fee_per_gas;
            match initial_total_fees.div_mod(gas_price) {
                (total, rem) if rem.is_zero() => total,
                (total, _) => total + 1,
            }
        } else {
            execution_gas_used
        };

        let total_fees = gas_price * gas_used;
        log!(host, Debug, "total_fees {total_fees} | execution_gas_used {execution_gas_used}");

        // Due to rounding, we may have a small amount of unaccounted-for gas.
        // Assign this to the flat fee (to be burned).
        let flat_fee = block_fees.flat_fee() + total_fees - initial_total_fees;
        let sequencer_compensation = total_fees - flat_fee;

        let fees = FeeUpdates {
            overall_gas_price: gas_price,
            overall_gas_used: gas_used,
            burn_amount: flat_fee,
            charge_user_amount: total_fees - execution_gas_fees,
            compensate_sequencer_amount: sequencer_compensation,
        };

        fees
    }

    pub fn modify_outcome(&self, outcome: &mut ExecutionOutcome) {
        outcome.gas_used = self.overall_gas_used.as_u64();
    }

    pub fn apply(
        &self,
        host: &mut impl Runtime,
        accounts: &mut EthereumAccountStorage,
        caller: H160,
    ) -> Result<(), anyhow::Error> {

        log!(host, Debug, "fees: {self:#?}");

        let caller_account_path = account_path(&caller)?;
        let mut caller_account = accounts.get_or_create(host, &caller_account_path)?;
        if !caller_account.balance_remove(host, self.charge_user_amount)? {
            return Err(anyhow::anyhow!(
                "Failed to charge {caller} additional fees of {}",
                self.charge_user_amount
            ));
        }

        Ok(())
    }
}
