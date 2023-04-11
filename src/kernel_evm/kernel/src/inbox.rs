// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use tezos_smart_rollup_host::input::Message;
use tezos_smart_rollup_host::runtime::Runtime;

use crate::Error;

use tezos_ethereum::transaction::{RawTransaction, TransactionHash};

pub struct Transaction {
    pub tx_hash: TransactionHash,
    pub tx: RawTransaction,
}

pub enum InputResult {
    NoInput,
    SimpleTransaction(Box<Transaction>),
    NewChunkedTransaction {
        tx_hash: TransactionHash,
        len: u16,
    },
    TransactionChunk {
        tx_hash: TransactionHash,
        i: u16,
        data: Vec<u8>,
    },
    Unparsable,
}

const SIMPLE_TRANSACTION_TAG: u8 = 0;

const NEW_CHUNKED_TRANSACTION_TAG: u8 = 1;

const TRANSACTION_CHUNK_TAG: u8 = 2;

impl InputResult {
    fn parse_simple_transaction(bytes: &[u8]) -> Self {
        // Next 32 bytes is the transaction hash.
        let (tx_hash, remaining) = bytes.split_at(32);
        let tx_hash: TransactionHash = match tx_hash.try_into() {
            Ok(tx_hash) => tx_hash,
            Err(_) => return InputResult::Unparsable,
        };
        // Remaining bytes is the rlp encoded transaction.
        let tx = match RawTransaction::decode_from_rlp(remaining) {
            Ok(tx) => tx,
            Err(_) => return InputResult::Unparsable,
        };
        InputResult::SimpleTransaction(Box::new(Transaction { tx_hash, tx }))
    }

    fn parse_new_chunked_transaction(bytes: &[u8]) -> Self {
        // Next 32 bytes is the transaction hash.
        let (tx_hash, remaining) = bytes.split_at(32);
        let tx_hash: TransactionHash = match tx_hash.try_into() {
            Ok(tx_hash) => tx_hash,
            Err(_) => return InputResult::Unparsable,
        };
        // Next 2 bytes is the number of chunks.
        let (len, remaining) = remaining.split_at(2);
        let len = u16::from_le_bytes(len.try_into().unwrap());
        if remaining.is_empty() {
            Self::NewChunkedTransaction { tx_hash, len }
        } else {
            Self::Unparsable
        }
    }

    fn parse_transaction_chunk(bytes: &[u8]) -> Self {
        // Next 32 bytes is the transaction hash.
        let (tx_hash, remaining) = bytes.split_at(32);
        let tx_hash: TransactionHash = match tx_hash.try_into() {
            Ok(tx_hash) => tx_hash,
            Err(_) => return InputResult::Unparsable,
        };
        // Next 2 bytes is the index.
        let (i, remaining) = remaining.split_at(2);
        let i = u16::from_le_bytes(i.try_into().unwrap());
        Self::TransactionChunk {
            tx_hash,
            i,
            data: remaining.to_vec(),
        }
    }

    pub fn parse(input: Message, smart_rollup_address: [u8; 20]) -> Self {
        let bytes = Message::as_ref(&input);
        let (input_tag, remaining) = match bytes.split_first() {
            Some(res) => res,
            None => return InputResult::Unparsable,
        };
        // External messages starts with the tag 1, they are the only
        // messages we consider.
        if *input_tag != 1 {
            return InputResult::Unparsable;
        };
        // Next 20 bytes is the targeted smart rollup address.
        let remaining = {
            let (target_smart_rollup_address, remaining) = remaining.split_at(20);

            if target_smart_rollup_address == smart_rollup_address {
                remaining
            } else {
                return InputResult::Unparsable;
            }
        };
        let (transaction_tag, remaining) = match remaining.split_first() {
            Some(res) => res,
            None => return InputResult::Unparsable,
        };
        match *transaction_tag {
            SIMPLE_TRANSACTION_TAG => Self::parse_simple_transaction(remaining),
            NEW_CHUNKED_TRANSACTION_TAG => Self::parse_new_chunked_transaction(remaining),
            TRANSACTION_CHUNK_TAG => Self::parse_transaction_chunk(remaining),
            _ => InputResult::Unparsable,
        }
    }
}

pub fn read_input<Host: Runtime>(
    host: &mut Host,
    smart_rollup_address: [u8; 20],
) -> Result<InputResult, Error> {
    let input = host.read_input()?;
    match input {
        Some(input) => Ok(InputResult::parse(input, smart_rollup_address)),
        None => Ok(InputResult::NoInput),
    }
}

fn handle_transaction_chunk<Host: Runtime>(
    host: &mut Host,
    tx_hash: TransactionHash,
    i: u16,
    data: Vec<u8>,
) -> Result<Option<Transaction>, Error> {
    // Sanity check to verify that the transaction chunk uses the maximum
    // space capacity allowed.
    let len = crate::storage::chunked_transaction_len(host, &tx_hash)?;
    let maximum_size = 4095 - 20 - 1 - 2 - 32;
    if i != len - 1 && data.len() < maximum_size {
        panic!("Removes the whole chunked transaction?")
    };
    // When the transaction is stored in the storage, it returns the full transaction
    // if `data` was the missing chunk.
    if let Some(data) = crate::storage::store_transaction_chunk(host, &tx_hash, i, data)?
    {
        if let Ok(tx) = RawTransaction::decode_from_rlp(&data) {
            return Ok(Some(Transaction { tx_hash, tx }));
        }
    }
    Ok(None)
}

pub fn read_inbox<Host: Runtime>(
    host: &mut Host,
    smart_rollup_address: [u8; 20],
) -> Result<Vec<Transaction>, Error> {
    let mut res = Vec::new();
    loop {
        match read_input(host, smart_rollup_address)? {
            InputResult::NoInput => return Ok(res),
            InputResult::Unparsable => (),
            InputResult::SimpleTransaction(tx) => res.push(*tx),
            InputResult::NewChunkedTransaction { tx_hash, len } => {
                crate::storage::create_chunked_transaction(host, &tx_hash, len)?
            }
            InputResult::TransactionChunk { tx_hash, i, data } => {
                if let Some(tx) = handle_transaction_chunk(host, tx_hash, i, data)? {
                    res.push(tx)
                }
            }
        }
    }
}
