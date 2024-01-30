// SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use risc_v_machine_state::registers::XRegister;

#[derive(Debug, PartialEq)]
pub struct RTypeArgs {
    pub rd: XRegister,
    pub rs1: XRegister,
    pub rs2: XRegister,
}

#[derive(Debug, PartialEq)]
pub struct ITypeArgs {
    pub rd: XRegister,
    pub rs1: XRegister,
    pub imm: i64,
}

#[derive(Debug, PartialEq)]
pub struct SBTypeArgs {
    pub rs1: XRegister,
    pub rs2: XRegister,
    pub imm: i64,
}

#[derive(Debug, PartialEq)]
pub struct UJTypeArgs {
    pub rd: XRegister,
    pub imm: i64,
}

#[derive(Debug, PartialEq)]
pub enum Instr {
    // RV64I R-type instructions
    Add(RTypeArgs),
    Sub(RTypeArgs),
    Xor(RTypeArgs),
    Or(RTypeArgs),
    And(RTypeArgs),
    Sll(RTypeArgs),
    Srl(RTypeArgs),
    Sra(RTypeArgs),
    Slt(RTypeArgs),
    Sltu(RTypeArgs),
    Addw(RTypeArgs),
    Subw(RTypeArgs),
    Sllw(RTypeArgs),
    Srlw(RTypeArgs),
    Sraw(RTypeArgs),

    // RV64I I-type instructions
    Addi(ITypeArgs),
    Addiw(ITypeArgs),
    Xori(ITypeArgs),
    Ori(ITypeArgs),
    Andi(ITypeArgs),
    Slli(ITypeArgs),
    Srli(ITypeArgs),
    Srai(ITypeArgs),
    Slliw(ITypeArgs),
    Srliw(ITypeArgs),
    Sraiw(ITypeArgs),
    Slti(ITypeArgs),
    Sltiu(ITypeArgs),
    Lb(ITypeArgs),
    Lh(ITypeArgs),
    Lw(ITypeArgs),
    Lbu(ITypeArgs),
    Lhu(ITypeArgs),
    Lwu(ITypeArgs),
    Ld(ITypeArgs),
    Fence {
        // Section 2.7: The unused fields in the FENCE instructions (rs1 and rd)
        // are reserved for finer-grain fences in future extensions.
        // For forward compatibility, base implementations shall ignore these
        // fields, and standard software shall zero these fields.
        i_imm: i64,
    },
    Ecall,
    Ebreak,

    // RV64I S-type instructions
    Sb(SBTypeArgs),
    Sh(SBTypeArgs),
    Sw(SBTypeArgs),
    Sd(SBTypeArgs),

    // RV64I B-type instructions
    Beq(SBTypeArgs),
    Bne(SBTypeArgs),
    Blt(SBTypeArgs),
    Bge(SBTypeArgs),
    Bltu(SBTypeArgs),
    Bgeu(SBTypeArgs),

    // RV64I U-type instructions
    Lui(UJTypeArgs),
    Auipc(UJTypeArgs),

    // RV64I jump instructions
    Jal(UJTypeArgs),
    Jalr(ITypeArgs),

    // TODO placeholder for parsed compressed instruction
    Compressed {
        bytes: u16,
    },

    Unparsed_ {
        instr: u32,
    },
}
