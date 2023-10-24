// This is a generated file! Please edit source .ksy file and use kaitai-struct-compiler to rebuild

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['kaitai-struct/KaitaiStream'], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory(require('kaitai-struct/KaitaiStream'));
  } else {
    root.ListOfUint8 = factory(root.KaitaiStream);
  }
}(typeof self !== 'undefined' ? self : this, function (KaitaiStream) {
/**
 * Encoding id: list_of_uint8
 */

var ListOfUint8 = (function() {
  function ListOfUint8(_io, _parent, _root) {
    this._io = _io;
    this._parent = _parent;
    this._root = _root || this;

    this._read();
  }
  ListOfUint8.prototype._read = function() {
    this.listOfUint8Entries = [];
    for (var i = 0; i < 5; i++) {
      this.listOfUint8Entries.push(new ListOfUint8Entries(this._io, this, this._root));
    }
  }

  var ListOfUint8Entries = ListOfUint8.ListOfUint8Entries = (function() {
    function ListOfUint8Entries(_io, _parent, _root) {
      this._io = _io;
      this._parent = _parent;
      this._root = _root || this;

      this._read();
    }
    ListOfUint8Entries.prototype._read = function() {
      this.listOfUint8Elt = this._io.readU1();
    }

    return ListOfUint8Entries;
  })();

  return ListOfUint8;
})();
return ListOfUint8;
}));
