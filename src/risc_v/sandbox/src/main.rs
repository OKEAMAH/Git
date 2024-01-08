use kernel_loader::Memory;
use rvemu::{emulator::Emulator, exception::Exception};
use std::{error::Error, fs};
use tezos_crypto_rs::hash::{ContractKt1Hash, ContractTz1Hash, HashTrait};
use tezos_smart_rollup_encoding::{
    contract::Contract,
    michelson::{ticket::UnitTicket, MichelsonBytes, MichelsonPair, MichelsonUnit},
    public_key_hash::PublicKeyHash,
    smart_rollup::SmartRollupAddress,
};

mod boot;
mod cli;
mod devicetree;
mod inbox;
mod input;
mod rv;
mod syscall;

/// Convert a RISC-V exception into an error.
pub fn exception_to_error(exc: Exception) -> Box<dyn Error> {
    format!("{:?}", exc).into()
}

fn main() -> Result<(), Box<dyn Error>> {
    let cli = cli::parse();

    let mut emu = Emulator::new();

    // Load the ELF binary into the emulator.
    let contents = std::fs::read(&cli.input)?;
    let initrd_addr = input::configure_emulator(&contents, &mut emu)?;

    // Load the initial ramdisk to memory.
    let initrd_info = cli
        .initrd
        .map(|initrd_path| -> Result<_, Box<dyn Error>> {
            let initrd = fs::read(initrd_path)?;
            emu.cpu.bus.write_bytes(initrd_addr, initrd.as_slice())?;
            Ok(devicetree::InitialRamDisk {
                start: initrd_addr,
                length: initrd.len() as u64,
            })
        })
        .transpose()?;

    // Generate and load the flattened device tree.
    let dtb_addr = initrd_info
        .as_ref()
        .map(|info| info.start + info.length)
        .unwrap_or(initrd_addr);
    let dtb = devicetree::generate(initrd_info)?;
    emu.cpu.bus.write_bytes(dtb_addr, dtb.as_slice())?;

    // Prepare the boot procedure
    boot::configure(&mut emu, dtb_addr);

    // Rollup metadata
    let meta = syscall::RollupMetadata {
        origination_level: cli.origination_level,
        address: SmartRollupAddress::from_b58check(cli.address.as_str()).unwrap(),
    };

    // Prepare inbox
    let mut inbox = inbox::InboxBuilder::new();
    {
        inbox
            .insert_transfer(
                ContractKt1Hash::from_base58_check("KT1EfTusMLoeCAAGd9MZJn5yKzFr6kJU5U91").unwrap(),
                PublicKeyHash::from_b58check("tz1dJ21ejKD17t7HKcKkTPuwQphgcSiehTYi").unwrap(),
                meta.address.clone(),
                MichelsonPair(
                    MichelsonBytes(
                        ContractTz1Hash::from_b58check("tz1dJ21ejKD17t7HKcKkTPuwQphgcSiehTYi")
                            .unwrap()
                            .0
                            .to_vec(),
                    ),
                    UnitTicket::new(
                        Contract::Originated(
                            ContractKt1Hash::from_base58_check(
                                "KT1EfTusMLoeCAAGd9MZJn5yKzFr6kJU5U91",
                            )
                            .unwrap(),
                        ),
                        MichelsonUnit,
                        100000000i32,
                    )
                    .unwrap(),
                ),
            )
            .insert_external([
                0u8, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 243, 130, 110, 10, 184, 55, 247, 199, 18,
                241, 91, 107, 191, 128, 66, 137, 15, 8, 203, 50, 164, 223, 209, 154, 177, 171, 26,
                12, 20, 58, 132, 68, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 136, 172, 140, 241, 223,
                197, 82, 180, 50, 239, 231, 211, 131, 131, 235, 175, 134, 97, 23, 65, 42, 30, 83,
                86, 158, 0, 136, 45, 70, 135, 112, 99, 108, 229, 143, 47, 78, 162, 120, 232, 173,
                219, 223, 96, 18, 200, 38, 224, 41, 173, 194, 216, 55, 32, 196, 151, 118, 201, 244,
                0, 141, 164, 131, 10, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 131, 132, 110, 221, 213,
                211, 197, 237, 150, 233, 98, 80, 98, 83, 149, 134, 73, 200, 74, 116, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 9, 1, 0, 0, 0, 0, 0, 0, 99, 111, 110, 115, 116, 32, 75, 69,
                89, 32, 61, 32, 34, 99, 111, 117, 110, 116, 101, 114, 34, 59, 10, 10, 99, 111, 110,
                115, 116, 32, 104, 97, 110, 100, 108, 101, 114, 32, 61, 32, 40, 41, 32, 61, 62, 32,
                123, 10, 32, 32, 108, 101, 116, 32, 99, 111, 117, 110, 116, 101, 114, 32, 61, 32,
                75, 118, 46, 103, 101, 116, 40, 75, 69, 89, 41, 59, 10, 32, 32, 99, 111, 110, 115,
                111, 108, 101, 46, 108, 111, 103, 40, 96, 67, 111, 117, 110, 116, 101, 114, 58, 32,
                36, 123, 99, 111, 117, 110, 116, 101, 114, 125, 96, 41, 59, 10, 32, 32, 105, 102,
                32, 40, 99, 111, 117, 110, 116, 101, 114, 32, 61, 61, 61, 32, 110, 117, 108, 108,
                41, 32, 123, 10, 32, 32, 32, 32, 99, 111, 117, 110, 116, 101, 114, 32, 61, 32, 48,
                59, 10, 32, 32, 125, 32, 101, 108, 115, 101, 32, 123, 10, 32, 32, 32, 32, 99, 111,
                117, 110, 116, 101, 114, 43, 43, 59, 10, 32, 32, 125, 10, 32, 32, 75, 118, 46, 115,
                101, 116, 40, 75, 69, 89, 44, 32, 99, 111, 117, 110, 116, 101, 114, 41, 59, 10, 32,
                32, 114, 101, 116, 117, 114, 110, 32, 110, 101, 119, 32, 82, 101, 115, 112, 111,
                110, 115, 101, 40, 41, 59, 10, 125, 59, 10, 10, 101, 120, 112, 111, 114, 116, 32,
                100, 101, 102, 97, 117, 108, 116, 32, 104, 97, 110, 100, 108, 101, 114, 59, 10,
                128, 150, 152, 0, 0, 0, 0, 0,
            ]);

        for _ in 0..1000 {
            inbox.insert_external([
                0u8, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 243, 130, 110, 10, 184, 55, 247, 199, 18,
                241, 91, 107, 191, 128, 66, 137, 15, 8, 203, 50, 164, 223, 209, 154, 177, 171, 26,
                12, 20, 58, 132, 68, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 99, 68, 105, 123, 156,
                205, 111, 10, 43, 242, 122, 51, 105, 137, 179, 200, 99, 160, 227, 12, 97, 105, 78,
                147, 174, 136, 61, 113, 70, 74, 71, 96, 115, 222, 207, 139, 113, 191, 155, 192, 65,
                147, 142, 26, 162, 110, 13, 73, 222, 61, 5, 128, 54, 56, 254, 25, 107, 18, 155, 26,
                51, 90, 64, 12, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 131, 132, 110, 221, 213, 211,
                197, 237, 150, 233, 98, 80, 98, 83, 149, 134, 73, 200, 74, 116, 1, 0, 0, 0, 0, 0,
                0, 0, 1, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 0, 116, 101, 122, 111, 115, 58, 47, 47,
                116, 122, 49, 85, 105, 86, 50, 67, 105, 111, 71, 85, 74, 114, 72, 109, 101, 82,
                111, 114, 97, 118, 56, 88, 104, 89, 86, 112, 102, 104, 87, 104, 101, 99, 107, 118,
                47, 4, 0, 0, 0, 0, 0, 0, 0, 80, 79, 83, 84, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            ]);
        }
    }
    let mut inbox = inbox.build();

    let handle_syscall = if cli.posix {
        fn dummy(
            emu: &mut Emulator,
            _: &syscall::RollupMetadata,
            _: &mut inbox::Inbox,
        ) -> Result<(), Box<dyn Error>> {
            syscall::handle_posix(emu)
        }
        dummy
    } else {
        syscall::handle_sbi
    };

    let mut prev_pc = emu.cpu.pc;
    let mut inbox_exhausted = false;

    while !inbox_exhausted || cli.keep_going {
        emu.cpu.devices_increment();

        if let Some(interrupt) = emu.cpu.check_pending_interrupt() {
            interrupt.take_trap(&mut emu.cpu);

            // We don't do anything with the devices at the moment. So we'll
            // just panic if they magically come alive.
            panic!("Interrupt {:?}", interrupt);
        }

        emu.cpu
            .execute()
            .map(|_| ())
            .or_else(|exception| -> Result<(), Box<dyn Error>> {
                match exception {
                    Exception::EnvironmentCallFromSMode | Exception::EnvironmentCallFromUMode => {
                        let inbox_level = inbox.level();
                        let inbox_empty = inbox.is_empty();

                        handle_syscall(&mut emu, &meta, &mut inbox).map_err(
                            |err| -> Box<dyn Error> {
                                format!("Failed to handle environment call at {prev_pc:x}: {}", err)
                                    .as_str()
                                    .into()
                            },
                        )?;

                        // This occurs when calling `next()` twice on an empty inbox.
                        inbox_exhausted = inbox_empty && inbox.level() > inbox_level;

                        // We need to update the program counter ourselves now.
                        // This is a recent change in behaviour in RVEmu.
                        emu.cpu.pc += 4;

                        Ok(())
                    }

                    _ => {
                        let trap = exception.take_trap(&mut emu.cpu);

                        // Don't bother handling other exceptions. For now they're
                        // all fatal.
                        panic!("Exception {:?} at {:#x}: {:?}", exception, prev_pc, trap)
                    }
                }
            })?;

        // If the program loops in place we assume it is stuck.
        if prev_pc == emu.cpu.pc {
            panic!("Stuck at {:#x}", prev_pc);
        }

        prev_pc = emu.cpu.pc;
    }

    Ok(())
}
