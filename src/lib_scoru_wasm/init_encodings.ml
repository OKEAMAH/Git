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
  let tag_EC_Next = 0 and tag_EC_Stop = 1 in
  let select_encode = function
    | EC_Next c -> destruction ~tag:tag_EC_Next ~res:c ~delegate:ec_next_enc
    | EC_Stop v -> destruction ~tag:tag_EC_Stop ~res:v ~delegate:ec_stop_enc
  in
  let select_decode = function
    | 0 -> decoding_branch ~extract:(fun c -> EC_Next c) ~delegate:ec_next_enc
    | 1 -> decoding_branch ~extract:(fun v -> EC_Stop v) ~delegate:ec_stop_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union ~select_encode ~select_decode ()

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
  let tag_J_Init = 0 and tag_J_Next = 1 and tag_J_Stop = 2 in
  let select_encode = function
    | J_Init v -> destruction ~tag:tag_J_Init ~res:v ~delegate:j_init_enc
    | J_Next (kont, acc) ->
        destruction ~tag:tag_J_Next ~res:(kont, acc) ~delegate:j_next_enc
    | J_Stop res -> destruction ~tag:tag_J_Stop ~res ~delegate:j_stop_enc
  in
  let select_decode = function
    | 0 -> decoding_branch ~extract:(fun v -> J_Init v) ~delegate:j_init_enc
    | 1 ->
        decoding_branch
          ~extract:(fun (kont, acc) -> J_Next (kont, acc))
          ~delegate:j_next_enc
    | 2 -> decoding_branch ~extract:(fun res -> J_Stop res) ~delegate:j_stop_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union ~select_encode ~select_decode ()

let map_concat_kont_encoding enc_a enc_b =
  let mc_map_enc =
    map_kont_encoding
      (lazy_vec_encoding enc_a)
      (lazy_vec_encoding (lazy_vec_encoding enc_b))
  in
  let mc_join_enc = join_kont_encoding enc_b in
  let tag_MC_Map = 0 and tag_MC_Join = 1 in
  let select_encode = function
    | MC_Map m -> destruction ~tag:tag_MC_Map ~res:m ~delegate:mc_map_enc
    | MC_Join j -> destruction ~tag:tag_MC_Join ~res:j ~delegate:mc_join_enc
  in
  let select_decode = function
    | 0 -> decoding_branch ~extract:(fun m -> MC_Map m) ~delegate:mc_map_enc
    | 1 -> decoding_branch ~extract:(fun m -> MC_Join m) ~delegate:mc_join_enc
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union ~select_encode ~select_decode ()

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
  let tag_IK_Start = 0
  and tag_IK_Add_import = 1
  and tag_IK_Types = 2
  and tag_IK_Aggregate_fun = 3
  and tag_IK_Aggregate_concat_fun = 4
  and tag_IK_Aggregate_global = 5
  and tag_IK_Aggregate_concat_global = 6
  and tag_IK_Aggregate_table = 7
  and tag_IK_Aggregate_concat_table = 8
  and tag_IK_Aggregate_memory = 9
  and tag_IK_Aggregage_concat_memory = 10
  and tag_IK_Exports = 11
  and tag_IK_Elems = 12
  and tag_IK_Datas = 13 in

  let select_encode = function
    | IK_Start exts ->
        destruction ~tag:tag_IK_Start ~res:exts ~delegate:ik_start_enc
    | IK_Add_import m ->
        destruction ~tag:tag_IK_Add_import ~res:m ~delegate:ik_add_import_enc
    | IK_Type (m, t) ->
        destruction ~tag:tag_IK_Types ~res:(m, t) ~delegate:ik_type_enc
    | IK_Aggregate (m, Func, t) ->
        destruction
          ~tag:tag_IK_Aggregate_fun
          ~res:(m, t)
          ~delegate:ik_aggregate_func_enc
    | IK_Aggregate_concat (m, Func, t) ->
        destruction
          ~tag:tag_IK_Aggregate_concat_fun
          ~res:(m, t)
          ~delegate:ik_aggregate_concat_func_enc
    | IK_Aggregate (m, Global, t) ->
        destruction
          ~tag:tag_IK_Aggregate_global
          ~res:(m, t)
          ~delegate:ik_aggregate_global_enc
    | IK_Aggregate_concat (m, Global, t) ->
        destruction
          ~tag:tag_IK_Aggregate_concat_global
          ~res:(m, t)
          ~delegate:ik_aggregate_concat_global_enc
    | IK_Aggregate (m, Table, t) ->
        destruction
          ~tag:tag_IK_Aggregate_table
          ~res:(m, t)
          ~delegate:ik_aggregate_table_enc
    | IK_Aggregate_concat (m, Table, t) ->
        destruction
          ~tag:tag_IK_Aggregate_concat_table
          ~res:(m, t)
          ~delegate:ik_aggregate_concat_table_enc
    | IK_Aggregate (m, Memory, t) ->
        destruction
          ~tag:tag_IK_Aggregate_memory
          ~res:(m, t)
          ~delegate:ik_aggregate_memory_enc
    | IK_Aggregate_concat (m, Memory, t) ->
        destruction
          ~tag:tag_IK_Aggregate_concat_memory
          ~res:(m, t)
          ~delegate:ik_aggregate_concat_memory_enc
    | IK_Exports (inst, fold) ->
        destruction
          ~tag:tag_IK_Exports
          ~res:(inst, fold)
          ~delegate:ik_exports_enc
    | IK_Elems (inst, map) ->
        destruction ~tag:tag_IK_Elems ~res:(inst, map) ~delegate:ik_elems_enc
    | IK_Datas (inst, map) ->
        destruction ~tag:tag_IK_Datas ~res:(inst, map) ~delegate:ik_datas_enc
    | IK_Es_elems (inst, map) ->
        destruction
          ~tag:tag_IK_Es_elems
          ~res:(inst, map)
          ~delegate:ik_es_elems_enc
    | IK_Es_datas (inst, map, es_elem) ->
        destruction
          ~tag:tag_IK_Es_datas
          ~res:(inst, map, es_elem)
          ~delegate:ik_es_datas_enc
    | IK_Join_admin (m, admin) ->
        destruction
          ~tag:tag_IK_Join_admin
          ~res:(m, admin)
          ~delegate:ik_join_admin_enc
    | IK_Eval config ->
        destruction ~tag:tag_IK_Eval ~res:config ~delegate:ik_eval_enc
    | IK_Stop -> destruction ~tag:tag_IK_Stop ~res:() ~delegate:ik_stop_enc
  in
  let select_decode = function
    | "IK_Start" ->
        decoding_branch
          ~extract:(fun exts -> IK_Start exts)
          ~delegate:ik_start_enc
    | "IK_Add_import" ->
        decoding_branch
          ~extract:(function m -> IK_Add_import m)
          ~delegate:ik_add_import_enc
    | "IK_Types" ->
        decoding_branch
          ~extract:(function m, t -> IK_Type (m, t))
          ~delegate:ik_type_enc
    | "IK_Aggregate_fun" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate (m, Func, t))
          ~delegate:ik_aggregate_func_enc
    | "IK_Aggregate_concat_fun" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate_concat (m, Func, t))
          ~delegate:ik_aggregate_concat_func_enc
    | "IK_Aggregate_global" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate (m, Global, t))
          ~delegate:ik_aggregate_global_enc
    | "IK_Aggregate_concat_global" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate_concat (m, Global, t))
          ~delegate:ik_aggregate_concat_global_enc
    | "IK_Aggregate_table" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate (m, Table, t))
          ~delegate:ik_aggregate_table_enc
    | "IK_Aggregate_concat_table" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate_concat (m, Table, t))
          ~delegate:ik_aggregate_concat_table_enc
    | "IK_Aggregate_memory" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate (m, Memory, t))
          ~delegate:ik_aggregate_memory_enc
    | "IK_Aggregate_concat_memory" ->
        decoding_branch
          ~extract:(function m, t -> IK_Aggregate_concat (m, Memory, t))
          ~delegate:ik_aggregate_concat_memory_enc
    | "IK_Exports" ->
        decoding_branch
          ~extract:(function inst, fold -> IK_Exports (inst, fold))
          ~delegate:ik_exports_enc
    | "IK_Elems" ->
        decoding_branch
          ~extract:(function inst, map -> IK_Elems (inst, map))
          ~delegate:ik_elems_enc
    | "IK_Datas" ->
        decoding_branch
          ~extract:(function inst, map -> IK_Datas (inst, map))
          ~delegate:ik_datas_enc
    | "IK_Es_elems" ->
        decoding_branch
          ~extract:(function inst, map -> IK_Es_elems (inst, map))
          ~delegate:ik_es_elems_enc
    | "IK_Es_datas" ->
        decoding_branch
          ~extract:(function
            | inst, map, es_elem -> IK_Es_datas (inst, map, es_elem))
          ~delegate:ik_es_datas_enc
    | "IK_Join_admin" ->
        decoding_branch
          ~extract:(function m, admin -> IK_Join_admin (m, admin))
          ~delegate:ik_join_admin_enc
    | "IK_Eval" ->
        decoding_branch
          ~extract:(function config -> IK_Eval config)
          ~delegate:ik_eval_enc
    | "IK_Stop" ->
        decoding_branch
          ~extract:(function () -> IK_Stop)
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
