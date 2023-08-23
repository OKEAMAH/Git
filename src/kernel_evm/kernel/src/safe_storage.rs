// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2023 Trilitech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_evm_logging::{log, Level};
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::RollupMetadata,
    path::{concat, OwnedPath, Path, RefPath},
    runtime::{Runtime, RuntimeError, ValueType},
    KERNEL_BOOT_PATH,
};

const BACKUP_KERNEL_BOOT_PATH: RefPath =
    RefPath::assert_from(b"/__backup_kernel/boot.wasm");

pub const TMP_PATH: RefPath = RefPath::assert_from(b"/tmp");

pub struct SafeStorage<Host>(pub Host);

pub fn safe_path<T: Path>(path: &T) -> Result<OwnedPath, RuntimeError> {
    concat(&TMP_PATH, path).map_err(|_| RuntimeError::PathNotFound)
}

impl<Host: Runtime> Runtime for SafeStorage<&mut Host> {
    fn write_output(&mut self, from: &[u8]) -> Result<(), RuntimeError> {
        self.0.write_output(from)
    }

    fn write_debug(&self, msg: &str) {
        self.0.write_debug(msg)
    }

    fn read_input(&mut self) -> Result<Option<Message>, RuntimeError> {
        self.0.read_input()
    }

    fn store_has<T: Path>(&self, path: &T) -> Result<Option<ValueType>, RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_has(&path)
    }

    fn store_read<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        max_bytes: usize,
    ) -> Result<Vec<u8>, RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_read(&path, from_offset, max_bytes)
    }

    fn store_read_slice<T: Path>(
        &self,
        path: &T,
        from_offset: usize,
        buffer: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_read_slice(&path, from_offset, buffer)
    }

    fn store_read_all(&self, path: &impl Path) -> Result<Vec<u8>, RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_read_all(&path)
    }

    fn store_write<T: Path>(
        &mut self,
        path: &T,
        src: &[u8],
        at_offset: usize,
    ) -> Result<(), RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_write(&path, src, at_offset)
    }

    fn store_write_all<T: Path>(
        &mut self,
        path: &T,
        src: &[u8],
    ) -> Result<(), RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_write_all(&path, src)
    }

    fn store_delete<T: Path>(&mut self, path: &T) -> Result<(), RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_delete(&path)
    }

    fn store_delete_value<T: Path>(&mut self, path: &T) -> Result<(), RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_delete_value(&path)
    }

    fn store_count_subkeys<T: Path>(&self, prefix: &T) -> Result<u64, RuntimeError> {
        let prefix = safe_path(prefix)?;
        self.0.store_count_subkeys(&prefix)
    }

    fn store_move(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = safe_path(from_path)?;
        let to_path = safe_path(to_path)?;
        self.0.store_move(&from_path, &to_path)
    }

    fn store_copy(
        &mut self,
        from_path: &impl Path,
        to_path: &impl Path,
    ) -> Result<(), RuntimeError> {
        let from_path = safe_path(from_path)?;
        let to_path = safe_path(to_path)?;
        self.0.store_copy(&from_path, &to_path)
    }

    fn reveal_preimage(
        &self,
        hash: &[u8; PREIMAGE_HASH_SIZE],
        destination: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        self.0.reveal_preimage(hash, destination)
    }

    fn store_value_size(&self, path: &impl Path) -> Result<usize, RuntimeError> {
        let path = safe_path(path)?;
        self.0.store_value_size(&path)
    }

    fn mark_for_reboot(&mut self) -> Result<(), RuntimeError> {
        self.0.mark_for_reboot()
    }

    fn reveal_metadata(&self) -> RollupMetadata {
        self.0.reveal_metadata()
    }

    #[cfg(all(feature = "alloc", feature = "proto-alpha"))]
    fn reveal_dal_page(
        &self,
        published_level: i32,
        slot_index: u8,
        page_index: i16,
        destination: &mut [u8],
    ) -> Result<usize, RuntimeError> {
        self.0
            .reveal_dal_page(published_level, slot_index, page_index, destination)
    }

    fn last_run_aborted(&self) -> Result<bool, RuntimeError> {
        self.0.last_run_aborted()
    }

    fn upgrade_failed(&self) -> Result<bool, RuntimeError> {
        self.0.upgrade_failed()
    }

    fn restart_forced(&self) -> Result<bool, RuntimeError> {
        self.0.restart_forced()
    }

    fn reboot_left(&self) -> Result<u32, RuntimeError> {
        self.0.reboot_left()
    }

    fn runtime_version(&self) -> Result<String, RuntimeError> {
        self.0.runtime_version()
    }
}

impl<Host: Runtime> SafeStorage<&mut Host> {
    fn backup_current_kernel(&mut self) -> Result<(), RuntimeError> {
        // Fallback preparation detected
        // Storing the current kernel boot path under a temporary path in
        // order to fallback on it if something goes wrong in the upcoming
        // upgraded kernel.
        log!(
            self.0,
            Level::Info,
            "Preparing potential fallback by backing up the current kernel."
        );
        self.0
            .store_copy(&KERNEL_BOOT_PATH, &BACKUP_KERNEL_BOOT_PATH)
    }

    pub fn fallback_backup_kernel(&mut self) -> Result<(), RuntimeError> {
        log!(
            self.0,
            Level::Info,
            "Something went wrong, fallback mechanism is triggered."
        );
        self.0
            .store_move(&BACKUP_KERNEL_BOOT_PATH, &KERNEL_BOOT_PATH)
    }

    fn clean_backup_kernel(&mut self) -> Result<(), RuntimeError> {
        log!(self.0, Level::Info, "Cleaning the backup kernel.");
        self.0.store_delete(&BACKUP_KERNEL_BOOT_PATH)
    }

    pub fn promote_upgrade(&mut self) -> Result<(), RuntimeError> {
        let safe_kernel_boot_path = safe_path(&KERNEL_BOOT_PATH)?;
        match self.0.store_read(&safe_kernel_boot_path, 0, 0) {
            Ok(_) => {
                // Upgrade detected
                log!(self, Level::Info, "Upgrade activated.");
                self.backup_current_kernel()?;
                self.0.store_move(&safe_kernel_boot_path, &KERNEL_BOOT_PATH)
            }
            Err(_) => {
                // No on-going upgrade detected
                if self.0.store_read(&BACKUP_KERNEL_BOOT_PATH, 0, 0).is_ok() {
                    self.clean_backup_kernel()?
                };
                Ok(())
            }
        }
    }

    pub fn promote(&mut self, path: &impl Path) -> Result<(), RuntimeError> {
        self.0.store_move(&TMP_PATH, path)
    }

    pub fn revert(&mut self) -> Result<(), RuntimeError> {
        self.0.store_delete(&TMP_PATH)
    }
}
