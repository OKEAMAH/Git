(* open Tztest *)
open Tezos_webassembly_interpreter

(* open Tezos_scoru_wasm *)
open QCheck2.Gen

let gen_names : Ast.name_list t = list int

let types_gen = Ast_generators.(map no_region func_type_gen)

let global_type_gen =
  let* value = Ast_generators.value_type_gen in
  let* mt = oneofl [Types.Immutable; Types.Mutable] in
  let ty = Types.GlobalType (value, mt) in
  return ty

let const_gen = Ast_generators.(map no_region block_label_gen)

let glob_gen =
  let* gtype = global_type_gen in
  let* ginit = const_gen in
  return @@ Ast_generators.no_region Ast.{gtype; ginit}

let table'_gen =
  let* len = frequency [(10, int_range 1 10); (1, int_range 100 200)] in
  let* ttype = Ast_generators.table_type_gen len in
  return @@ Ast_generators.no_region Ast.{ttype}

let mem_gen =
  let open Ast_generators in
  let* mtype = memory_type_gen in
  let memory' = Ast.{mtype} in
  return @@ no_region memory'

let start_gen =
  let open Ast_generators in
  let* sfunc = var_gen in
  let start' = Ast.{sfunc} in
  oneof [return None; return @@ Some (no_region start')]

let segm_mode_gen =
  let open Ast_generators in
  let index = no_region 0l in
  let* offset = const_gen in
  map no_region @@ oneofl Ast.[Passive; Active {index; offset}]

let elm_seg_gen =
  let open Ast_generators in
  let* etype = ref_type_gen in
  let* einit = vector_gen const_gen in
  let* emode = segm_mode_gen in
  return @@ Ast_generators.no_region Ast.{etype; einit; emode}

let data_segm_gen =
  let* bs = string in
  let dinit = Chunked_byte_vector.Lwt.of_string bs in
  let* dmode = segm_mode_gen in
  return @@ Ast_generators.no_region Ast.{dinit; dmode}

let import_desc_gen =
  let open Ast_generators in
  let* var = var_gen in
  let* len = frequency [(10, int_range 1 10); (1, int_range 100 200)] in
  let* table_type = table_type_gen len in
  let* memory_type = memory_type_gen in
  let* global_type = global_type_gen in
  map no_region
  @@ oneofl
       Ast.
         [
           FuncImport var;
           TableImport table_type;
           MemoryImport memory_type;
           GlobalImport global_type;
         ]

let name_gen = Ast_generators.vector_gen int

let import_gen =
  let open Ast_generators in
  let* module_name = name_gen in
  let* item_name = name_gen in
  let* idesc = import_desc_gen in
  return @@ no_region @@ Ast.{module_name; item_name; idesc}

let det_import_gen list_of_imports =
  let open Ast_generators in
  let rand = Random.State.make_self_init () in
  let importsl =
    List.map
      (fun module_name ->
        let item_name = generate1 ~rand name_gen in
        let idesc = generate1 ~rand import_desc_gen in
        no_region @@ Ast.{module_name; item_name; idesc})
      list_of_imports
  in
  Lazy_vector.LwtInt32Vector.of_list importsl

let export_desc_gen =
  let open Ast_generators in
  let* var = var_gen in

  map no_region
  @@ oneofl
       Ast.[FuncExport var; TableExport var; MemoryExport var; GlobalExport var]

let export_gen =
  let* name = name_gen in
  let* edesc = export_desc_gen in
  return @@ Ast_generators.no_region Ast.{name; edesc}

let block_table_gen =
  let open Ast_generators in
  let instr_g =
    let* instr = instr_gen in
    return @@ Ast_generators.no_region instr.it
  in
  vector_gen @@ vector_gen instr_g

let module_generator =
  let open Ast_generators in
  let* types = vector_gen types_gen in
  let* globals = vector_gen glob_gen in
  let* tables = vector_gen table'_gen in
  let* memories = vector_gen mem_gen in
  let* funcs = vector_gen func'_gen in
  let* start = start_gen in
  let* elems = vector_gen elm_seg_gen in
  let* datas = vector_gen data_segm_gen in
  let* imports = vector_gen import_gen in
  let* exports = vector_gen export_gen in
  let* blocks = block_table_gen in

  return
    Ast.
      {
        types;
        globals;
        tables;
        memories;
        funcs;
        start;
        elems;
        datas;
        imports;
        exports;
        blocks;
      }

module Vector = Lazy_vector.LwtInt32Vector

let module_generator_det list_of_imports =
  let open Ast_generators in
  let* _types = vector_gen types_gen in
  let* _globals = vector_gen glob_gen in
  let* _tables = vector_gen table'_gen in
  let* _memories = vector_gen mem_gen in
  let* _funcs = vector_gen func'_gen in
  let* _start = start_gen in
  let* _elems = vector_gen elm_seg_gen in
  let* datas = vector_gen data_segm_gen in
  let imports = det_import_gen list_of_imports in
  let* _exports = vector_gen export_gen in
  let* _blocks = block_table_gen in

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
        datas;
        imports;
        exports = Vector.create 0l;
        blocks = Vector.create 0l;
      }
