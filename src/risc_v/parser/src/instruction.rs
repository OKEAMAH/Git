// SPDX-FileCopyrightText: 2024 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

#[derive(Debug, PartialEq)]
pub enum Instr {
    // TODO placeholder for parsed uncompressed instruction
    Uncompressed { bytes: u32 },
    // TODO placeholder for parsed compressed instruction
    Compressed { bytes: u16 },
}
