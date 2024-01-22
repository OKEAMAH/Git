// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::error::Error;
use crate::error::UpgradeProcessError;
use tezos_evm_logging::{log, Level::*};
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_host::runtime::Runtime;
use tezos_smart_rollup_installer_config::binary::promote::upgrade_reveal_flow;

pub fn upgrade_kernel<Host: Runtime>(
    host: &mut Host,
    root_hash: [u8; PREIMAGE_HASH_SIZE],
) -> Result<(), Error> {
    log!(host, Info, "Kernel upgrade initialisation.");

    let config = upgrade_reveal_flow(root_hash);
    config
        .evaluate(host)
        .map_err(UpgradeProcessError::InternalUpgrade)?;

    log!(host, Info, "Kernel is ready to be upgraded.");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::OsString;
    use std::fs;
    use std::path::Path;
    use tezos_smart_rollup_encoding::dac::{prepare_preimages, PreimageHash};
    use tezos_smart_rollup_host::KERNEL_BOOT_PATH;
    use tezos_smart_rollup_mock::MockHost;

    fn preliminary_upgrade(host: &mut MockHost) -> (PreimageHash, Vec<u8>) {
        let upgrade_to = OsString::from("tests/resources/debug_kernel.wasm");
        let upgrade_to = Path::new(&upgrade_to);

        // Preimages preparation

        let original_kernel = fs::read(upgrade_to).unwrap();
        let save_preimages = |_hash: PreimageHash, preimage: Vec<u8>| {
            host.set_preimage(preimage);
        };
        (
            prepare_preimages(&original_kernel, save_preimages).unwrap(),
            original_kernel,
        )
    }

    #[test]
    // Test if we manage to upgrade the kernel from the actual one to
    // the debug kernel one from `tests/resources/debug_kernel.wasm`.
    fn test_kernel_upgrade() {
        let mut host = MockHost::default();
        let (root_hash, original_kernel) = preliminary_upgrade(&mut host);
        upgrade_kernel(&mut host, root_hash.into())
            .expect("Kernel upgrade must succeed.");

        let boot_kernel = host.store_read_all(&KERNEL_BOOT_PATH).unwrap();
        assert_eq!(original_kernel, boot_kernel);
    }
}
