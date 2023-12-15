// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>

use crate::{
    error::Error,
    inbox::{Transaction, TransactionContent},
    safe_storage::SafeStorage,
};
use anyhow::Result;
use primitive_types::H160;
use rlp::{Decodable, DecoderError, Encodable, Rlp};
use tezos_ethereum::{
    rlp_helpers::{append_pair, decode_field, decode_pair, next},
    transaction::TRANSACTION_HASH_SIZE,
    tx_common::EthereumTransactionCommon,
};
use tezos_smart_rollup_host::{path::RefPath, runtime::Runtime};

pub const DELAYED_INBOX_PATH: RefPath = RefPath::assert_from(b"/delayed-inbox");

// Tags that indicates the delayed transaction is a eth transaction.
pub const DELAYED_TRANSACTION_TAG: u8 = 0x01;

pub trait DelayedInbox {
    /// Saves the transaction to the delayed inbox
    ///
    /// The transaction will be located under /delayed-inbox
    fn save_transaction(&mut self, transaction: &Transaction) -> Result<()>;
}

/// Hash of a transaction
///
/// It represents the key of the transaction in the delayed inbox
#[derive(Clone, Copy)]
pub struct Hash([u8; TRANSACTION_HASH_SIZE]);

impl Encodable for Hash {
    fn rlp_append(&self, s: &mut rlp::RlpStream) {
        s.append(&self.0.to_vec());
    }
}

impl Decodable for Hash {
    fn decode(decoder: &rlp::Rlp) -> Result<Self, rlp::DecoderError> {
        let hash: Vec<u8> = decoder.as_val()?;
        let hash = hash
            .try_into()
            .map_err(|_| DecoderError::Custom("expected a vec of 32 elements"))?;
        Ok(Hash(hash))
    }
}

impl AsRef<[u8]> for Hash {
    fn as_ref(&self) -> &[u8] {
        &self.0
    }
}

/// Delayed transaction
pub struct DelayedEthereum {
    pub caller: H160,
    pub content: EthereumTransactionCommon,
}

/// Delayed transaction
/// Later it might be turn into a struct
/// And fields like the timestamp might be added
#[allow(clippy::large_enum_variant)]
pub enum DelayedTransaction {
    Ethereum(DelayedEthereum),
}

impl Encodable for DelayedEthereum {
    fn rlp_append(&self, stream: &mut rlp::RlpStream) {
        let DelayedEthereum { caller, content } = self;
        append_pair(stream, caller, &content.to_bytes());
    }
}

impl Decodable for DelayedEthereum {
    fn decode(decoder: &Rlp) -> std::prelude::v1::Result<Self, DecoderError> {
        let (caller, bytes): (H160, Vec<u8>) = decode_pair(decoder)?;
        let content = EthereumTransactionCommon::from_bytes(&bytes)?;
        Ok(DelayedEthereum { caller, content })
    }
}

impl Encodable for DelayedTransaction {
    fn rlp_append(&self, stream: &mut rlp::RlpStream) {
        stream.begin_list(2);
        match self {
            DelayedTransaction::Ethereum(delayed_tx) => {
                stream.append(&DELAYED_TRANSACTION_TAG);
                stream.append(delayed_tx);
            }
        }
    }
}

impl Decodable for DelayedTransaction {
    fn decode(decoder: &rlp::Rlp) -> Result<Self, DecoderError> {
        if !decoder.is_list() {
            return Err(DecoderError::RlpExpectedToBeList);
        }
        if !decoder.item_count()? != 2 {
            return Err(DecoderError::RlpIncorrectListLen);
        }
        let mut it = decoder.iter();
        let tag: u8 = decode_field(&next(&mut it)?, "tag")?;
        match tag {
            DELAYED_TRANSACTION_TAG => {
                let delayed_tx = decode_field(&next(&mut it)?, "content")?;
                Ok(DelayedTransaction::Ethereum(delayed_tx))
            }
            _ => Err(DecoderError::Custom("unknown tag")),
        }
    }
}

impl<Host: Runtime, Internal> DelayedInbox for SafeStorage<&mut Host, &mut Internal> {
    fn save_transaction(&mut self, tx: &Transaction) -> Result<()> {
        let Some(ref mut delayed_inbox) = self.delayed_inbox else {
            return Err(Error::NotSequencer.into())
        };
        let Transaction { tx_hash, content } = tx;
        let delayed_transaction = match content {
            TransactionContent::Ethereum(tx) => {
                let caller = tx.caller()?;
                DelayedTransaction::Ethereum(DelayedEthereum {
                    caller,
                    content: tx.clone(),
                })
            }
            _ => {
                // not yet supported
                return Ok(());
            }
        };
        delayed_inbox.push(self.host, &Hash(*tx_hash), &delayed_transaction)?;
        Ok(())
    }
}
