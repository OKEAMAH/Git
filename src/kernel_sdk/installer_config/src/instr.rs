#[cfg(feature = "alloc")]
pub use encoding::*;
#[cfg(feature = "alloc")]
use tezos_data_encoding::enc::BinWriter;
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_host::path::RefPath;

// RefPath is not used directly because it's tricky
// to define instances for remote types
#[derive(Debug, PartialEq, Eq)]
pub struct RawPath<'a>(pub &'a [u8]);

#[allow(clippy::from_over_into)]
impl<'a> Into<RefPath<'a>> for RawPath<'a> {
    fn into(self) -> RefPath<'a> {
        RefPath::assert_from(self.0)
    }
}

#[derive(Debug, PartialEq, Eq)]
pub struct RawBytes<'a>(pub &'a [u8]);

#[allow(clippy::from_over_into)]
impl<'a> Into<[u8; PREIMAGE_HASH_SIZE]> for RawBytes<'a> {
    fn into(self) -> [u8; PREIMAGE_HASH_SIZE] {
        self.0.try_into().unwrap()
    }
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub struct CopyInstruction<'a> {
    pub from: RawPath<'a>,
    pub to: RawPath<'a>,
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub struct MoveInstruction<'a> {
    pub from: RawPath<'a>,
    pub to: RawPath<'a>,
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub struct DeleteInstruction<'a> {
    pub path: RawPath<'a>,
}

// Value dependent instructions start here

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub enum ValueSource<'a> {
    Path(RawPath<'a>),
    Value(RawBytes<'a>),
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub struct SetInstruction<'a> {
    pub value: ValueSource<'a>,
    pub to: RawPath<'a>,
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub struct RevealInstruction<'a> {
    pub hash: ValueSource<'a>,
    pub to: RawPath<'a>,
}

#[cfg_attr(feature = "alloc", derive(BinWriter))]
#[derive(Debug, PartialEq, Eq)]
pub enum ConfigInstruction<'a> {
    Set(SetInstruction<'a>),
    Reveal(RevealInstruction<'a>),
    Copy(CopyInstruction<'a>),
    Move(MoveInstruction<'a>),
    Delete(DeleteInstruction<'a>),
}

#[cfg(feature = "alloc")]
mod encoding {
    // Custom encodings of reference types

    use super::*;
    use tezos_data_encoding::enc::{put_bytes, BinError, BinResult, BinWriter};

    // TODO this function, perhaps, should be exposed from use tezos_data_encoding::enc
    // now it's just copy-pasted here
    fn put_size(size: usize, out: &mut Vec<u8>) -> BinResult {
        let size = u32::try_from(size).map_err(|_| {
            BinError::custom(format!(
                "Expected {} but got {}",
                (u32::MAX >> 2) as usize,
                size
            ))
        })?;
        put_bytes(&size.to_be_bytes(), out);
        Ok(())
    }

    impl<'a> BinWriter for RawPath<'a> {
        fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
            put_size(self.0.len(), output)?;
            put_bytes(self.0, output);
            Ok(())
        }
    }

    impl<'a> BinWriter for RawBytes<'a> {
        fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
            put_size(self.0.len(), output)?;
            put_bytes(self.0, output);
            Ok(())
        }
    }

    #[derive(Debug)]
    pub struct ConfigProgram<'a>(Vec<ConfigInstruction<'a>>);

    // Encode all commands with appended number of commands at the end.
    // It makes possible for the installer_kernel to
    // parse commands at the end of the kernel binary.
    impl<'a> BinWriter for ConfigProgram<'a> {
        fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
            let initial_size = output.len();
            for i in 0..self.0.len() {
                let mut current_instr = vec![];
                self.0[i].bin_write(&mut current_instr)?;
                // Put size of the instruction encoding first,
                // in order to make a decoding easier
                put_size(current_instr.len(), output)?;
                output.extend_from_slice(&current_instr);
            }
            put_size(output.len() - initial_size, output)?;
            Ok(())
        }
    }
}

// If we want to be able to parse config programs from text files,
// we have to parametrise ValueSource struct with V type of value
// and then define following type as an instance of V.
// pub enum ReadableValue {
//     B58(String),
//     Hex(String),
// }

// pub struct TextualProgramm<'a>(Vec<ConfigInstruction<'a, ReadableValue>>);

#[cfg(test)]
mod test {
    use std::fmt::Debug;

    #[cfg(feature = "alloc")]
    use tezos_data_encoding::enc::BinWriter;

    use crate::nom::NomReader;

    // I have to pass `out` here because for some reason
    // borrow checker complaines about this line:
    //    `T::nom_read(out).unwrap()`
    // saying that `out` is dropped but still borrowed in this line,
    // despite the faact `decoded` should be dropped on leaving the function
    #[cfg(feature = "alloc")]
    fn roundtrip<'a, T: Debug + PartialEq + Eq + BinWriter + NomReader<'a>>(
        orig: &T,
        out: &'a mut Vec<u8>,
    ) {
        orig.bin_write(out).unwrap();

        let decoded = T::nom_read(out).unwrap();
        assert!(decoded.0.is_empty());
        assert_eq!(*orig, decoded.1);
    }

    #[cfg(feature = "alloc")]
    #[test]
    fn roundtrip_encdec() {
        use crate::instr::{
            ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction,
            RawBytes, RawPath, RevealInstruction, SetInstruction, ValueSource,
        };
        let path1 = RawPath("/aaa/bb/c".as_bytes());
        let path2 = RawPath("/xxx/cc/ad".as_bytes());
        roundtrip(&path1, &mut vec![]);
        roundtrip(&RawBytes("hello".as_bytes()), &mut vec![]);

        roundtrip(
            &CopyInstruction {
                from: path2,
                to: path1,
            },
            &mut vec![],
        );
        roundtrip(
            &MoveInstruction {
                from: RawPath("/d".as_bytes()),
                to: RawPath("/cc".as_bytes()),
            },
            &mut vec![],
        );

        roundtrip(
            &DeleteInstruction {
                path: RawPath("/pp".as_bytes()),
            },
            &mut vec![],
        );

        roundtrip(
            &ValueSource::Path(RawPath("/ccc/xx".as_bytes())),
            &mut vec![],
        );

        roundtrip(
            &ValueSource::Value(RawBytes("any bytes".as_bytes())),
            &mut vec![],
        );

        roundtrip(
            &SetInstruction {
                to: RawPath("/pp".as_bytes()),
                value: ValueSource::Path(RawPath("/ooo/bbb".as_bytes())),
            },
            &mut vec![],
        );

        roundtrip(
            &SetInstruction {
                to: RawPath("/pp".as_bytes()),
                value: ValueSource::Value(RawBytes("hello value".as_bytes())),
            },
            &mut vec![],
        );

        roundtrip(
            &RevealInstruction {
                to: RawPath("/fldl/sfjisfkj".as_bytes()),
                hash: ValueSource::Value(RawBytes(
                    "some hash should be 33 bytes".as_bytes(),
                )),
            },
            &mut vec![],
        );

        roundtrip(
            &ConfigInstruction::Set(SetInstruction {
                to: RawPath("/pp".as_bytes()),
                value: ValueSource::Value(RawBytes("hello value".as_bytes())),
            }),
            &mut vec![],
        );

        roundtrip(
            &ConfigInstruction::Reveal(RevealInstruction {
                to: RawPath("/fldl/sfjisfkj".as_bytes()),
                hash: ValueSource::Value(RawBytes(
                    "some hash should be 33 bytes".as_bytes(),
                )),
            }),
            &mut vec![],
        );
    }
}
