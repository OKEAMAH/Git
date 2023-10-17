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
pub struct Id008Ptedo2zkScriptLoc {
    pub michelineLocation: i32,
}

impl KaitaiStruct for Id008Ptedo2zkScriptLoc {
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
        self.michelineLocation = self.stream.read_s4be()?;
    }
}

impl Id008Ptedo2zkScriptLoc {

    /*
     * Canonical location in a Micheline expression: The location of a node in a Micheline expression tree in prefix order, with zero being the root and adding one for every basic node, sequence and primitive application.
     */
}
