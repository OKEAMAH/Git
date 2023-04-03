use installer_config::instr::{ConfigInstruction, ValueSource};
use tezos_smart_rollup_core::{MAX_FILE_CHUNK_SIZE, PREIMAGE_HASH_SIZE};
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
        ConfigInstruction::Set(instr) => match instr.value {
            ValueSource::Path(p) => {
                let from_path: RefPath = p.into();
                let value_size = host
                    .store_value_size(&from_path)
                    .map_err(|_| "Failed to read reading value size")?;
                let to_path: RefPath = instr.to.into();
                let mut buffer = [0u8; MAX_FILE_CHUNK_SIZE];
                let mut offset = 0;
                while offset < value_size {
                    let read_bytes =
                        Runtime::store_read_slice(host, &from_path, offset, &mut buffer)
                            .map_err(|_| {
                                "Failed to read chunk in ConfigInstruction::Set"
                            })?;
                    Runtime::store_write(host, &to_path, &buffer[..read_bytes], offset)
                        .map_err(|_| "Failed to write chunk in ConfigInstruction::Set")?;
                    offset += read_bytes;
                }
                Ok(())
            }
            ValueSource::Value(v) => {
                let to: RefPath = instr.to.into();
                Runtime::store_write(host, &to, v.0, 0)
                    .map_err(|_| "Failed to handle ConfigInstruction::Set")
            }
        },
        ConfigInstruction::Reveal(instr) => match instr.hash {
            ValueSource::Path(p) => {
                let to_path: RefPath = p.into();
                let hash_size = host
                    .store_value_size(&to_path)
                    .map_err(|_| "Failed to read hash size")?;
                if hash_size != PREIMAGE_HASH_SIZE {
                    Err("Hash size in revel instruction is not equal to 33 bytes")
                } else {
                    let mut preimage = [0u8; PREIMAGE_HASH_SIZE];
                    let to: RefPath = instr.to.into();
                    Runtime::store_read_slice(host, &to_path, 0, &mut preimage)
                        .map_err(|_| "Failed to read root preimage")?;
                    reveal_root_hash(host, &preimage, to)
                }
            }
            ValueSource::Value(v) => {
                let to_path: RefPath = instr.to.into();
                reveal_root_hash(host, &v.into(), to_path)
            }
        },
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
