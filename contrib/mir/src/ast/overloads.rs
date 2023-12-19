/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Add {
    IntInt,
    NatNat,
    IntNat,
    NatInt,
    MutezMutez,
    Bls12381G1,
    Bls12381G2,
    Bls12381Fr,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum And {
    Bool,
    NatNat,
    IntNat,
    Bytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Or {
    Bool,
    Nat,
    Bytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Xor {
    Bool,
    Nat,
    Bytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Not {
    Bool,
    Nat,
    Int,
    Bytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Mem {
    Set,
    Map,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Get {
    Map,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Update {
    Set,
    Map,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Size {
    String,
    Bytes,
    List,
    Set,
    Map,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Iter {
    List,
    Set,
    Map,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Slice {
    String,
    Bytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Concat {
    TwoStrings,
    TwoBytes,
    ListOfStrings,
    ListOfBytes,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Int {
    Nat,
    Bls12381Fr,
}
