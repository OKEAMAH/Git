open Api
open Vectors

exception Trap of string

let none = Ctypes.from_voidp Types.Trap.t Ctypes.null

let from_string store str =
  let msg = Message.from_string (str ^ "\000") in
  Functions.Trap.new_ store (Ctypes.addr msg)

let message trap =
  let msg = Message.empty () in
  Functions.Trap.message trap (Ctypes.addr msg) ;
  Message.to_string msg

let check trap = if not (Ctypes.is_null trap) then raise (Trap (message trap))
