/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use tezos_crypto_rs::{
    base58::FromBase58CheckError,
    hash::{
        FromBytesError, Hash, HashTrait, PublicKeyBls, PublicKeyEd25519, PublicKeyError,
        PublicKeyP256, PublicKeySecp256k1,
    },
};

#[derive(Debug, PartialEq, Eq, Clone, thiserror::Error)]
pub enum KeyError {
    #[error("unknown key prefix: {0}")]
    UnknownPrefix(String),
    #[error("wrong key format: {0}")]
    WrongFormat(String),
}

impl From<FromBase58CheckError> for KeyError {
    fn from(value: FromBase58CheckError) -> Self {
        Self::WrongFormat(value.to_string())
    }
}

impl From<PublicKeyError> for KeyError {
    fn from(value: PublicKeyError) -> Self {
        Self::WrongFormat(value.to_string())
    }
}

impl From<FromBytesError> for KeyError {
    fn from(value: FromBytesError) -> Self {
        Self::WrongFormat(value.to_string())
    }
}

macro_rules! key_type_and_impls {
    ($($con:ident($ty:ident)),* $(,)*) => {
        #[derive(Debug, Clone, Eq, PartialOrd, Ord, PartialEq)]
        pub enum Key {
            $($con($ty)),*
        }

        $(impl From<$ty> for Key {
            fn from(value: $ty) -> Self {
                Key::$con(value)
            }
        })*

        impl AsRef<[u8]> for Key {
            fn as_ref(&self) -> &[u8] {
                match self {
                    $(Key::$con($ty(h)))|* => h,
                }
            }
        }

        impl From<Key> for Vec<u8> {
            fn from(value: Key) -> Self {
                match value {
                    $(Key::$con($ty(h)))|* => h,
                }
            }
        }

        impl Key {
            pub fn to_base58_check(&self) -> String {
                match self {
                    $(Key::$con(h) => h.to_base58_check()),*
                }
            }
        }
    };
}

key_type_and_impls! {
    Ed25519(PublicKeyEd25519),
    Secp256k1(PublicKeySecp256k1),
    P256(PublicKeyP256),
    Bls(PublicKeyBls),
}

impl TryFrom<&[u8]> for Key {
    type Error = KeyError;
    fn try_from(value: &[u8]) -> Result<Self, Self::Error> {
        Self::from_bytes(value)
    }
}

impl TryFrom<&str> for Key {
    type Error = KeyError;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Self::from_base58_check(value)
    }
}

pub(super) fn check_size(data: &[u8], min_size: usize, name: &str) -> Result<(), KeyError> {
    let size = data.len();
    if size < min_size {
        Err(KeyError::WrongFormat(format!(
            "address must be at least {min_size} {name} long, but it is {size} {name} long"
        )))
    } else {
        Ok(())
    }
}

const TAG_ED25519: u8 = 0;
const TAG_SECP256K1: u8 = 1;
const TAG_P256: u8 = 2;
const TAG_BLS: u8 = 3;

impl Key {
    /// Smallest key size
    pub const MIN_BASE58_SIZE: usize = 54;
    pub const MIN_BYTE_SIZE: usize = 32;

    pub fn from_base58_check(data: &str) -> Result<Self, KeyError> {
        use Key::*;

        check_size(data.as_bytes(), Self::MIN_BASE58_SIZE, "characters")?;

        Ok(match &data[0..4] {
            "edpk" => Ed25519(HashTrait::from_b58check(data)?),
            "sppk" => Secp256k1(HashTrait::from_b58check(data)?),
            "p2pk" => P256(HashTrait::from_b58check(data)?),
            "BLpk" => Bls(HashTrait::from_b58check(data)?),
            s => return Err(KeyError::UnknownPrefix(s.to_owned())),
        })
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, KeyError> {
        use Key::*;

        check_size(bytes, Self::MIN_BYTE_SIZE, "bytes")?;

        Ok(match bytes[0] {
            TAG_ED25519 => Ed25519(HashTrait::try_from_bytes(&bytes[1..])?),
            TAG_SECP256K1 => Secp256k1(HashTrait::try_from_bytes(&bytes[1..])?),
            TAG_P256 => P256(HashTrait::try_from_bytes(&bytes[1..])?),
            TAG_BLS => Bls(HashTrait::try_from_bytes(&bytes[1..])?),
            _ => {
                return Err(KeyError::UnknownPrefix(format!(
                    "0x{}",
                    hex::encode(&bytes[..1])
                )))
            }
        })
    }

    pub fn to_bytes(&self, out: &mut Vec<u8>) {
        use Key::*;
        fn go(out: &mut Vec<u8>, tag: u8, hash: impl AsRef<Hash>) {
            out.push(tag);
            out.extend_from_slice(hash.as_ref());
        }
        match self {
            Ed25519(hash) => go(out, TAG_ED25519, hash),
            Secp256k1(hash) => go(out, TAG_SECP256K1, hash),
            P256(hash) => go(out, TAG_P256, hash),
            Bls(hash) => go(out, TAG_BLS, hash),
        }
    }

    pub fn to_bytes_vec(&self) -> Vec<u8> {
        let mut out = Vec::new();
        self.to_bytes(&mut out);
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base58_to_bin() {
        for (b58, hex) in FIXTURES {
            assert_eq!(
                hex::encode(Key::from_base58_check(b58).unwrap().to_bytes_vec()),
                hex,
            );
        }
    }

    #[test]
    fn test_bin_to_base58() {
        // unknown tag
        assert_eq!(
            Key::from_bytes(
                &hex::decode("ff9c0f7c35a4352c2eb5e3ad30bf3ea9ecabb8b65b40ccfeea3d58bea08a36c286")
                    .unwrap()
            ),
            Err(KeyError::UnknownPrefix("0xff".to_owned())),
        );

        for (b58, hex) in FIXTURES {
            assert_eq!(
                Key::from_bytes(&hex::decode(hex).unwrap())
                    .unwrap()
                    .to_base58_check(),
                b58,
            );
        }
    }

    // binary representation produced by running
    //
    // `octez-client --mode mockup normalize data ... of type key --unparsing-mode Optimized`
    const FIXTURES: [(&str, &str); 8] = [
        (
            "edpkupxHveP7SFVnBq4X9Dkad5smzLcSxpRx9tpR7US8DPN5bLPFwu",
            "009c0f7c35a4352c2eb5e3ad30bf3ea9ecabb8b65b40ccfeea3d58bea08a36c286",
        ),
        (
            "edpkupH22qrz1sNQt5HSvWfRJFfyJ9dhNbZLptE6GR4JbMoBcACZZH",
            "009a85e0f3f47852869ae667adc3b03a20fa9f324d046174dff6834e7d1fab0e8d",
        ),
        (
            "edpkuwTWKgQNnhR5v17H2DYHbfcxYepARyrPGbf1tbMoGQAj8Ljr3V",
            "00aad3f16293766169f7db278c5e0e9db4fb82ffe1cbcc35258059617dc0fec082",
        ),
        (
            "sppk7cdA7Afj8MvuBFrP6KsTLfbM5DtH9GwYaRZwCf5tBVCz6UKGQFR",
            "0103b524d0184276467c848ac13557fb0ff8bec5907960f72683f22af430503edfc1",
        ),
        (
            "sppk7Ze7NMs6EHF2uB8qq8GrEgJvE9PWYkUijN3LcesafzQuGyniHBD",
            "01022c380cd1ff286a0a1a7c3aad6e891d237fa82e2a7cdeec08ccb55e90fdef995f",
        ),
        (
            "p2pk67K1dwkDFPB63RZU5H3SoMCvmJdKZDZszc7U4FiGKN2YypKdDCB",
            "020368afbb09255d849813712108a4144237dc1fdd5bb74e68335f4c68c12c1e5723",
        ),
        (
            "p2pk68C6tJr7pNLvgBH63K3hBVoztCPCA36zcWhXFUGywQJTjYBfpxk",
            "0203dcb1916c475902f2b1083212e1b4e6f8ce1531710218c7d34340439f47040e7c",
        ),
        (
            "BLpk1yoPpFtFF3jGUSn2GrGzgHVcj1cm5o6HTMwiqSjiTNFSJskXFady9nrdhoZzrG6ybXiTSK5G",
            "03b6cf94b6a59d102044d1ff16ebe3eccc5cd554965bb66ac80fb2728c18715817e185fb5ac9437908c9e609a742610177",
        ),
    ];
}