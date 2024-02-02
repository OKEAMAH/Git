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

    /// run `AUIPC` instruction (U-type)
    pub fn run_auipc(&mut self, imm: i64, rd: XRegister) {
        // U-type immediates have bits [31:20] set and the lower 20 zeroed.
        let rval = self.pc.read().wrapping_add(imm as u64);
        self.xregisters.write(rd, rval);
    }
}

#[cfg(test)]
pub mod tests {
    use crate::{
        backend::tests::TestBackendFactory,
        create_backend, create_state,
        registers::{a0, a1, a2, t5, t6},
        HartState, HartStateLayout,
    };

    pub fn test<F: TestBackendFactory>() {
        test_auipc::<F>();
    }

    fn test_auipc<F: TestBackendFactory>() {
        let pc_imm_res_rd = [
            (0, 0, 0, a2),
            (0, 0xFF_FFF0_0000, 0xFF_FFF0_0000, a0),
            (0x000A_AAAA, 0xFF_FFF0_0000, 0xFF_FFFA_AAAA, a1),
            (0xABCD_AAAA_FBC0_D3FE, 0, 0xABCD_AAAA_FBC0_D3FE, t5),
            (0xFFFF_FFFF_FFF0_0000, 0x10_0000, 0, t6),
        ];

        for (init_pc, imm, res, rd) in pc_imm_res_rd {
            let mut backend = create_backend!(HartStateLayout, F);
            let mut state = create_state!(HartState, F, backend);

            // Keep only bits [31:20] and then sign-extend back to 64 bits
            let u_imm = ((imm >> 20) & 0xF_FFFF) << 20;
            assert_eq!(imm, u_imm);
            println!("pc: {init_pc:x}, imm: {imm:x}, res: {res:x}");

            state.pc.write(init_pc);
            state.run_auipc(imm, rd);

            let read_pc = state.xregisters.read(rd);

            assert_eq!(read_pc, res);
        }
    }
}
