open Api
open Vectors
open Utils

module Resolver = Map.Make (struct
  type t = string * string * Types.Externkind.t

  let compare (l1, l2, l3) (r1, r2, r3) =
    match
      (String.compare l1 r1, String.compare l2 r2, Unsigned.UInt8.compare l3 r3)
    with
    | 0, 0, r -> r
    | 0, r, _ -> r
    | r, _, _ -> r
end)

exception Null

type t = {module_ : Module.t; instance : Types.Instance.t Ctypes.ptr}

exception
  Unsatisfied_import of {
    module_ : string;
    name : string;
    kind : Types.Externkind.t;
  }

let resolve_imports store modul resolver =
  let lookup import =
    let module_ = Import_type.module_ import in
    let name = Import_type.name import in
    let kind = Import_type.type_ import |> Functions.Externtype.kind in
    let match_ = Resolver.find_opt (module_, name, kind) resolver in
    match match_ with
    | None -> raise (Unsatisfied_import {module_; name; kind})
    | Some m -> Extern.to_extern store m
  in

  Module.imports modul |> Import_type_vector.to_array |> Array.map lookup
  |> Extern_vector.from_array

let create store module_ externs =
  let open Lwt.Syntax in
  let externs_vec =
    externs
    |> List.map (fun (module_, name, extern) ->
           ((module_, name, Extern.to_externkind extern), extern))
    |> List.to_seq |> Resolver.of_seq
    |> resolve_imports store module_
  in

  let trap = Ctypes.allocate_n (Ctypes.ptr Types.Trap.t) ~count:1 in
  Ctypes.(trap <-@ Trap.none) ;

  let+ instance =
    Lwt_preemptive.detach
      (fun (store, module_, externs_vec, trap) ->
        Functions.Instance.new_ store module_ (Ctypes.addr externs_vec) trap)
      (store, module_, externs_vec, trap)
  in
  check_null_ptr Null instance ;

  let trap = Ctypes.(!@trap) in
  Trap.check trap ;

  {module_; instance}

let delete inst = Functions.Instance.delete inst.instance
