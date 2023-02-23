// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use num_bigint::BigUint;

use rlp::{Decodable, DecoderError, Rlp};
use std::ops::{Add, Deref, Mul, Sub};

pub struct Wei(BigUint);

pub const ETH_AS_WEI: u64 = 1_000_000_000_000_000_000;

impl Deref for Wei {
    type Target = BigUint;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl Wei {
    pub fn from_bytes_le(bytes: &[u8]) -> Wei {
        Wei(BigUint::from_bytes_le(bytes))
    }
}

impl From<u64> for Wei {
    fn from(v: u64) -> Wei {
        Wei(BigUint::from(v))
    }
}

impl From<BigUint> for Wei {
    fn from(b: BigUint) -> Wei {
        Wei(b)
    }
}

impl Add for Wei {
    type Output = Self;

    fn add(self, other: Self) -> Self {
        Wei(self.0 + other.0)
    }
}

impl Sub for Wei {
    type Output = Self;

    fn sub(self, other: Self) -> Self {
        Wei(self.0 - other.0)
    }
}

impl Mul for Wei {
    type Output = Self;

    fn mul(self, other: Self) -> Self {
        Wei(self.0 * other.0)
    }
}

pub fn from_eth(eth: u64) -> Wei {
    Wei::from(eth) * Wei::from(ETH_AS_WEI)
}

impl Decodable for Wei {
    fn decode(decoder: &Rlp<'_>) -> Result<Wei, DecoderError> {
        Ok(Wei::from_bytes_le(decoder.data()?))
    }
}
