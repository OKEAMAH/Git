// SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

pub mod instruction;

use crate::instruction::Instr;
use core::ops::Range;

use risc_v_machine_state::registers::XRegister;

fn xregister(r: u32) -> XRegister {
    use XRegister::*;
    match r {
        0b0_0000 => x0,  // zero
        0b0_0001 => x1,  // ra
        0b0_0010 => x2,  // sp
        0b0_0011 => x3,  // gp
        0b0_0100 => x4,  // tp
        0b0_0101 => x5,  // t0
        0b0_0110 => x6,  // t1
        0b0_0111 => x7,  // t2
        0b0_1000 => x8,  // s0 or fp
        0b0_1001 => x9,  // s1
        0b0_1010 => x10, // a0
        0b0_1011 => x11, // a1
        0b0_1100 => x12, // a2
        0b0_1101 => x13, // a3
        0b0_1110 => x14, // a4
        0b0_1111 => x15, // a5
        0b1_0000 => x16, // a6
        0b1_0001 => x17, // a7
        0b1_0010 => x18, // s2
        0b1_0011 => x19, // s3
        0b1_0100 => x20, // s4
        0b1_0101 => x21, // s5
        0b1_0110 => x22, // s6
        0b1_0111 => x23, // s7
        0b1_1000 => x24, // s8
        0b1_1001 => x25, // s9
        0b1_1010 => x26, // s10
        0b1_1011 => x27, // s11
        0b1_1100 => x28, // t3
        0b1_1101 => x29, // t4
        0b1_1110 => x30, // t5
        0b1_1111 => x31, // t6
        _ => panic!("Invalid register"),
    }
}

// Bit matching functions adapted from `rvsim`
// https://docs.rs/crate/rvsim/0.2.2/source/src/cpu/op.in.rs

#[inline(always)]
fn opcode(instr: u32) -> u32 {
    instr & 0b0000_0000_0000_0000_0000_0000_0111_1111
}

#[inline(always)]
fn funct3(instr: u32) -> u32 {
    (instr & 0b0000_0000_0000_0000_0111_0000_0000_0000) >> 12
}

#[inline(always)]
fn funct7(instr: u32) -> u32 {
    (instr & 0b1111_1110_0000_0000_0000_0000_0000_0000) >> 25
}

#[inline(always)]
fn rd(instr: u32) -> u32 {
    (instr & 0b0000_0000_0000_0000_0000_1111_1000_0000) >> 7
}

#[inline(always)]
fn rs1(instr: u32) -> u32 {
    (instr & 0b0000_0000_0000_1111_1000_0000_0000_0000) >> 15
}

#[inline(always)]
fn rs2(instr: u32) -> u32 {
    (instr & 0b0000_0001_1111_0000_0000_0000_0000_0000) >> 20
}

#[inline(always)]
fn imm_5_11(instr: u32) -> u32 {
    (instr & 0b1111_1110_0000_0000_0000_0000_0000_0000) >> 25
}

#[inline(always)]
fn imm_6_11(instr: u32) -> u32 {
    (instr & 0b1111_1100_0000_0000_0000_0000_0000_0000) >> 26
}

// When producing immediates, sign extension is performed by casting to i64

fn i_imm(instr: u32) -> i64 {
    ((instr & 0b1111_1111_1111_0000_0000_0000_0000_0000) as i64) >> 20
}

fn s_imm(instr: u32) -> i64 {
    (((instr & 0b0000_0000_0000_0000_0000_1111_1000_0000) as i64) >> 7)
        | (((instr & 0b1111_1110_0000_0000_0000_0000_0000_0000) as i64) >> 20)
}

fn b_imm(instr: u32) -> i64 {
    (((instr & 0b0000_0000_0000_0000_0000_1111_0000_0000) as i64) >> 7)
        | (((instr & 0b0111_1110_0000_0000_0000_0000_0000_0000) as i64) >> 20)
        | (((instr & 0b0000_0000_0000_0000_0000_0000_1000_0000) as i64) << 4)
        | (((instr & 0b1000_0000_0000_0000_0000_0000_0000_0000) as i64) >> 19)
}

fn u_imm(instr: u32) -> i64 {
    (instr & 0b1111_1111_1111_1111_1111_0000_0000_0000) as i64
}

fn j_imm(instr: u32) -> i64 {
    (((instr & 0b0111_1111_1110_0000_0000_0000_0000_0000) as i64) >> 20)
        | (((instr & 0b0000_0000_0001_0000_0000_0000_0000_0000) as i64) >> 9)
        | ((instr & 0b0000_0000_0000_1111_1111_0000_0000_0000) as i64)
        | (((instr & 0b1000_0000_0000_0000_0000_0000_0000_0000) as i64) >> 11)
}

macro_rules! r_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::RTypeArgs {
            rd: xregister(rd($instr)),
            rs1: xregister(rs1($instr)),
            rs2: xregister(rs2($instr)),
        })
    };
}

macro_rules! i_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::ITypeArgs {
            rd: xregister(rd($instr)),
            rs1: xregister(rs1($instr)),
            imm: i_imm($instr),
        })
    };
}

macro_rules! s_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::SBTypeArgs {
            rs1: xregister(rs1($instr)),
            rs2: xregister(rs2($instr)),
            imm: s_imm($instr),
        })
    };
}

macro_rules! b_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::SBTypeArgs {
            rs1: xregister(rs1($instr)),
            rs2: xregister(rs2($instr)),
            imm: b_imm($instr),
        })
    };
}

macro_rules! u_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::UJTypeArgs {
            rd: xregister(rd($instr)),
            imm: u_imm($instr),
        })
    };
}

macro_rules! j_instr {
    ($enum_variant:ident, $instr:expr) => {
        $enum_variant(instruction::UJTypeArgs {
            rd: xregister(rd($instr)),
            imm: j_imm($instr),
        })
    };
}

fn parse_uncompressed_instruction(instr: u32) -> Instr {
    use Instr::*;
    match opcode(instr) {
        // R-type instructions
        0b011_0011 => match funct3(instr) {
            0b000 => match funct7(instr) {
                0b0 => r_instr!(Add, instr),
                0b010_0000 => r_instr!(Sub, instr),
                _ => Unparsed_ { instr },
            },
            0b100 => r_instr!(Xor, instr),
            0b110 => r_instr!(Or, instr),
            0b111 => r_instr!(And, instr),
            0b001 => r_instr!(Sll, instr),
            0b101 => match funct7(instr) {
                0b0 => r_instr!(Srl, instr),
                0b010_0000 => r_instr!(Sra, instr),
                _ => Unparsed_ { instr },
            },
            0b010 => r_instr!(Slt, instr),
            0b011 => r_instr!(Sltu, instr),
            _ => Unparsed_ { instr },
        },
        0b011_1011 => match funct3(instr) {
            0b000 => match funct7(instr) {
                0b0 => r_instr!(Addw, instr),
                0b010_0000 => r_instr!(Subw, instr),
                _ => Unparsed_ { instr },
            },
            0b001 => r_instr!(Sllw, instr),
            0b101 => match funct7(instr) {
                0b0 => r_instr!(Srlw, instr),
                0b010_0000 => r_instr!(Sraw, instr),
                _ => Unparsed_ { instr },
            },
            _ => Unparsed_ { instr },
        },

        // I-type instructions
        0b001_0011 => match funct3(instr) {
            0b000 => i_instr!(Addi, instr),
            0b100 => i_instr!(Xori, instr),
            0b110 => i_instr!(Ori, instr),
            0b111 => i_instr!(Andi, instr),
            0b001 => i_instr!(Slli, instr),
            0b101 => match imm_6_11(instr) {
                // imm[6:11] -> type of shift, imm[0:5] -> shift amount
                0b00_0000 => i_instr!(Srli, instr),
                0b01_0000 => i_instr!(Srai, instr),
                _ => Unparsed_ { instr },
            },
            0b010 => i_instr!(Slti, instr),
            0b011 => i_instr!(Sltiu, instr),
            _ => Unparsed_ { instr },
        },
        0b000_0011 => match funct3(instr) {
            0b000 => i_instr!(Lb, instr),
            0b001 => i_instr!(Lh, instr),
            0b010 => i_instr!(Lw, instr),
            0b100 => i_instr!(Lbu, instr),
            0b101 => i_instr!(Lhu, instr),
            0b110 => i_instr!(Lwu, instr),
            0b011 => i_instr!(Ld, instr),
            _ => Unparsed_ { instr },
        },
        0b001_1011 => match funct3(instr) {
            0b000 => i_instr!(Addiw, instr),
            0b001 => i_instr!(Slliw, instr),
            0b101 => match imm_5_11(instr) {
                // imm[5:11] -> type of shift, imm[0:4] -> shift amount
                0b000_0000 => i_instr!(Srliw, instr),
                0b010_0000 => i_instr!(Sraiw, instr),
                _ => Unparsed_ { instr },
            },
            _ => Unparsed_ { instr },
        },
        0b000_1111 => match funct3(instr) {
            0b000 => Fence {
                i_imm: i_imm(instr),
            },
            _ => Unparsed_ { instr },
        },
        0b111_0011 => match funct3(instr) {
            0b000 => match funct7(instr) {
                0b0 => Ecall,
                0b1 => Ebreak,
                _ => Unparsed_ { instr },
            },
            _ => Unparsed_ { instr },
        },

        // S-type instructions
        0b010_0011 => match funct3(instr) {
            0b000 => s_instr!(Sb, instr),
            0b001 => s_instr!(Sh, instr),
            0b010 => s_instr!(Sw, instr),
            0b011 => s_instr!(Sd, instr),
            _ => Unparsed_ { instr },
        },

        // B-type instructions
        0b110_0011 => match funct3(instr) {
            0b000 => b_instr!(Beq, instr),
            0b001 => b_instr!(Bne, instr),
            0b100 => b_instr!(Blt, instr),
            0b101 => b_instr!(Bge, instr),
            0b110 => b_instr!(Bltu, instr),
            0b111 => b_instr!(Bgeu, instr),
            _ => Unparsed_ { instr },
        },

        // U-type instructions
        0b011_0111 => u_instr!(Lui, instr),
        0b001_0111 => u_instr!(Auipc, instr),

        // Jump instructions
        0b110_1111 => j_instr!(Jal, instr),
        0b110_0111 => match funct3(instr) {
            0b000 => i_instr!(Jalr, instr),
            _ => Unparsed_ { instr },
        },
        _ => Unparsed_ { instr },
    }
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
    use crate::{
        instruction::{ITypeArgs, SBTypeArgs, UJTypeArgs},
        XRegister::*,
    };
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
            Instr::Jal(UJTypeArgs { rd: x0, imm: 0x50 }),
            Instr::Unparsed_ {
                instr: u32::from_le_bytes([0x73, 0x2f, 0x20, 0x34]),
            },
            Instr::Addi(ITypeArgs {
                rd: x31,
                rs1: x0,
                imm: 0x8,
            }),
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
            Instr::Addi(ITypeArgs {
                rd: x3,
                rs1: x0,
                imm: 21,
            }),
            Instr::Compressed {
                bytes: u16::from_le_bytes([0x05, 0x64]),
            },
            Instr::Addiw(ITypeArgs {
                rd: x8,
                rs1: x8,
                imm: 564,
            }),
            Instr::Compressed {
                bytes: u16::from_le_bytes([0x12, 0x04]),
            },
            Instr::Lui(UJTypeArgs {
                rd: x7,
                imm: 0x12 << 12,
            }),
            Instr::Addiw(ITypeArgs {
                rd: x7,
                rs1: x7,
                imm: 832,
            }),
            Instr::Bne(SBTypeArgs {
                rs1: x8,
                rs2: x7,
                imm: 288,
            }),
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
