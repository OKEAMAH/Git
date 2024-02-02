// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-License-Identifier: MIT

//! Definitions & tezos-encodings for *michelson* data.
use nom::branch::alt;
use nom::combinator::map;
use prim::{TICKET_TAG, UNIT_TAG, UNIT_TYPE_TAG};
use std::fmt::Debug;
use tezos_data_encoding::enc::{self, BinResult, BinWriter};
use tezos_data_encoding::encoding::{Encoding, HasEncoding};
use tezos_data_encoding::nom::{self as nom_read, NomReader, NomResult};
use tezos_data_encoding::types::Zarith;
use micheline::annots::Annotations;

mod micheline;
#[cfg(feature = "alloc")]
pub mod ticket;

use self::micheline::{bin_write_micheline_ticket, Node};

use super::contract::Contract;
use micheline::{
    bin_write_micheline_bytes, bin_write_micheline_int, bin_write_micheline_string,
    bin_write_prim_1_arg_no_annots, bin_write_prim_2_args_no_annots,
    bin_write_prim_no_args_no_annots, nom_read_micheline_bytes, nom_read_micheline_int,
    nom_read_micheline_string, MichelinePrim1ArgNoAnnots, MichelinePrim2ArgsNoAnnots,
    MichelinePrimNoArgsNoAnnots,
};
use v1_primitives as prim;

pub mod v1_primitives {
    //! Encoding of [michelson_v1_primitives].
    //!
    //! [michelson_v1_primitives]: <https://gitlab.com/tezos/tezos/-/blob/9028b797894a5d9db38bc61a20abb793c3778316/src/proto_alpha/lib_protocol/michelson_v1_primitives.ml>

    /// `("Left", D_Left)` case tag.
    pub const LEFT_TAG: u8 = 5;

    /// `("None", D_None)` case tag.
    pub const NONE_TAG: u8 = 6;

    /// `("Pair", D_PAIR)` case tag.
    pub const PAIR_TAG: u8 = 7;

    /// `("Right", D_Right)` case tag.
    pub const RIGHT_TAG: u8 = 8;

    /// `("Some", D_Some)` case tag.
    pub const SOME_TAG: u8 = 9;

    /// unit encoding case tag.
    pub const UNIT_TAG: u8 = 11;

    /// unit type tag
    pub const UNIT_TYPE_TAG: u8 = 108;

    /// ticket encoding case tag.
    pub const TICKET_TAG: u8 = 157;
}


/// marker trait for michelson encoding
pub trait Michelson:
    HasEncoding + BinWriter + NomReader + Debug + PartialEq + Eq
{
}

impl Michelson for MichelsonUnit {}
impl Michelson for MichelsonContract {}
impl Michelson for MichelsonInt {}
impl Michelson for MichelsonString {}
impl Michelson for MichelsonBytes {}
impl<Arg0, Arg1> Michelson for MichelsonPair<Arg0, Arg1>
where
    Arg0: Michelson,
    Arg1: Michelson,
{
}
impl<Arg0, Arg1> Michelson for MichelsonOr<Arg0, Arg1>
where
    Arg0: Michelson,
    Arg1: Michelson,
{
}
impl<Arg> Michelson for MichelsonOption<Arg> where Arg: Michelson {}

/// Michelson *ticket* encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonTicket<Arg0>(pub MichelsonContract, pub Arg0, pub MichelsonInt)
where
    Arg0: Debug + PartialEq + Eq;

/// Michelson *unit* encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonUnit;

/// Michelson *contract* encoding.
///
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonContract(pub Contract);

/// Michelson *pair* encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonPair<Arg0, Arg1>(pub Arg0, pub Arg1)
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq;

/// Michelson *or* encoding.
#[derive(Debug, PartialEq, Eq)]
pub enum MichelsonOr<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    /// The *Left* case
    Left(Arg0),
    /// The *Right* case
    Right(Arg1),
}

/// Michelson *option* encoding.  #[derive(Debug, PartialEq, Eq)] pub
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonOption<Arg>(pub Option<Arg>)
where
    Arg: Debug + PartialEq + Eq;

/// Michelson String encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonString(pub String);

/// Michelson Bytes encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonBytes(pub Vec<u8>);

/// Michelson Int encoding.
#[derive(Debug, PartialEq, Eq)]
pub struct MichelsonInt(pub Zarith);

// ----------
// CONVERSION
// ----------
impl From<String> for MichelsonString {
    fn from(str: String) -> MichelsonString {
        MichelsonString(str)
    }
}

impl From<Vec<u8>> for MichelsonBytes {
    fn from(b: Vec<u8>) -> MichelsonBytes {
        MichelsonBytes(b)
    }
}

impl From<Zarith> for MichelsonInt {
    fn from(value: Zarith) -> MichelsonInt {
        MichelsonInt(value)
    }
}

impl From<i32> for MichelsonInt {
    fn from(value: i32) -> MichelsonInt {
        MichelsonInt(Zarith(value.into()))
    }
}

// --------
// ENCODING
// --------
impl HasEncoding for MichelsonContract {
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl HasEncoding for MichelsonUnit {
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl<Arg0, Arg1> HasEncoding for MichelsonPair<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl<Arg0, Arg1> HasEncoding for MichelsonOr<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl<Arg> HasEncoding for MichelsonOption<Arg>
where
    Arg: Debug + PartialEq + Eq,
{
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl HasEncoding for MichelsonString {
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl HasEncoding for MichelsonBytes {
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl HasEncoding for MichelsonInt {
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

impl<Arg> HasEncoding for MichelsonTicket<Arg>
where
    Arg: Debug + PartialEq + Eq,
{
    fn encoding() -> Encoding {
        Encoding::Custom
    }
}

// --------
// DECODING
// --------
impl NomReader for MichelsonContract {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(
            nom_read_micheline_bytes(Contract::nom_read),
            MichelsonContract,
        )(input)
    }
}

impl NomReader for MichelsonUnit {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(
            MichelinePrimNoArgsNoAnnots::<{ prim::UNIT_TAG }>::nom_read,
            |_prim| MichelsonUnit,
        )(input)
    }
}

impl<Arg0, Arg1> NomReader for MichelsonPair<Arg0, Arg1>
where
    Arg0: NomReader + Debug + PartialEq + Eq,
    Arg1: NomReader + Debug + PartialEq + Eq,
{
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(
            MichelinePrim2ArgsNoAnnots::<_, _, { prim::PAIR_TAG }>::nom_read,
            Into::into,
        )(input)
    }
}

// Binary representation of a unit Ticket
// Ticket KT1FHqsvc7vRS3u54L66DdMX4gb6QKqxJ1JW unit Unit 1
// 0x099d0000002d01000000244b543146487173766337765253337535344c363644644d5834676236514b71784a314a57036c030b00000000
// \t\x9d\x00\x00\x00-\x01\x00\x00\x00$KT1FHqsvc7vRS3u54L66DdMX4gb6QKqxJ1JW\x03l\x03\x0b\x00\x00\x00\x00
impl NomReader for MichelsonTicket<MichelsonUnit> {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        let (fst, node) = Node::nom_read(input)?;
        let Node::Prim {
            prim_tag,
            args,
            annots,
        } = node
        else {
            todo!()
        };

        if prim_tag != TICKET_TAG || !annots.is_empty() || args.len() != 4 {
            todo!()
        };
        let [arg0, arg1, arg2, arg3] = args.try_into().unwrap();
        let Node::String(ticketer) = arg0 else {
            todo!()
        };
        match arg1 {
            Node::Prim {
                prim_tag,
                args,
                annots,
            } if prim_tag == UNIT_TYPE_TAG && args.is_empty() && annots.is_empty() => (),
            _ => todo!(),
        };
        let contents = match arg2 {
            Node::Prim {
                prim_tag,
                args,
                annots,
            } if prim_tag == UNIT_TAG && args.is_empty() && annots.is_empty() => {
                MichelsonUnit
            }
            _ => todo!(),
        };
        // let Node::Prim { prim_tag, args, annots } = args[1];
        // let conents = args[2];
        // let amount = args[3];
        let Node::Int(amount) = arg3 else { todo!() };

        let ticket = MichelsonTicket(
            MichelsonContract(Contract::from_b58check(&ticketer).unwrap()),
            contents,
            MichelsonInt(amount),
        );
        Ok((fst, ticket))
        // map(Node::nom_read, |node| {
        //     MichelsonTicket(node., arg1, amount.0.into())
        // })(input)
    }
}

// impl<Arg0> TryFrom<Node> for MichelsonTicket<Arg0>
// where
// Arg0: NomReader + Debug + PartialEq + Eq,


impl BinWriter for MichelsonTicket<MichelsonUnit>
{
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        let MichelsonTicket(ticketer, _contents,amount ) = self;

        let ticketer = Node::String(ticketer.0.to_b58check());
        let contents_type = Node::Prim { prim_tag: UNIT_TYPE_TAG, args: vec![], annots: Annotations(vec![]) };
        let contents = Node::Prim { prim_tag: UNIT_TAG, args: vec![], annots: Annotations(vec![]) };
        let amount = Node::Int(amount.0.clone());

        let args = vec![ticketer, contents_type, contents, amount];

        let node = Node::Prim { prim_tag: TICKET_TAG, args, annots: Annotations(vec![]) };
        node.bin_write(output)

    }
   
}

impl<Arg0, Arg1> NomReader for MichelsonOr<Arg0, Arg1>
where
    Arg0: NomReader + Debug + PartialEq + Eq,
    Arg1: NomReader + Debug + PartialEq + Eq,
{
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        alt((
            map(
                MichelinePrim1ArgNoAnnots::<_, { prim::LEFT_TAG }>::nom_read,
                |MichelinePrim1ArgNoAnnots { arg }| Self::Left(arg),
            ),
            map(
                MichelinePrim1ArgNoAnnots::<_, { prim::RIGHT_TAG }>::nom_read,
                |MichelinePrim1ArgNoAnnots { arg }| Self::Right(arg),
            ),
        ))(input)
    }
}

impl<Arg> NomReader for MichelsonOption<Arg>
where
    Arg: NomReader + Debug + PartialEq + Eq,
{
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        alt((
            map(
                MichelinePrimNoArgsNoAnnots::<{ prim::NONE_TAG }>::nom_read,
                |_prim| Self(None),
            ),
            map(
                MichelinePrim1ArgNoAnnots::<_, { prim::SOME_TAG }>::nom_read,
                |MichelinePrim1ArgNoAnnots { arg }| Self(Some(arg)),
            ),
        ))(input)
    }
}

impl NomReader for MichelsonString {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(nom_read_micheline_string, MichelsonString)(input)
    }
}

impl NomReader for MichelsonBytes {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(nom_read_micheline_bytes(nom_read::bytes), MichelsonBytes)(input)
    }
}

impl NomReader for MichelsonInt {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        map(nom_read_micheline_int, MichelsonInt)(input)
    }
}

// --------
// ENCODING
// --------
impl BinWriter for MichelsonContract {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_micheline_bytes(Contract::bin_write)(&self.0, output)
    }
}

impl BinWriter for MichelsonUnit {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_prim_no_args_no_annots(prim::UNIT_TAG, output)
    }
}

impl<Arg0, Arg1> BinWriter for MichelsonPair<Arg0, Arg1>
where
    Arg0: BinWriter + Debug + PartialEq + Eq,
    Arg1: BinWriter + Debug + PartialEq + Eq,
{
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_prim_2_args_no_annots(prim::PAIR_TAG, &self.0, &self.1, output)
    }
}

impl<Arg0, Arg1> From<MichelinePrim2ArgsNoAnnots<Arg0, Arg1, { prim::PAIR_TAG }>>
    for MichelsonPair<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn from(
        micheline: MichelinePrim2ArgsNoAnnots<Arg0, Arg1, { prim::PAIR_TAG }>,
    ) -> Self {
        Self(micheline.arg1, micheline.arg2)
    }
}

impl<Arg0, Arg1> From<MichelsonPair<Arg0, Arg1>>
    for MichelinePrim2ArgsNoAnnots<Arg0, Arg1, { prim::PAIR_TAG }>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn from(michelson: MichelsonPair<Arg0, Arg1>) -> Self {
        Self {
            arg1: michelson.0,
            arg2: michelson.1,
        }
    }
}

impl<Arg0, Arg1> BinWriter for MichelsonOr<Arg0, Arg1>
where
    Arg0: BinWriter + Debug + PartialEq + Eq,
    Arg1: BinWriter + Debug + PartialEq + Eq,
{
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        match self {
            MichelsonOr::Left(left) => {
                bin_write_prim_1_arg_no_annots(prim::LEFT_TAG, left, output)
            }
            MichelsonOr::Right(right) => {
                bin_write_prim_1_arg_no_annots(prim::RIGHT_TAG, right, output)
            }
        }
    }
}

impl<Arg0, Arg1> From<MichelinePrim1ArgNoAnnots<Arg0, { prim::LEFT_TAG }>>
    for MichelsonOr<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn from(micheline: MichelinePrim1ArgNoAnnots<Arg0, { prim::LEFT_TAG }>) -> Self {
        Self::Left(micheline.arg)
    }
}

impl<Arg0, Arg1> From<MichelinePrim1ArgNoAnnots<Arg1, { prim::RIGHT_TAG }>>
    for MichelsonOr<Arg0, Arg1>
where
    Arg0: Debug + PartialEq + Eq,
    Arg1: Debug + PartialEq + Eq,
{
    fn from(micheline: MichelinePrim1ArgNoAnnots<Arg1, { prim::RIGHT_TAG }>) -> Self {
        Self::Right(micheline.arg)
    }
}

impl<Arg> BinWriter for MichelsonOption<Arg>
where
    Arg: BinWriter + Debug + PartialEq + Eq,
{
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        match self {
            MichelsonOption(None) => {
                bin_write_prim_no_args_no_annots(prim::NONE_TAG, output)
            }
            MichelsonOption(Some(arg)) => {
                bin_write_prim_1_arg_no_annots(prim::SOME_TAG, arg, output)
            }
        }
    }
}

impl BinWriter for MichelsonString {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_micheline_string(&self.0, output)
    }
}

impl BinWriter for MichelsonBytes {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_micheline_bytes(enc::bytes)(self.0.as_slice(), output)
    }
}

impl BinWriter for MichelsonInt {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        bin_write_micheline_int(&self.0, output)
    }
}

#[cfg(test)]
mod test {

    use super::*;
    #[test]
    fn basic_encode_decode_on_ticket() {
        let x = "099d0000002f01000000244b543146487173766337765253337535344c363644644d5834676236514b71784a314a57036c030b000b00000000";
        let bytes = hex::decode(x).unwrap();
        let result = MichelsonTicket::<MichelsonUnit>::nom_read(bytes.as_slice());
        assert!(result.is_ok());
        let mut output = Vec::new();
        let result = result.unwrap().1.bin_write(&mut output);
        assert!(result.is_ok());
        assert_eq!(bytes, output)
    }
}
