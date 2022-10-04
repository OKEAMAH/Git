module Config : sig
  type compiler = CRANELIFT | LLVM | SINGLEPASS

  type t = {compiler : compiler}

  val default : t
end

module Engine : sig
  type t

  val create : Config.t -> t
end

module Store : sig
  type t

  val create : Engine.t -> t
end

module Ref : sig
  type t
end

type _ typ

val i32 : int32 typ

val i64 : int64 typ

val f32 : float typ

val f64 : float typ

val anyref : Ref.t typ

val funcref : Ref.t typ

type _ fn

val ( @-> ) : 'a typ -> 'b fn -> ('a -> 'b) fn

val returning1 : 'a typ -> (unit -> 'a Lwt.t) fn

type 'a ret

val ( @** ) : 'a typ -> 'b typ -> ('a * 'b) ret

val ( @* ) : 'a typ -> 'b ret -> ('a * 'b) ret

val returning : 'a ret -> (unit -> 'a Lwt.t) fn

val void : (unit -> unit Lwt.t) fn

type extern

val fn : 'a fn -> 'a -> extern

module Module : sig
  type t

  val create_from_wasm : Store.t -> string -> t

  val create_from_wat : Store.t -> string -> t

  val delete : t -> unit
end

module Memory : sig
  include module type of Ctypes.CArray

  type t = Unsigned.uint8 Ctypes.carray
end

module Instance : sig
  type t

  val create : Store.t -> Module.t -> (string * string * extern) list -> t Lwt.t

  val delete : t -> unit
end

module Exports : sig
  type t

  val from_instance : Instance.t -> t

  val fn : t -> string -> 'a fn -> 'a

  val mem : t -> string -> Memory.t * Unsigned.uint32 * Unsigned.uint32

  val mem0 : t -> Memory.t * Unsigned.uint32 * Unsigned.uint32
end
