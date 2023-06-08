// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use crate::delayed_inbox::read_input;
use crate::routing::FilterBehavior;
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::RollupMetadata,
    path::{concat, Path, RefPath},
    runtime::{Runtime, RuntimeError, ValueType},
    Error,
};

/// The new root path of the user kernel
const USER_PATH: RefPath = RefPath::assert_from(b"/user_kernel_storage");

pub struct SequencerRuntime<R>
where
    R: Runtime,
{
    host: R,
    /// if true then the input is added to the delayed inbox
    input_predicate: FilterBehavior,
    /// maximum number of level a message can stay in the delayed inbox
    timeout_window: u32,
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
        Self {
            host,
            input_predicate,
            timeout_window,
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
        read_input(&mut self.host, self.input_predicate, self.timeout_window)
    }

    fn store_has<T: Path>(&self, path: &T) -> Result<Option<ValueType>, RuntimeError> {
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_has(&path)
    }

    fn store_read<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        max_bytes: usize,
    ) -> Result<Vec<u8>, RuntimeError> {
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_read(&path, from_offset, max_bytes)
    }

    fn store_read_slice<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        buffer: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_read_slice(&path, from_offset, buffer)
    }

    fn store_write<T: Path>(
        &mut self,
        path: &T,
        src: &[u8],
        at_offset: usize,
    ) -> Result<(), RuntimeError> {
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_write(&path, src, at_offset)
    }

    fn store_delete<T: Path>(&mut self, path: &T) -> Result<(), RuntimeError> {
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_delete(&path)
    }

    fn store_count_subkeys<T: Path>(&self, prefix: &T) -> Result<u64, RuntimeError> {
        let prefix = concat(&USER_PATH, prefix)
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_count_subkeys(&prefix)
    }

    fn store_move(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = concat(&USER_PATH, from_path)
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        let to_path = concat(&USER_PATH, to_path)
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        self.host.store_move(&from_path, &to_path)
    }

    fn store_copy(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = concat(&USER_PATH, from_path)
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
        let to_path = concat(&USER_PATH, to_path)
            .map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
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
        let path =
            concat(&USER_PATH, path).map_err(|_| RuntimeError::HostErr(Error::StoreInvalidKey))?;
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
    use crate::FilterBehavior;

    use super::SequencerRuntime;
    use tezos_data_encoding_derive::BinWriter;
    use tezos_smart_rollup_host::{
        path::{OwnedPath, RefPath},
        runtime::Runtime,
    };
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

    fn prepare() -> (SequencerRuntime<MockHost>, Vec<u8>, OwnedPath, OwnedPath) {
        let mock_host = MockHost::default();
        let sequencer_runtime = SequencerRuntime::new(mock_host, FilterBehavior::AllowAll, 5);

        let path_1 = OwnedPath::try_from("/test-1".to_string()).unwrap();
        let path_2 = OwnedPath::try_from("/test-2".to_string()).unwrap();
        let data = b"hello world".to_vec();

        (sequencer_runtime, data, path_1, path_2)
    }

    #[test]
    fn test_store_read_write() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let user_data = sequencer_runtime.store_read(&path, 0, data.len()).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let seq_data = host
            .store_read(
                &RefPath::assert_from(b"/user_kernel_storage/test-1"),
                0,
                data.len(),
            )
            .unwrap();

        assert_eq!(user_data, seq_data);
        assert_eq!(user_data, data);
    }

    #[test]
    fn test_store_has() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let user_is_present = sequencer_runtime.store_has(&path).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let sequencer_is_present = host
            .store_has(&RefPath::assert_from(b"/user_kernel_storage/test-1"))
            .unwrap();

        assert_eq!(user_is_present, sequencer_is_present);
        assert!(matches!(sequencer_is_present, Some(_)));
    }

    #[test]
    fn test_store_copy() {
        let (mut sequencer_runtime, data, path_1, path_2) = prepare();

        sequencer_runtime.store_write(&path_1, &data, 0).unwrap();
        sequencer_runtime.store_copy(&path_1, &path_2).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let data_1 = host
            .store_read(
                &RefPath::assert_from(b"/user_kernel_storage/test-1"),
                0,
                data.len(),
            )
            .unwrap();
        let data_2 = host
            .store_read(
                &RefPath::assert_from(b"/user_kernel_storage/test-2"),
                0,
                data.len(),
            )
            .unwrap();

        assert_eq!(data_1, data_2);
    }

    #[test]
    fn test_store_move() {
        let (mut sequencer_runtime, data, path_1, path_2) = prepare();

        sequencer_runtime.store_write(&path_1, &data, 0).unwrap();
        sequencer_runtime.store_move(&path_1, &path_2).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let data_1 = host.store_read(
            &RefPath::assert_from(b"/user_kernel_storage/test-1"),
            0,
            data.len(),
        );
        let data_2 = host
            .store_read(
                &RefPath::assert_from(b"/user_kernel_storage/test-2"),
                0,
                data.len(),
            )
            .unwrap();

        assert_eq!(data.to_vec(), data_2);
        assert!(data_1.is_err());
    }

    #[test]
    fn test_store_count_subkeys() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let user_subkeys = sequencer_runtime.store_count_subkeys(&path).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let sequencer_subkeys = host
            .store_count_subkeys(&RefPath::assert_from(b"/user_kernel_storage/test-1"))
            .unwrap();

        assert_eq!(user_subkeys, sequencer_subkeys);
    }

    #[test]
    fn test_store_delete() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let _ = sequencer_runtime.store_delete(&path);

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let data = host.store_read(
            &RefPath::assert_from(b"/user_kernel_storage/test-1"),
            0,
            data.len(),
        );

        assert!(data.is_err());
    }

    #[test]
    fn test_store_read_slice() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        // How to initialize a vector of a capacity of 11
        // Using Vec::with_capacity doesn't seem to work
        let mut buffer_1 = [0x00; 11];
        let mut buffer_2 = [0x00; 11];

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let _ = sequencer_runtime
            .store_read_slice(&path, 0, &mut buffer_1)
            .unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let _ = host
            .store_read_slice(
                &RefPath::assert_from(b"/user_kernel_storage/test-1"),
                0,
                &mut buffer_2,
            )
            .unwrap();

        assert_eq!(buffer_1, buffer_2);
        assert_eq!(buffer_1.to_vec(), data)
    }

    #[test]
    fn test_store_value_size() {
        let (mut sequencer_runtime, data, path, _) = prepare();

        sequencer_runtime.store_write(&path, &data, 0).unwrap();
        let user_size = sequencer_runtime.store_value_size(&path).unwrap();

        let SequencerRuntime { host, .. } = sequencer_runtime;
        let sequencer_size = host
            .store_value_size(&RefPath::assert_from(b"/user_kernel_storage/test-1"))
            .unwrap();

        assert_eq!(user_size, sequencer_size);
        assert_eq!(sequencer_size, data.len());
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
            .store_has(&RefPath::assert_from(b"/delayed-inbox/elements/0"))
            .unwrap()
            .is_some());
        assert!(host
            .store_has(&RefPath::assert_from(b"/delayed-inbox/elements/1"))
            .unwrap()
            .is_some());
        assert!(host
            .store_has(&RefPath::assert_from(b"/delayed-inbox/elements/2"))
            .unwrap()
            .is_some());
    }
}
