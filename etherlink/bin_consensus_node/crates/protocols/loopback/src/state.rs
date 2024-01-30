// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use std::sync::Arc;

use dsn_core::storage::{Snapshot, StorageBackend, WriteBatch};
use dsn_core::types::{PreBlock, PreBlockHeader};

use crate::error::LoopbackError;

const PRE_BLOCKS_SCOPE: &'static str = "pre_blocks";
const HEAD_SCOPE: &'static str = "head";
const LATEST_PRE_BLOCK_HEADER_KEY: &'static [u8] = &[0u8];

#[derive(Debug)]
pub struct LoopbackState<S: StorageBackend> {
    storage: Arc<S>,
}

impl<S: StorageBackend> Clone for LoopbackState<S> {
    fn clone(&self) -> Self {
        Self {
            storage: self.storage.clone(),
        }
    }
}

impl<S: StorageBackend> LoopbackState<S> {
    pub fn new(storage: Arc<S>) -> Self {
        Self { storage }
    }

    pub fn get_head(&self) -> Result<PreBlockHeader, LoopbackError> {
        let head = self.storage.snapshot(vec![HEAD_SCOPE])?;

        let bytes = head
            .get(HEAD_SCOPE, LATEST_PRE_BLOCK_HEADER_KEY)?
            .ok_or_else(|| LoopbackError::MissingPreBlockHead)?;

        Ok(bcs::from_bytes(&bytes)?)
    }

    pub fn get_pre_blocks(
        &self,
        from_id: u64,
        max_count: usize,
    ) -> Result<Vec<PreBlock>, LoopbackError> {
        let pre_blocks = self.storage.snapshot(vec![PRE_BLOCKS_SCOPE])?;

        let mut id = from_id;
        let mut res = Vec::with_capacity(max_count);

        loop {
            if let Some(bytes) = pre_blocks.get(PRE_BLOCKS_SCOPE, &id.to_be_bytes())? {
                let pre_block = bcs::from_bytes(&bytes)?;
                res.push(pre_block);
                id += 1;
            } else {
                break;
            }

            if res.len() == max_count {
                break;
            }
        }

        Ok(res)
    }

    pub fn update_head(&self, pre_block: PreBlock) -> Result<(), LoopbackError> {
        let mut batch = self.storage.batch()?;

        let pre_block_bytes = bcs::to_bytes(&pre_block)?;
        batch.insert(
            PRE_BLOCKS_SCOPE,
            &pre_block.header.id.to_be_bytes(),
            pre_block_bytes,
        )?;

        let header_bytes = bcs::to_bytes(&pre_block.header)?;
        batch.insert(HEAD_SCOPE, LATEST_PRE_BLOCK_HEADER_KEY, header_bytes)?;

        self.storage.write(batch)?;
        Ok(())
    }
}
