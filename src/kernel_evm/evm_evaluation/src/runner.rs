// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2021-2023 draganrakita
//
// SPDX-License-Identifier: MIT

use evm_execution::account_storage::{init_account_storage, EthereumAccount};
use evm_execution::precompiles::precompile_set;
use evm_execution::{run_transaction, Config};

use primitive_types::{H160, H256, U256};
use tezos_ethereum::block::BlockConstants;
use tezos_smart_rollup_mock::MockHost;

use hex_literal::hex;
use primitives::{HashMap, SpecId, B160, B256};
use std::path::Path;
use thiserror::Error;

use crate::models::{Env, SpecName, TestSuit};

fn u256_to_h256(value: &U256) -> H256 {
    let mut ret = H256::zero();
    value.to_big_endian(ret.as_bytes_mut());
    ret
}

#[derive(Debug, Error)]
pub enum TestError {
    #[error(
        "Test: {id} ({spec_id:?}), root mismatched, expected: {expect:?} got: {got:?}"
    )]
    _RootMismatch {
        spec_id: SpecId,
        id: usize,
        got: B256,
        expect: B256,
    },
    #[error("Serde json error")]
    SerdeDeserialize(#[from] serde_json::Error),
    #[error("Internal system error")]
    _SystemError,
    #[error("Unknown private key: {private_key:?}")]
    UnknownPrivateKey { private_key: B256 },
}

pub fn run_test(path: &Path) -> Result<(), TestError> {
    let json_reader = std::fs::read(path).unwrap();
    let suit: TestSuit = serde_json::from_reader(&*json_reader)?;

    let map_caller_keys: HashMap<B256, B160> = [
        (
            B256(hex!(
                "45a915e4d060149eb4365960e6a7a45f334393093061116b197e3240065ff2d8"
            )),
            B160(hex!("a94f5374fce5edbc8e2a8697c15331677e6ebf0b")),
        ),
        (
            B256(hex!(
                "c85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4"
            )),
            B160(hex!("cd2a3d9f938e13cd947ec05abc7fe734df8dd826")),
        ),
        (
            B256(hex!(
                "044852b2a670ade5407e78fb2863c51de9fcb96542a07186fe3aeda6bb8a116d"
            )),
            B160(hex!("82a978b3f5962a5b0957d9ee9eef472ee55b42f1")),
        ),
        (
            B256(hex!(
                "6a7eeac5f12b409d42028f66b0b2132535ee158cfda439e3bfdd4558e8f4bf6c"
            )),
            B160(hex!("c9c5a15a403e41498b6f69f6f89dd9f5892d21f7")),
        ),
        (
            B256(hex!(
                "a95defe70ebea7804f9c3be42d20d24375e2a92b9d9666b832069c5f3cd423dd"
            )),
            B160(hex!("3fb1cd2cd96c6d5c0b5eb3322d807b34482481d4")),
        ),
        (
            B256(hex!(
                "fe13266ff57000135fb9aa854bbfe455d8da85b21f626307bf3263a0c2a8e7fe"
            )),
            B160(hex!("dcc5ba93a1ed7e045690d722f2bf460a51c61415")),
        ),
    ]
    .into();

    for (name, unit) in suit.0.into_iter() {
        println!("Running unit test: {}", name);
        let mut host = MockHost::default();
        let precompiles = precompile_set::<MockHost>();
        let mut evm_account_storage = init_account_storage().unwrap();

        println!("\n[START] Accounts initialisation");
        for (address, info) in unit.pre.into_iter() {
            let h160_address: H160 = address.as_fixed_bytes().into();
            println!("\nAccount is {}", h160_address);
            let mut account =
                EthereumAccount::from_address(&address.as_fixed_bytes().into()).unwrap();
            if info.nonce != 0 {
                account.set_nonce(&mut host, info.nonce.into()).unwrap();
                println!("Nonce is set for {} : {}", address, info.nonce);
            }
            account.balance_add(&mut host, info.balance).unwrap();
            println!("Balance for {} was added : {}", address, info.balance);
            account.set_code(&mut host, &info.code).unwrap();
            println!("Code was set for {}", address);
            for (index, value) in info.storage.iter() {
                account
                    .set_storage(&mut host, &u256_to_h256(index), &u256_to_h256(value))
                    .unwrap();
            }
        }
        println!("\n[END] Accounts initialisation\n");

        let mut env = Env::default();
        env.cfg.chain_id = 1; // Mainnet

        // BlockEnv
        env.block.number = unit.env.current_number;
        env.block.coinbase = unit.env.current_coinbase;
        env.block.timestamp = unit.env.current_timestamp;
        env.block.gas_limit = unit.env.current_gas_limit;
        env.block.basefee = unit.env.current_base_fee.unwrap_or_default();
        env.block.difficulty = unit.env.current_difficulty;
        // After the Merge prevrandao replaces mix_hash field in block and replaced
        // difficulty opcode in EVM.
        let mut prevrandao_bytes: [u8; 32] = [0; 32];
        unit.env
            .current_difficulty
            .to_little_endian(&mut prevrandao_bytes);
        env.block.prevrandao = Some(prevrandao_bytes.into());

        // TxEnv
        env.tx.caller = if let Some(caller) =
            map_caller_keys.get(&unit.transaction.secret_key.unwrap())
        {
            *caller
        } else {
            let private_key = unit.transaction.secret_key.unwrap();
            return Err(TestError::UnknownPrivateKey { private_key });
        };
        env.tx.gas_price = unit
            .transaction
            .gas_price
            .unwrap_or_else(|| unit.transaction.max_fee_per_gas.unwrap_or_default());
        env.tx.gas_priority_fee = unit.transaction.max_priority_fee_per_gas;

        // post and execution
        for (spec_name, tests) in unit.post {
            if matches!(
                spec_name,
                SpecName::ByzantiumToConstantinopleAt5
                    | SpecName::Constantinople
                    | SpecName::Unknown
            ) {
                continue;
            }

            env.cfg.spec_id = spec_name.to_spec_id();

            // TODO: use id
            for (_id, test) in tests.into_iter().enumerate() {
                let gas_limit =
                    *unit.transaction.gas_limit.get(test.indexes.gas).unwrap();
                let gas_limit = u64::try_from(gas_limit).unwrap_or(u64::MAX);
                env.tx.gas_limit = gas_limit;
                env.tx.data = unit
                    .transaction
                    .data
                    .get(test.indexes.data)
                    .unwrap()
                    .clone();
                env.tx.value = *unit.transaction.value.get(test.indexes.value).unwrap();

                env.tx.access_list = Vec::new(); // TODO: not used for now
                env.tx.transact_to = unit.transaction.to;
            }

            let block_constants = BlockConstants {
                gas_price: env.tx.gas_price,
                number: env.block.number,
                coinbase: env.block.coinbase.to_fixed_bytes().into(),
                timestamp: env.block.timestamp,
                difficulty: env.block.difficulty,
                gas_limit: env.block.gas_limit.as_u64(),
                base_fee_per_gas: env.block.basefee,
                chain_id: env.cfg.chain_id.into(),
            };
            let address = env.tx.transact_to.map(|addr| addr.to_fixed_bytes().into());
            let caller = env.tx.caller.to_fixed_bytes().into();
            let call_data = env.tx.data.to_vec();
            let gas_limit = Some(env.tx.gas_limit);
            let transaction_value = Some(env.tx.value);
            let pay_for_gas = true; // always, for now

            // TODO: make the config dependant on the specId
            let config = Config::london();

            match run_transaction(
                &mut host,
                &block_constants,
                &mut evm_account_storage,
                &precompiles,
                config,
                address,
                caller,
                call_data,
                gas_limit,
                transaction_value,
                pay_for_gas,
            ) {
                Ok(execution_outcome_opt) => {
                    let outcome_status = match execution_outcome_opt {
                        Some(execution_outcome) => {
                            if execution_outcome.is_success {
                                "[SUCCESS]"
                            } else {
                                "[FAILURE]"
                            }
                        }
                        None => "[INVALID]",
                    };
                    println!("\nOutcome status: {}", outcome_status);
                    println!("\n=======> OK! <=======\n")
                }
                Err(e) => panic!("A test failed due to {:?}", e),
            }
        }
    }
    Ok(())
}
