open Api
open Vectors

type t = Types.Exporttype.t Ctypes.ptr

let name modul =
  let name = Functions.Exporttype.name modul in
  Name.to_string Ctypes.(!@name)

let type_ = Functions.Exporttype.type_
