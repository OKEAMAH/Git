use crate::{
    backend,
    registers::{self},
    HartState,
};

/// Implementation of M extension for RISC-V
/// Section 7.2 Unprivileged spec
impl<M> HartState<M>
where
    M: backend::Manager,
{
    /// run "mul" instruction
    pub fn run_mul(
        &mut self,
        rs1: registers::XRegister,
        rs2: registers::XRegister,
        rd: registers::XRegister,
    ) {
        // Return the lower XLEN (64 bits in our case) bits of the multiplication
        // Irrespective of sign, the result is the same, casting to u64 to fix behaviour
        let lhs = self.xregisters.read(rs1);
        let rhs = self.xregisters.read(rs2);
        let result = lhs.wrapping_mul(rhs);
        self.xregisters.write(rd, result);
    }

    /// run "div" instruction
    pub fn run_div(
        &mut self,
        rs1: registers::XRegister,
        rs2: registers::XRegister,
        rd: registers::XRegister,
    ) {
        let dividend = self.xregisters.read(rs1) as i64;
        let divisor = self.xregisters.read(rs2) as i64;
        let result = if divisor == 0 {
            // Division by zero, return all bits set to 1
            !0
        } else if divisor == -1 && dividend == i64::MIN {
            // Overflow, return dividend
            dividend as u64
        } else {
            // division of rs1 by rs2, rounding towards zero
            dividend.wrapping_div(divisor) as u64
        };

        self.xregisters.write(rd, result);
    }
}
