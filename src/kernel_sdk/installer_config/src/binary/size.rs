// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_smart_rollup_core::MAX_OUTPUT_SIZE;
use tezos_smart_rollup_host::path::PATH_MAX_SIZE;

use super::instr::{
    ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction, RawBytes,
    RawPath, RevealInstruction, SetInstruction,
};

// https://stackoverflow.com/questions/53619695/calculating-maximum-value-of-a-set-of-constant-expressions-at-compile-time
const fn max(a: usize, b: usize) -> usize {
    [a, b][(a < b) as usize]
}

/// This trait is auxiliary one,
/// which is needed to estimate maximum possible size of config instruction,
/// in order to allocate buffer of statically known size,
/// which would fit one instruction.
pub trait EncodingSize {
    const MAX_SIZE: usize;
}

impl<'a> EncodingSize for RawPath<'a> {
    const MAX_SIZE: usize = 4 + PATH_MAX_SIZE;
}

impl<'a> EncodingSize for RawBytes<'a> {
    const MAX_SIZE: usize = 4 + MAX_OUTPUT_SIZE;
}

impl<'a> EncodingSize for CopyInstruction<'a> {
    const MAX_SIZE: usize = RawPath::MAX_SIZE * 2;
}

impl<'a> EncodingSize for MoveInstruction<'a> {
    const MAX_SIZE: usize = RawPath::MAX_SIZE * 2;
}

impl<'a> EncodingSize for DeleteInstruction<'a> {
    const MAX_SIZE: usize = RawPath::MAX_SIZE;
}

impl<'a> EncodingSize for SetInstruction<'a> {
    const MAX_SIZE: usize = RawPath::MAX_SIZE + RawBytes::MAX_SIZE;
}

impl<'a> EncodingSize for RevealInstruction<'a> {
    const MAX_SIZE: usize = RawBytes::MAX_SIZE + RawPath::MAX_SIZE;
}

impl<'a> EncodingSize for ConfigInstruction<'a> {
    const MAX_SIZE: usize = 1 + max(
        max(SetInstruction::MAX_SIZE, RevealInstruction::MAX_SIZE),
        max(
            max(CopyInstruction::MAX_SIZE, MoveInstruction::MAX_SIZE),
            DeleteInstruction::MAX_SIZE,
        ),
    );
}
