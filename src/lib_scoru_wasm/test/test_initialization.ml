open Tezos_webassembly_interpreter
open Instance
open Tezos_scoru_wasm
module Context = Tezos_context_memory.Context_binary
open QCheck2.Gen
open Tztest

let det_import_gen list_of_imports =
  let open Ast_generators in
  let memory_type = Types.(MemoryType {min = 1l; max = Some 3l}) in
  let importsl =
    List.map
      (fun module_name ->
        let item_name = Utf8.decode "memory" in
        let idesc = no_region @@ Ast.MemoryImport memory_type in
        no_region @@ Ast.{module_name; item_name; idesc})
      list_of_imports
  in
  Lazy_vector.LwtInt32Vector.of_list importsl

module Vector = Lazy_vector.LwtInt32Vector

let module_generator_det list_of_imports =
  let allocations =
    let blocks = Vector.create 0l in
    let datas = Vector.create 0l in
    Ast.{blocks; datas}
  in

  (* let b = Vector.num_elements allocations.blocks in *)
  let imports = det_import_gen list_of_imports in

  return
    Ast.
      {
        types = Vector.create 0l;
        globals = Vector.create 0l;
        tables = Vector.create 0l;
        memories = Vector.create 0l;
        funcs = Vector.create 0l;
        start = None;
        elems = Vector.create 0l;
        datas = Vector.create 0l;
        imports;
        exports = Vector.create 0l;
        allocations;
      }

module Tree = struct
  type t = Context.t

  type tree = Context.tree

  type key = Context.key

  type value = Context.value

  include Context.Tree
end

module Wasm = Wasm_pvm.Make (Tree)
module EncDec = Tree_encoding_decoding.Make (Tree)
module Wasm_encoding = Wasm_encoding.Make (EncDec)

let current_tick_encoding =
  EncDec.value ["wasm"; "current_tick"] Data_encoding.z

let status_encoding = EncDec.value ["input"; "consuming"] Data_encoding.bool

let floppy_encoding =
  EncDec.value
    ["gather-floppies"; "status"]
    Gather_floppies.internal_status_encoding

let initialise_tree () =
  let open Lwt_syntax in
  let* tree =
    let open Lwt_syntax in
    let* index = Context.init "/tmp" in
    let empty_store = Context.empty index in
    return (Context.Tree.empty empty_store)
  in

  let* tree = EncDec.encode current_tick_encoding Z.zero tree in
  let* tree =
    EncDec.encode floppy_encoding Gather_floppies.Not_gathering_floppies tree
  in
  let* tree = EncDec.encode status_encoding true tree in
  Lwt.return tree

let x0 =
  QCheck2.Gen.generate1
    ~rand:(Random.State.make_self_init ())
    (module_generator_det [Utf8.decode "m1"; Utf8.decode "m2"])

let x1 =
  QCheck2.Gen.generate1
    ~rand:(Random.State.make_self_init ())
    (module_generator_det [Utf8.decode "m3"])

let x2 =
  QCheck2.Gen.generate1
    ~rand:(Random.State.make_self_init ())
    (module_generator_det [])

let x3 =
  QCheck2.Gen.generate1
    ~rand:(Random.State.make_self_init ())
    (module_generator_det [])

let name_list name = Lwt_main.run @@ Ast.Vector.to_list @@ Utf8.decode name

let maps =
  Ast_generators.
    [
      (name_list "m0", no_region x0);
      (name_list "m1", no_region x1);
      (name_list "m2", no_region x2);
      (name_list "m3", no_region x3);
    ]

let map =
  List.fold_left (fun m (a, b) -> NameMap.(set a b m)) (NameMap.create ()) maps

let memory_gen =
  let ty = Types.(MemoryType {min = 1l; max = Some 3l}) in
  let bs = "hello" in
  let chunks = Chunked_byte_vector.Lwt.of_string bs in
  return @@ Memory.of_chunks ty chunks

let memory = QCheck2.Gen.generate1 memory_gen

let lookup name =
  let open Lwt.Syntax in
  let+ name = Utf8.encode name in
  match name with "memory" -> ExternMemory memory | _ -> assert false

let print = Format.asprintf "%a" Ast_printer.pp_module

let check_modules module_name tree =
  let open Lwt_result_syntax in
  let host_function_registry =
    Tezos_webassembly_interpreter.Host_funcs.empty ()
  in
  let*! decoded =
    EncDec.(
      decode (Wasm_encoding.module_instance_encoding ~module_name ()) tree)
  in
  let*! module_ = NameMap.get (name_list module_name) map in
  let*! initialised =
    let m = Ast_generators.no_region module_.it in
    let*! imports = Import.link m in
    Eval.init host_function_registry m imports
  in
  assert (print decoded = print initialised) ;
  return_unit

let test () =
  let open Lwt_result_syntax in
  let*! _ =
    List.fold_left
      (fun _ x -> Import.register ~module_name:(Utf8.decode x) lookup)
      Lwt.return_unit
      ["m0"; "m1"; "m2"; "m3"]
  in

  let*! tree = initialise_tree () in
  let host_function_registry =
    Tezos_webassembly_interpreter.Host_funcs.empty ()
  in

  let*! tree =
    Wasm.initialize ~host_function_registry map tree (Utf8.decode "m0")
  in
  let*! _ = check_modules "m0" tree in
  let*! _ = check_modules "m1" tree in
  let*! _ = check_modules "m2" tree in
  let*! _ = check_modules "m3" tree in

  return_unit

(* let decode_encode enc x =
     let open Lwt_syntax in
     let* t =
       let open Lwt_syntax in
       let* index = Context.init "/tmp" in
       let empty_store = Context.empty index in
       return @@ Context.Tree.empty empty_store
     in
     let* t1 = EncDec.encode enc x t in
     EncDec.decode enc t1

   let assert_string_equal s1 s2 =
     let open Lwt_result_syntax in
     if String.equal s1 s2 then return_unit else failwith "Not equal"

   (** Test serialize/deserialize empty_mem. *)
   let test_mem () =
     let open Lwt_result_syntax in
     let print = Format.asprintf "%a" Ast_printer.pp_memory in
     let mem1 =
       let ty = Types.(MemoryType {min = 1l; max = Some 3l}) in
       Memory.alloc ty
     in
     let mem1_str = print mem1 in
     let*! mem2 = decode_encode Wasm_encoding.memory_encoding mem1 in
     let mem2_str = print mem2 in

     assert_string_equal mem1_str mem2_str *)

let tests =
  [tztest "initialisation" `Quick test (* tztest "memory" `Quick test_mem *)]
