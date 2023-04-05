// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

pub use atomic::*;

#[derive(Debug, PartialEq, Eq)]
pub struct CopyInstruction<P> {
    pub from: P,
    pub to: P,
}

#[derive(Debug, PartialEq, Eq)]
pub struct MoveInstruction<P> {
    pub from: P,
    pub to: P,
}

#[derive(Debug, PartialEq, Eq)]
pub struct DeleteInstruction<P> {
    pub path: P,
}

// Value dependent instructions start here

#[derive(Debug, PartialEq, Eq)]
pub struct SetInstruction<P, B> {
    pub value: B,
    pub to: P,
}

#[derive(Debug, PartialEq, Eq)]
pub struct RevealInstruction<P, B> {
    pub hash: B,
    pub to: P,
}

#[derive(Debug, PartialEq, Eq)]
pub enum ConfigInstruction<P, B> {
    Set(SetInstruction<P, B>),
    Reveal(RevealInstruction<P, B>),
    Copy(CopyInstruction<P>),
    Move(MoveInstruction<P>),
    Delete(DeleteInstruction<P>),
}

mod atomic {
    use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
    use tezos_smart_rollup_host::path::RefPath;

    // RefPath is not used directly because it's tricky
    // to define instances for remote types
    #[derive(Debug, PartialEq, Eq)]
    pub struct RefRawPath<'a>(pub &'a [u8]);

    #[allow(clippy::from_over_into)]
    impl<'a> Into<RefPath<'a>> for RefRawPath<'a> {
        fn into(self) -> RefPath<'a> {
            RefPath::assert_from(self.0)
        }
    }

    #[derive(Debug, PartialEq, Eq)]
    pub struct RefBytes<'a>(pub &'a [u8]);

    #[allow(clippy::from_over_into)]
    impl<'a> Into<[u8; PREIMAGE_HASH_SIZE]> for RefBytes<'a> {
        fn into(self) -> [u8; PREIMAGE_HASH_SIZE] {
            self.0.try_into().unwrap()
        }
    }
}

pub struct RefConfigInstruction<'a>(
    pub(crate) ConfigInstruction<RefRawPath<'a>, RefBytes<'a>>,
);

impl<'a> RefConfigInstruction<'a> {
    pub fn get_instr(&self) -> &ConfigInstruction<RefRawPath<'a>, RefBytes<'a>> {
        &self.0
    }

    pub fn into_instr(self) -> ConfigInstruction<RefRawPath<'a>, RefBytes<'a>> {
        self.0
    }
}

// impl<'a> ConfigInstruction<'a> {
//     pub fn reveal_instr(
//         hash: &'a [u8; PREIMAGE_HASH_SIZE],
//         to: RawPath<'a>,
//     ) -> ConfigInstruction<'a> {
//         ConfigInstruction::Reveal(RevealInstruction {
//             hash: RawBytes(hash),
//             to,
//         })
//     }

//     pub fn move_instr(from: RawPath<'a>, to: RawPath<'a>) -> ConfigInstruction<'a> {
//         ConfigInstruction::Move(MoveInstruction { from, to })
//     }
// }
