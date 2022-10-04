module Array = Ctypes.CArray

type t = {
  raw : Unsigned.uint8 Array.t;
  min : Unsigned.uint32;
  max : Unsigned.uint32 option;
}

let get mem = Array.get mem.raw

let set mem = Array.set mem.raw

let length mem = Array.length mem.raw
