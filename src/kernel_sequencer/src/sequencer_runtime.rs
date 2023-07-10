// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::RollupMetadata,
    path::Path,
    runtime::{Runtime, RuntimeError, ValueType},
};

use crate::{
    delayed_inbox::read_input, queue::Queue, routing::FilterBehavior, storage::map_user_path,
    storage::DELAYED_INBOX_PATH,
};

pub struct SequencerRuntime<R>
where
    R: Runtime,
{
    host: R,
    /// if true then the input is added to the delayed inbox
    input_predicate: FilterBehavior,
    /// maximum number of level a message can stay in the delayed inbox
    timeout_window: u32,
    /// The delayed inbox queue
    delayed_inbox_queue: Queue,
}

/// Runtime that handles the delayed inbox and the sequencer protocol.
///
/// The sequencer protocol is driven by the call of the read_input function.
/// That's why all the other functions of this runtime are calling the runtime passed in parameter.
impl<R> SequencerRuntime<R>
where
    R: Runtime,
{
    pub fn new(host: R, input_predicate: FilterBehavior, timeout_window: u32) -> Self {
        let delayed_inbox_queue = Queue::new(&host, DELAYED_INBOX_PATH.into()).unwrap();
        Self {
            host,
            input_predicate,
            timeout_window,
            delayed_inbox_queue,
        }
    }
}

impl<R> Runtime for SequencerRuntime<R>
where
    R: Runtime,
{
    fn write_output(&mut self, from: &[u8]) -> Result<(), RuntimeError> {
        self.host.write_output(from)
    }

    fn write_debug(&self, msg: &str) {
        self.host.write_debug(msg)
    }

    fn read_input(&mut self) -> Result<Option<Message>, RuntimeError> {
        read_input(
            &mut self.host,
            self.input_predicate,
            self.timeout_window,
            &mut self.delayed_inbox_queue,
        )
    }

    fn store_has<T: Path>(&self, path: &T) -> Result<Option<ValueType>, RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_has(&path)
    }

    fn store_read<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        max_bytes: usize,
    ) -> Result<Vec<u8>, RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_read(&path, from_offset, max_bytes)
    }

    fn store_read_slice<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        buffer: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_read_slice(&path, from_offset, buffer)
    }

    fn store_read_all(&self, path: &impl Path) -> Result<Vec<u8>, RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_read_all(&path)
    }

    fn store_write<T: Path>(
        &mut self,
        path: &T,
        src: &[u8],
        at_offset: usize,
    ) -> Result<(), RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_write(&path, src, at_offset)
    }

    fn store_delete<T: Path>(&mut self, path: &T) -> Result<(), RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_delete(&path)
    }

    fn store_count_subkeys<T: Path>(&self, prefix: &T) -> Result<u64, RuntimeError> {
        let prefix = map_user_path(prefix)?;
        self.host.store_count_subkeys(&prefix)
    }

    fn store_move(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = map_user_path(from_path)?;
        let to_path = map_user_path(to_path)?;
        self.host.store_move(&from_path, &to_path)
    }

    fn store_copy(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = map_user_path(from_path)?;
        let to_path = map_user_path(to_path)?;
        self.host.store_copy(&from_path, &to_path)
    }

    fn reveal_preimage(
        &self,
        hash: &[u8; PREIMAGE_HASH_SIZE],
        destination: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        self.host.reveal_preimage(hash, destination)
    }

    fn store_value_size(&self, path: &impl Path) -> Result<usize, RuntimeError> {
        let path = map_user_path(path)?;
        self.host.store_value_size(&path)
    }

    fn mark_for_reboot(&mut self) -> Result<(), RuntimeError> {
        self.host.mark_for_reboot()
    }

    fn reveal_metadata(&self) -> RollupMetadata {
        self.host.reveal_metadata()
    }

    fn last_run_aborted(&self) -> Result<bool, RuntimeError> {
        self.host.last_run_aborted()
    }

    fn upgrade_failed(&self) -> Result<bool, RuntimeError> {
        self.host.upgrade_failed()
    }

    fn restart_forced(&self) -> Result<bool, RuntimeError> {
        self.host.restart_forced()
    }

    fn reboot_left(&self) -> Result<u32, RuntimeError> {
        self.host.reboot_left()
    }

    fn runtime_version(&self) -> Result<String, RuntimeError> {
        self.host.runtime_version()
    }
}

#[cfg(test)]
mod tests {

    use super::SequencerRuntime;
    use tezos_data_encoding_derive::BinWriter;
    use tezos_smart_rollup_host::{path::RefPath, runtime::Runtime};
    use tezos_smart_rollup_mock::MockHost;

    #[derive(BinWriter)]
    struct UserMessage {
        payload: u32,
    }

    impl UserMessage {
        fn new(payload: u32) -> UserMessage {
            UserMessage { payload }
        }
    }

    #[test]
    fn test_add_user_message() {
        let mut mock_host = MockHost::default();
        mock_host.add_external(UserMessage::new(1));
        mock_host.add_external(UserMessage::new(2));
        mock_host.add_external(UserMessage::new(3));

        let mut sequencer_runtime =
            SequencerRuntime::new(mock_host, crate::FilterBehavior::AllowAll, 1);

        let input = sequencer_runtime.read_input().unwrap();
        let SequencerRuntime { host, .. } = sequencer_runtime;

        assert!(input.is_none());
        assert!(host
            .store_has(&RefPath::assert_from(
                b"/__sequencer/delayed-inbox/elements/0"
            ))
            .unwrap()
            .is_some());
        assert!(host
            .store_has(&RefPath::assert_from(
                b"/__sequencer/delayed-inbox/elements/1"
            ))
            .unwrap()
            .is_some());
        assert!(host
            .store_has(&RefPath::assert_from(
                b"/__sequencer/delayed-inbox/elements/2"
            ))
            .unwrap()
            .is_some());
    }
}
