// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_smart_rollup_core::MAX_OUTPUT_SIZE;
use tezos_smart_rollup_host::path::PATH_MAX_SIZE;

use super::{
    instr::{
        ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction, RefBytes,
        RefRawPath, RevealInstruction, SetInstruction,
    },
    RefConfigInstruction,
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

impl<'a> EncodingSize for RefRawPath<'a> {
    const MAX_SIZE: usize = 4 + PATH_MAX_SIZE;
}

impl<'a> EncodingSize for RefBytes<'a> {
    const MAX_SIZE: usize = 4 + MAX_OUTPUT_SIZE;
}

impl<P: EncodingSize> EncodingSize for CopyInstruction<P> {
    const MAX_SIZE: usize = P::MAX_SIZE * 2;
}

impl<P: EncodingSize> EncodingSize for MoveInstruction<P> {
    const MAX_SIZE: usize = P::MAX_SIZE * 2;
}

impl<P: EncodingSize> EncodingSize for DeleteInstruction<P> {
    const MAX_SIZE: usize = P::MAX_SIZE;
}

impl<P: EncodingSize, B: EncodingSize> EncodingSize for SetInstruction<P, B> {
    const MAX_SIZE: usize = P::MAX_SIZE + B::MAX_SIZE;
}

impl<P: EncodingSize, B: EncodingSize> EncodingSize for RevealInstruction<P, B> {
    const MAX_SIZE: usize = P::MAX_SIZE + B::MAX_SIZE;
}

impl<P: EncodingSize, B: EncodingSize> EncodingSize for ConfigInstruction<P, B> {
    const MAX_SIZE: usize = 1 + max(
        max(
            SetInstruction::<P, B>::MAX_SIZE,
            RevealInstruction::<P, B>::MAX_SIZE,
        ),
        max(
            max(
                CopyInstruction::<P>::MAX_SIZE,
                MoveInstruction::<P>::MAX_SIZE,
            ),
            DeleteInstruction::<P>::MAX_SIZE,
        ),
    );
}

impl<'a> EncodingSize for RefConfigInstruction<'a> {
    const MAX_SIZE: usize = ConfigInstruction::<RefRawPath<'a>, RefBytes<'a>>::MAX_SIZE;
}
