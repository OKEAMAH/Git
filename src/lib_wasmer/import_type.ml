open Api
open Vectors

let module_ modul =
  let name = Functions.Importtype.module_ modul in
  Name.to_string Ctypes.(!@name)

let name modul =
  let name = Functions.Importtype.name modul in
  Name.to_string Ctypes.(!@name)

let type_ = Functions.Importtype.type_
