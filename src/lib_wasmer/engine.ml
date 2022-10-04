open Utils
open Api

exception Failed_to_create

type t = Types.Engine.t Ctypes.ptr

let create config =
  let config = Config.to_owned config in
  let engine = Functions.Engine.new_with_config config in
  check_null_ptr Failed_to_create engine ;
  engine

let delete = Functions.Engine.delete
