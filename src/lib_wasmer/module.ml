open Utils
open Vectors
open Api

exception Failed_to_create

type t = Types.Module.t Ctypes.ptr

let wat2wasm code =
  let source = Byte_vector.from_string code in
  let dest = Byte_vector.empty () in
  Functions.wat2wasm (Ctypes.addr source) (Ctypes.addr dest) ;
  dest

let create_from_wasm store code =
  let wasm = Byte_vector.from_string code in
  let modul = Functions.Module.new_ store (Ctypes.addr wasm) in
  Byte_vector.delete wasm ;
  check_null_ptr Failed_to_create modul ;
  modul

let create_from_wat store code =
  let wasm = wat2wasm code in
  let modul = Functions.Module.new_ store (Ctypes.addr wasm) in
  Byte_vector.delete wasm ;
  check_null_ptr Failed_to_create modul ;
  modul

let imports modul =
  let outputs = Import_type_vector.empty () in
  Functions.Module.imports modul (Ctypes.addr outputs) ;
  outputs

let exports modul =
  let outputs = Export_type_vector.empty () in
  Functions.Module.exports modul (Ctypes.addr outputs) ;
  outputs

let delete = Functions.Module.delete
