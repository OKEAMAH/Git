// SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

pub mod instruction;

use crate::instruction::Instr;
use core::ops::Range;

fn parse_uncompressed_instruction(bytes: u32) -> Instr {
    // TODO parse an uncompressed instruction
    Instr::Uncompressed { bytes }
}

fn parse_compressed_instruction(bytes: u16) -> Instr {
    // TODO parse a compressed instruction
    Instr::Compressed { bytes }
}

#[derive(Debug)]
pub enum ParserError {
    MisalignedBuffer,
    UnexpectedEndOfBuffer,
}

/// Attempt to parse `bytes` into an instruction. If `bytes` encodes a 2-byte
/// compressed instruction, parse it immediately. If it encodes a 4-byte
/// uncompressed instruction, request 2 extra bytes via `more`.
pub fn parse(
    bytes: u16,
    more: impl FnOnce() -> Result<u16, ParserError>,
) -> Result<Instr, ParserError> {
    if bytes & 0b11 != 0b11 {
        Ok(parse_compressed_instruction(bytes))
    } else {
        let upper = more()?;
        let combined = (upper as u32) << 16 | (bytes as u32);
        Ok(parse_uncompressed_instruction(combined))
    }
}

/// Transform a u8 iterator into a parsed instruction iterator
pub struct InstrIterator<'a, I>
where
    I: Iterator<Item = u8>,
{
    iter: &'a mut I,
}

impl<'a, I> InstrIterator<'a, I>
where
    I: Iterator<Item = u8>,
{
    fn new(iter: &'a mut I) -> Self {
        InstrIterator { iter }
    }
}

impl<'a, I> Iterator for InstrIterator<'a, I>
where
    I: Iterator<Item = u8>,
{
    type Item = Result<Instr, ParserError>;

    fn next(&mut self) -> Option<Self::Item> {
        match (self.iter.next(), self.iter.next()) {
            (Some(lower), Some(upper)) => {
                let c = u16::from_le_bytes([lower, upper]);
                let instr = parse(c, || match (self.iter.next(), self.iter.next()) {
                    (Some(lower), Some(upper)) => Ok(u16::from_le_bytes([lower, upper])),
                    (Some(_), None) => Err(ParserError::MisalignedBuffer),
                    (None, _) => Err(ParserError::UnexpectedEndOfBuffer),
                });
                Some(instr)
            }
            (Some(_), None) => Some(Err(ParserError::MisalignedBuffer)),
            (None, _) => None,
        }
    }
}

fn parse_block(bytes: &[u8]) -> Result<Vec<Instr>, ParserError> {
    let mut iter = bytes.iter().copied();
    let instructions: Result<Vec<Instr>, ParserError> = InstrIterator::new(&mut iter).collect();
    instructions
}

pub fn parse_segment(contents: &[u8], range: Range<usize>) -> Result<Vec<Instr>, ParserError> {
    parse_block(&contents[range])
}

#[cfg(test)]
mod tests {
    use super::*;
    use goblin::{
        elf::program_header::{PF_X, PT_LOAD},
        elf::Elf,
    };

    // rv64ui-p-addiw
    // 0000000080000000 <_start>:
    //     80000000:	0500006f          	jal	zero,80000050 <reset_vector>

    // 0000000080000004 <trap_vector>:
    //     80000004:	34202f73          	csrrs	t5,mcause,zero
    //     80000008:	00800f93          	addi	t6,zero,8
    #[test]
    fn test_1() {
        let bytes: [u8; 12] = [
            0x6f, 0x0, 0x0, 0x5, 0x73, 0x2f, 0x20, 0x34, 0x93, 0xf, 0x80, 0x0,
        ];

        let expected = [
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x6f, 0x0, 0x0, 0x5]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x73, 0x2f, 0x20, 0x34]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x93, 0xf, 0x80, 0x0]),
            },
        ];
        match parse_block(&bytes) {
            Ok(instructions) => {
                assert_eq!(instructions, expected)
            }
            Err(_) => panic!("Unexpected buffer size issue"),
        }
    }

    // rv64uc-p-rvc
    // 0000000080002190 <test_21>:
    // 80002190:	01500193          	addi	gp,zero,21
    // 80002194:	6405                	c.lui	s0,0x1
    // 80002196:	2344041b          	addiw	s0,s0,564 # 1234 <_start-0x7fffedcc>
    // 8000219a:	0412                	c.slli	s0,0x4
    // 8000219c:	000123b7          	lui	t2,0x12
    // 800021a0:	3403839b          	addiw	t2,t2,832 # 12340 <_start-0x7ffedcc0>
    // 800021a4:	12741063          	bne	s0,t2,800022c4 <fail>
    #[test]
    fn test_2() {
        let bytes: [u8; 24] = [
            0x93, 0x1, 0x50, 0x1, 0x5, 0x64, 0x1b, 0x4, 0x44, 0x23, 0x12, 0x4, 0xb7, 0x23, 0x1,
            0x0, 0x9b, 0x83, 0x3, 0x34, 0x63, 0x10, 0x74, 0x12,
        ];
        let expected = [
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x93, 0x1, 0x50, 0x1]),
            },
            Instr::Compressed {
                bytes: u16::from_le_bytes([0x05, 0x64]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x1b, 0x4, 0x44, 0x23]),
            },
            Instr::Compressed {
                bytes: u16::from_le_bytes([0x12, 0x04]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0xb7, 0x23, 0x1, 0x0]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x9b, 0x83, 0x3, 0x34]),
            },
            Instr::Uncompressed {
                bytes: u32::from_le_bytes([0x63, 0x10, 0x74, 0x12]),
            },
        ];
        match parse_block(&bytes) {
            Ok(instructions) => {
                assert_eq!(instructions, expected)
            }
            Err(_) => panic!("Unexpected buffer size issue"),
        }
    }

    #[test]
    fn test_3() {
        let bytes: [u8; 5] = [0x1, 0x5, 0x64, 0x1b, 0x4];
        match parse_block(&bytes) {
            Err(ParserError::MisalignedBuffer) => (),
            _ => {
                panic!("Expected MisalignedBuffer error")
            }
        }
    }

    #[test]
    fn test_4() {
        let bytes: [u8; 6] = [0x6f, 0x0, 0x0, 0x5, 0x73, 0x2f];
        match parse_block(&bytes) {
            Err(ParserError::UnexpectedEndOfBuffer) => (),
            _ => {
                panic!("Expected UnexpectedEndOfBuffer error")
            }
        }
    }

    #[test]
    fn parse_elf_file() {
        let contents = std::fs::read("../../../tezt/tests/riscv-tests/generated/rv64uc-p-rvc")
            .expect("Failed to read file");

        let elf = Elf::parse(&contents).expect("Failed to parse ELF file");

        let executable_segments = elf
            .program_headers
            .iter()
            .filter(|header| header.p_type == PT_LOAD && (header.p_flags & PF_X) != 0);

        for segment in executable_segments {
            println!("Offset: {} Size: {}", segment.p_offset, segment.p_filesz);
            let range = segment.file_range();
            match parse_segment(&contents, range) {
                Ok(_) => (),
                Err(_) => panic!("Unexpected buffer size issue"),
            }
        }
    }
}
