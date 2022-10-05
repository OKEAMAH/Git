(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Tezos_webassembly_interpreter.Eval
module Parser = Binary_parser_encodings
open Tree_encoding
open Kont_encodings

let tag_encoding = value [] Data_encoding.string

let lazy_vec_encoding enc = int32_lazy_vector (value [] Data_encoding.int32) enc

let eval_const_kont_encoding ~host_funcs =
  let ec_next_enc = Wasm_encoding.config_encoding ~host_funcs in
  let ec_stop_enc = Wasm_encoding.value_encoding in
  let select_encode = function
    | EC_Next c ->
        destruction ~tag:"EC_Next" ~res:(Lwt.return c) ~delegate:ec_next_enc
    | EC_Stop v ->
        destruction ~tag:"EC_Stop" ~res:(Lwt.return v) ~delegate:ec_stop_enc
  in
  let select_decode = function
    | "EC_Next" ->
        decoding_branch
          ~extract:(fun c -> Lwt.return @@ EC_Next c)
          ~delegate:ec_next_enc
    | "EC_Stop" ->
        decoding_branch
          ~extract:(fun v -> Lwt.return @@ EC_Stop v)
          ~delegate:ec_stop_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union tag_encoding ~select_encode ~select_decode

let create_global_kont_encoding ~host_funcs =
  tup2
    ~flatten:true
    (value ["global_type"] Interpreter_encodings.Types.global_type_encoding)
    (scope ["kont"] (eval_const_kont_encoding ~host_funcs))

let create_elem_kont_encoding ~host_funcs =
  tick_map_kont_encoding
    (eval_const_kont_encoding ~host_funcs)
    (lazy_vec_encoding (value [] Interpreter_encodings.Ast.const_encoding))
    (lazy_vec_encoding Wasm_encoding.value_ref_encoding)

let join_kont_encoding enc_b =
  let j_init_enc = lazy_vec_encoding (lazy_vec_encoding enc_b) in
  let j_next_enc =
    tup2
      ~flatten:true
      (scope ["kont"] (concat_kont_encoding (lazy_vec_encoding enc_b)))
      (scope ["acc"] (lazy_vec_encoding (lazy_vec_encoding enc_b)))
  in
  let j_stop_enc = lazy_vec_encoding enc_b in
  let select_encode = function
    | J_Init v ->
        destruction ~tag:"J_Init" ~res:(Lwt.return v) ~delegate:j_init_enc
    | J_Next (kont, acc) ->
        destruction
          ~tag:"J_Next"
          ~res:(Lwt.return (kont, acc))
          ~delegate:j_next_enc
    | J_Stop res ->
        destruction ~tag:"J_Stop" ~res:(Lwt.return res) ~delegate:j_stop_enc
  in
  let select_decode = function
    | "J_Init" ->
        decoding_branch
          ~extract:(fun v -> Lwt.return @@ J_Init v)
          ~delegate:j_init_enc
    | "J_Next" ->
        decoding_branch
          ~extract:(fun (kont, acc) -> Lwt.return @@ J_Next (kont, acc))
          ~delegate:j_next_enc
    | "J_Stop" ->
        decoding_branch
          ~extract:(fun res -> Lwt.return @@ J_Stop res)
          ~delegate:j_stop_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union tag_encoding ~select_encode ~select_decode

let map_concat_kont_encoding enc_a enc_b =
  let mc_map_enc =
    map_kont_encoding
      (lazy_vec_encoding enc_a)
      (lazy_vec_encoding (lazy_vec_encoding enc_b))
  in
  let mc_join_enc = join_kont_encoding enc_b in
  let select_encode = function
    | MC_Map m ->
        destruction ~tag:"MC_Map" ~res:(Lwt.return m) ~delegate:mc_map_enc
    | MC_Join j ->
        destruction ~tag:"MC_Join" ~res:(Lwt.return j) ~delegate:mc_join_enc
  in
  let select_decode = function
    | "MC_Map" ->
        decoding_branch
          ~extract:(fun m -> Lwt.return @@ MC_Map m)
          ~delegate:mc_map_enc
    | "MC_Join" ->
        decoding_branch
          ~extract:(fun m -> Lwt.return @@ MC_Join m)
          ~delegate:mc_join_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union tag_encoding ~select_encode ~select_decode

let exports_acc_encoding =
  conv
    (fun (exports_memory_0, exports) -> {exports_memory_0; exports})
    (fun {exports_memory_0; exports} -> (exports_memory_0, exports))
    (tup2
       ~flatten:true
       (value ["exports-memory-0"] Data_encoding.bool)
       (scope ["exports"] Wasm_encoding.extern_map_encoding))

let init_kont_encoding ~host_funcs =
  let ik_start_enc =
    scope ["externs"] (lazy_vec_encoding Wasm_encoding.extern_encoding)
  in

  let ik_add_import_enc =
    fold_right2_kont_encoding
      (lazy_vec_encoding Wasm_encoding.extern_encoding)
      (lazy_vec_encoding Parser.(no_region_encoding Import.import_encoding))
      Wasm_encoding.module_instance_encoding
  in
  let ik_type_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (map_kont_encoding
            (lazy_vec_encoding
               Parser.(no_region_encoding Wasm_encoding.func_type_encoding))
            Wasm_encoding.function_type_vector_encoding))
  in
  let ik_aggregate_enc enc_kont enc_a enc_b =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (tick_map_kont_encoding
            enc_kont
            (lazy_vec_encoding enc_a)
            (lazy_vec_encoding enc_b)))
  in
  let ik_aggregate_concat_enc enc_b =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope ["kont"] (concat_kont_encoding (lazy_vec_encoding enc_b)))
  in
  let ik_aggregate_func_enc =
    let a = Parser.Code.func_encoding and b = Wasm_encoding.function_encoding in
    ik_aggregate_enc (either a b) a b
  in
  let ik_aggregate_concat_func_enc =
    ik_aggregate_concat_enc Wasm_encoding.function_encoding
  in
  let ik_aggregate_global_enc =
    let ab = create_global_kont_encoding ~host_funcs in
    let a = value [] Interpreter_encodings.Ast.global_encoding in
    let b = Wasm_encoding.global_encoding in
    ik_aggregate_enc ab a b
  in
  let ik_aggregate_concat_global_enc =
    ik_aggregate_concat_enc Wasm_encoding.global_encoding
  in
  let ik_aggregate_table_enc =
    let a = value [] Interpreter_encodings.Ast.table_encoding in
    let b = Wasm_encoding.table_encoding in
    ik_aggregate_enc (either a b) a b
  in
  let ik_aggregate_concat_table_enc =
    ik_aggregate_concat_enc Wasm_encoding.table_encoding
  in
  let ik_aggregate_memory_enc =
    let a = value [] Interpreter_encodings.Ast.memory_encoding in
    let b = Wasm_encoding.memory_encoding in
    ik_aggregate_enc (either a b) a b
  in
  let ik_aggregate_concat_memory_enc =
    ik_aggregate_concat_enc Wasm_encoding.memory_encoding
  in
  let ik_exports_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope ["kont"]
      @@ fold_left_kont_encoding
           (lazy_vec_encoding
              Parser.(no_region_encoding Export.export_encoding))
           exports_acc_encoding)
  in
  let ik_elems_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (tick_map_kont_encoding
            (create_elem_kont_encoding ~host_funcs)
            (lazy_vec_encoding Parser.(no_region_encoding Elem.elem_encoding))
            (lazy_vec_encoding
               (conv ref ( ! ) Wasm_encoding.value_ref_vector_encoding))))
  in
  let ik_datas_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (map_kont_encoding
            (lazy_vec_encoding
               Parser.(no_region_encoding Data.data_segment_encoding))
            (lazy_vec_encoding Wasm_encoding.data_label_ref_encoding)))
  in
  let ik_es_elems_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (map_concat_kont_encoding
            Parser.(no_region_encoding Elem.elem_encoding)
            Wasm_encoding.admin_instr_encoding))
  in
  let ik_es_datas_enc =
    tup3
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope
         ["kont"]
         (map_concat_kont_encoding
            Parser.(no_region_encoding Data.data_segment_encoding)
            Wasm_encoding.admin_instr_encoding))
      (scope ["es_elem"] (lazy_vec_encoding Wasm_encoding.admin_instr_encoding))
  in
  let ik_join_admin_enc =
    tup2
      ~flatten:true
      (scope ["module"] Wasm_encoding.module_instance_encoding)
      (scope ["kont"] (join_kont_encoding Wasm_encoding.admin_instr_encoding))
  in
  let ik_eval_enc =
    scope ["config"] (Wasm_encoding.config_encoding ~host_funcs)
  in
  let ik_stop_enc = value [] (Data_encoding.constant "ik_stop") in
  let select_encode = function
    | IK_Start exts ->
        destruction
          ~tag:"IK_Start"
          ~res:(Lwt.return exts)
          ~delegate:ik_start_enc
    | IK_Add_import m ->
        destruction
          ~tag:"IK_Add_import"
          ~res:(Lwt.return m)
          ~delegate:ik_add_import_enc
    | IK_Type (m, t) ->
        destruction
          ~tag:"IK_Types"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_type_enc
    | IK_Aggregate (m, Func, t) ->
        destruction
          ~tag:"IK_Aggregate_fun"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_func_enc
    | IK_Aggregate_concat (m, Func, t) ->
        destruction
          ~tag:"IK_Aggregate_concat_fun"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_concat_func_enc
    | IK_Aggregate (m, Global, t) ->
        destruction
          ~tag:"IK_Aggregate_global"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_global_enc
    | IK_Aggregate_concat (m, Global, t) ->
        destruction
          ~tag:"IK_Aggregate_concat_global"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_concat_global_enc
    | IK_Aggregate (m, Table, t) ->
        destruction
          ~tag:"IK_Aggregate_table"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_table_enc
    | IK_Aggregate_concat (m, Table, t) ->
        destruction
          ~tag:"IK_Aggregate_concat_table"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_concat_table_enc
    | IK_Aggregate (m, Memory, t) ->
        destruction
          ~tag:"IK_Aggregate_memory"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_memory_enc
    | IK_Aggregate_concat (m, Memory, t) ->
        destruction
          ~tag:"IK_Aggregate_concat_memory"
          ~res:(Lwt.return (m, t))
          ~delegate:ik_aggregate_concat_memory_enc
    | IK_Exports (inst, fold) ->
        destruction
          ~tag:"IK_Exports"
          ~res:(Lwt.return (inst, fold))
          ~delegate:ik_exports_enc
    | IK_Elems (inst, map) ->
        destruction
          ~tag:"IK_Elems"
          ~res:(Lwt.return (inst, map))
          ~delegate:ik_elems_enc
    | IK_Datas (inst, map) ->
        destruction
          ~tag:"IK_Datas"
          ~res:(Lwt.return (inst, map))
          ~delegate:ik_datas_enc
    | IK_Es_elems (inst, map) ->
        destruction
          ~tag:"IK_Es_elems"
          ~res:(Lwt.return (inst, map))
          ~delegate:ik_es_elems_enc
    | IK_Es_datas (inst, map, es_elem) ->
        destruction
          ~tag:"IK_Es_datas"
          ~res:(Lwt.return (inst, map, es_elem))
          ~delegate:ik_es_datas_enc
    | IK_Join_admin (m, admin) ->
        destruction
          ~tag:"IK_Join_admin"
          ~res:(Lwt.return (m, admin))
          ~delegate:ik_join_admin_enc
    | IK_Eval config ->
        destruction
          ~tag:"IK_Eval"
          ~res:(Lwt.return config)
          ~delegate:ik_eval_enc
    | IK_Stop ->
        destruction ~tag:"IK_Stop" ~res:Lwt.return_unit ~delegate:ik_stop_enc
  in
  let select_decode = function
    | "IK_Start" ->
        decoding_branch
          ~extract:(fun exts -> Lwt.return @@ IK_Start exts)
          ~delegate:ik_start_enc
    | "IK_Add_import" ->
        decoding_branch
          ~extract:(function m -> Lwt.return @@ IK_Add_import m)
          ~delegate:ik_add_import_enc
    | "IK_Types" ->
        decoding_branch
          ~extract:(function m, t -> Lwt.return @@ IK_Type (m, t))
          ~delegate:ik_type_enc
    | "IK_Aggregate_fun" ->
        decoding_branch
          ~extract:(function m, t -> Lwt.return @@ IK_Aggregate (m, Func, t))
          ~delegate:ik_aggregate_func_enc
    | "IK_Aggregate_concat_fun" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate_concat (m, Func, t))
          ~delegate:ik_aggregate_concat_func_enc
    | "IK_Aggregate_global" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate (m, Global, t))
          ~delegate:ik_aggregate_global_enc
    | "IK_Aggregate_concat_global" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate_concat (m, Global, t))
          ~delegate:ik_aggregate_concat_global_enc
    | "IK_Aggregate_table" ->
        decoding_branch
          ~extract:(function m, t -> Lwt.return @@ IK_Aggregate (m, Table, t))
          ~delegate:ik_aggregate_table_enc
    | "IK_Aggregate_concat_table" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate_concat (m, Table, t))
          ~delegate:ik_aggregate_concat_table_enc
    | "IK_Aggregate_memory" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate (m, Memory, t))
          ~delegate:ik_aggregate_memory_enc
    | "IK_Aggregate_concat_memory" ->
        decoding_branch
          ~extract:(function
            | m, t -> Lwt.return @@ IK_Aggregate_concat (m, Memory, t))
          ~delegate:ik_aggregate_concat_memory_enc
    | "IK_Exports" ->
        decoding_branch
          ~extract:(function
            | inst, fold -> Lwt.return @@ IK_Exports (inst, fold))
          ~delegate:ik_exports_enc
    | "IK_Elems" ->
        decoding_branch
          ~extract:(function inst, map -> Lwt.return @@ IK_Elems (inst, map))
          ~delegate:ik_elems_enc
    | "IK_Datas" ->
        decoding_branch
          ~extract:(function inst, map -> Lwt.return @@ IK_Datas (inst, map))
          ~delegate:ik_datas_enc
    | "IK_Es_elems" ->
        decoding_branch
          ~extract:(function
            | inst, map -> Lwt.return @@ IK_Es_elems (inst, map))
          ~delegate:ik_es_elems_enc
    | "IK_Es_datas" ->
        decoding_branch
          ~extract:(function
            | inst, map, es_elem ->
                Lwt.return @@ IK_Es_datas (inst, map, es_elem))
          ~delegate:ik_es_datas_enc
    | "IK_Join_admin" ->
        decoding_branch
          ~extract:(function
            | m, admin -> Lwt.return @@ IK_Join_admin (m, admin))
          ~delegate:ik_join_admin_enc
    | "IK_Eval" ->
        decoding_branch
          ~extract:(function config -> Lwt.return @@ IK_Eval config)
          ~delegate:ik_eval_enc
    | "IK_Stop" ->
        decoding_branch
          ~extract:(function () -> Lwt.return @@ IK_Stop)
          ~delegate:ik_stop_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union tag_encoding ~select_encode ~select_decode
(*
   @ [
       case
         "IK_Stop"
         (value [] Data_encoding.empty)
         (function IK_Stop -> Some () | _ -> None)
         (function () -> IK_Stop);
     ]
*)
