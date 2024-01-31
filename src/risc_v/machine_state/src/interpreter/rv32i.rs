//! Implementation of RV_32_I extension for RISC-V
//!
//! Chapter 2 - Unprivileged spec

use crate::{
    backend,
    registers::{XRegister, XRegisters},
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

    /// run "lui" instruction
    ///
    /// Set the upper 20 bits of the `rd` register to immediate value,
    /// Since `lui` is a `U-type` operation, the immediate is correctly formatted
    pub fn run_lui(&mut self, imm: i64, rd: XRegister) {
        self.write(rd, imm as u64);
    }
}

#[cfg(test)]
pub mod tests {
    use crate::{
        backend::tests::TestBackendFactory,
        create_backend, create_state,
        registers::{a2, a3, a4, XRegisters, XRegistersLayout},
    };
    use proptest::{prelude::any, prop_assert_eq, proptest};

    pub fn test<F: TestBackendFactory>() {
        test_lui::<F>();
    }

    fn test_lui<F: TestBackendFactory>() {
        proptest!(|(imm in any::<i64>())| {
            let mut backend = create_backend!(XRegistersLayout, F);
            let mut xregs = create_state!(XRegisters, F, backend);
            xregs.write(a2, 0);
            xregs.write(a4, 0);

            // U-type immediate sets imm[31:20]
            let imm = imm & 0xFFFF_F000;
            xregs.run_lui(imm, a3);
            // read value is the expected one
            prop_assert_eq!(xregs.read(a3), imm as u64);
            // it doesn't modify other registers
            prop_assert_eq!(xregs.read(a2), 0);
            prop_assert_eq!(xregs.read(a4), 0);
        });
    }
}
