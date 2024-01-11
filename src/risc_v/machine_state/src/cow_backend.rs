// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

#[cfg(test)]
mod tests {
    use core::slice;
    use std::{collections::hash_map::RandomState, error::Error, hash::BuildHasher};

    use blake2b_simd::{many::HashManyJob, Params};
    use proptest::collection::HashMapStrategy;

    struct Rng {
        state: RandomState,
        acc: u64,
    }

    impl Rng {
        fn new(seed: u64) -> Self {
            Self {
                state: RandomState::new(),
                acc: seed,
            }
        }

        fn next(&mut self) -> u64 {
            let acc = self.state.hash_one(self.acc);
            self.acc = acc;
            acc
        }
    }

    macro_rules! time {
        ($name:expr, $code:block) => {{
            let t = std::time::SystemTime::now();
            let r = { $code };
            eprintln!("> '{}' took {:?}", $name, t.elapsed().unwrap());
            r
        }};
    }

    struct ChunkedVector {}

    impl ChunkedVector {
        fn new(len: usize) -> Self {
            memmap2::MmapRaw
            Self {}
        }  q
    }

    unsafe fn foo() -> Result<(), Box<dyn Error>> {
        let mut rng = Rng::new(1237);
        let mut data = vec![0u8; 4 * 1024 * 1024 * 1024];

        time!("randomise", {
            for i in slice::from_raw_parts_mut(data.as_mut_ptr().cast::<u64>(), data.len() / 8) {
                *i = rng.next();
            }
        });

        Ok(())
    }

    #[test]
    fn test_foo() {
        unsafe { foo().expect("Works") }
    }
}
