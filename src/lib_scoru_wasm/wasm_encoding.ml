(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

open Tezos_webassembly_interpreter
open Lazy_containers
open Kont_encodings

exception Uninitialized_current_module

module V = Instance.Vector
module M = Instance.NameMap
module C = Chunked_byte_vector
open Tree_encoding
module NameMap = Lazy_map_encoding.Make (Instance.NameMap)
module ModuleMap = Lazy_map_encoding.Make (Instance.ModuleMap.Map)

(** Utility function*)
let string_tag = value [] Data_encoding.string

let lazy_vector_encoding field_name tree_encoding =
  scope
    [field_name]
    (int32_lazy_vector (value [] Data_encoding.int32) tree_encoding)

let lazy_vector_encoding' tree_encoding =
  int32_lazy_vector (value [] Data_encoding.int32) tree_encoding

let func'_encoding =
  let ftype = value ["ftype"] Interpreter_encodings.Ast.var_encoding in
  let locals =
    lazy_vector_encoding
      "locals"
      (value [] Interpreter_encodings.Types.value_type_encoding)
  in
  let body = value ["body"] Interpreter_encodings.Ast.block_label_encoding in
  conv
    (fun (ftype, locals, body) -> Ast.{ftype; locals; body})
    (fun {ftype; locals; body} -> (ftype, locals, body))
    (tup3 ~flatten:true ftype locals body)

let func_encoding =
  conv
    (fun func -> Source.(func @@ no_region))
    (fun {it = func; _} -> func)
    func'_encoding

let function_type_encoding =
  conv
    (fun (params, result) -> Types.FuncType (params, result))
    (function Types.FuncType (params, result) -> (params, result))
    (tup2
       ~flatten:false
       (lazy_vector_encoding
          "type-params"
          (value [] Interpreter_encodings.Types.value_type_encoding))
       (lazy_vector_encoding
          "type-result"
          (value [] Interpreter_encodings.Types.value_type_encoding)))

let var_list_encoding =
  value [] (Data_encoding.list Interpreter_encodings.Ast.var_encoding)

let block_label_encoding =
  value [] Interpreter_encodings.Ast.block_label_encoding

let data_label_encoding = value [] Interpreter_encodings.Ast.data_label_encoding

let raw_instruction_encoding =
  let open Ast in
  let unit_encoding = value [] Data_encoding.unit in
  let var_1_encoding = value ["$1"] Interpreter_encodings.Ast.var_encoding in
  let var_2_encoding =
    tup2
      ~flatten:false
      (value ["$1"] Interpreter_encodings.Ast.var_encoding)
      (value ["$2"] Interpreter_encodings.Ast.var_encoding)
  in
  let select_encoding =
    value
      ["$1"]
      (* `Select` actually accepts only one value, but is a list for some
         reason. See [Valid.check_instr] for reference or the reference
         documentation. *)
      Data_encoding.(
        option (list Interpreter_encodings.Types.value_type_encoding))
  in
  let block_encoding =
    tup2
      ~flatten:false
      (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
      (scope ["$2"] block_label_encoding)
  in
  let loop_encoding =
    tup2
      ~flatten:false
      (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
      (scope ["$2"] block_label_encoding)
  in
  let if_encoding =
    tup3
      ~flatten:false
      (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
      (scope ["$2"] block_label_encoding)
      (scope ["$3"] block_label_encoding)
  in
  let br_table_encoding =
    tup2
      ~flatten:false
      (scope ["$1"] var_list_encoding)
      (value ["$2"] Interpreter_encodings.Ast.var_encoding)
  in
  let load_encoding = value ["$1"] Interpreter_encodings.Ast.loadop_encoding in
  let store_encoding =
    value ["$1"] Interpreter_encodings.Ast.storeop_encoding
  in
  let vec_store_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_storeop_encoding
  in
  let vec_load_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_loadop_encoding
  in
  let vec_load_lane_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_laneop_encoding
  in
  let vec_store_lane_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_laneop_encoding
  in
  let ref_null_encoding =
    value ["$1"] Interpreter_encodings.Types.ref_type_encoding
  in
  let const_encoding = value ["$1"] Interpreter_encodings.Ast.num_encoding in
  let test_encoding = value ["$1"] Interpreter_encodings.Ast.testop_encoding in
  let compare_encoding =
    value ["$1"] Interpreter_encodings.Ast.relop_encoding
  in
  let unary_encoding = value ["$1"] Interpreter_encodings.Ast.unop_encoding in
  let binary_encoding = value ["$1"] Interpreter_encodings.Ast.binop_encoding in
  let convert_encoding =
    value ["$1"] Interpreter_encodings.Ast.cvtop_encoding
  in
  let vec_const_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_encoding
  in
  let vec_test_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_testop_encoding
  in
  let vec_compare_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_relop_encoding
  in
  let vec_unary_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_unop_encoding
  in
  let vec_binary_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_binop_encoding
  in
  let vec_convert_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_cvtop_encoding
  in
  let vec_shift_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_shiftop_encoding
  in
  let vec_bitmask_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_bitmaskop_encoding
  in
  let vec_test_bits_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_vtestop_encoding
  in
  let vec_unary_bits_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_vunop_encoding
  in
  let vec_binary_bits_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_vbinop_encoding
  in
  let vec_ternary_bits_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_vternop_encoding
  in
  let vec_splat_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_splatop_encoding
  in
  let vec_extract_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_extractop_encoding
  in
  let vec_replace_encoding =
    value ["$1"] Interpreter_encodings.Ast.vec_replaceop_encoding
  in
  let select_encode =
    let enum_case tag = destruction ~tag ~res:() ~delegate:unit_encoding in
    let instr_1 tag var = destruction ~tag ~res:var ~delegate:var_1_encoding in
    let instr_2 tag var1 var2 =
      destruction ~tag ~res:(var1, var2) ~delegate:var_2_encoding
    in
    function
    | Unreachable -> enum_case "Unreachable"
    | Nop -> enum_case "Nop"
    | Drop -> enum_case "Drop"
    | Select p -> destruction ~tag:"Select" ~res:p ~delegate:select_encoding
    | Block (type_, instr) ->
        destruction ~tag:"Block" ~res:(type_, instr) ~delegate:block_encoding
    | Loop (type_, instr) ->
        destruction ~tag:"Loop" ~res:(type_, instr) ~delegate:loop_encoding
    | If (type_, instr_if, instrs_else) ->
        destruction
          ~tag:"If"
          ~res:(type_, instr_if, instrs_else)
          ~delegate:if_encoding
    | Br var -> instr_1 "Br" var
    | BrIf var -> instr_1 "BrIf" var
    | BrTable (table, target) ->
        destruction
          ~tag:"BrTable"
          ~res:(table, target)
          ~delegate:br_table_encoding
    | Return -> enum_case "Return"
    | Call var -> instr_1 "Call" var
    | CallIndirect (var1, var2) -> instr_2 "CallIndirect" var1 var2
    | LocalGet var -> instr_1 "LocalGet" var
    | LocalSet var -> instr_1 "LocalSet" var
    | LocalTee var -> instr_1 "LocalTee" var
    | GlobalGet var -> instr_1 "GlobalGet" var
    | GlobalSet var -> instr_1 "GlobalSet" var
    | TableGet var -> instr_1 "TableGet" var
    | TableSet var -> instr_1 "TableSet" var
    | TableSize var -> instr_1 "TableSize" var
    | TableGrow var -> instr_1 "TableGrow" var
    | TableFill var -> instr_1 "TableFill" var
    | TableCopy (var1, var2) -> instr_2 "TableCopy" var1 var2
    | TableInit (var1, var2) -> instr_2 "TableInit" var1 var2
    | ElemDrop var -> instr_1 "ElemDrop" var
    | Load loadop -> destruction ~tag:"Load" ~res:loadop ~delegate:load_encoding
    | Store storeop ->
        destruction ~tag:"Store" ~res:storeop ~delegate:store_encoding
    | VecLoad vec_loadop ->
        destruction ~tag:"VecLoad" ~res:vec_loadop ~delegate:vec_load_encoding
    | VecStore vec_storeop ->
        destruction
          ~tag:"VecStore"
          ~res:vec_storeop
          ~delegate:vec_store_encoding
    | VecLoadLane vec_laneop ->
        destruction
          ~tag:"VecLoadLane"
          ~res:vec_laneop
          ~delegate:vec_load_lane_encoding
    | VecStoreLane vec_laneop ->
        destruction
          ~tag:"VecStoreLane"
          ~res:vec_laneop
          ~delegate:vec_store_lane_encoding
    | MemorySize -> enum_case "MemorySize"
    | MemoryGrow -> enum_case "MemoryGrow"
    | MemoryFill -> enum_case "MemoryFill"
    | MemoryCopy -> enum_case "MemoryCopy"
    | MemoryInit var -> instr_1 "MemoryInit" var
    | DataDrop var -> instr_1 "DataDrop" var
    | RefNull ref_type ->
        destruction ~tag:"RefNull" ~res:ref_type ~delegate:ref_null_encoding
    | RefFunc var -> instr_1 "RefFunc" var
    | RefIsNull -> enum_case "RefIsNull"
    | Const num -> destruction ~tag:"Const" ~res:num ~delegate:const_encoding
    | Test testop -> destruction ~tag:"Test" ~res:testop ~delegate:test_encoding
    | Compare relop ->
        destruction ~tag:"Compare" ~res:relop ~delegate:compare_encoding
    | Unary unop -> destruction ~tag:"Unary" ~res:unop ~delegate:unary_encoding
    | Binary binop ->
        destruction ~tag:"Binary" ~res:binop ~delegate:binary_encoding
    | Convert cvtop ->
        destruction ~tag:"Convert" ~res:cvtop ~delegate:convert_encoding
    | VecConst vec ->
        destruction ~tag:"VecConst" ~res:vec ~delegate:vec_const_encoding
    | VecTest vec_testop ->
        destruction ~tag:"VecTest" ~res:vec_testop ~delegate:vec_test_encoding
    | VecCompare relop ->
        destruction ~tag:"VecCompare" ~res:relop ~delegate:vec_compare_encoding
    | VecUnary vec_unop ->
        destruction ~tag:"VecUnary" ~res:vec_unop ~delegate:vec_unary_encoding
    | VecBinary vec_binop ->
        destruction
          ~tag:"VecBinary"
          ~res:vec_binop
          ~delegate:vec_binary_encoding
    | VecConvert vec_cvtop ->
        destruction
          ~tag:"VecConvert"
          ~res:vec_cvtop
          ~delegate:vec_convert_encoding
    | VecShift vec_shiftop ->
        destruction
          ~tag:"VecShift"
          ~res:vec_shiftop
          ~delegate:vec_shift_encoding
    | VecBitmask vec_bitmaskop ->
        destruction
          ~tag:"VecBitmask"
          ~res:vec_bitmaskop
          ~delegate:vec_bitmask_encoding
    | VecTestBits vtestop ->
        destruction
          ~tag:"VecTestBits"
          ~res:vtestop
          ~delegate:vec_test_bits_encoding
    | VecUnaryBits vec_vunop ->
        destruction
          ~tag:"VecUnaryBits"
          ~res:vec_vunop
          ~delegate:vec_unary_bits_encoding
    | VecBinaryBits vbinop ->
        destruction
          ~tag:"VecBinaryBits"
          ~res:vbinop
          ~delegate:vec_binary_bits_encoding
    | VecTernaryBits vternop ->
        destruction
          ~tag:"VecTernaryBits"
          ~res:vternop
          ~delegate:vec_ternary_bits_encoding
    | VecSplat splatop ->
        destruction ~tag:"VecSplat" ~res:splatop ~delegate:vec_splat_encoding
    | VecExtract extractop ->
        destruction
          ~tag:"VecExtract"
          ~res:extractop
          ~delegate:vec_extract_encoding
    | VecReplace vec_replaceop ->
        destruction
          ~tag:"VecReplace"
          ~res:vec_replaceop
          ~delegate:vec_replace_encoding
  and select_decode =
    let enum_case w =
      decoding_branch ~extract:(fun () -> Lwt.return w) ~delegate:unit_encoding
    in
    let instr_1 mk =
      decoding_branch
        ~extract:(fun var -> Lwt.return @@ mk var)
        ~delegate:var_1_encoding
    in
    let instr_2 mk =
      decoding_branch
        ~extract:(fun (var1, var2) -> Lwt.return @@ mk var1 var2)
        ~delegate:var_2_encoding
    in
    function
    | "Unreachable" -> enum_case Unreachable
    | "Nop" -> enum_case Nop
    | "Drop" -> enum_case Drop
    | "Select" ->
        decoding_branch
          ~extract:(fun p -> Lwt.return (Select p))
          ~delegate:select_encoding
    | "Block" ->
        decoding_branch
          ~extract:(fun (type_, instr) -> Lwt.return (Block (type_, instr)))
          ~delegate:block_encoding
    | "Loop" ->
        decoding_branch
          ~extract:(fun (type_, instr) -> Lwt.return (Loop (type_, instr)))
          ~delegate:loop_encoding
    | "If" ->
        decoding_branch
          ~extract:(fun (type_, instr_if, instrs_else) ->
            Lwt.return (If (type_, instr_if, instrs_else)))
          ~delegate:if_encoding
    | "Br" -> instr_1 (fun var -> Br var)
    | "BrIf" -> instr_1 (fun var -> BrIf var)
    | "BrTable" ->
        decoding_branch
          ~extract:(fun (table, target) -> Lwt.return (BrTable (table, target)))
          ~delegate:br_table_encoding
    | "Return" -> enum_case Return
    | "Call" -> instr_1 (fun var -> Call var)
    | "CallIndirect" -> instr_2 (fun var1 var2 -> CallIndirect (var1, var2))
    | "LocalGet" -> instr_1 (fun var -> LocalGet var)
    | "LocalSet" -> instr_1 (fun var -> LocalSet var)
    | "LocalTee" -> instr_1 (fun var -> LocalTee var)
    | "GlobalGet" -> instr_1 (fun var -> GlobalGet var)
    | "GlobalSet" -> instr_1 (fun var -> GlobalSet var)
    | "TableGet" -> instr_1 (fun var -> TableGet var)
    | "TableSet" -> instr_1 (fun var -> TableSet var)
    | "TableSize" -> instr_1 (fun var -> TableSize var)
    | "TableGrow" -> instr_1 (fun var -> TableGrow var)
    | "TableFill" -> instr_1 (fun var -> TableFill var)
    | "TableCopy" -> instr_2 (fun var1 var2 -> TableCopy (var1, var2))
    | "TableInit" -> instr_2 (fun var1 var2 -> TableInit (var1, var2))
    | "ElemDrop" -> instr_1 (fun var -> ElemDrop var)
    | "Load" ->
        decoding_branch
          ~extract:(fun loadop -> Lwt.return (Load loadop))
          ~delegate:load_encoding
    | "Store" ->
        decoding_branch
          ~extract:(fun storeop -> Lwt.return (Store storeop))
          ~delegate:store_encoding
    | "VecLoad" ->
        decoding_branch
          ~extract:(fun vec_loadop -> Lwt.return (VecLoad vec_loadop))
          ~delegate:vec_load_encoding
    | "VecStore" ->
        decoding_branch
          ~extract:(fun vec_storeop -> Lwt.return (VecStore vec_storeop))
          ~delegate:vec_store_encoding
    | "VecLoadLane" ->
        decoding_branch
          ~extract:(fun vec_laneop -> Lwt.return (VecLoadLane vec_laneop))
          ~delegate:vec_load_lane_encoding
    | "VecStoreLane" ->
        decoding_branch
          ~extract:(fun vec_laneop -> Lwt.return (VecStoreLane vec_laneop))
          ~delegate:vec_store_lane_encoding
    | "MemorySize" -> enum_case MemorySize
    | "MemoryGrow" -> enum_case MemoryGrow
    | "MemoryFill" -> enum_case MemoryFill
    | "MemoryCopy" -> enum_case MemoryCopy
    | "MemoryInit" -> instr_1 (fun var -> MemoryInit var)
    | "DataDrop" -> instr_1 (fun var -> DataDrop var)
    | "RefNull" ->
        decoding_branch
          ~extract:(fun ref_type -> Lwt.return (RefNull ref_type))
          ~delegate:ref_null_encoding
    | "RefFunc" -> instr_1 (fun var -> RefFunc var)
    | "RefIsNull" -> enum_case RefIsNull
    | "Const" ->
        decoding_branch
          ~extract:(fun num -> Lwt.return (Const num))
          ~delegate:const_encoding
    | "Test" ->
        decoding_branch
          ~extract:(fun testop -> Lwt.return (Test testop))
          ~delegate:test_encoding
    | "Compare" ->
        decoding_branch
          ~extract:(fun relop -> Lwt.return (Compare relop))
          ~delegate:compare_encoding
    | "Unary" ->
        decoding_branch
          ~extract:(fun unop -> Lwt.return (Unary unop))
          ~delegate:unary_encoding
    | "Binary" ->
        decoding_branch
          ~extract:(fun binop -> Lwt.return (Binary binop))
          ~delegate:binary_encoding
    | "Convert" ->
        decoding_branch
          ~extract:(fun cvtop -> Lwt.return (Convert cvtop))
          ~delegate:convert_encoding
    | "VecConst" ->
        decoding_branch
          ~extract:(fun vec -> Lwt.return (VecConst vec))
          ~delegate:vec_const_encoding
    | "VecTest" ->
        decoding_branch
          ~extract:(fun vec_testop -> Lwt.return (VecTest vec_testop))
          ~delegate:vec_test_encoding
    | "VecCompare" ->
        decoding_branch
          ~extract:(fun vec_relop -> Lwt.return (VecCompare vec_relop))
          ~delegate:vec_compare_encoding
    | "VecUnary" ->
        decoding_branch
          ~extract:(fun vec_unop -> Lwt.return (VecUnary vec_unop))
          ~delegate:vec_unary_encoding
    | "VecBinary" ->
        decoding_branch
          ~extract:(fun vec_binop -> Lwt.return (VecBinary vec_binop))
          ~delegate:vec_binary_encoding
    | "VecConvert" ->
        decoding_branch
          ~extract:(fun vec_cvtop -> Lwt.return (VecConvert vec_cvtop))
          ~delegate:vec_convert_encoding
    | "VecShift" ->
        decoding_branch
          ~extract:(fun vec_shiftop -> Lwt.return (VecShift vec_shiftop))
          ~delegate:vec_shift_encoding
    | "VecBitmask" ->
        decoding_branch
          ~extract:(fun vec_bitmaskop -> Lwt.return (VecBitmask vec_bitmaskop))
          ~delegate:vec_bitmask_encoding
    | "VecTestBits" ->
        decoding_branch
          ~extract:(fun vec_vtestop -> Lwt.return (VecTestBits vec_vtestop))
          ~delegate:vec_test_bits_encoding
    | "VecUnaryBits" ->
        decoding_branch
          ~extract:(fun vec_vunop -> Lwt.return (VecUnaryBits vec_vunop))
          ~delegate:vec_unary_bits_encoding
    | "VecBinaryBits" ->
        decoding_branch
          ~extract:(fun vec_vbinop -> Lwt.return (VecBinaryBits vec_vbinop))
          ~delegate:vec_binary_bits_encoding
    | "VecTernaryBits" ->
        decoding_branch
          ~extract:(fun vec_vternop -> Lwt.return (VecTernaryBits vec_vternop))
          ~delegate:vec_ternary_bits_encoding
    | "VecSplat" ->
        decoding_branch
          ~extract:(fun vec_splatop -> Lwt.return (VecSplat vec_splatop))
          ~delegate:vec_splat_encoding
    | "VecExtract" ->
        decoding_branch
          ~extract:(fun vec_extractop -> Lwt.return (VecExtract vec_extractop))
          ~delegate:vec_extract_encoding
    | "VecReplace" ->
        decoding_branch
          ~extract:(fun vec_replaceop -> Lwt.return (VecReplace vec_replaceop))
          ~delegate:vec_replace_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let instruction_encoding =
  conv
    (fun instr -> Source.{at = no_region; it = instr})
    (fun Source.{at = _; it} -> it)
    raw_instruction_encoding

let func_type_encoding =
  conv
    (fun (type_params, type_result) ->
      Types.FuncType (type_params, type_result))
    (fun (Types.FuncType (type_params, type_result)) ->
      (type_params, type_result))
    (tup2
       ~flatten:false
       (lazy_vector_encoding
          "type_params"
          (value [] Interpreter_encodings.Types.value_type_encoding))
       (lazy_vector_encoding
          "type_result"
          (value [] Interpreter_encodings.Types.value_type_encoding)))

let module_key_encoding =
  conv
    (fun key -> Instance.Module_key key)
    (fun (Instance.Module_key key) -> key)
    (value [] Data_encoding.string)

let function_encoding =
  let host_func_encoding =
    tup2 ~flatten:false func_type_encoding (value ["name"] Data_encoding.string)
  in
  let ast_func_encoding =
    tup5
      ~flatten:false
      function_type_encoding
      (scope ["module"] module_key_encoding)
      (value ["ftype"] Interpreter_encodings.Ast.var_encoding)
      (lazy_vector_encoding
         "locals"
         (value [] Interpreter_encodings.Types.value_type_encoding))
      block_label_encoding
  in
  let select_encode = function
    | Func.HostFunc (func_type, name) ->
        destruction
          ~tag:"Host"
          ~res:(func_type, name)
          ~delegate:host_func_encoding
    | Func.AstFunc (type_, module_, {at = _; it = {ftype; locals; body}}) ->
        destruction
          ~tag:"Native"
          ~res:(type_, module_, ftype, locals, body)
          ~delegate:ast_func_encoding
  in
  let select_decode = function
    | "Host" ->
        decoding_branch
          ~extract:(fun (func_type, name) ->
            Lwt.return (Func.HostFunc (func_type, name)))
          ~delegate:host_func_encoding
    | "Native" ->
        decoding_branch
          ~extract:(fun (type_, module_, ftype, locals, body) ->
            let func =
              Source.{at = no_region; it = {Ast.ftype; locals; body}}
            in
            Lwt.return @@ Func.AstFunc (type_, module_, func))
          ~delegate:ast_func_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let value_ref_encoding =
  let extern_ref_encoding = value [] Data_encoding.int32 in
  let null_ref_encoding =
    value [] Interpreter_encodings.Types.ref_type_encoding
  in
  let select_encode = function
    | Instance.FuncRef func_inst ->
        destruction ~tag:"FuncRef" ~res:func_inst ~delegate:function_encoding
    | Values.ExternRef v ->
        destruction ~tag:"ExternRef" ~res:v ~delegate:extern_ref_encoding
    | Values.NullRef v ->
        destruction ~tag:"NullRef" ~res:v ~delegate:null_ref_encoding
    | _ -> (* FIXME *) assert false
  in
  let select_decode = function
    | "FuncRef" ->
        decoding_branch
          ~extract:(fun func_inst -> Lwt.return (Instance.FuncRef func_inst))
          ~delegate:function_encoding
    | "ExternRef" ->
        decoding_branch
          ~extract:(fun v -> Lwt.return (Values.ExternRef v))
          ~delegate:extern_ref_encoding
    | "NullRef" ->
        decoding_branch
          ~extract:(fun v -> Lwt.return (Values.NullRef v))
          ~delegate:null_ref_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let value_encoding =
  let num_encoding = value [] Interpreter_encodings.Values.num_encoding in
  let vec_encoding = value [] Interpreter_encodings.Values.vec_encoding in
  let select_encode = function
    | Values.Num n -> destruction ~tag:"NumType" ~res:n ~delegate:num_encoding
    | Values.Vec v ->
        destruction ~tag:"VecType V128Type" ~res:v ~delegate:vec_encoding
    | Values.Ref r ->
        destruction ~tag:"RefType" ~res:r ~delegate:value_ref_encoding
  and select_decode = function
    | "NumType" ->
        decoding_branch
          ~extract:(fun n -> Lwt.return (Values.Num n))
          ~delegate:num_encoding
    | "VecType V128Type" ->
        decoding_branch
          ~extract:(fun v -> Lwt.return (Values.Vec v))
          ~delegate:vec_encoding
    | "RefType" ->
        decoding_branch
          ~extract:(fun r -> Lwt.return (Values.Ref r))
          ~delegate:value_ref_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let values_encoding = lazy_vector_encoding' value_encoding

let name_encoding key = value [key] Data_encoding.string

let memory_encoding =
  conv
    (fun (min, max, chunks) -> Memory.of_chunks (MemoryType {min; max}) chunks)
    (fun memory_inst ->
      let (MemoryType {min; max}) = Memory.type_of memory_inst in
      let content = Memory.content memory_inst in
      (min, max, content))
    (tup3
       ~flatten:false
       (value ["min"] Data_encoding.int32)
       (value_option ["max"] Data_encoding.int32)
       (scope ["chunks"] chunked_byte_vector))

let table_encoding =
  conv
    (fun (min, max, vector, ref_type) ->
      let table_type = Types.TableType ({min; max}, ref_type) in
      Table.of_lazy_vector table_type vector)
    (fun table ->
      let (Types.TableType ({min; max}, ref_type)) = Table.type_of table in
      (min, max, Table.content table, ref_type))
    (tup4
       ~flatten:false
       (value ["min"] Data_encoding.int32)
       (value_option ["max"] Data_encoding.int32)
       (lazy_vector_encoding "refs" value_ref_encoding)
       (value ["ref-type"] Interpreter_encodings.Types.ref_type_encoding))

let global_encoding =
  conv
    (fun (type_, value) ->
      let ty = Types.GlobalType (Values.type_of_value value, type_) in
      Global.alloc ty value)
    (fun global ->
      let (Types.GlobalType (_, mutability)) = Global.type_of global in
      let value = Global.load global in
      (mutability, value))
    (tup2
       ~flatten:false
       (value ["type"] Interpreter_encodings.Types.mutability_encoding)
       (scope ["value"] value_encoding))

let memory_instance_encoding = lazy_vector_encoding "memories" memory_encoding

let table_vector_encoding = lazy_vector_encoding "tables" table_encoding

let global_vector_encoding = lazy_vector_encoding "globals" global_encoding

let data_label_ref_encoding =
  conv (fun x -> ref x) (fun r -> !r) data_label_encoding

let function_vector_encoding =
  lazy_vector_encoding "functions" function_encoding

let function_type_vector_encoding =
  lazy_vector_encoding "types" function_type_encoding

let value_ref_vector_encoding = lazy_vector_encoding "refs" value_ref_encoding

let extern_encoding =
  let select_encode = function
    | Instance.ExternFunc x ->
        destruction ~tag:"ExternFunc" ~res:x ~delegate:function_encoding
    | Instance.ExternTable x ->
        destruction ~tag:"ExternTable" ~res:x ~delegate:table_encoding
    | Instance.ExternMemory x ->
        destruction ~tag:"ExternMemory" ~res:x ~delegate:memory_encoding
    | Instance.ExternGlobal x ->
        destruction ~tag:"ExternGlobal" ~res:x ~delegate:global_encoding
  and select_decode = function
    | "ExternFunc" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Instance.ExternFunc x))
          ~delegate:function_encoding
    | "ExternTable" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Instance.ExternTable x))
          ~delegate:table_encoding
    | "ExternMemory" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Instance.ExternMemory x))
          ~delegate:memory_encoding
    | "ExternGlobal" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Instance.ExternGlobal x))
          ~delegate:global_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let export_instance_encoding =
  tup2 ~flatten:false (name_encoding "name") (scope ["extern"] extern_encoding)

let extern_map_encoding = NameMap.lazy_map extern_encoding

let value_ref_vector_vector_encoding =
  lazy_vector_encoding
    "elements"
    (conv (fun x -> ref x) (fun r -> !r) value_ref_vector_encoding)

let data_instance_encoding =
  lazy_vector_encoding "datas" data_label_ref_encoding

let block_table_encoding =
  lazy_vector_encoding
    "block-table"
    (lazy_vector_encoding "instructions" instruction_encoding)

let datas_table_encoding =
  lazy_vector_encoding "datas-table" chunked_byte_vector

let allocations_encoding =
  conv
    (fun (blocks, datas) -> Ast.{blocks; datas})
    (fun {blocks; datas} -> (blocks, datas))
    (tup2 ~flatten:false block_table_encoding datas_table_encoding)

let module_instance_encoding =
  conv
    (fun ( types,
           funcs,
           tables,
           memories,
           globals,
           exports,
           elems,
           datas,
           allocations ) ->
      {
        Instance.types;
        funcs;
        tables;
        memories;
        globals;
        exports;
        elems;
        datas;
        allocations;
      })
    (fun {
           Instance.types;
           funcs;
           tables;
           memories;
           globals;
           exports;
           elems;
           datas;
           allocations;
         } ->
      ( types,
        funcs,
        tables,
        memories,
        globals,
        exports,
        elems,
        datas,
        allocations ))
    (tup9
       ~flatten:false
       function_type_vector_encoding
       function_vector_encoding
       table_vector_encoding
       memory_instance_encoding
       global_vector_encoding
       extern_map_encoding
       value_ref_vector_vector_encoding
       data_instance_encoding
       allocations_encoding)

let module_instances_encoding =
  conv
    Instance.ModuleMap.of_immutable
    Instance.ModuleMap.snapshot
    (ModuleMap.lazy_map module_instance_encoding)

let frame_encoding =
  conv
    (fun (inst, locals) -> Eval.{inst; locals})
    (fun Eval.{inst; locals} -> (inst, locals))
    (tup2
       ~flatten:true
       (scope ["module"] module_key_encoding)
       (lazy_vector_encoding "locals" value_encoding))

let admin_instr'_encoding =
  let open Eval in
  let from_block_encoding =
    tup2 ~flatten:false block_label_encoding (value [] Data_encoding.int32)
  in
  let plain_encoding =
    Source.(conv (fun i -> i.it) (at no_region) instruction_encoding)
  in
  let trapping_encoding = value [] Data_encoding.string in
  let breaking_encoding =
    tup2 ~flatten:false (value [] Data_encoding.int32) values_encoding
  in
  let table_init_meta_encoding =
    tup7
      ~flatten:false
      (value [] Data_encoding.int32)
      value_ref_encoding
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Interpreter_encodings.Ast.var_encoding)
      (value [] Interpreter_encodings.Ast.var_encoding)
  in
  let table_fill_meta_encoding =
    tup5
      ~flatten:false
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      value_ref_encoding
      (value [] Interpreter_encodings.Ast.var_encoding)
  in
  let table_copy_meta_encoding =
    tup7
      ~flatten:false
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Interpreter_encodings.Ast.var_encoding)
      (value [] Interpreter_encodings.Ast.var_encoding)
      (value [] Data_encoding.bool)
  in
  let memory_init_meta_encoding =
    tup6
      ~flatten:false
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Interpreter_encodings.Ast.var_encoding)
  in
  let memory_fill_meta_encoding =
    tup4
      ~flatten:false
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Interpreter_encodings.Values.num_encoding)
      (value [] Data_encoding.int32)
  in
  let memory_copy_meta_encoding =
    tup5
      ~flatten:false
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.int32)
      (value [] Data_encoding.bool)
  in
  let select_encode = function
    | From_block (block, index) ->
        destruction
          ~tag:"From_block"
          ~res:(block, index)
          ~delegate:from_block_encoding
    | Plain x -> destruction ~tag:"Plain" ~res:x ~delegate:plain_encoding
    | Refer x -> destruction ~tag:"Refer" ~res:x ~delegate:value_ref_encoding
    | Invoke x -> destruction ~tag:"Invoke" ~res:x ~delegate:function_encoding
    | Trapping x ->
        destruction ~tag:"Trapping" ~res:x ~delegate:trapping_encoding
    | Returning x ->
        destruction ~tag:"Returning" ~res:x ~delegate:values_encoding
    | Breaking (index, values) ->
        destruction
          ~tag:"Breaking"
          ~res:(index, values)
          ~delegate:breaking_encoding
    | Table_init_meta (idx, v, d, s, n, x, y) ->
        destruction
          ~tag:"Table_init_meta"
          ~res:(idx, v, d, s, n, x, y)
          ~delegate:table_init_meta_encoding
    | Table_fill_meta (idx, i, n, r, x) ->
        destruction
          ~tag:"Table_fill_meta"
          ~res:(idx, i, n, r, x)
          ~delegate:table_fill_meta_encoding
    | Table_copy_meta (idx, d, s, n, x, y, case) ->
        destruction
          ~tag:"Table_copy_meta"
          ~res:(idx, d, s, n, x, y, case)
          ~delegate:table_copy_meta_encoding
    | Memory_init_meta (idx, d, b, n, s, x) ->
        destruction
          ~tag:"Memory_init_meta"
          ~res:(idx, d, b, n, s, x)
          ~delegate:memory_init_meta_encoding
    | Memory_fill_meta (idx, i, k, n) ->
        destruction
          ~tag:"Memory_fill_meta"
          ~res:(idx, i, k, n)
          ~delegate:memory_fill_meta_encoding
    | Memory_copy_meta (idx, d, s, n, case) ->
        destruction
          ~tag:"Memory_copy_meta"
          ~res:(idx, d, s, n, case)
          ~delegate:memory_copy_meta_encoding
  and select_decode = function
    | "From_block" ->
        decoding_branch
          ~extract:(fun (block, index) ->
            Lwt.return (From_block (block, index)))
          ~delegate:from_block_encoding
    | "Plain" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Plain x))
          ~delegate:plain_encoding
    | "Refer" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Refer x))
          ~delegate:value_ref_encoding
    | "Invoke" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Invoke x))
          ~delegate:function_encoding
    | "Trapping" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Trapping x))
          ~delegate:trapping_encoding
    | "Returning" ->
        decoding_branch
          ~extract:(fun x -> Lwt.return (Returning x))
          ~delegate:values_encoding
    | "Breaking" ->
        decoding_branch
          ~extract:(fun (index, values) ->
            Lwt.return (Breaking (index, values)))
          ~delegate:breaking_encoding
    | "Table_init_meta" ->
        decoding_branch
          ~extract:(fun (idx, value, d, s, n, x, y) ->
            Lwt.return @@ Table_init_meta (idx, value, d, s, n, x, y))
          ~delegate:table_init_meta_encoding
    | "Table_fill_meta" ->
        decoding_branch
          ~extract:(fun (idx, i, n, r, x) ->
            Lwt.return @@ Table_fill_meta (idx, i, n, r, x))
          ~delegate:table_fill_meta_encoding
    | "Table_copy_meta" ->
        decoding_branch
          ~extract:(fun (idx, d, s, n, x, y, case) ->
            Lwt.return @@ Table_copy_meta (idx, d, s, n, x, y, case))
          ~delegate:table_copy_meta_encoding
    | "Memory_init_meta" ->
        decoding_branch
          ~extract:(fun (idx, d, b, n, s, x) ->
            Lwt.return @@ Memory_init_meta (idx, d, b, n, s, x))
          ~delegate:memory_init_meta_encoding
    | "Memory_fill_meta" ->
        decoding_branch
          ~extract:(fun (idx, i, k, n) ->
            Lwt.return @@ Memory_fill_meta (idx, i, k, n))
          ~delegate:memory_fill_meta_encoding
    | "Memory_copy_meta" ->
        decoding_branch
          ~extract:(fun (idx, d, s, n, case) ->
            Lwt.return @@ Memory_copy_meta (idx, d, s, n, case))
          ~delegate:memory_copy_meta_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let admin_instr_encoding =
  conv Source.(at no_region) Source.(fun x -> x.it) admin_instr'_encoding

let input_buffer_message_encoding =
  conv_lwt
    (fun (rtype, raw_level, message_counter, payload) ->
      let open Lwt.Syntax in
      let+ payload = C.to_bytes payload in
      Input_buffer.{rtype; raw_level; message_counter; payload})
    (fun Input_buffer.{rtype; raw_level; message_counter; payload} ->
      let payload = C.of_bytes payload in
      Lwt.return (rtype, raw_level, message_counter, payload))
    (tup4
       ~flatten:true
       (value ["rtype"] Data_encoding.int32)
       (value ["raw-level"] Data_encoding.int32)
       (value ["message-counter"] Data_encoding.z)
       chunked_byte_vector)

let input_buffer_encoding =
  conv
    (fun (content, num_elements) ->
      {
        Input_buffer.content = Lazy_vector.Mutable.ZVector.of_immutable content;
        num_elements;
      })
    (fun buffer ->
      Input_buffer.
        ( Lazy_vector.Mutable.ZVector.snapshot buffer.content,
          buffer.num_elements ))
    (tup2
       ~flatten:true
       (scope
          ["messages"]
          (z_lazy_vector
             (value [] Data_encoding.z)
             input_buffer_message_encoding))
       (value ["num-messages"] Data_encoding.z))

let label_encoding =
  conv
    (fun (label_arity, label_break, vs, es) ->
      Eval.{label_arity; label_break; label_code = (vs, es)})
    (fun {label_arity; label_break; label_code = vs, es} ->
      (label_arity, label_break, vs, es))
    (tup4
       ~flatten:true
       (value_option ["arity"] Data_encoding.int32)
       (scope ["label_break"] (option instruction_encoding))
       (scope ["values"] values_encoding)
       (lazy_vector_encoding "instructions" admin_instr_encoding))

let ongoing_label_kont_encoding : Eval.ongoing Eval.label_kont t =
  tagged_union
    string_tag
    [
      case
        "Label_stack"
        (tup2
           ~flatten:true
           (scope ["top"] label_encoding)
           (lazy_vector_encoding "rst" label_encoding))
        (function Eval.Label_stack (label, stack) -> Some (label, stack))
        (fun (label, stack) -> Label_stack (label, stack));
    ]

type packed_label_kont = Packed : 'a Eval.label_kont -> packed_label_kont

let packed_label_kont_encoding : packed_label_kont t =
  let label_stack_encoding =
    tup2
      ~flatten:true
      (scope ["top"] label_encoding)
      (lazy_vector_encoding "rst" label_encoding)
  in
  let label_trapped_encoding = value [] Data_encoding.string in
  let select_encode = function
    | Packed (Label_stack (label, stack)) ->
        destruction
          ~tag:"Label_stack"
          ~res:(label, stack)
          ~delegate:label_stack_encoding
    | Packed (Label_result vs0) ->
        destruction ~tag:"Label_result" ~res:vs0 ~delegate:values_encoding
    | Packed (Label_trapped msg) ->
        destruction
          ~tag:"Label_trapped"
          ~res:msg.it
          ~delegate:label_trapped_encoding
  and select_decode = function
    | "Label_stack" ->
        decoding_branch
          ~extract:(fun (label, stack) ->
            Lwt.return (Packed (Label_stack (label, stack))))
          ~delegate:label_stack_encoding
    | "Label_result" ->
        decoding_branch
          ~extract:(fun vs0 -> Lwt.return @@ Packed (Label_result vs0))
          ~delegate:values_encoding
    | "Label_trapped" ->
        decoding_branch
          ~extract:(fun msg ->
            Lwt.return @@ Packed (Label_trapped Source.(msg @@ no_region)))
          ~delegate:label_trapped_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_decode ~select_encode

let ongoing_frame_stack_encoding =
  conv
    (fun (frame_arity, frame_specs, frame_label_kont) ->
      Eval.{frame_arity; frame_specs; frame_label_kont})
    (fun {frame_arity; frame_specs; frame_label_kont} ->
      (frame_arity, frame_specs, frame_label_kont))
    (tup3
       ~flatten:true
       (value_option ["arity"] Data_encoding.int32)
       (scope ["frame"] frame_encoding)
       (scope ["label_kont"] ongoing_label_kont_encoding))

type packed_frame_stack =
  | Packed_fs : 'a Eval.frame_stack -> packed_frame_stack

let packed_frame_stack_encoding =
  conv
    (fun (frame_arity, frame_specs, Packed frame_label_kont) ->
      Packed_fs Eval.{frame_arity; frame_specs; frame_label_kont})
    (function
      | Packed_fs Eval.{frame_arity; frame_specs; frame_label_kont} ->
          (frame_arity, frame_specs, Packed frame_label_kont))
    (tup3
       ~flatten:true
       (value_option ["arity"] Data_encoding.int32)
       (scope ["frame"] frame_encoding)
       (scope ["label_kont"] packed_label_kont_encoding))

let invoke_step_kont_encoding =
  let inv_start_encoding =
    tup3
      ~flatten:true
      (scope ["func"] function_encoding)
      (scope ["values"] values_encoding)
      (lazy_vector_encoding "instructions" admin_instr_encoding)
  in
  let inv_prepare_locals_encoding =
    tup7
      ~flatten:true
      (value ["arity"] Data_encoding.int32)
      (lazy_vector_encoding "args" value_encoding)
      (lazy_vector_encoding "values" value_encoding)
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (scope ["inst"] module_key_encoding)
      (scope ["func"] func_encoding)
      (scope
         ["kont"]
         (map_kont_encoding
            (lazy_vector_encoding
               "x"
               (value [] Interpreter_encodings.Types.value_type_encoding))
            (lazy_vector_encoding "y" value_encoding)))
  in
  let inv_prepare_args_encoding =
    tup7
      ~flatten:true
      (value ["arity"] Data_encoding.int32)
      (lazy_vector_encoding "values" value_encoding)
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (scope ["inst"] module_key_encoding)
      (scope ["func"] func_encoding)
      (lazy_vector_encoding "locals" value_encoding)
      (scope
         ["kont"]
         (map_kont_encoding
            (lazy_vector_encoding "1" value_encoding)
            (lazy_vector_encoding "2" value_encoding)))
  in
  let inv_concat_encoding =
    tup6
      ~flatten:true
      (value ["arity"] Data_encoding.int32)
      (lazy_vector_encoding "values" value_encoding)
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (scope ["inst"] module_key_encoding)
      (scope ["func"] func_encoding)
      (scope
         ["kont"]
         (concat_kont_encoding (lazy_vector_encoding "2" value_encoding)))
  in
  let inv_stop_encoding =
    tup3
      ~flatten:true
      (scope ["values"] values_encoding)
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (scope ["fresh_frame"] (option ongoing_frame_stack_encoding))
  in
  let select_encode = function
    | Eval.Inv_start {func; code = vs, es} ->
        destruction
          ~tag:"Inv_start"
          ~res:(func, vs, es)
          ~delegate:inv_start_encoding
    | Eval.Inv_prepare_locals
        {arity; args; vs; instructions; inst; func; locals_kont} ->
        destruction
          ~tag:"Inv_prepare_locals"
          ~res:(arity, args, vs, instructions, inst, func, locals_kont)
          ~delegate:inv_prepare_locals_encoding
    | Eval.Inv_prepare_args
        {arity; vs; instructions; inst; func; locals; args_kont} ->
        destruction
          ~tag:"Inv_prepare_args"
          ~res:(arity, vs, instructions, inst, func, locals, args_kont)
          ~delegate:inv_prepare_args_encoding
    | Eval.Inv_concat {arity; vs; instructions; inst; func; concat_kont} ->
        destruction
          ~tag:"Inv_concat"
          ~res:(arity, vs, instructions, inst, func, concat_kont)
          ~delegate:inv_concat_encoding
    | Eval.Inv_stop {code = vs, es; fresh_frame} ->
        destruction
          ~tag:"Inv_stop"
          ~res:(vs, es, fresh_frame)
          ~delegate:inv_stop_encoding
  and select_decode = function
    | "Inv_start" ->
        decoding_branch
          ~extract:(fun (func, vs, es) ->
            Lwt.return @@ Eval.Inv_start {func; code = (vs, es)})
          ~delegate:inv_start_encoding
    | "Inv_prepare_locals" ->
        decoding_branch
          ~extract:
            (fun (arity, args, vs, instructions, inst, func, locals_kont) ->
            Lwt.return
            @@ Eval.Inv_prepare_locals
                 {arity; args; vs; instructions; inst; func; locals_kont})
          ~delegate:inv_prepare_locals_encoding
    | "Inv_prepare_args" ->
        decoding_branch
          ~extract:
            (fun (arity, vs, instructions, inst, func, locals, args_kont) ->
            Lwt.return
            @@ Eval.Inv_prepare_args
                 {arity; vs; instructions; inst; func; locals; args_kont})
          ~delegate:inv_prepare_args_encoding
    | "Inv_concat" ->
        decoding_branch
          ~extract:(fun (arity, vs, instructions, inst, func, concat_kont) ->
            Lwt.return
            @@ Eval.Inv_concat
                 {arity; vs; instructions; inst; func; concat_kont})
          ~delegate:inv_concat_encoding
    | "Inv_stop" ->
        decoding_branch
          ~extract:(fun (vs, es, fresh_frame) ->
            Lwt.return @@ Eval.Inv_stop {code = (vs, es); fresh_frame})
          ~delegate:inv_stop_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let label_step_kont_encoding =
  let ls_craft_frame_encoding =
    tup2
      ~flatten:true
      (scope ["label_kont"] ongoing_label_kont_encoding)
      (scope ["invoke_kont"] invoke_step_kont_encoding)
  in
  let ls_push_frame_encoding =
    tup2
      ~flatten:true
      (scope ["label_kont"] ongoing_label_kont_encoding)
      (scope ["fresh_frame"] ongoing_frame_stack_encoding)
  in
  let ls_consolidate_top_encoding =
    tup4
      ~flatten:true
      (scope ["label"] label_encoding)
      (scope
         ["kont"]
         (concat_kont_encoding (lazy_vector_encoding' value_encoding)))
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (lazy_vector_encoding "labels-stack" label_encoding)
  in
  let select_encode = function
    | Eval.LS_Start label ->
        destruction
          ~tag:"LS_Start"
          ~res:label
          ~delegate:ongoing_label_kont_encoding
    | Eval.LS_Craft_frame (l, i) ->
        destruction
          ~tag:"LS_Craft_frame"
          ~res:(l, i)
          ~delegate:ls_craft_frame_encoding
    | Eval.LS_Push_frame (l, i) ->
        destruction
          ~tag:"LS_Push_frame"
          ~res:(l, i)
          ~delegate:ls_push_frame_encoding
    | Eval.LS_Consolidate_top (l, k, es, s) ->
        destruction
          ~tag:"LS_Consolidate_top"
          ~res:(l, k, es, s)
          ~delegate:ls_consolidate_top_encoding
    | Eval.LS_Modify_top l ->
        destruction
          ~tag:"LS_Modify_top"
          ~res:(Packed l)
          ~delegate:packed_label_kont_encoding
  and select_decode = function
    | "LS_Start" ->
        decoding_branch
          ~extract:(fun label -> Lwt.return @@ Eval.LS_Start label)
          ~delegate:ongoing_label_kont_encoding
    | "LS_Craft_frame" ->
        decoding_branch
          ~extract:(fun (l, i) -> Lwt.return @@ Eval.LS_Craft_frame (l, i))
          ~delegate:ls_craft_frame_encoding
    | "LS_Push_frame" ->
        decoding_branch
          ~extract:(fun (l, i) -> Lwt.return @@ Eval.LS_Push_frame (l, i))
          ~delegate:ls_push_frame_encoding
    | "LS_Consolidate_top" ->
        decoding_branch
          ~extract:(fun (l, k, es, s) ->
            Lwt.return @@ Eval.LS_Consolidate_top (l, k, es, s))
          ~delegate:ls_consolidate_top_encoding
    | "LS_Modify_top" ->
        decoding_branch
          ~extract:(fun (Packed l) -> Lwt.return @@ Eval.LS_Modify_top l)
          ~delegate:packed_label_kont_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let step_kont_encoding =
  let sk_start_encoding =
    tup2
      ~flatten:true
      (scope ["top"] packed_frame_stack_encoding)
      (lazy_vector_encoding "rst" ongoing_frame_stack_encoding)
  in
  let sk_next_encoding =
    tup3
      ~flatten:true
      (scope ["top"] packed_frame_stack_encoding)
      (lazy_vector_encoding "rst" ongoing_frame_stack_encoding)
      (scope ["kont"] label_step_kont_encoding)
  in
  let sk_consolidate_label_result_encoding =
    tup6
      ~flatten:true
      (scope ["top-frame"] ongoing_frame_stack_encoding)
      (lazy_vector_encoding "frames-stack" ongoing_frame_stack_encoding)
      (scope ["top-label"] label_encoding)
      (scope
         ["kont"]
         (concat_kont_encoding (lazy_vector_encoding' value_encoding)))
      (lazy_vector_encoding "instructions" admin_instr_encoding)
      (lazy_vector_encoding "labels-stack" label_encoding)
  in
  let sk_trapped_encoding = value [] Data_encoding.string in
  let select_encode = function
    | Eval.SK_Start (f, rst) ->
        destruction
          ~tag:"SK_Start"
          ~res:(Packed_fs f, rst)
          ~delegate:sk_start_encoding
    | Eval.SK_Next (f, r, k) ->
        destruction
          ~tag:"SK_Next"
          ~res:(Packed_fs f, r, k)
          ~delegate:sk_next_encoding
    | Eval.SK_Consolidate_label_result (frame', stack, label, vs, es, lstack) ->
        destruction
          ~tag:"SK_Consolidate_label_result"
          ~res:(frame', stack, label, vs, es, lstack)
          ~delegate:sk_consolidate_label_result_encoding
    | Eval.SK_Result vs ->
        destruction ~tag:"SK_Result" ~res:vs ~delegate:values_encoding
    | Eval.SK_Trapped msg ->
        destruction ~tag:"SK_Trapped" ~res:msg.it ~delegate:sk_trapped_encoding
  and select_decode = function
    | "SK_Start" ->
        decoding_branch
          ~extract:(fun (Packed_fs f, rst) ->
            Lwt.return @@ Eval.SK_Start (f, rst))
          ~delegate:sk_start_encoding
    | "SK_Next" ->
        decoding_branch
          ~extract:(fun (Packed_fs f, r, k) ->
            Lwt.return @@ Eval.SK_Next (f, r, k))
          ~delegate:sk_next_encoding
    | "SK_Consolidate_label_result" ->
        decoding_branch
          ~extract:(fun (frame', stack, label, vs, es, lstack) ->
            Lwt.return
            @@ Eval.SK_Consolidate_label_result
                 (frame', stack, label, vs, es, lstack))
          ~delegate:sk_consolidate_label_result_encoding
    | "SK_Result" ->
        decoding_branch
          ~extract:(fun vs -> Lwt.return @@ Eval.SK_Result vs)
          ~delegate:values_encoding
    | "SK_Trapped" ->
        decoding_branch
          ~extract:(fun msg ->
            Lwt.return @@ Eval.SK_Trapped Source.(msg @@ no_region))
          ~delegate:sk_trapped_encoding
    | _ -> (* FIXME *) assert false
  in
  fast_tagged_union string_tag ~select_encode ~select_decode

let index_vector_encoding =
  conv
    (fun index -> Output_buffer.Index_Vector.of_immutable index)
    (fun buffer -> Output_buffer.Index_Vector.snapshot buffer)
    (z_lazy_vector (value [] Data_encoding.z) (value [] Data_encoding.bytes))

let output_buffer_encoding =
  conv
    (fun output -> Output_buffer.Level_Vector.of_immutable output)
    (fun buffer -> Output_buffer.Level_Vector.snapshot buffer)
    (int32_lazy_vector (value [] Data_encoding.int32) index_vector_encoding)

let config_encoding ~host_funcs =
  conv
    (fun (step_kont, stack_size_limit, module_reg) ->
      Eval.{step_kont; host_funcs; stack_size_limit; module_reg})
    (fun Eval.{step_kont; stack_size_limit; module_reg; _} ->
      (step_kont, stack_size_limit, module_reg))
    (tup3
       ~flatten:true
       (scope ["step_kont"] step_kont_encoding)
       (value ["stack_size_limit"] Data_encoding.int31)
       (scope ["modules"] module_instances_encoding))

let buffers_encoding =
  conv
    (fun (input, output) -> Eval.{input; output})
    (fun Eval.{input; output; _} -> (input, output))
    (tup2
       ~flatten:true
       (scope ["input"] input_buffer_encoding)
       (scope ["output"] output_buffer_encoding))
