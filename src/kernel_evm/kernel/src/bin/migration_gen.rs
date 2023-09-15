// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>

use primitive_types::{H160, H256, U256};
use rlp::RlpStream;
use std::{fs::write, path::Path};
use tezos_ethereum::{
    rlp_helpers::append_u256_le,
    transaction::{
        TransactionReceipt, TransactionStatus, TransactionType, TRANSACTION_HASH_SIZE,
    },
    Bloom,
};
use tezos_smart_rollup_installer_config::yaml::{Instr, SetArgs, YamlConfig};

fn tx_receipt_deprecated(tx: TransactionReceipt) -> Vec<u8> {
    let mut stream = RlpStream::new();
    stream.begin_list(12);
    stream.append(&tx.hash.to_vec());
    stream.append(&tx.index);
    stream.append(&tx.block_hash);
    append_u256_le(&mut stream, tx.block_number);
    stream.append(&tx.from);
    match &tx.to {
        Some(to) => stream.append(to),
        None => stream.append_empty_data(),
    };
    append_u256_le(&mut stream, tx.cumulative_gas_used);
    append_u256_le(&mut stream, tx.effective_gas_price);
    append_u256_le(&mut stream, tx.gas_used);
    match &tx.contract_address {
        Some(address) => stream.append(address),
        None => stream.append_empty_data(),
    };
    stream.append::<u8>(&tx.type_.into());
    stream.append::<u8>(&tx.status.into());

    stream.out().to_vec()
}

fn generate_tx_receipts(n: usize) -> Vec<TransactionReceipt> {
    let data = hex::decode("3535353535353535353535353535353535353535").unwrap();
    let address = H160::from_slice(&data);
    (0..n)
        .into_iter()
        .map(|tx_id| {
            let mut tx_hash = [0; TRANSACTION_HASH_SIZE];
            let tx_id_bytes = tx_id.to_be_bytes();
            tx_hash[..8].clone_from_slice(&tx_id_bytes);
            TransactionReceipt {
                hash: tx_hash,
                index: 15u32,
                block_hash: H256::default(),
                block_number: U256::from(42),
                from: address,
                to: Some(address),
                cumulative_gas_used: U256::from(1252345235),
                effective_gas_price: U256::from(47457345),
                gas_used: U256::from(474573452),
                contract_address: None,
                type_: TransactionType::Legacy,
                logs_bloom: Bloom::default(),
                logs: vec![],
                status: TransactionStatus::Success,
            }
        })
        .collect()
}

const TRANSACTION_RECEIPT_N: usize = 15000;

fn main() {
    let receipts = generate_tx_receipts(TRANSACTION_RECEIPT_N);
    let receipts_n = receipts.len();

    let mut receipts_instructions: Vec<Instr> = receipts
        .into_iter()
        .enumerate()
        .flat_map(|(i, receipt)| {
            let tx_id = hex::encode(receipt.hash);
            let tx_bytes = hex::encode(tx_receipt_deprecated(receipt));
            vec![
                Instr::Set(SetArgs {
                    value: tx_bytes,
                    to: format!("/evm/transactions_receipts/{}", tx_id),
                }),
                Instr::Set(SetArgs {
                    value: tx_id,
                    to: format!("/evm/indexes/transactions/{}", i),
                }),
            ]
        })
        .collect();

    let mut all_instructions = vec![];

    all_instructions.push(Instr::Set(SetArgs {
        value: "0000000000000000".to_owned(),
        to: "/evm/storage_version".to_owned(),
    }));
    all_instructions.push(Instr::Set(SetArgs {
        value: hex::encode(receipts_n.to_le_bytes()),
        to: "/evm/indexes/transactions/length".to_owned(),
    }));
    all_instructions.append(&mut receipts_instructions);

    let yaml = serde_yaml::to_string(&YamlConfig {
        instructions: all_instructions,
    })
    .unwrap();
    let output_path = Path::new("/Users/pva701/tezos/src/kernel_evm/15k_receipts.yaml");
    write(output_path, yaml).unwrap();
}
