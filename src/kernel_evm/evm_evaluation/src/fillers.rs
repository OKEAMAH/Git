// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::evalhost::EvalHost;
use crate::helpers::{parse_and_get_cmp, purify_network};
use crate::models::spec::SpecId;
use crate::models::{
    AccountInfoFiller, FillerResultIndexes, FillerSource, IndexKind, Info, SpecName,
};
use crate::ReportValue;

use evm_execution::account_storage::EthereumAccount;

use bytes::Bytes;
use primitive_types::{H160, H256, U256};
use std::collections::HashMap;
use std::fs::File;
use std::io::Write;
use std::str::FromStr;

fn check_filler_contraints(
    indexes: &FillerResultIndexes,
    info: &Info,
    tx_index: i64,
) -> bool {
    // A transaction matches the constraints if:
    // - there are no constraints
    // - OR, if it has a label, it matches one of the label of the test
    // - OR, its index is the range of those identified

    if indexes.data.is_empty() {
        return true;
    }

    let tx_label = info.labels.get(&tx_index.try_into().unwrap());

    for index_kind in indexes.to_owned().data.into_iter() {
        match index_kind {
            IndexKind::Label(label) => match tx_label {
                Some(tx_label) => {
                    if tx_label.eq(&label) {
                        return true;
                    }
                }
                None => (),
            },
            IndexKind::Range(start, end) => {
                if start <= tx_index && tx_index <= end {
                    return true;
                }
            }
        }
    }
    // at this point, no the constraint have been matched
    return false;
}

fn check_should_not_exist(
    host: &mut EvalHost,
    account: &EthereumAccount,
    invalid_state: &mut bool,
    shouldnotexist: &Option<String>,
    hex_address: &str,
) {
    if let Some(_shouldnotexist) = shouldnotexist {
        if account.balance(host).is_ok() {
            writeln!(
                host.buffer.borrow_mut(),
                "Account {} should not exist.",
                hex_address
            )
            .unwrap();
            *invalid_state = true;
        } else {
            writeln!(
                host.buffer.borrow_mut(),
                "Account {} rightfully do not exist.",
                hex_address
            )
            .unwrap();
        }
    }
}

fn check_balance(
    host: &mut EvalHost,
    account: &EthereumAccount,
    invalid_state: &mut bool,
    balance: &Option<U256>,
    hex_address: &str,
) {
    if let Some(balance) = balance {
        match account.balance(host) {
            Ok(current_balance) => {
                if current_balance != *balance {
                    *invalid_state = true;
                    writeln!( host.buffer.borrow_mut(), "Account {}: balance don't match current one, {} was expected, but got {}.", hex_address, balance, current_balance).unwrap();
                } else {
                    writeln!(
                        host.buffer.borrow_mut(),
                        "Account {}: balance matched.",
                        hex_address
                    )
                    .unwrap();
                }
            }
            Err(_) => {
                *invalid_state = true;
                writeln!(
                    host.buffer.borrow_mut(),
                    "Account {} should have a balance.",
                    hex_address
                )
                .unwrap();
            }
        }
    }
}

fn check_code(
    host: &mut EvalHost,
    account: &EthereumAccount,
    invalid_state: &mut bool,
    code: &Option<Bytes>,
    hex_address: &str,
) {
    if let Some(code) = &code {
        match account.code(host) {
            Ok(current_code) => {
                let current_code: Bytes = current_code.into();
                if current_code != code {
                    *invalid_state = true;
                    writeln!( host.buffer.borrow_mut(), "Account {}: code don't match current one, {:?} was expected, but got {:?}.", hex_address, code, current_code).unwrap();
                } else {
                    writeln!(
                        host.buffer.borrow_mut(),
                        "Account {}: code matched.",
                        hex_address
                    )
                    .unwrap();
                }
            }
            Err(_) => {
                *invalid_state = true;
                writeln!(
                    host.buffer.borrow_mut(),
                    "Account {} should have a code.",
                    hex_address
                )
                .unwrap();
            }
        }
    }
}

fn check_nonce(
    host: &mut EvalHost,
    account: &EthereumAccount,
    invalid_state: &mut bool,
    nonce: &Option<u64>,
    hex_address: &str,
) {
    if let Some(nonce) = nonce {
        match account.nonce(host) {
            Ok(current_nonce) => {
                if current_nonce != (*nonce).into() {
                    *invalid_state = true;
                    writeln!( host.buffer.borrow_mut(), "Account {}: nonce don't match current one, {} was expected, but got {}.", hex_address, nonce, current_nonce).unwrap();
                } else {
                    writeln!(
                        host.buffer.borrow_mut(),
                        "Account {}: nonce matched.",
                        hex_address
                    )
                    .unwrap();
                }
            }
            Err(_) => {
                *invalid_state = true;
                writeln!(
                    host.buffer.borrow_mut(),
                    "Account {} should have a nonce.",
                    hex_address
                )
                .unwrap();
            }
        }
    }
}

fn check_storage(
    host: &mut EvalHost,
    account: &EthereumAccount,
    invalid_state: &mut bool,
    storage: &Option<HashMap<H256, H256>>,
    hex_address: &str,
) {
    if let Some(storage) = &storage {
        if storage.is_empty() {
            writeln!(
                host.buffer.borrow_mut(),
                "Account {}: storage matched (both empty).",
                hex_address
            )
            .unwrap();
        }
        for (index, value) in storage.iter() {
            match account.get_storage(host, index) {
                Ok(current_storage_value) => {
                    let storage_value = value;
                    if current_storage_value != *storage_value {
                        *invalid_state = true;
                        writeln!( host.buffer.borrow_mut(), "Account {}: storage don't match current one for index {}, {} was expected, but got {}.", hex_address, index, storage_value, current_storage_value).unwrap();
                    } else {
                        writeln!(
                            host.buffer.borrow_mut(),
                            "Account {}: storage matched for index {}.",
                            hex_address,
                            index
                        )
                        .unwrap();
                    }
                }
                Err(_) => {
                    *invalid_state = true;
                    writeln!(
                        host.buffer.borrow_mut(),
                        "Account {} should have a storage.",
                        hex_address
                    )
                    .unwrap();
                }
            }
        }
    }
}

fn check_durable_storage(
    host: &mut EvalHost,
    filler_expectation_result: &HashMap<String, AccountInfoFiller>,
    good_state: &mut bool,
) {
    for (account, info) in filler_expectation_result.iter() {
        let hex_address = if account.contains("0x") {
            account.to_owned()
        } else {
            "0x".to_owned() + account
        };
        let address = H160::from_str(&hex_address).expect("Expect valid hex digit(s).");
        let account = EthereumAccount::from_address(&address).unwrap();
        let mut invalid_state = false;

        // Enable checks when fields are available in the source filler file.

        check_should_not_exist(
            host,
            &account,
            &mut invalid_state,
            &info.shouldnotexist,
            &hex_address,
        );

        check_balance(
            host,
            &account,
            &mut invalid_state,
            &info.balance,
            &hex_address,
        );

        check_code(host, &account, &mut invalid_state, &info.code, &hex_address);

        check_nonce(
            host,
            &account,
            &mut invalid_state,
            &info.nonce,
            &hex_address,
        );

        check_storage(
            host,
            &account,
            &mut invalid_state,
            &info.storage,
            &hex_address,
        );

        if invalid_state {
            // One invalid state will cause the entire test to be a failure.
            *good_state = false;
            writeln!(host.buffer.borrow_mut(), "==> [INVALID STATE]\n").unwrap();
        } else {
            writeln!(host.buffer.borrow_mut(), "==> [CORRECT STATE]\n").unwrap();
        }
    }
}

pub fn process(
    host: &mut EvalHost,
    filler_source: FillerSource,
    spec_name: &SpecName,
    report_map: &mut HashMap<String, ReportValue>,
    report_key: String,
    output_file: &mut File,
) {
    let mut good_state = true;

    for (name, fillers) in filler_source.0.into_iter() {
        writeln!(
            host.buffer.borrow_mut(),
            "Processing checks with filler: {}Filler\n",
            name
        )
        .unwrap();
        for filler_expectation in fillers.expect {
            for filler_network in filler_expectation.network {
                let cmp_spec_id = parse_and_get_cmp(&filler_network);
                let network = purify_network(&filler_network);
                let check_network_id = SpecId::from(&network) as u8;
                let current_network_config_id = SpecId::from(&spec_name.to_str()) as u8;

                if !cmp_spec_id(&current_network_config_id, &check_network_id) {
                    continue;
                }

                writeln!(
                    host.buffer.borrow_mut(),
                    "CONFIG NETWORK ---- {}",
                    spec_name.to_str()
                )
                .unwrap();
                writeln!(
                    host.buffer.borrow_mut(),
                    "CHECK  NETWORK ---- {}\n",
                    filler_network
                )
                .unwrap();

                check_durable_storage(host, &filler_expectation.result, &mut good_state);
            }
        }
    }

    if good_state {
        writeln!(output_file, "\nFINAL RESULT: SUCCESS\n").unwrap();
        report_map.entry(report_key).and_modify(|report_value| {
            *report_value = ReportValue {
                successes: report_value.successes + 1,
                failures: report_value.failures,
            };
        });
    } else {
        write!(
            output_file,
            "{}",
            String::from_utf8(host.buffer.borrow_mut().to_vec()).unwrap()
        )
        .unwrap();
        writeln!(output_file, "FINAL RESULT: FAILURE\n").unwrap();
        report_map.entry(report_key).and_modify(|report_value| {
            *report_value = ReportValue {
                successes: report_value.successes,
                failures: report_value.failures + 1,
            };
        });
    }
}

pub fn process_for_transaction(
    host: &mut EvalHost,
    filler_source: &FillerSource,
    tx_index: i64,
    info: &Info,
    spec_name: &SpecName,
    report_map: &mut HashMap<String, ReportValue>,
    report_key: String,
    output_file: &mut File,
) {
    let mut good_state = true;

    for (name, fillers) in filler_source.to_owned().0.into_iter() {
        writeln!(
            host.buffer.borrow_mut(),
            "Processing checks for transaction {} with filler: {}Filler\n",
            &tx_index,
            name
        )
        .unwrap();
        for filler_expectation in fillers.expect {
            for filler_network in filler_expectation.network {
                let cmp_spec_id = parse_and_get_cmp(&filler_network);
                let network = purify_network(&filler_network);
                let check_network_id = SpecId::from(&network) as u8;
                let current_network_config_id = SpecId::from(&spec_name.to_str()) as u8;

                if !cmp_spec_id(&current_network_config_id, &check_network_id) {
                    continue;
                }

                writeln!(
                    host.buffer.borrow_mut(),
                    "CONFIG NETWORK ---- {}",
                    spec_name.to_str()
                )
                .unwrap();
                writeln!(
                    host.buffer.borrow_mut(),
                    "CHECK  NETWORK ---- {}\n",
                    filler_network
                )
                .unwrap();

                if check_filler_contraints(&filler_expectation.indexes, &info, tx_index) {
                    check_durable_storage(
                        host,
                        &filler_expectation.result,
                        &mut good_state,
                    );
                }
            }
        }
    }

    if good_state {
        writeln!(output_file, "\nFINAL RESULT: SUCCESS\n").unwrap();
        report_map.entry(report_key).and_modify(|report_value| {
            *report_value = ReportValue {
                successes: report_value.successes + 1,
                failures: report_value.failures,
            };
        });
    } else {
        write!(
            output_file,
            "{}",
            String::from_utf8(host.buffer.borrow_mut().to_vec()).unwrap()
        )
        .unwrap();
        writeln!(output_file, "FINAL RESULT: FAILURE\n").unwrap();
        report_map.entry(report_key).and_modify(|report_value| {
            *report_value = ReportValue {
                successes: report_value.successes,
                failures: report_value.failures + 1,
            };
        });
    }
}
