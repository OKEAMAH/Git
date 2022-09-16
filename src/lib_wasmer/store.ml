open Api
open Utils

exception Failed_to_create

type t =
  (* TODO: Keep engine alive that was used during construction. *)
  Types.Store.t Ctypes.ptr

let create engine =
  let store = Functions.Store.new_ engine in
  check_null_ptr Failed_to_create store ;
  store

let delete = Functions.Store.delete
