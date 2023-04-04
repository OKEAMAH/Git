// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use nom::combinator::{complete, map, map_res};
use nom::multi::length_data;
use nom::number::complete::u32;
use nom::sequence::tuple;
use nom::{error::ErrorKind, number::Endianness};
use tezos_smart_rollup_core::MAX_FILE_CHUNK_SIZE;
use tezos_smart_rollup_host::path::PATH_MAX_SIZE;

use super::instr::{
    ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction, RawBytes,
    RawPath, RevealInstruction, SetInstruction,
};

// Those types and helpers copy paseted from tezos_data_encoding.
// As it's required to parse refs, lifetime 'a added to NomReader
pub type NomInput<'a> = &'a [u8];

pub type NomError<'a> = nom::error::Error<NomInput<'a>>;

pub type NomResult<'a, T> = nom::IResult<NomInput<'a>, T>;

// NomReader is like tezos_data_encoding::enc::NomReader,
// but tweaked with lifetime 'a
pub trait NomReader<'a>: Sized {
    fn nom_read(input: &'a [u8]) -> NomResult<Self>;
}

pub fn size(input: NomInput) -> NomResult<u32> {
    u32(Endianness::Big)(input)
}

// Copy-pasted from tezos_data_encoding and returning error tweaked
fn bounded_size(max: usize) -> impl FnMut(NomInput) -> NomResult<u32> {
    move |input| {
        let (input, size) = size(input)?;
        if size as usize <= max {
            Ok((input, size))
        } else {
            Err(nom::Err::Error(nom::error::Error {
                input,
                code: ErrorKind::TooLarge,
            }))
        }
    }
}

impl<'a> NomReader<'a> for RawPath<'a> {
    fn nom_read(input: &'a [u8]) -> NomResult<Self> {
        map_res(
            complete(nom::multi::length_data(bounded_size(PATH_MAX_SIZE))),
            |bytes| Ok::<RawPath<'_>, NomError<'_>>(RawPath(bytes)),
        )(input)
    }
}

impl<'a> NomReader<'a> for RawBytes<'a> {
    fn nom_read(input: &'a [u8]) -> NomResult<Self> {
        map_res(
            complete(length_data(bounded_size(MAX_FILE_CHUNK_SIZE))),
            |bytes| Ok::<RawBytes<'_>, NomError<'_>>(RawBytes(bytes)),
        )(input)
    }
}

impl<'a> NomReader<'a> for SetInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        map(
            nom::sequence::tuple((
                <RawBytes<'a> as NomReader>::nom_read,
                <RawPath<'a> as NomReader>::nom_read,
            )),
            |(value, to)| SetInstruction { value, to },
        )(bytes)
    }
}

impl<'a> NomReader<'a> for RevealInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        map(
            nom::sequence::tuple((
                <RawBytes<'a> as NomReader>::nom_read,
                <RawPath<'a> as NomReader>::nom_read,
            )),
            |(hash, to)| RevealInstruction { hash, to },
        )(bytes)
    }
}

impl<'a> NomReader<'a> for CopyInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        map(
            tuple((
                <RawPath<'a> as NomReader>::nom_read,
                <RawPath<'a> as NomReader>::nom_read,
            )),
            |(from, to)| CopyInstruction { from, to },
        )(bytes)
    }
}

impl<'a> NomReader<'a> for MoveInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        map(
            tuple((
                <RawPath<'a> as NomReader>::nom_read,
                <RawPath<'a> as NomReader>::nom_read,
            )),
            |(from, to)| MoveInstruction { from, to },
        )(bytes)
    }
}

impl<'a> NomReader<'a> for DeleteInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        map(<RawPath<'a> as NomReader>::nom_read, |path| {
            DeleteInstruction { path }
        })(bytes)
    }
}

impl<'a> NomReader<'a> for ConfigInstruction<'a> {
    fn nom_read(bytes: &'a [u8]) -> NomResult<Self> {
        (|input| {
            let (input, tag) = nom::number::complete::u8(input)?;
            let (input, variant) = if tag == 0 {
                (map(
                    <SetInstruction<'a> as NomReader>::nom_read,
                    ConfigInstruction::Set,
                ))(input)?
            } else if tag == 1 {
                (map(
                    <RevealInstruction<'a> as NomReader>::nom_read,
                    ConfigInstruction::Reveal,
                ))(input)?
            } else if tag == 2 {
                (map(
                    <CopyInstruction<'a> as NomReader>::nom_read,
                    ConfigInstruction::Copy,
                ))(input)?
            } else if tag == 3 {
                (map(
                    <MoveInstruction<'a> as NomReader>::nom_read,
                    ConfigInstruction::Move,
                ))(input)?
            } else if tag == 4 {
                (map(
                    <DeleteInstruction<'a> as NomReader>::nom_read,
                    ConfigInstruction::Delete,
                ))(input)?
            } else {
                return Err(nom::Err::Error(nom::error::Error {
                    input,
                    code: ErrorKind::Tag,
                }));
            };
            Ok((input, variant))
        })(bytes)
    }
}
