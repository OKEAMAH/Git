open Api
open Vectors

module Resolver = Map.Make (struct
  type t = string * Types.Externkind.t

  let compare (l1, l2) (r1, r2) =
    match (String.compare l1 r1, Unsigned.UInt8.compare l2 r2) with
    | 0, r -> r
    | r, _ -> r
end)

type t =
  (* TODO: Keep originating instance alive. *)
  Types.Extern.t Ctypes.ptr Resolver.t

let from_instance inst =
  let exports =
    Module.exports inst.Instance.module_ |> Export_type_vector.to_list
  in
  let externs = Extern_vector.empty () in
  Functions.Instance.exports inst.instance (Ctypes.addr externs) ;
  let externs = Extern_vector.to_list externs in
  List.fold_right2
    (fun export extern tail ->
      let name = Export_type.name export in
      let kind = Export_type.type_ export |> Functions.Externtype.kind in
      Resolver.add (name, kind) extern tail)
    exports
    externs
    Resolver.empty

let fn exports name typ =
  let kind = Types.Externkind.func in
  let extern = Resolver.find (name, kind) exports in
  let func = Functions.Extern.as_func extern in
  let f = Function.call func typ in
  () ;
  (* ^ This causes the current function to cap its arity. E.g. in case it gets
     aggressively inlined we make sure that the resulting extern function is
     entirely separate. *)
  f

let mem_of_extern extern =
  let mem = Functions.Extern.as_memory extern in
  let mem_type = Functions.Memory.type_ mem in
  let limits = Functions.Memory_type.limits mem_type in
  let min, max =
    let open Ctypes in
    (!@(limits |-> Types.Limits.min), !@(limits |-> Types.Limits.max))
  in
  let array =
    Ctypes.CArray.from_ptr
      (Functions.Memory.data mem)
      (Functions.Memory.data_size mem |> Unsigned.Size_t.to_int)
  in
  (array, min, max)

let mem exports name =
  let kind = Types.Externkind.memory in
  let extern = Resolver.find (name, kind) exports in
  mem_of_extern extern

let mem0 exports =
  let _, extern =
    Resolver.bindings exports
    |> List.find (fun ((_, kind), extern) -> kind = Types.Externkind.memory)
  in
  mem_of_extern extern
