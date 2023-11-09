/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use tezos_crypto_rs::base58::FromBase58CheckError;
use tezos_crypto_rs::hash::{
    ContractKt1Hash, ContractTz1Hash, ContractTz2Hash, ContractTz3Hash, ContractTz4Hash,
    FromBytesError, Hash, HashTrait, SmartRollupHash,
};

pub mod entrypoint;

pub use self::entrypoint::Entrypoint;

#[derive(Debug, PartialEq, Eq, Clone, thiserror::Error)]
pub enum AddressError {
    #[error("unknown address prefix: {0}")]
    UnknownPrefix(String),
    #[error("wrong address format: {0}")]
    WrongFormat(String),
}

impl From<FromBase58CheckError> for AddressError {
    fn from(value: FromBase58CheckError) -> Self {
        Self::WrongFormat(value.to_string())
    }
}

impl From<FromBytesError> for AddressError {
    fn from(value: FromBytesError) -> Self {
        Self::WrongFormat(value.to_string())
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

impl TryFrom<&[u8]> for AddressHash {
    type Error = AddressError;
    fn try_from(value: &[u8]) -> Result<Self, Self::Error> {
        Self::from_bytes(value)
    }
}

impl TryFrom<&str> for AddressHash {
    type Error = AddressError;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Self::from_base58_check(value)
    }
}

fn check_size(data: &[u8], min_size: usize, name: &str) -> Result<(), AddressError> {
    let size = data.len();
    if size < min_size {
        Err(AddressError::WrongFormat(format!(
            "address must be at least {min_size} {name} long, but it is {size} {name} long"
        )))
    } else {
        Ok(())
    }
}

impl AddressHash {
    const TAG_IMPLICIT: u8 = 0;
    const TAG_KT1: u8 = 1;
    const TAG_SR1: u8 = 3;
    const TAG_TZ1: u8 = 0;
    const TAG_TZ2: u8 = 1;
    const TAG_TZ3: u8 = 2;
    const TAG_TZ4: u8 = 3;
    const PADDING_IMPLICIT: &[u8] = &[];
    const PADDING_SMART: &[u8] = &[0];
    // all address hashes are 20 bytes in length
    const HASH_SIZE: usize = 20;
    // +2 for tags: implicit addresses use 2-byte, and KT1/sr1 add a
    // zero-byte separator to the end
    const BYTE_SIZE: usize = Self::HASH_SIZE + 2;
    const BASE58_SIZE: usize = 36;

    pub fn from_base58_check(data: &str) -> Result<Self, AddressError> {
        use AddressHash::*;

        check_size(data.as_bytes(), Self::BASE58_SIZE, "characters")?;

        Ok(match &data[0..3] {
            "KT1" => Kt1(HashTrait::from_b58check(data)?),
            "sr1" => Sr1(HashTrait::from_b58check(data)?),
            "tz1" => Tz1(HashTrait::from_b58check(data)?),
            "tz2" => Tz2(HashTrait::from_b58check(data)?),
            "tz3" => Tz3(HashTrait::from_b58check(data)?),
            "tz4" => Tz4(HashTrait::from_b58check(data)?),
            s => return Err(AddressError::UnknownPrefix(s.to_owned())),
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, AddressError> {
        use AddressHash::*;

        check_size(bytes, Self::BYTE_SIZE, "bytes")?;
        let validate_padding_byte = || match bytes.last().unwrap() {
            0 => Ok(()),
            b => Err(AddressError::WrongFormat(format!(
                "address must be padded with byte 0x00, but it was padded with 0x{}",
                hex::encode([*b])
            ))),
        };
        Ok(match bytes[0] {
            // implicit addresses
            Self::TAG_IMPLICIT => match bytes[1] {
                Self::TAG_TZ1 => Tz1(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ2 => Tz2(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ3 => Tz3(HashTrait::try_from_bytes(&bytes[2..])?),
                Self::TAG_TZ4 => Tz4(HashTrait::try_from_bytes(&bytes[2..])?),
                _ => {
                    return Err(AddressError::UnknownPrefix(format!(
                        "0x{}",
                        hex::encode(&bytes[..2])
                    )))
                }
            },
            Self::TAG_KT1 => {
                validate_padding_byte()?;
                Kt1(HashTrait::try_from_bytes(&bytes[1..bytes.len() - 1])?)
            }
            // 2 is txr1 addresses, which are deprecated
            Self::TAG_SR1 => {
                validate_padding_byte()?;
                Sr1(HashTrait::try_from_bytes(&bytes[1..bytes.len() - 1])?)
            }
            _ => {
                return Err(AddressError::UnknownPrefix(format!(
                    "0x{}",
                    hex::encode(&bytes[..1])
                )))
            }
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
                Self::PADDING_IMPLICIT,
            ),
            Tz2(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ2],
                hash,
                Self::PADDING_IMPLICIT,
            ),
            Tz3(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ3],
                hash,
                Self::PADDING_IMPLICIT,
            ),
            Tz4(hash) => go(
                out,
                &[Self::TAG_IMPLICIT, Self::TAG_TZ4],
                hash,
                Self::PADDING_IMPLICIT,
            ),
            Kt1(hash) => go(out, &[Self::TAG_KT1], hash, Self::PADDING_SMART),
            Sr1(hash) => go(out, &[Self::TAG_SR1], hash, Self::PADDING_SMART),
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
    pub entrypoint: Entrypoint,
}

impl Address {
    pub fn from_base58_check(data: &str) -> Result<Self, AddressError> {
        let (hash, ep) = if let Some(ep_sep_pos) = data.find('%') {
            (&data[..ep_sep_pos], &data[ep_sep_pos + 1..])
        } else {
            (data, "")
        };
        Ok(Address {
            hash: AddressHash::from_base58_check(hash)?,
            entrypoint: Entrypoint::try_from(ep)?,
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, AddressError> {
        check_size(bytes, AddressHash::BYTE_SIZE, "bytes")?;

        let (hash, ep) = bytes.split_at(AddressHash::BYTE_SIZE);
        Ok(Address {
            hash: AddressHash::from_bytes(hash)?,
            entrypoint: Entrypoint::try_from(ep)?,
        })
    }

    pub fn is_default_ep(&self) -> bool {
        self.entrypoint.is_default()
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
            format!(
                "{}%{}",
                self.hash.to_base58_check(),
                self.entrypoint.as_str()
            )
        }
    }
}

impl TryFrom<&[u8]> for Address {
    type Error = AddressError;
    fn try_from(value: &[u8]) -> Result<Self, Self::Error> {
        Self::from_bytes(value)
    }
}

impl TryFrom<&str> for Address {
    type Error = AddressError;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Self::from_base58_check(value)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base58_to_bin() {
        // address with explicit, but empty, entrypoint
        assert_eq!(
            Address::from_base58_check("tz1Nw5nr152qddEjKT2dKBH8XcBMDAg72iLw%")
                .unwrap()
                .to_bytes_vec(),
            hex::decode("00002422090f872dfd3a39471bb23f180e6dfed030f3").unwrap(),
        );

        // address with explicit default entrypoint
        assert_eq!(
            Address::from_base58_check("tz1Nw5nr152qddEjKT2dKBH8XcBMDAg72iLw%default")
                .unwrap()
                .to_bytes_vec(),
            hex::decode("00002422090f872dfd3a39471bb23f180e6dfed030f3").unwrap(),
        );

        for (b58, hex) in FIXTURES {
            assert_eq!(
                Address::from_base58_check(b58).unwrap().to_bytes_vec(),
                hex::decode(hex).unwrap(),
            );
        }
    }

    #[test]
    fn test_bin_to_base58() {
        // explicit default entrypoint is apparently forbidden in binary encoding
        assert!(matches!(
            Address::from_bytes(
                &hex::decode("00007b09f782e0bcd67739510afa819d85976119d5ef64656661756c74").unwrap()
            ),
            Err(AddressError::WrongFormat(_)),
        ));

        // unknown implicit tag
        assert_eq!(
            dbg!(Address::from_bytes(
                &hex::decode("00ff7b09f782e0bcd67739510afa819d85976119d5ef").unwrap()
            )),
            Err(AddressError::UnknownPrefix("0x00ff".to_owned())),
        );

        // unknown tag
        assert_eq!(
            Address::from_bytes(
                &hex::decode("ffff7b09f782e0bcd67739510afa819d85976119d5ef").unwrap()
            ),
            Err(AddressError::UnknownPrefix("0xff".to_owned())),
        );

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
