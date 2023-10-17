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
pub struct Id018ProxfordConstantsFixed {
    pub proofOfWorkNonceSize: u8,
    pub nonceLength: u8,
    pub maxAnonOpsPerBlock: u8,
    pub maxOperationDataLength: i32,
    pub maxProposalsPerDelegate: u8,
    pub maxMichelineNodeCount: i32,
    pub maxMichelineBytesLimit: i32,
    pub maxAllowedGlobalConstantsDepth: i32,
    pub cacheLayoutSize: u8,
    pub michelsonMaximumTypeSize: u16,
    pub smartRollupMaxWrappedProofBinarySize: i32,
    pub smartRollupMessageSizeLimit: i32,
    pub smartRollupMaxNumberOfMessagesPerLevel: Box<Id018ProxfordConstantsFixed__N>,
}

impl KaitaiStruct for Id018ProxfordConstantsFixed {
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
        self.proofOfWorkNonceSize = self.stream.read_u1()?;
        self.nonceLength = self.stream.read_u1()?;
        self.maxAnonOpsPerBlock = self.stream.read_u1()?;
        self.maxOperationDataLength = self.stream.read_s4be()?;
        self.maxProposalsPerDelegate = self.stream.read_u1()?;
        self.maxMichelineNodeCount = self.stream.read_s4be()?;
        self.maxMichelineBytesLimit = self.stream.read_s4be()?;
        self.maxAllowedGlobalConstantsDepth = self.stream.read_s4be()?;
        self.cacheLayoutSize = self.stream.read_u1()?;
        self.michelsonMaximumTypeSize = self.stream.read_u2be()?;
        self.smartRollupMaxWrappedProofBinarySize = self.stream.read_s4be()?;
        self.smartRollupMessageSizeLimit = self.stream.read_s4be()?;
        self.smartRollupMaxNumberOfMessagesPerLevel = Box::new(Id018ProxfordConstantsFixed__N::new(self.stream, self, _root)?);
    }
}

impl Id018ProxfordConstantsFixed {
}
#[derive(Default)]
pub struct Id018ProxfordConstantsFixed__N {
    pub n: Vec<Box<Id018ProxfordConstantsFixed__NChunk>>,
}

impl KaitaiStruct for Id018ProxfordConstantsFixed__N {
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
        self.n = vec!();
        while {
            let tmpa = Box::new(Id018ProxfordConstantsFixed__NChunk::new(self.stream, self, _root)?);
            self.n.append(tmpa);
            !(!(tmpa.has_more))
        } { }
    }
}

impl Id018ProxfordConstantsFixed__N {
}
#[derive(Default)]
pub struct Id018ProxfordConstantsFixed__NChunk {
    pub hasMore: bool,
    pub payload: u64,
}

impl KaitaiStruct for Id018ProxfordConstantsFixed__NChunk {
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
        self.hasMore = self.stream.read_bits_int(1)? != 0;
        self.payload = self.stream.read_bits_int(7)?;
    }
}

impl Id018ProxfordConstantsFixed__NChunk {
}
