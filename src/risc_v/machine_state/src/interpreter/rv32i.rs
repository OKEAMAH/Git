//! Implementation of RV_32_I extension for RISC-V
//!
//! Chapter 2 - Unprivileged spec

use crate::{
    backend,
    bus::Address,
    registers::{XRegister, XRegisters},
    HartState,
};

impl<M> XRegisters<M>
where
    M: backend::Manager,
{
    /// run "addi" instruction
    pub fn run_addi(&mut self, imm: i32, rs1: XRegister, rd: XRegister) {
        // Return the lower XLEN (64 bits in our case) bits of the multiplication
        // Irrespective of sign, the result is the same, casting to u64 for addition
        let rval = self.read(rs1);
        let result = rval.wrapping_add(imm as u64);
        self.write(rd, result);
    }
}

impl<M> HartState<M>
where
    M: backend::Manager,
{
    /// run "jalr" instruction
    ///
    /// Instruction mis-aligned will never be thrown because we allow C extension
    ///
    /// Returns the previous address before the target address jumped to (jump address - 4 bytes)
    pub fn run_jalr(&mut self, imm: i64, rs1: XRegister, rd: XRegister) -> Address {
        // Save the address after jump into rd
        let after_jump_addr = self.pc.read().wrapping_add(4);

        self.xregisters.write(rd, after_jump_addr);

        // The target address is obtained by adding the sign-extended
        // 12-bit I-immediate to the register rs1, then setting
        // the least-significant bit of the result to zero
        let target_addr = self.xregisters.read(rs1).wrapping_add(imm as u64) & !1;

        target_addr.wrapping_sub(4)
    }

    /// run "jal" instruction
    ///
    /// Instruction mis-aligned will never be thrown because we allow C extension
    ///
    /// Returns the previous address before the target address (jump address - 4 bytes)
    pub fn run_jal(&mut self, imm: i64, rd: XRegister) -> Address {
        // Save the address after jump into rd
        let current_pc = self.pc.read();

        let after_jump_addr = current_pc.wrapping_add(4);
        self.xregisters.write(rd, after_jump_addr);

        current_pc.wrapping_add(imm as u64).wrapping_sub(4)
    }
}
