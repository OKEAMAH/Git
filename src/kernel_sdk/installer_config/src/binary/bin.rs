// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_data_encoding::enc::{BinError, BinResult, BinWriter};
use thiserror::Error;

use super::{
    ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction,
    RevealInstruction, SetInstruction,
};

impl<P: BinWriter> BinWriter for CopyInstruction<P> {
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        (|data: &Self, out: &mut Vec<u8>| {
            tezos_data_encoding::enc::field(
                "CopyInstruction::from",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.from, out)?;
            tezos_data_encoding::enc::field(
                "CopyInstruction::to",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.to, out)?;
            Ok(())
        })(self, out)
    }
}

impl<P: BinWriter> BinWriter for MoveInstruction<P> {
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        (|data: &Self, out: &mut Vec<u8>| {
            tezos_data_encoding::enc::field(
                "MoveInstruction::from",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.from, out)?;
            tezos_data_encoding::enc::field(
                "MoveInstruction::to",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.to, out)?;
            Ok(())
        })(self, out)
    }
}

impl<P: BinWriter> tezos_data_encoding::enc::BinWriter for DeleteInstruction<P> {
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        (|data: &Self, out: &mut Vec<u8>| {
            tezos_data_encoding::enc::field(
                "DeleteInstruction::path",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.path, out)?;
            Ok(())
        })(self, out)
    }
}

impl<P: BinWriter, B: BinWriter> tezos_data_encoding::enc::BinWriter
    for SetInstruction<P, B>
{
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        (|data: &Self, out: &mut Vec<u8>| {
            tezos_data_encoding::enc::field(
                "SetInstruction::value",
                <B as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.value, out)?;
            tezos_data_encoding::enc::field(
                "SetInstruction::to",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.to, out)?;
            Ok(())
        })(self, out)
    }
}

impl<P: BinWriter, B: BinWriter> tezos_data_encoding::enc::BinWriter
    for RevealInstruction<P, B>
{
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        (|data: &Self, out: &mut Vec<u8>| {
            tezos_data_encoding::enc::field(
                "RevealInstruction::hash",
                <B as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.hash, out)?;
            tezos_data_encoding::enc::field(
                "RevealInstruction::to",
                <P as tezos_data_encoding::enc::BinWriter>::bin_write,
            )(&data.to, out)?;
            Ok(())
        })(self, out)
    }
}

impl<P: BinWriter, B: BinWriter> tezos_data_encoding::enc::BinWriter
    for ConfigInstruction<P, B>
{
    fn bin_write(&self, out: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        match self {
          ConfigInstruction::Set(inner) => tezos_data_encoding::enc::variant_with_field("ConfigInstruction::Set",tezos_data_encoding::enc::u8, <SetInstruction<P,B>as tezos_data_encoding::enc::BinWriter> ::bin_write)(&0,inner,out),
          ConfigInstruction::Reveal(inner) => tezos_data_encoding::enc::variant_with_field("ConfigInstruction::Reveal",tezos_data_encoding::enc::u8, <RevealInstruction<P,B>as tezos_data_encoding::enc::BinWriter> ::bin_write)(&1,inner,out),
          ConfigInstruction::Copy(inner) => tezos_data_encoding::enc::variant_with_field("ConfigInstruction::Copy",tezos_data_encoding::enc::u8, <CopyInstruction<P>as tezos_data_encoding::enc::BinWriter> ::bin_write)(&2,inner,out),
          ConfigInstruction::Move(inner) => tezos_data_encoding::enc::variant_with_field("ConfigInstruction::Move",tezos_data_encoding::enc::u8, <MoveInstruction<P>as tezos_data_encoding::enc::BinWriter> ::bin_write)(&3,inner,out),
          ConfigInstruction::Delete(inner) => tezos_data_encoding::enc::variant_with_field("ConfigInstruction::Delete",tezos_data_encoding::enc::u8, <DeleteInstruction<P>as tezos_data_encoding::enc::BinWriter> ::bin_write)(&4,inner,out)

          }
    }
}

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
    tezos_data_encoding::enc::put_bytes(&size.to_be_bytes(), out);
    Ok(())
}

#[derive(Debug, PartialEq, Eq)]
pub struct RawPath(pub String);

impl BinWriter for RawPath {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        put_size(self.0.len(), output)?;
        tezos_data_encoding::enc::put_bytes(self.0.as_bytes(), output);
        Ok(())
    }
}

#[derive(Debug, PartialEq, Eq)]
pub struct Bytes(pub Vec<u8>);

impl BinWriter for Bytes {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        put_size(self.0.len(), output)?;
        tezos_data_encoding::enc::put_bytes(&self.0, output);
        Ok(())
    }
}

// This wrapper is necessary to prevent direct creation of
// ConfigInstruction because we want to create only valid instruction,
// for instance, with valid path, value size not exceeding max possible in set
// and 33 bytes reveal hash
#[derive(Debug)]
pub struct InstallerConfigInstruction(ConfigInstruction<RawPath, Bytes>);

#[derive(Debug, Error)]
pub enum ConfigInstructionInitError {}

impl InstallerConfigInstruction {
    pub fn copy_instr(
        from: String,
        to: String,
    ) -> Result<InstallerConfigInstruction, ConfigInstructionInitError> {
        // TODO verify path
        Ok(InstallerConfigInstruction(ConfigInstruction::Copy(
            CopyInstruction {
                from: RawPath(from),
                to: RawPath(to),
            },
        )))
    }

    pub fn move_instr(
        from: String,
        to: String,
    ) -> Result<InstallerConfigInstruction, ConfigInstructionInitError> {
        // TODO verify path
        Ok(InstallerConfigInstruction(ConfigInstruction::Move(
            MoveInstruction {
                from: RawPath(from),
                to: RawPath(to),
            },
        )))
    }

    pub fn delete_instr(
        path: String,
    ) -> Result<InstallerConfigInstruction, ConfigInstructionInitError> {
        // TODO verify path
        Ok(InstallerConfigInstruction(ConfigInstruction::Delete(
            DeleteInstruction {
                path: RawPath(path),
            },
        )))
    }

    pub fn set_instr(
        path: String,
        value: Vec<u8>,
    ) -> Result<InstallerConfigInstruction, ConfigInstructionInitError> {
        // TODO make sure value doesn't exceed max len
        // TODO verify path
        Ok(InstallerConfigInstruction(ConfigInstruction::Set(
            SetInstruction {
                value: Bytes(value),
                to: RawPath(path),
            },
        )))
    }

    pub fn reveal_instr(
        root_hash: Vec<u8>,
        to: String,
    ) -> Result<InstallerConfigInstruction, ConfigInstructionInitError> {
        // TODO make sure hash has expected length
        // TODO verify path
        Ok(InstallerConfigInstruction(ConfigInstruction::Reveal(
            RevealInstruction {
                hash: Bytes(root_hash),
                to: RawPath(to),
            },
        )))
    }
}

// Represents only valid programs
#[derive(Debug)]
pub struct InstallerConfigProgram(Vec<InstallerConfigInstruction>);

impl InstallerConfigProgram {
    // TODO Could possibly add checks that paths in operations are consistent,
    // for instance no accessing to pathes which weren't created before in the program
    pub fn new(instrs: Vec<InstallerConfigInstruction>) -> InstallerConfigProgram {
        InstallerConfigProgram(instrs)
    }
}

// Encode all commands with appended number of commands at the end.
// It makes possible for the installer_kernel to
// parse commands at the end of the kernel binary.
impl BinWriter for InstallerConfigProgram {
    fn bin_write(&self, output: &mut Vec<u8>) -> BinResult {
        let initial_size = output.len();
        for i in 0..self.0.len() {
            let mut current_instr = vec![];
            self.0[i].0.bin_write(&mut current_instr)?;
            // Put size of the instruction encoding first,
            // in order to make a decoding easier
            put_size(current_instr.len(), output)?;
            output.extend_from_slice(&current_instr);
        }
        put_size(output.len() - initial_size, output)?;
        Ok(())
    }
}

#[cfg(test)]
mod test {
    use std::fmt::Debug;

    use tezos_data_encoding::enc::BinWriter;

    use crate::binary::instr::{
        ConfigInstruction, CopyInstruction, DeleteInstruction, MoveInstruction, RefBytes,
        RefRawPath, RevealInstruction, SetInstruction,
    };

    use super::super::nom::NomReader;
    use super::{Bytes, RawPath};

    impl<'a> PartialEq<RefRawPath<'a>> for RawPath {
        fn eq(&self, other: &RefRawPath) -> bool {
            self.0.as_bytes().eq(other.0)
        }
    }

    impl<'a> PartialEq<RefBytes<'a>> for Bytes {
        fn eq(&self, other: &RefBytes) -> bool {
            self.0.eq(other.0)
        }
    }

    impl<'a> PartialEq<CopyInstruction<RefRawPath<'a>>> for CopyInstruction<RawPath> {
        fn eq(&self, other: &CopyInstruction<RefRawPath<'a>>) -> bool {
            self.from.eq(&other.from) && self.to.eq(&other.to)
        }
    }

    impl<'a> PartialEq<MoveInstruction<RefRawPath<'a>>> for MoveInstruction<RawPath> {
        fn eq(&self, other: &MoveInstruction<RefRawPath<'a>>) -> bool {
            self.from.eq(&other.from) && self.to.eq(&other.to)
        }
    }

    impl<'a> PartialEq<DeleteInstruction<RefRawPath<'a>>> for DeleteInstruction<RawPath> {
        fn eq(&self, other: &DeleteInstruction<RefRawPath<'a>>) -> bool {
            self.path.eq(&other.path)
        }
    }

    impl<'a> PartialEq<SetInstruction<RefRawPath<'a>, RefBytes<'a>>>
        for SetInstruction<RawPath, Bytes>
    {
        fn eq(&self, other: &SetInstruction<RefRawPath<'a>, RefBytes<'a>>) -> bool {
            self.value.eq(&other.value) && self.to.eq(&other.to)
        }
    }

    impl<'a> PartialEq<RevealInstruction<RefRawPath<'a>, RefBytes<'a>>>
        for RevealInstruction<RawPath, Bytes>
    {
        fn eq(&self, other: &RevealInstruction<RefRawPath<'a>, RefBytes<'a>>) -> bool {
            self.hash.eq(&other.hash) && self.to.eq(&other.to)
        }
    }

    impl<'a> PartialEq<ConfigInstruction<RefRawPath<'a>, RefBytes<'a>>>
        for ConfigInstruction<RawPath, Bytes>
    {
        fn eq(&self, other: &ConfigInstruction<RefRawPath<'a>, RefBytes<'a>>) -> bool {
            use ConfigInstruction::*;
            match (self, other) {
                (Set(s), Set(o)) => s.eq(o),
                (Reveal(s), Reveal(o)) => s.eq(o),
                (Copy(s), Copy(o)) => s.eq(o),
                (Move(s), Move(o)) => s.eq(o),
                (Delete(s), Delete(o)) => s.eq(o),
                _ => false,
            }
        }
    }

    // I have to pass `out` here because for some reason
    // borrow checker complaines about this line:
    //    `T::nom_read(out).unwrap()`
    // saying that `out` is dropped but still borrowed in this line,
    // despite the faact `decoded` should be dropped on leaving the function
    fn roundtrip<
        'a,
        R: NomReader<'a> + Eq + Debug,
        T: PartialEq<R> + BinWriter + Debug,
    >(
        orig: &T,
        out: &'a mut Vec<u8>,
    ) {
        orig.bin_write(out).unwrap();

        let decoded = R::nom_read(out).unwrap();
        assert!(decoded.0.is_empty());
        assert_eq!(*orig, decoded.1);
    }

    #[test]
    fn roundtrip_encdec() {
        let path1 = RawPath("/aaa/bb/c".to_owned());
        let path2 = RawPath("/xxx/cc/ad".to_owned());
        roundtrip::<RefRawPath, RawPath>(&path1, &mut vec![]);
        roundtrip::<RefBytes, Bytes>(&Bytes("hello".as_bytes().to_owned()), &mut vec![]);

        roundtrip::<CopyInstruction<RefRawPath>, CopyInstruction<RawPath>>(
            &CopyInstruction {
                from: path2,
                to: path1,
            },
            &mut vec![],
        );
        roundtrip::<MoveInstruction<RefRawPath>, MoveInstruction<RawPath>>(
            &MoveInstruction {
                from: RawPath("/d".to_string()),
                to: RawPath("/cc".to_string()),
            },
            &mut vec![],
        );

        roundtrip::<DeleteInstruction<RefRawPath>, DeleteInstruction<RawPath>>(
            &DeleteInstruction {
                path: RawPath("/pp".to_string()),
            },
            &mut vec![],
        );

        roundtrip::<SetInstruction<RefRawPath, RefBytes>, SetInstruction<RawPath, Bytes>>(
            &SetInstruction {
                to: RawPath("/pp".to_string()),
                value: Bytes("hello value".as_bytes().to_owned()),
            },
            &mut vec![],
        );

        roundtrip::<
            RevealInstruction<RefRawPath, RefBytes>,
            RevealInstruction<RawPath, Bytes>,
        >(
            &RevealInstruction {
                to: RawPath("/fldl/sfjisfkj".to_string()),
                hash: Bytes("some hash should be 33 bytes".as_bytes().to_owned()),
            },
            &mut vec![],
        );

        roundtrip::<
            ConfigInstruction<RefRawPath, RefBytes>,
            ConfigInstruction<RawPath, Bytes>,
        >(
            &ConfigInstruction::Set(SetInstruction {
                to: RawPath("/pp".to_string()),
                value: Bytes("hello value".as_bytes().to_owned()),
            }),
            &mut vec![],
        );

        roundtrip::<
            ConfigInstruction<RefRawPath, RefBytes>,
            ConfigInstruction<RawPath, Bytes>,
        >(
            &ConfigInstruction::Reveal(RevealInstruction {
                to: RawPath("/fldl/sfjisfkj".to_string()),
                hash: Bytes("some hash should be 33 bytes".as_bytes().to_owned()),
            }),
            &mut vec![],
        );
    }
}
