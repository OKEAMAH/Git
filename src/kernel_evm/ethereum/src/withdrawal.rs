// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Withdrawals to layer 1 from the EVM kernel

use primitive_types::U256;
use tezos_data_encoding::nom::NomReader;
use tezos_smart_rollup_encoding::contract::Contract;

/// A single withdrawal from the rollup to an account on layer one.
#[derive(Debug, Eq, PartialEq)]
pub struct Withdrawal {
    /// The target address on layer one.
    pub target: Contract,
    /// The amount in wei we wish to transfer. This has to be
    /// translated into CTEZ or whatever currency is used for
    /// paying for L2XTZ.
    pub amount: U256,
}

impl Withdrawal {
    /// De-serialize a contract address from bytes (binary format).
    pub fn address_from_bytes(bytes: &[u8]) -> Option<Contract> {
        Some(Contract::nom_read(bytes).ok()?.1)
    }

    /// De-serialize a contract address from string given as bytes
    /// (use case). The bytes present the address in textual format.
    pub fn address_from_str(s: &str) -> Option<Contract> {
        Contract::from_b58check(s).ok()
    }

    /// Check if `self` withdrawal can be merged with some other withdrawal.
    /// This is the case iff they target the same layer one address, _and_
    /// there is no amount overflow. In case merging succeeds, the `self`
    /// withdrawal is updated to reflect the merge, while the other withdrawal
    /// should be discarded.
    #[allow(dead_code)]
    pub fn merge(&mut self, other: &Self) -> bool {
        if other.target == self.target {
            if let Some(new_amount) = self.amount.checked_add(other.amount) {
                self.amount = new_amount;
                true
            } else {
                false
            }
        } else {
            false
        }
    }
}

mod test {
    /*
    fn merge_same_target_succeeds() {
        todo!()
    }

    fn merge_different_target_fails() {
        todo!()
    }

    fn merge_fails_for_amount_overflow() {
        todo!()
    }
    */
}
