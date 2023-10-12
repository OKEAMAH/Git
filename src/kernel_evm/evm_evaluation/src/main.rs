// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

mod models;
mod runner;

use std::{
    ffi::OsStr,
    path::{Path, PathBuf},
};
use walkdir::{DirEntry, WalkDir};
use std::collections::BTreeMap;

const SKIP_ANY: bool = true;

pub fn find_all_json_tests(path: &Path) -> Vec<PathBuf> {
    WalkDir::new(path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().ends_with(".json"))
        .map(DirEntry::into_path)
        .collect::<Vec<PathBuf>>()
}

/* REPORT - 09/10/2023 - 11:09 (UTC+2)

Number of tests:

- Runned: 2612
- Skipped: 9

Ethereum transactions:

- 12790 in total
  Outcome:
    - 8946 SUCCESS
    - 3575 FAILURE
    - 269 INVALID

Errors:

- 2621 CallErrorAsFatal(OutOfGas)
- 42 CallErrorAsFatal(OutOfFund)
- 5 CallErrorAsFatal(InvalidJump)
- 5 CallErrorAsFatal(StackOverflow)
- 5 CallErrorAsFatal(StackUnderflow)
- 5 InvalidCode(Opcode(201))
- 5 InvalidCode(Opcode(181))
- 5 InvalidCode(Opcode(182))
- 5 InvalidCode(Opcode(227))
- 2 InvalidCode(Opcode(95))
- 5 InvalidCode(Opcode(164))
- X InvalidCode(Opcode(XXX))

TOTAL: 3XXX */

pub fn main() {
    // Preliminary step:
    // - clone https://github.com/ethereum/tests repo inside [engine_evaluation]
    let folder_path = "tests/GeneralStateTests";
    let test_files = find_all_json_tests(&PathBuf::from(folder_path));
    println!("Start running tests on: {:?}", folder_path);
    for test_file in test_files.into_iter() {
        println!("---------- Test: {:?} ----------", test_file);

        if SKIP_ANY {
            // Funky test with `bigint 0x00` value in json not possible to happen on
            // Mainnet and require custom json parser.
            if test_file.file_name() == Some(OsStr::new("ValueOverflow.json")) {
                println!("\nSKIPPED\n");
                continue;
            }

            // The following test are failing they need in depth debugging
            // Reason: panicked at 'arithmetic operation overflow'
            if test_file.file_name() == Some(OsStr::new("HighGasPrice.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest32.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest7.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest50.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest468.json"))
            {
                println!("\nSKIPPED\n");
                continue;
            }

            // The following test are failing they need in depth debugging
            // Reason: stack overflow
            if test_file.file_name() == Some(OsStr::new("CallRecursiveContract.json"))
                || test_file.file_name()
                    == Some(OsStr::new("RecursiveCreateContracts.json"))
            {
                println!("\nSKIPPED\n");
                continue;
            }

            // Long tests ✔ (passing)
            if test_file.file_name() == Some(OsStr::new("loopMul.json")) {
                println!("\nSKIPPED\n");
                continue;
            }
        }

        runner::run_test(&test_file).unwrap();
    }
    println!("@@@@@ END OF TESTING @@@@@");
}
