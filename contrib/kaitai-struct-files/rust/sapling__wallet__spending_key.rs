// This is a generated file! Please edit source .ksy file and use kaitai-struct-compiler to rebuild

use std::option::Option;
use std::boxed::Box;
use std::io::Result;
use std::io::Cursor;
use std::vec::Vec;
use std::default::Default;
use kaitai_struct::KaitaiStream;
use kaitai_struct::KaitaiStruct;

#[derive(Default)]
pub struct SaplingWalletSpendingKey {
    pub depth: Vec<u8>,
    pub parentFvkTag: Vec<u8>,
    pub childIndex: Vec<u8>,
    pub chainCode: Vec<u8>,
    pub expsk: Box<SaplingWalletSpendingKey__SaplingWalletExpandedSpendingKey>,
    pub dk: Vec<u8>,
}

impl KaitaiStruct for SaplingWalletSpendingKey {
    fn new<S: KaitaiStream>(stream: &mut S,
                            _parent: &Option<Box<KaitaiStruct>>,
                            _root: &Option<Box<KaitaiStruct>>)
                            -> Result<Self>
        where Self: Sized {
        let mut s: Self = Default::default();

        s.stream = stream;
        s.read(stream, _parent, _root)?;

        Ok(s)
    }


    fn read<S: KaitaiStream>(&mut self,
                             stream: &mut S,
                             _parent: &Option<Box<KaitaiStruct>>,
                             _root: &Option<Box<KaitaiStruct>>)
                             -> Result<()>
        where Self: Sized {
        self.depth = self.stream.read_bytes(1)?;
        self.parentFvkTag = self.stream.read_bytes(4)?;
        self.childIndex = self.stream.read_bytes(4)?;
        self.chainCode = self.stream.read_bytes(32)?;
        self.expsk = Box::new(SaplingWalletSpendingKey__SaplingWalletExpandedSpendingKey::new(self.stream, self, _root)?);
        self.dk = self.stream.read_bytes(32)?;
    }
}

impl SaplingWalletSpendingKey {
}
#[derive(Default)]
pub struct SaplingWalletSpendingKey__SaplingWalletExpandedSpendingKey {
    pub ask: Vec<u8>,
    pub nsk: Vec<u8>,
    pub ovk: Vec<u8>,
}

impl KaitaiStruct for SaplingWalletSpendingKey__SaplingWalletExpandedSpendingKey {
    fn new<S: KaitaiStream>(stream: &mut S,
                            _parent: &Option<Box<KaitaiStruct>>,
                            _root: &Option<Box<KaitaiStruct>>)
                            -> Result<Self>
        where Self: Sized {
        let mut s: Self = Default::default();

        s.stream = stream;
        s.read(stream, _parent, _root)?;

        Ok(s)
    }


    fn read<S: KaitaiStream>(&mut self,
                             stream: &mut S,
                             _parent: &Option<Box<KaitaiStruct>>,
                             _root: &Option<Box<KaitaiStruct>>)
                             -> Result<()>
        where Self: Sized {
        self.ask = self.stream.read_bytes(32)?;
        self.nsk = self.stream.read_bytes(32)?;
        self.ovk = self.stream.read_bytes(32)?;
    }
}

impl SaplingWalletSpendingKey__SaplingWalletExpandedSpendingKey {
}
