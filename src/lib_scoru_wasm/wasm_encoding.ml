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

exception Uninitialized_current_module

module Make
    (Tree_encoding_decoding : Tree_encoding_decoding.S
                                with type vector_key = int32
                                 and type 'a vector = 'a Instance.Vector.t
                                 and type 'a map = 'a Instance.NameMap.t
                                 and type chunked_byte_vector =
                                  Chunked_byte_vector.Lwt.t) =
struct
  module V = Instance.Vector
  module M = Instance.NameMap
  module C = Chunked_byte_vector.Lwt
  include Tree_encoding_decoding

  (** Utility function*)
  let string_tag = value [] Data_encoding.string

  let list_encoding item_enc =
    let vector = lazy_vector (value [] Data_encoding.int32) item_enc in
    (* TODO: #3076
       This should return a [Instance.Vector.t] instead of a list. Once the AST
       has been sufficiently adapted to lazy vectors and maps, this change can
       go forward. *)
    conv_lwt V.to_list (fun list -> Lwt.return (V.of_list list)) vector

  let lazy_vector_encoding field_name tree_encoding =
    lazy_vector (value ["num-" ^ field_name] Data_encoding.int32) tree_encoding

  let function_type_encoding =
    conv
      (fun (params, result) -> Types.FuncType (params, result))
      (function Types.FuncType (params, result) -> (params, result))
      (tup2
         ~flatten:false
         (lazy_vector_encoding
            "type_params"
            (value [] Interpreter_encodings.Types.value_type_encoding))
         (lazy_vector_encoding
            "type_result"
            (value [] Interpreter_encodings.Types.value_type_encoding)))

  let var_list_encoding =
    list_encoding (value [] Interpreter_encodings.Ast.var_encoding)

  let block_label_encoding =
    value [] Interpreter_encodings.Ast.block_label_encoding

  let instruction_encoding =
    let unit_encoding = value [] Data_encoding.unit in
    let open Ast in
    conv
      (fun instr -> Source.{at = no_region; it = instr})
      (fun Source.{at = _; it} -> it)
      (tagged_union
         string_tag
         [
           case
             "Unreachable"
             unit_encoding
             (function Unreachable -> Some () | _ -> None)
             (fun () -> Unreachable);
           case
             "Nop"
             unit_encoding
             (function Nop -> Some () | _ -> None)
             (fun () -> Nop);
           case
             "Drop"
             unit_encoding
             (function Drop -> Some () | _ -> None)
             (fun () -> Drop);
           case
             "Select"
             (value
                ["$1"]
                (* `Select` actually accepts only one value, but is a list for some
                   reason. See [Valid.check_instr] for reference or the reference
                   documentation. *)
                Data_encoding.(
                  option (list Interpreter_encodings.Types.value_type_encoding)))
             (function Select p -> Some p | _ -> None)
             (fun p -> Select p);
           case
             "Block"
             (tup2
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
                (scope ["$2"] block_label_encoding))
             (function
               | Block (type_, instr) -> Some (type_, instr) | _ -> None)
             (fun (type_, instr) -> Block (type_, instr));
           case
             "Loop"
             (tup2
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
                (scope ["$2"] block_label_encoding))
             (function Loop (type_, instr) -> Some (type_, instr) | _ -> None)
             (fun (type_, instr) -> Loop (type_, instr));
           case
             "If"
             (tup3
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.block_type_encoding)
                (scope ["$2"] block_label_encoding)
                (scope ["$3"] block_label_encoding))
             (function
               | If (type_, instr_if, instrs_else) ->
                   Some (type_, instr_if, instrs_else)
               | _ -> None)
             (fun (type_, instrs_if, instrs_else) ->
               If (type_, instrs_if, instrs_else));
           case
             "Br"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function Br var -> Some var | _ -> None)
             (fun var -> Br var);
           case
             "BrIf"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function BrIf var -> Some var | _ -> None)
             (fun var -> BrIf var);
           case
             "BrTable"
             (tup2
                ~flatten:false
                (scope ["$1"] var_list_encoding)
                (value ["$2"] Interpreter_encodings.Ast.var_encoding))
             (function
               | BrTable (table, target) -> Some (table, target) | _ -> None)
             (fun (table, target) -> BrTable (table, target));
           case
             "Return"
             unit_encoding
             (function Return -> Some () | _ -> None)
             (fun () -> Return);
           case
             "Call"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function Call var -> Some var | _ -> None)
             (fun var -> Call var);
           case
             "CallIndirect"
             (tup2
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.var_encoding)
                (value ["$2"] Interpreter_encodings.Ast.var_encoding))
             (function
               | CallIndirect (var1, var2) -> Some (var1, var2) | _ -> None)
             (fun (var1, var2) -> CallIndirect (var1, var2));
           case
             "LocalGet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function LocalGet var -> Some var | _ -> None)
             (fun var -> LocalGet var);
           case
             "LocalSet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function LocalSet var -> Some var | _ -> None)
             (fun var -> LocalSet var);
           case
             "LocalTee"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function LocalTee var -> Some var | _ -> None)
             (fun var -> LocalTee var);
           case
             "GlobalGet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function GlobalGet var -> Some var | _ -> None)
             (fun var -> GlobalGet var);
           case
             "GlobalSet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function GlobalSet var -> Some var | _ -> None)
             (fun var -> GlobalSet var);
           case
             "TableGet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function TableGet var -> Some var | _ -> None)
             (fun var -> TableGet var);
           case
             "TableSet"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function TableSet var -> Some var | _ -> None)
             (fun var -> TableSet var);
           case
             "TableSize"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function TableSize var -> Some var | _ -> None)
             (fun var -> TableSize var);
           case
             "TableGrow"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function TableGrow var -> Some var | _ -> None)
             (fun var -> TableGrow var);
           case
             "TableFill"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function TableFill var -> Some var | _ -> None)
             (fun var -> TableFill var);
           case
             "TableCopy"
             (tup2
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.var_encoding)
                (value ["$2"] Interpreter_encodings.Ast.var_encoding))
             (function
               | TableCopy (var1, var2) -> Some (var1, var2) | _ -> None)
             (fun (var1, var2) -> TableCopy (var1, var2));
           case
             "TableInit"
             (tup2
                ~flatten:false
                (value ["$1"] Interpreter_encodings.Ast.var_encoding)
                (value ["$2"] Interpreter_encodings.Ast.var_encoding))
             (function
               | TableInit (var1, var2) -> Some (var1, var2) | _ -> None)
             (fun (var1, var2) -> TableInit (var1, var2));
           case
             "ElemDrop"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function ElemDrop var -> Some var | _ -> None)
             (fun var -> ElemDrop var);
           case
             "Load"
             (value ["$1"] Interpreter_encodings.Ast.loadop_encoding)
             (function Load loadop -> Some loadop | _ -> None)
             (fun loadop -> Load loadop);
           case
             "Store"
             (value ["$1"] Interpreter_encodings.Ast.storeop_encoding)
             (function Store loadop -> Some loadop | _ -> None)
             (fun loadop -> Store loadop);
           case
             "VecLoad"
             (value ["$1"] Interpreter_encodings.Ast.vec_loadop_encoding)
             (function VecLoad vec_loadop -> Some vec_loadop | _ -> None)
             (fun vec_loadop -> VecLoad vec_loadop);
           case
             "VecStore"
             (value ["$1"] Interpreter_encodings.Ast.vec_storeop_encoding)
             (function VecStore vec_loadop -> Some vec_loadop | _ -> None)
             (fun vec_storeop -> VecStore vec_storeop);
           case
             "VecLoadLane"
             (value ["$1"] Interpreter_encodings.Ast.vec_laneop_encoding)
             (function VecLoadLane vec_laneop -> Some vec_laneop | _ -> None)
             (fun vec_laneop -> VecLoadLane vec_laneop);
           case
             "VecStoreLane"
             (value ["$1"] Interpreter_encodings.Ast.vec_laneop_encoding)
             (function VecStoreLane vec_laneop -> Some vec_laneop | _ -> None)
             (fun vec_laneop -> VecStoreLane vec_laneop);
           case
             "MemorySize"
             unit_encoding
             (function MemorySize -> Some () | _ -> None)
             (fun () -> MemorySize);
           case
             "MemoryGrow"
             unit_encoding
             (function MemoryGrow -> Some () | _ -> None)
             (fun () -> MemoryGrow);
           case
             "MemoryFill"
             unit_encoding
             (function MemoryFill -> Some () | _ -> None)
             (fun () -> MemoryFill);
           case
             "MemoryCopy"
             unit_encoding
             (function MemoryCopy -> Some () | _ -> None)
             (fun () -> MemoryCopy);
           case
             "MemoryInit"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function MemoryInit var -> Some var | _ -> None)
             (fun var -> MemoryInit var);
           case
             "DataDrop"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function DataDrop var -> Some var | _ -> None)
             (fun var -> DataDrop var);
           case
             "RefNull"
             (value ["$1"] Interpreter_encodings.Types.ref_type_encoding)
             (function RefNull ref_type -> Some ref_type | _ -> None)
             (fun ref_type -> RefNull ref_type);
           case
             "RefFunc"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function RefFunc var -> Some var | _ -> None)
             (fun var -> RefFunc var);
           case
             "RefFunc"
             (value ["$1"] Interpreter_encodings.Ast.var_encoding)
             (function RefFunc var -> Some var | _ -> None)
             (fun var -> RefFunc var);
           case
             "RefIsNull"
             unit_encoding
             (function RefIsNull -> Some () | _ -> None)
             (fun () -> RefIsNull);
           case
             "Const"
             (value ["$1"] Interpreter_encodings.Ast.num_encoding)
             (function Const var -> Some var | _ -> None)
             (fun var -> Const var);
           case
             "Test"
             (value ["$1"] Interpreter_encodings.Ast.testop_encoding)
             (function Test var -> Some var | _ -> None)
             (fun var -> Test var);
           case
             "Compare"
             (value ["$1"] Interpreter_encodings.Ast.relop_encoding)
             (function Compare var -> Some var | _ -> None)
             (fun var -> Compare var);
           case
             "Unary"
             (value ["$1"] Interpreter_encodings.Ast.unop_encoding)
             (function Unary var -> Some var | _ -> None)
             (fun var -> Unary var);
           case
             "Binary"
             (value ["$1"] Interpreter_encodings.Ast.binop_encoding)
             (function Binary var -> Some var | _ -> None)
             (fun var -> Binary var);
           case
             "Convert"
             (value ["$1"] Interpreter_encodings.Ast.cvtop_encoding)
             (function Convert var -> Some var | _ -> None)
             (fun var -> Convert var);
           case
             "VecConst"
             (value ["$1"] Interpreter_encodings.Ast.vec_encoding)
             (function VecConst vec -> Some vec | _ -> None)
             (fun vec -> VecConst vec);
           case
             "VecTest"
             (value ["$1"] Interpreter_encodings.Ast.vec_testop_encoding)
             (function VecTest op -> Some op | _ -> None)
             (fun op -> VecTest op);
           case
             "VecCompare"
             (value ["$1"] Interpreter_encodings.Ast.vec_relop_encoding)
             (function VecCompare op -> Some op | _ -> None)
             (fun op -> VecCompare op);
           case
             "VecUnary"
             (value ["$1"] Interpreter_encodings.Ast.vec_unop_encoding)
             (function VecUnary op -> Some op | _ -> None)
             (fun op -> VecUnary op);
           case
             "VecBinary"
             (value ["$1"] Interpreter_encodings.Ast.vec_binop_encoding)
             (function VecBinary op -> Some op | _ -> None)
             (fun op -> VecBinary op);
           case
             "VecConvert"
             (value ["$1"] Interpreter_encodings.Ast.vec_cvtop_encoding)
             (function VecConvert op -> Some op | _ -> None)
             (fun op -> VecConvert op);
           case
             "VecShift"
             (value ["$1"] Interpreter_encodings.Ast.vec_shiftop_encoding)
             (function VecShift op -> Some op | _ -> None)
             (fun op -> VecShift op);
           case
             "VecBitmask"
             (value ["$1"] Interpreter_encodings.Ast.vec_bitmaskop_encoding)
             (function VecBitmask op -> Some op | _ -> None)
             (fun op -> VecBitmask op);
           case
             "VecTestBits"
             (value ["$1"] Interpreter_encodings.Ast.vec_vtestop_encoding)
             (function VecTestBits op -> Some op | _ -> None)
             (fun op -> VecTestBits op);
           case
             "VecUnaryBits"
             (value ["$1"] Interpreter_encodings.Ast.vec_vunop_encoding)
             (function VecUnaryBits op -> Some op | _ -> None)
             (fun op -> VecUnaryBits op);
           case
             "VecBinaryBits"
             (value ["$1"] Interpreter_encodings.Ast.vec_vbinop_encoding)
             (function VecBinaryBits op -> Some op | _ -> None)
             (fun op -> VecBinaryBits op);
           case
             "VecTernaryBits"
             (value ["$1"] Interpreter_encodings.Ast.vec_vternop_encoding)
             (function VecTernaryBits op -> Some op | _ -> None)
             (fun op -> VecTernaryBits op);
           case
             "VecSplat"
             (value ["$1"] Interpreter_encodings.Ast.vec_splatop_encoding)
             (function VecSplat op -> Some op | _ -> None)
             (fun op -> VecSplat op);
           case
             "VecExtract"
             (value ["$1"] Interpreter_encodings.Ast.vec_extractop_encoding)
             (function VecExtract op -> Some op | _ -> None)
             (fun op -> VecExtract op);
           case
             "VecReplace"
             (value ["$1"] Interpreter_encodings.Ast.vec_replaceop_encoding)
             (function VecReplace op -> Some op | _ -> None)
             (fun op -> VecReplace op);
         ])

  let instruction_list_encoding =
    (* TODO: #3149
       Rewrite instruction list encoding using virtual "instruction block"
       pointers. *)
    list_encoding instruction_encoding

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

  let function_encoding ~current_module =
    tagged_union
      string_tag
      [
        case
          "Host"
          (tup2
             ~flatten:false
             func_type_encoding
             (value ["name"] Data_encoding.string))
          (function
            | Func.HostFunc (func_type, name) -> Some (func_type, name)
            | _ -> None)
          (fun (func_type, name) -> Func.HostFunc (func_type, name));
        case
          "Native"
          (tup4
             ~flatten:false
             function_type_encoding
             (value ["ftype"] Interpreter_encodings.Ast.var_encoding)
             (lazy_vector_encoding
                "locals"
                (value [] Interpreter_encodings.Types.value_type_encoding))
             block_label_encoding)
          (function
            | Func.AstFunc
                (type_, _current_module, {at = _; it = {ftype; locals; body}})
              ->
                (* Note that we do not encode [_current_module] to avoid
                   infinite recursion. Instead we use the given self-reference
                   [current_module] on decoding. *)
                Some (type_, ftype, locals, body)
            | _ -> None)
          (fun (type_, ftype, locals, body) ->
            let func =
              Source.{at = no_region; it = {Ast.ftype; locals; body}}
            in
            Func.AstFunc (type_, Lazy.force current_module, func));
      ]

  let value_ref_encoding ~current_module =
    tagged_union
      string_tag
      [
        case
          "FuncRef"
          (function_encoding ~current_module)
          (fun val_ref ->
            match val_ref with
            | Instance.FuncRef func_inst -> Some func_inst
            | _ -> None)
          (fun func -> Instance.FuncRef func);
        case
          "ExternRef"
          (value ["value"] Data_encoding.int32)
          (function Values.ExternRef v -> Some v | _ -> None)
          (fun v -> Values.ExternRef v);
      ]

  let value_encoding ~current_module =
    tagged_union
      string_tag
      [
        case
          "NumType I32Type"
          (value ["value"] Interpreter_encodings.Values.num_encoding)
          (function Values.Num n -> Some n | _ -> None)
          (fun n -> Values.Num n);
        case
          "NumType I64Type"
          (value ["value"] Interpreter_encodings.Values.num_encoding)
          (function Values.Num n -> Some n | _ -> None)
          (fun n -> Values.Num n);
        case
          "VecType V128Type"
          (value ["value"] Interpreter_encodings.Values.vec_encoding)
          (function Values.Vec v -> Some v | _ -> None)
          (fun v -> Values.Vec v);
        case
          "RefType"
          (value_ref_encoding ~current_module)
          (function Values.Ref r -> Some r | _ -> None)
          (fun r -> Values.Ref r);
      ]

  let memory_encoding =
    conv
      (fun (min, max, chunks) ->
        Memory.of_chunks (MemoryType {min; max}) chunks)
      (fun memory_inst ->
        let (MemoryType {min; max}) = Memory.type_of memory_inst in
        let content = Memory.content memory_inst in
        (min, max, content))
      (tup3
         ~flatten:false
         (value ["min"] Data_encoding.int32)
         (option (value ["max"] Data_encoding.int32))
         (scope ["chunks"] chunked_byte_vector))

  let table_encoding ~current_module =
    conv
      (fun (min, max, vector) ->
        let table_type = Types.TableType ({min; max}, FuncRefType) in
        (* There are different vector types so we need to map from one to
           the other. *)
        let table_entries =
          Table.Vector.Vector.create
            ~produce_value:(fun ix -> V.get ix vector)
            (V.num_elements vector)
        in
        Table.of_lazy_vector table_type table_entries)
      (fun table ->
        let (Types.TableType ({min; max}, _)) = Table.type_of table in
        (* Here we map the other way round. *)
        let table_entries = Table.content table in
        let vector =
          V.create
            ~produce_value:(fun ix -> Table.Vector.Vector.get ix table_entries)
            (Table.Vector.Vector.num_elements table_entries)
        in
        (min, max, vector))
      (tup3
         ~flatten:false
         (value ["min"] Data_encoding.int32)
         (option (value ["max"] Data_encoding.int32))
         (lazy_vector_encoding "refs" (value_ref_encoding ~current_module)))

  let global_encoding ~current_module =
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
         (scope ["value"] (value_encoding ~current_module)))

  let memory_instance_encoding = lazy_vector_encoding "memories" memory_encoding

  let table_vector_encoding ~current_module =
    lazy_vector_encoding "tables" (table_encoding ~current_module)

  let global_vector_encoding ~current_module =
    lazy_vector_encoding "globals" (global_encoding ~current_module)

  let chunked_byte_vector_ref_encoding =
    conv (fun x -> ref x) (fun r -> !r) chunked_byte_vector

  let function_vector_encoding ~current_module =
    lazy_vector_encoding "functions" (function_encoding ~current_module)

  let function_type_vector_encoding =
    lazy_vector_encoding "types" function_type_encoding

  let value_ref_vector_encoding ~current_module =
    lazy_vector_encoding "refs" (value_ref_encoding ~current_module)

  let extern_map_encoding ~current_module =
    lazy_mapping
      (tagged_union
         string_tag
         [
           case
             "ExternFunc"
             (function_encoding ~current_module)
             (function Instance.ExternFunc x -> Some x | _ -> None)
             (fun x -> Instance.ExternFunc x);
           case
             "ExternTable"
             (table_encoding ~current_module)
             (function Instance.ExternTable x -> Some x | _ -> None)
             (fun x -> Instance.ExternTable x);
           case
             "ExternMemory"
             memory_encoding
             (function Instance.ExternMemory x -> Some x | _ -> None)
             (fun x -> Instance.ExternMemory x);
           case
             "ExternGlobal"
             (global_encoding ~current_module)
             (function Instance.ExternGlobal x -> Some x | _ -> None)
             (fun x -> Instance.ExternGlobal x);
         ])

  let value_ref_vector_vector_encoding ~current_module =
    lazy_vector_encoding
      "elements"
      (conv
         (fun x -> ref x)
         (fun r -> !r)
         (value_ref_vector_encoding ~current_module))

  let data_instance_encoding =
    lazy_vector_encoding "datas" chunked_byte_vector_ref_encoding

  let block_table_encoding =
    lazy_vector_encoding
      "block-table"
      (lazy_vector_encoding "instructions" instruction_encoding)

  let module_instance_encoding =
    let open Lwt_syntax in
    let gen_encoding current_module =
      let current_module = Lazy.map (fun x -> ref x) current_module in
      conv_lwt
        (fun ( types,
               funcs,
               tables,
               memories,
               globals,
               exports,
               elems,
               datas,
               blocks ) ->
          let open Lwt_syntax in
          return
            {
              Instance.types;
              funcs;
              tables;
              memories;
              globals;
              exports;
              elems;
              datas;
              blocks;
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
               blocks;
             } ->
          return
            ( types,
              funcs,
              tables,
              memories,
              globals,
              exports,
              elems,
              datas,
              blocks ))
        (tup9
           ~flatten:false
           function_type_vector_encoding
           (function_vector_encoding ~current_module)
           (table_vector_encoding ~current_module)
           memory_instance_encoding
           (global_vector_encoding ~current_module)
           (extern_map_encoding ~current_module)
           (value_ref_vector_vector_encoding ~current_module)
           data_instance_encoding
           block_table_encoding)
    in
    with_self_reference gen_encoding
end
