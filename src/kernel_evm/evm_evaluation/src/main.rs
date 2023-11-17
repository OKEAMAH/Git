// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

mod evalhost;
mod fillers;
mod helpers;
mod models;
mod runner;

use std::{
    collections::HashMap,
    ffi::OsStr,
    fs::OpenOptions,
    io::Write,
    path::{Path, PathBuf},
};
use structopt::StructOpt;
use walkdir::{DirEntry, WalkDir};

use crate::helpers::construct_folder_path;

const SKIP_ANY: bool = true;

pub fn find_all_json_tests(path: &Path) -> Vec<PathBuf> {
    WalkDir::new(path)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| e.file_name().to_string_lossy().ends_with(".json"))
        .map(DirEntry::into_path)
        .collect::<Vec<PathBuf>>()
}

#[derive(Default)]
pub struct ReportValue {
    pub successes: u16,
    pub failures: u16,
}

#[derive(Debug, StructOpt)]
#[structopt(name = "evm-evaluation", about = "Evaluate EVM's engine semantic.")]
pub struct Opt {
    #[structopt(
        short = "d",
        long = "eth-tests",
        default_value = "tests",
        about = "Specify the directory path of [ethereum/tests]. By default it will be 'tests/'."
    )]
    eth_tests: String,
    #[structopt(
        short = "s",
        long = "sub-directory",
        about = "Specify the sub directory of tests you want to execute."
    )]
    sub_dir: Option<String>,
    #[structopt(
        short = "t",
        long = "test",
        about = "Specify the name of the test to execute."
    )]
    test: Option<String>,
    #[structopt(
        short = "o",
        long = "output",
        default_value = "evm_evaluation.regression",
        about = "Specify the file where the logs will be outputed. By default it will be outputed to 'evm_evaluation.regression'."
    )]
    output: String,
}

pub fn main() {
    let opt = Opt::from_args();
    let mut output_file = OpenOptions::new()
        .append(true)
        .truncate(false)
        .create(true)
        .open(&opt.output)
        .unwrap();
    let folder_path =
        construct_folder_path("GeneralStateTests", &opt.eth_tests, &opt.sub_dir);
    let test_files = find_all_json_tests(&folder_path);
    let mut report_map: HashMap<String, ReportValue> = HashMap::new();

    writeln!(
        output_file,
        "Start running tests on: {}",
        folder_path.to_str().unwrap()
    )
    .unwrap();
    for test_file in test_files.into_iter() {
        let splitted_path: Vec<&str> = test_file.to_str().unwrap().split('/').collect();
        let report_key = splitted_path
            .get(splitted_path.len() - 2)
            .unwrap()
            .to_owned();
        if !report_map.contains_key(report_key) {
            report_map.insert(report_key.to_owned(), ReportValue::default());
        }

        if let Some(test) = &opt.test {
            let mut file_name = PathBuf::from(test);
            file_name.set_extension("json");
            if test_file.file_name() == Some(OsStr::new(&file_name)) {
                runner::run_test(
                    &test_file,
                    &mut report_map,
                    report_key.to_owned(),
                    &opt,
                    &mut output_file,
                )
                .unwrap();
            }
            continue;
        }

        writeln!(output_file, "---------- Test: {:?} ----------", test_file).unwrap();

        if SKIP_ANY {
            // Funky test with `bigint 0x00` value in json not possible to happen on
            // Mainnet and require custom json parser.
            if test_file.file_name() == Some(OsStr::new("ValueOverflow.json")) {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // The following test(s) is/are failing they need in depth debugging
            // Reason: panicked at 'arithmetic operation overflow'
            if test_file.file_name() == Some(OsStr::new("HighGasPrice.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest32.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest7.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest50.json"))
                || test_file.file_name() == Some(OsStr::new("randomStatetest468.json"))
                || test_file.file_name() == Some(OsStr::new("gasCostBerlin.json"))
                || test_file.file_name() == Some(OsStr::new("underflowTest.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // The following test(s) is/are failing they need in depth debugging
            // Reason: memory allocation of X bytes failed | 73289 IOT instruction (core dumped)
            if test_file.file_name() == Some(OsStr::new("sha3.json")) {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Long tests ✔ (passing)
            if test_file.file_name() == Some(OsStr::new("loopMul.json")) {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Oddly long checks on a test that do no relevant check (passing)
            if test_file.file_name() == Some(OsStr::new("intrinsic.json")) {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Long tests ~ (outcome is unknown)
            if test_file.file_name() == Some(OsStr::new("static_Call50000_sha256.json"))
                || test_file.file_name()
                    == Some(OsStr::new("static_Call50000_ecrec.json"))
                || test_file.file_name() == Some(OsStr::new("static_Call50000.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Reason: panicked at 'attempt to add with overflow'
            if let Some(file_name) = test_file.to_str() {
                if file_name.contains("DiffPlaces.json") {
                    writeln!(output_file, "\nSKIPPED\n").unwrap();
                    continue;
                }
            }

            // Reason: panicked at 'attempt to multiply with overflow'
            if test_file.file_name()
                == Some(OsStr::new("static_Call1024BalanceTooLow.json"))
                || test_file.file_name()
                    == Some(OsStr::new("static_Call1024BalanceTooLow2.json"))
                || test_file.file_name()
                    == Some(OsStr::new("static_Call1024PreCalls3.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Reason: panicked at 'attempt to add with overflow'
            if test_file.file_name() == Some(OsStr::new("static_Call1024PreCalls.json"))
                || test_file.file_name()
                    == Some(OsStr::new("static_Call1024PreCalls2.json"))
                || test_file.file_name() == Some(OsStr::new("diffPlaces.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // SKIPPED BECAUSE OF WRONG PARSING OF FILLER FILES

            // ********** JSON ********** //

            // Reason: comments in the result field
            if test_file.file_name() == Some(OsStr::new("add11.json"))
                || test_file.file_name() == Some(OsStr::new("add11.json"))
                || test_file.file_name()
                    == Some(OsStr::new("static_CREATE_EmptyContractAndCallIt_0wei.json"))
                || test_file.file_name()
                    == Some(OsStr::new(
                        "static_CREATE_EmptyContractWithStorageAndCallIt_0wei.json",
                    ))
                || test_file.file_name() == Some(OsStr::new("callToNonExistent.json"))
                || test_file.file_name()
                    == Some(OsStr::new("CreateAndGasInsideCreate.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Reason: invalid length 0, expected a (both 0x-prefixed or not) hex string or
            // byte array containing between (0; 32] bytes
            if test_file.file_name()
                == Some(OsStr::new("ZeroValue_SUICIDE_ToOneStorageKey.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Reason: inconsistent hex/dec field value
            if test_file.file_name() == Some(OsStr::new("TouchToEmptyAccountRevert.json"))
                || test_file.file_name()
                    == Some(OsStr::new("CREATE_EContract_ThenCALLToNonExistentAcc.json"))
                || test_file.file_name() == Some(OsStr::new("CREATE_EmptyContract.json"))
                || test_file.file_name() == Some(OsStr::new("StoreGasOnCreate.json"))
                || test_file.file_name() == Some(OsStr::new("OverflowGasRequire2.json"))
                || test_file.file_name() == Some(OsStr::new("StackDepthLimitSEC.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // ********** YAML ********** //

            // Reason: invalid hex character: _
            if test_file.file_name() == Some(OsStr::new("doubleSelfdestructTest.json"))
                || test_file.file_name() == Some(OsStr::new("clearReturnBuffer.json"))
                || test_file.file_name() == Some(OsStr::new("gasCost.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }

            // Reason: invalid length 0, expected a (both 0x-prefixed or not) hex string or
            // byte array containing between (0; 32] bytes
            if test_file.file_name() == Some(OsStr::new("eqNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("mulmodNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("addmodNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("smodNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("callcodeNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("mstoreNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("modNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("extcodesizeNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("log1NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("extcodecopyNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("log2NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("andNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("log3NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("sgtNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("expNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("mloadNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("log0NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("byteNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("orNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("codecopyNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("gtNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("signextNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("ltNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("sltNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("balanceNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("mstore8NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("delegatecallNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("iszeroNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("subNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("calldatacopyNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("sha3NonConst.json"))
                || test_file.file_name() == Some(OsStr::new("sdivNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("addNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("notNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("createNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("xorNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("calldataloadNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("divNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("returnNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("mulNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("callNonConst.json"))
                || test_file.file_name() == Some(OsStr::new("twoOps.json"))
            {
                writeln!(output_file, "\nSKIPPED\n").unwrap();
                continue;
            }
        }

        runner::run_test(
            &test_file,
            &mut report_map,
            report_key.to_owned(),
            &opt,
            &mut output_file,
        )
        .unwrap();
    }
    writeln!(output_file, "@@@@@ END OF TESTING @@@@@\n").unwrap();

    writeln!(output_file, "@@@@@@ FINAL REPORT @@@@@@").unwrap();
    let mut successes_total = 0;
    let mut failure_total = 0;
    for (key, report_value) in report_map {
        successes_total += report_value.successes;
        failure_total += report_value.failures;
        writeln!(
            output_file,
            "For sub-dir {}, there was {} success(es) and {} failure(s).",
            key, report_value.successes, report_value.failures
        )
        .unwrap();
    }
    writeln!(
        output_file,
        "\nSUCCESSES IN TOTAL: {}\nFAILURES IN TOTAL: {}",
        successes_total, failure_total
    )
    .unwrap();
}
