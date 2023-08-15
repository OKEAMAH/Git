// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

// Before running this script, run the following commands to build the debugger and the benchmark kernel
// $ make 
// $ make -C src/kernel_evm/

// Then run this script using the following command
// $ node src/kernel_evm/benchmarks/scripts/run_tps_benchmarks.js

const { spawn } = require('child_process');
const { execSync } = require('child_process');

const RUN_DEBUGGER_COMMAND = './octez-smart-rollup-wasm-debugger';
const RUN_INSTALLER_COMMAND = 'src/kernel_sdk/target/release/smart-rollup-installer'
const EVM_INSTALLER_KERNEL_PATH = 'evm_installer.wasm';
const PREIMAGE_DIR = 'preimages';
const SETUP_FILE_PATH = 'src/kernel_evm/config/benchmarking.yaml';
const EVM_KERNEL_PATH = 'src/kernel_evm/target/wasm32-unknown-unknown/release/evm_kernel.wasm';

function build_evm_installer_kernel_for_benchmark() {
    try {
        execSync(`${RUN_INSTALLER_COMMAND} get-reveal-installer --upgrade-to ${EVM_KERNEL_PATH} --output ${EVM_INSTALLER_KERNEL_PATH} --preimages-dir ${PREIMAGE_DIR} --setup-file ${SETUP_FILE_PATH}`);
    } catch (error) {
        console.log("Error building evm kernel installer");
        console.error(error);
    }
}

function build_benchmark_scenario(benchmark_script) {
    try {
        execSync(`node ${benchmark_script} > transactions.json`);
    } catch (error) {
        console.log(`Error running script ${benchmark_script}. Please fixed the error in the script before running this benchmark script`)
        console.error(error);
    }
}

function run_tps_benchmark(path) {

    profiler_result = new Promise ((resolve, _) => {

        var time_used = "";

        var transaction_count = "";

        const args = ["--kernel", EVM_INSTALLER_KERNEL_PATH, "--inputs", path, "--preimage-dir", PREIMAGE_DIR];

        const childProcess = spawn(RUN_DEBUGGER_COMMAND, args, {});

        childProcess.stdin.write("load inputs\n");

        childProcess.stdin.write("time step inbox\n");

        childProcess.stdin.end();

        childProcess.stdout.on('data', (data) => {
            const output = data.toString();
            const transaction_count_regex = /contains (\d+) transactions/;
            const transaction_count_match = output.match(transaction_count_regex);
            const transaction_count_result = transaction_count_match 
                ? transaction_count_match[1] 
                : null;
            if (transaction_count_result !== null) {
                transaction_count = transaction_count_result;
            }
            const time_used_regex = /took (\d+\.\d+)s/;
            const time_used_match = output.match(time_used_regex);
            const time_used_result = time_used_match 
                ? time_used_match[1]
                : null;
            if (time_used_result !== null) {
                time_used = time_used_result;
            }
        });
        childProcess.on('close', _ => {
            if (transaction_count == "") {
                console.log(new Error("Transaction count data not found"));
            }
            if (time_used == "") {
                console.log(new Error("Time usage data not found"));
            }
            resolve(transaction_count / time_used);
        });
    })
    return profiler_result;
}

async function main() {
    build_evm_installer_kernel_for_benchmark();
    erc20_scenario = "src/kernel_evm/benchmarks/scripts/benchmarks/tps_bench_erc20tok.js";
    build_benchmark_scenario(erc20_scenario);
    tps = await run_tps_benchmark("transactions.json");
    console.log("TPS for ERC-20 transaction:", tps);
}
  
main();
