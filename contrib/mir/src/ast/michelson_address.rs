/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::str::Utf8Error;

use tezos_crypto_rs::base58::FromBase58CheckError;
use tezos_crypto_rs::hash::{
    ContractKt1Hash, ContractTz1Hash, ContractTz2Hash, ContractTz3Hash, ContractTz4Hash,
    FromBytesError, Hash, HashTrait, SmartRollupHash,
};

#[derive(Debug, PartialEq, Eq, Clone, thiserror::Error)]
pub enum AddressError {
    #[error("unknown address prefix: {0}")]
    UnknownStrPrefix(String),
    #[error("unknown address prefix: {0:?}")]
    UnknownBytesPrefix(Vec<u8>),
    #[error("too short to be an address with length {0}")]
    TooShort(usize),
    #[error("{0}")]
    FromBase58CheckError(String),
    #[error("{0}")]
    FromBytesError(String),
    #[error(transparent)]
    FromUtf8Error(#[from] Utf8Error),
    #[error("invalid separator byte: {0}")]
    InvalidSeparatorByte(u8),
}

/* Note: tezos_crypto_rs errors

this is silly, but PartialEq and Clone aren't implemented for tezos_crypto_rs
errors for some reason, and coherence rules forbid us from implementing those
here. to avoid a terrifyingly long and brittle match expression, especially
considering some errors are entirely opaque, we're using strings instead.

*/

impl From<FromBase58CheckError> for AddressError {
    fn from(value: FromBase58CheckError) -> Self {
        Self::FromBase58CheckError(value.to_string())
    }
}

impl From<FromBytesError> for AddressError {
    fn from(value: FromBytesError) -> Self {
        Self::FromBase58CheckError(value.to_string())
    }
}

macro_rules! address_hash_type_and_impls {
    ($($con:ident($ty:ident)),* $(,)*) => {
        #[derive(Debug, Clone, Eq, PartialOrd, Ord, PartialEq)]
        pub enum AddressHash {
            $($con($ty)),*
        }

        $(impl From<$ty> for AddressHash {
            fn from(value: $ty) -> Self {
                AddressHash::$con(value)
            }
        })*

        impl AsRef<[u8]> for AddressHash {
            fn as_ref(&self) -> &[u8] {
                match self {
                    $(AddressHash::$con($ty(h)))|* => h,
                }
            }
        }

        impl From<AddressHash> for Vec<u8> {
            fn from(value: AddressHash) -> Self {
                match value {
                    $(AddressHash::$con($ty(h)))|* => h,
                }
            }
        }

        impl AddressHash {
            pub fn to_base58_check(&self) -> String {
                match self {
                    $(AddressHash::$con(h) => h.to_base58_check()),*
                }
            }
        }
    };
}

address_hash_type_and_impls! {
    Tz1(ContractTz1Hash),
    Tz2(ContractTz2Hash),
    Tz3(ContractTz3Hash),
    Tz4(ContractTz4Hash),
    Kt1(ContractKt1Hash),
    Sr1(SmartRollupHash),
}

impl AddressHash {
    const TAG_IMPLICIT: u8 = 0;
    const TAG_KT1: u8 = 1;
    const TAG_SR1: u8 = 3;
    const TAG_TZ1: u8 = 0;
    const TAG_TZ2: u8 = 1;
    const TAG_TZ3: u8 = 2;
    const TAG_TZ4: u8 = 3;
    const SEP_IMPLICIT: &[u8] = &[];
    const SEP_SMART: &[u8] = &[0];

    pub fn from_base58_check(data: &str) -> Result<Self, AddressError> {
        use AddressHash::*;
        if data.len() < 3 {
            return Err(AddressError::TooShort(data.len()));
        }
        Ok(match &data[0..3] {
            "KT1" => Kt1(HashTrait::from_b58check(data)?),
            "sr1" => Sr1(HashTrait::from_b58check(data)?),
            "tz1" => Tz1(HashTrait::from_b58check(data)?),
            "tz2" => Tz2(HashTrait::from_b58check(data)?),
            "tz3" => Tz3(HashTrait::from_b58check(data)?),
            "tz4" => Tz4(HashTrait::from_b58check(data)?),
            s => return Err(AddressError::UnknownStrPrefix(s.to_owned())),
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, AddressError> {
        use AddressHash::*;
        let too_short_err = || AddressError::TooShort(bytes.len());
        let validate_separator_byte = || {
            match bytes.last() {
                Some(0) => Ok(()),
                Some(b) => Err(AddressError::InvalidSeparatorByte(*b)),
                // should be impossible to hit
                None => Err(AddressError::TooShort(0)),
            }
        };
        Ok(match *bytes.first().ok_or_else(too_short_err)? {
            // implicit addresses
            Self::TAG_IMPLICIT => match *bytes.get(1).ok_or_else(too_short_err)? {
                Self::TAG_TZ1 => Tz1(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ2 => Tz2(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ3 => Tz3(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ4 => Tz4(HashTrait::try_from_bytes(&bytes[2..])?),
                _ => return Err(AddressError::UnknownBytesPrefix(bytes[..2].to_vec())),
            },
            Self::TAG_KT1 => {
                validate_separator_byte()?;
                Kt1(HashTrait::try_from_bytes(&bytes[1..bytes.len() - 1])?)
            }
            // 2 is txr1 addresses, which are deprecated
            Self::TAG_SR1 => {
                validate_separator_byte()?;
                Sr1(HashTrait::try_from_bytes(&bytes[1..bytes.len() - 1])?)
            }
            _ => return Err(AddressError::UnknownBytesPrefix(bytes[..1].to_vec())),
        })
    }

    pub fn to_bytes(&self, out: &mut Vec<u8>) {
        use AddressHash::*;
        fn go(out: &mut Vec<u8>, tag: &[u8], hash: impl AsRef<Hash>, sep: &[u8]) {
            out.extend_from_slice(tag);
            out.extend_from_slice(hash.as_ref());
            out.extend_from_slice(sep);
        }
        match self {
            Tz1(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ1],
                hash,
                Self::SEP_IMPLICIT,
            ),
            Tz2(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ2],
                hash,
                Self::SEP_IMPLICIT,
            ),
            Tz3(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ3],
                hash,
                Self::SEP_IMPLICIT,
            ),
            Tz4(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ4],
                hash,
                Self::SEP_IMPLICIT,
            ),
            Kt1(hash) => go(out, &[Self::TAG_KT1], hash, Self::SEP_SMART),
            Sr1(hash) => go(out, &[Self::TAG_SR1], hash, Self::SEP_SMART),
        }
    }

    pub fn to_bytes_vec(&self) -> Vec<u8> {
        let mut out = Vec::new();
        self.to_bytes(&mut out);
        out
    }
}

#[derive(Debug, Clone, Eq, PartialOrd, Ord, PartialEq)]
pub struct Address {
    pub hash: AddressHash,
    pub entrypoint: String,
}

// NB: default entrypoint is represented as literal "default", because it
// affects comparision for addresses.
const DEFAULT_EP_NAME: &str = "default";

impl Address {
    pub fn from_base58_check(data: &str) -> Result<Self, AddressError> {
        let (hash, ep) = if let Some(ep_sep_pos) = data.find('%') {
            (&data[..ep_sep_pos], Some(&data[ep_sep_pos + 1..]))
        } else {
            (data, None)
        };
        Ok(Address {
            hash: AddressHash::from_base58_check(hash)?,
            entrypoint: ep.unwrap_or(DEFAULT_EP_NAME).to_owned(),
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, AddressError> {
        // all address hashes are 20 bytes in length
        const HASH_SIZE: usize = 20;
        // +2 for tags: implicit addresses use 2-byte, and KT1/sr1 add a
        // zero-byte separator to the end
        const EP_START: usize = HASH_SIZE + 2;

        if bytes.len() < EP_START {
            return Err(AddressError::TooShort(bytes.len()));
        }

        let (hash, ep) = bytes.split_at(EP_START);
        let ep = if ep.is_empty() {
            DEFAULT_EP_NAME
        } else {
            std::str::from_utf8(ep)?
        };
        Ok(Address {
            hash: AddressHash::from_bytes(hash)?,
            entrypoint: ep.to_owned(),
        })
    }

    pub fn is_default_ep(&self) -> bool {
        self.entrypoint == DEFAULT_EP_NAME
    }

    pub fn to_bytes(&self, out: &mut Vec<u8>) {
        self.hash.to_bytes(out);
        if !self.is_default_ep() {
            out.extend_from_slice(self.entrypoint.as_bytes())
        }
    }

    pub fn to_bytes_vec(&self) -> Vec<u8> {
        let mut out = Vec::new();
        self.to_bytes(&mut out);
        out
    }

    pub fn to_base58_check(&self) -> String {
        if self.is_default_ep() {
            self.hash.to_base58_check()
        } else {
            format!("{}%{}", self.hash.to_base58_check(), self.entrypoint)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base58_to_bin() {
        for (b58, hex) in FIXTURES {
            assert_eq!(
                Address::from_base58_check(b58).unwrap().to_bytes_vec(),
                hex::decode(hex).unwrap(),
            );
        }
    }

    #[test]
    fn test_bin_to_base58() {
        for (b58, hex) in FIXTURES {
            assert_eq!(
                Address::from_bytes(&hex::decode(hex).unwrap())
                    .unwrap()
                    .to_base58_check(),
                b58,
            );
        }
    }

    // binary representation produced by running
    //
    // `octez-client --mode mockup run script 'parameter address; storage unit;
    // code { CAR; FAILWITH }' on storage Unit and input "\"$addr\""`
    const FIXTURES: [(&str, &str); 25] = [
        (
            "tz1Nw5nr152qddEjKT2dKBH8XcBMDAg72iLw",
            "00002422090f872dfd3a39471bb23f180e6dfed030f3",
        ),
        (
            "tz1SNL5w4RFRbCWRMB4yDWvoRQrPQxZmNzeQ",
            "000049d0be8c2987e04e080f4d73cbe24d8bf83997e2",
        ),
        (
            "tz1V8fDHpHzN8RrZqiYCHaJM9EocsYZch5Cy",
            "0000682343b6fe7589573e11db2b87fd206b936e2a79",
        ),
        (
            "tz1WPGZjP9eHGqD9DkiRJ1xGRU1wEMY19AAF",
            "000075deb97789e2429f2b9bb5dba1b1e4a061e832a3",
        ),
        (
            "tz1WrbkDrzKVqcGXkjw4Qk4fXkjXpAJuNP1j%bar",
            "00007b09f782e0bcd67739510afa819d85976119d5ef626172",
        ),
        (
            "tz1WrbkDrzKVqcGXkjw4Qk4fXkjXpAJuNP1j%defauls",
            "00007b09f782e0bcd67739510afa819d85976119d5ef64656661756c73",
        ),
        (
            "tz1WrbkDrzKVqcGXkjw4Qk4fXkjXpAJuNP1j",
            "00007b09f782e0bcd67739510afa819d85976119d5ef",
        ),
        (
            "tz1WrbkDrzKVqcGXkjw4Qk4fXkjXpAJuNP1j%defaulu",
            "00007b09f782e0bcd67739510afa819d85976119d5ef64656661756c75",
        ),
        (
            "tz1WrbkDrzKVqcGXkjw4Qk4fXkjXpAJuNP1j%foo",
            "00007b09f782e0bcd67739510afa819d85976119d5ef666f6f",
        ),
        (
            "tz1hHGTh6Yk4k7d2PiTcBUeMvw6fJCFikedv",
            "0000ed6586813c9085c8b6252ec3a654ee0e36a0f0e2",
        ),
        (
            "tz29EDhZ4D3XueHxm5RGZsJLHRtj3qSA2MzH%bar",
            "00010a053e3d8b622a993d3182e3f6cc5638ff5f12fe626172",
        ),
        (
            "tz29EDhZ4D3XueHxm5RGZsJLHRtj3qSA2MzH",
            "00010a053e3d8b622a993d3182e3f6cc5638ff5f12fe",
        ),
        (
            "tz29EDhZ4D3XueHxm5RGZsJLHRtj3qSA2MzH%foo",
            "00010a053e3d8b622a993d3182e3f6cc5638ff5f12fe666f6f",
        ),
        (
            "tz3UoffC7FG7zfpmvmjUmUeAaHvzdcUvAj6r%bar",
            "00025cfa532f50de3e12befc0ad21603835dd7698d35626172",
        ),
        (
            "tz3UoffC7FG7zfpmvmjUmUeAaHvzdcUvAj6r",
            "00025cfa532f50de3e12befc0ad21603835dd7698d35",
        ),
        (
            "tz3UoffC7FG7zfpmvmjUmUeAaHvzdcUvAj6r%foo",
            "00025cfa532f50de3e12befc0ad21603835dd7698d35666f6f",
        ),
        (
            "tz4J46gb6DxDFYxkex8k9sKiYZwjuiaoNSqN%bar",
            "00036342f30484dd46b6074373aa6ddca9dfb70083d6626172",
        ),
        (
            "tz4J46gb6DxDFYxkex8k9sKiYZwjuiaoNSqN",
            "00036342f30484dd46b6074373aa6ddca9dfb70083d6",
        ),
        (
            "tz4J46gb6DxDFYxkex8k9sKiYZwjuiaoNSqN%foo",
            "00036342f30484dd46b6074373aa6ddca9dfb70083d6666f6f",
        ),
        (
            "KT1BRd2ka5q2cPRdXALtXD1QZ38CPam2j1ye%bar",
            "011f2d825fdd9da219235510335e558520235f4f5400626172",
        ),
        (
            "KT1BRd2ka5q2cPRdXALtXD1QZ38CPam2j1ye",
            "011f2d825fdd9da219235510335e558520235f4f5400",
        ),
        (
            "KT1BRd2ka5q2cPRdXALtXD1QZ38CPam2j1ye%foo",
            "011f2d825fdd9da219235510335e558520235f4f5400666f6f",
        ),
        (
            "sr1RYurGZtN8KNSpkMcCt9CgWeUaNkzsAfXf%bar",
            "03d601f22256d2ad1faec0c64374e527c6e62f2e5a00626172",
        ),
        (
            "sr1RYurGZtN8KNSpkMcCt9CgWeUaNkzsAfXf",
            "03d601f22256d2ad1faec0c64374e527c6e62f2e5a00",
        ),
        (
            "sr1RYurGZtN8KNSpkMcCt9CgWeUaNkzsAfXf%foo",
            "03d601f22256d2ad1faec0c64374e527c6e62f2e5a00666f6f",
        ),
    ];
}
