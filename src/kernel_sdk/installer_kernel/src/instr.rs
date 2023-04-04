use installer_config::instr::ConfigInstruction;
use tezos_smart_rollup_host::{path::RefPath, runtime::Runtime};

use crate::preimage::reveal_root_hash;
use crate::KERNEL_BOOT_PATH;

pub fn read_instruction(
    host: &impl Runtime,
    offset: &mut usize,
    mut buffer: &mut [u8],
) -> Result<(), &'static str> {
    while !buffer.is_empty() {
        let read_size =
            Runtime::store_read_slice(host, &KERNEL_BOOT_PATH, *offset, buffer)
                .map_err(|_| "Failed to read kernel boot path in read_instruction")?;
        *offset += read_size;
        buffer = &mut buffer[read_size..];
    }
    Ok(())
}

pub fn handle_instruction(
    host: &mut impl Runtime,
    instr: ConfigInstruction,
) -> Result<(), &'static str> {
    match instr {
        ConfigInstruction::Set(instr) => {
            let to: RefPath = instr.to.into();
            Runtime::store_write(host, &to, instr.value.0, 0)
                .map_err(|_| "Failed to handle ConfigInstruction::Set")
        }
        ConfigInstruction::Reveal(instr) => {
            let to_path: RefPath = instr.to.into();
            reveal_root_hash(host, &instr.hash.into(), to_path)
        }
        ConfigInstruction::Copy(instr) => {
            let from_path: RefPath = instr.from.into();
            let to_path: RefPath = instr.to.into();
            Runtime::store_copy(host, &from_path, &to_path)
                .map_err(|_| "Couldn't copy path during config application")
        }
        ConfigInstruction::Move(instr) => {
            let from_path: RefPath = instr.from.into();
            let to_path: RefPath = instr.to.into();
            Runtime::store_move(host, &from_path, &to_path)
                .map_err(|_| "Couldn't move path during config application")
        }
        ConfigInstruction::Delete(instr) => {
            let path: RefPath = instr.path.into();
            Runtime::store_delete(host, &path)
                .map_err(|_| "Couldn't delete path during config application")
        }
    }
}
