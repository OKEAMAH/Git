(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech  <contact@trili.tech>                       *)
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

open Lazy_containers
open Tezos_webassembly_interpreter

let pp_int32 out n = Format.fprintf out "%ld" n

let pp_int64 out n = Format.fprintf out "%Ld" n

let pp_var = Source.pp_phrase pp_int32

let pp_list pp out x =
  Format.fprintf
    out
    "@[<hv 2>[%a]@]"
    (Format.pp_print_list ~pp_sep:(fun out () -> Format.fprintf out ";@;") pp)
    x

let pp_value_type_list = pp_list Types.pp_value_type

let pp_block_label out (Ast.Block_label l) =
  Format.fprintf out "Block_label @[<hv 2>(%ld)@]" l

let pp_data_label out (Ast.Data_label l) =
  Format.fprintf out "Data_label @[<hv 2>(%ld)@]" l

let pp_opt pp out = function
  | Some x -> Format.fprintf out "Some @[<hv 2>(%a)@]" pp x
  | None -> Format.fprintf out "None"

let pp_unit out () = Format.pp_print_string out "()"

let pp_pair pp1 pp2 out (x, y) = Format.fprintf out "(%a, %a)" pp1 x pp2 y

let pp_block_type out = function
  | Ast.VarBlockType v -> pp_var out v
  | Ast.ValBlockType v -> pp_opt Types.pp_value_type out v

let pp_memop pp_ty pp_pack out {Ast.ty; align; pack; offset} =
  Format.fprintf
    out
    "@[<hv 2>{ty = %a;@; align = %d;@; pack = %a;@; offset = %a}@]"
    pp_ty
    ty
    align
    pp_pack
    pack
    pp_int32
    offset

let pp_vec_store_op = pp_memop Types.pp_vec_type pp_unit

let pp_value_op pp_int32 pp_int64 out = function
  | Values.I32 x -> pp_int32 out x
  | I64 x -> pp_int64 out x
  | _ -> Stdlib.failwith "Floating point values are not supported"

let pp_num = Source.pp_phrase (pp_value_op pp_int32 pp_int64)

let pp_int_relop out op =
  Format.pp_print_string
    out
    (match op with
    | Ast.IntOp.Eq -> "Eq"
    | Ne -> "Ne"
    | LtS -> "LtS"
    | LtU -> "LtU"
    | LeS -> "LeS"
    | LeU -> "LeU"
    | GtS -> "GtS"
    | GtU -> "GtU"
    | GeS -> "GeS"
    | GeU -> "GeU")

let float_relop_gen out op =
  Format.pp_print_string
    out
    (match op with
    | Ast.FloatOp.Eq -> "Eq"
    | Ne -> "Ne"
    | Lt -> "Lt"
    | Le -> "Le"
    | Gt -> "Gt"
    | Ge -> "Ge")

let pp_int_unop out op =
  match op with
  | Ast.IntOp.Clz -> Format.pp_print_string out "Clz"
  | Ctz -> Format.pp_print_string out "Ctz"
  | Popcnt -> Format.pp_print_string out "Popcnt"
  | ExtendS ps -> Format.fprintf out "Extend %a" Types.pp_pack_size ps

let pp_int_binop out op =
  Format.pp_print_string
    out
    (match op with
    | Ast.IntOp.Add -> "Add"
    | Sub -> "Sub"
    | Mul -> "Mul"
    | DivS -> "DivS"
    | DivU -> "DivU"
    | RemS -> "RemS"
    | RemU -> "RemU"
    | And -> "And"
    | Or -> "Or"
    | Xor -> "Xor"
    | Shl -> "Shl"
    | ShrS -> "ShrS"
    | ShrU -> "ShrU"
    | Rotl -> "Rotl"
    | Rotr -> "Rotr")

let pp_int_cvtop out op =
  Format.pp_print_string
    out
    (match op with
    | Ast.IntOp.ExtendSI32 -> "ExtendSI32"
    | ExtendUI32 -> "ExtendUI32"
    | WrapI64 -> "WrapI64"
    | TruncSF32 -> "TruncSF32"
    | TruncUF32 -> "TruncUF32"
    | TruncSF64 -> "TruncSF64"
    | TruncUF64 -> "TruncUF64"
    | TruncSatSF32 -> "TruncSatSF32"
    | TruncSatUF32 -> "TruncSatUF32"
    | TruncSatSF64 -> "TruncSatSF64"
    | TruncSatUF64 -> "TruncSatUF64"
    | ReinterpretFloat -> "ReinterpretFloat")

(*
  Generate instructions. The following are missing:
  - [VecTest]
  - [VecCompare]
  - [VecUnary]
  - [VecBinary]
  - [VecConvert]
  - [VecShift]
  - [VecBitmask]
  - [VecTestBits]
  - [VecUnaryBits]
  - [VecBinaryBits]
  - [VecTernaryBits]
  - [VecSplat]
  - [VecExtract]
  - [VecReplace]
  *)
let pp_instr' out instr =
  let open Ast in
  let str s = Format.pp_print_string out s in
  let var s v = Format.fprintf out "%s %a" s pp_var v in
  match instr with
  | Unreachable -> str "Unreachable"
  | Nop -> str "Nop"
  | Drop -> str "Drop"
  | Return -> str "Return"
  | MemorySize -> str "MemorySize"
  | MemoryGrow -> str "MemoryGrow"
  | MemoryFill -> str "MemoryFill"
  | MemoryCopy -> str "MemoryCopy"
  | RefIsNull -> str "RefIsNull"
  | Br v -> var "Br" v
  | BrIf v -> var "BrIf" v
  | Call v -> var "Call" v
  | LocalGet v -> var "LocalGet" v
  | LocalSet v -> var "LocalSet" v
  | LocalTee v -> var "LocalTee" v
  | GlobalGet v -> var "GlobalGet" v
  | GlobalSet v -> var "GlobalSet" v
  | TableGet v -> var "TableGet" v
  | TableSet v -> var "TableSet" v
  | TableSize v -> var "TableSize" v
  | TableGrow v -> var "TableGrow" v
  | TableFill v -> var "TableFill" v
  | ElemDrop v -> var "ElemDrop" v
  | MemoryInit v -> var "MemoryInit" v
  | DataDrop v -> var "DataDrop" v
  | RefFunc v -> var "RefFunc" v
  | Select vt -> Format.fprintf out "Select (%a)" (pp_opt pp_value_type_list) vt
  | Block (bt, l) ->
      Format.fprintf out "Block (%a, %a)" pp_block_type bt pp_block_label l
  | Loop (bt, l) ->
      Format.fprintf out "Loop (%a, %a)" pp_block_type bt pp_block_label l
  | If (bt, l1, l2) ->
      Format.fprintf
        out
        "If (%a, %a, %a)"
        pp_block_type
        bt
        pp_block_label
        l1
        pp_block_label
        l2
  | BrTable (vs, v) ->
      Format.fprintf out "BrTable(%a, %a)" (pp_list pp_var) vs pp_var v
  | CallIndirect (v1, v2) ->
      Format.fprintf out "CallIndirect(%a, %a)" pp_var v1 pp_var v2
  | Load o -> Format.fprintf out "Load(%a)" pp_loadop o
  | Store o -> Format.fprintf out "Store(%a)" pp_storeop o
  | VecLoad o -> Format.fprintf out "VecLoad(%a)" pp_vec_loadop o
  | VecStore o -> Format.fprintf out "VecSore(%a)" pp_vec_store_op o
  | VecLoadLane o -> Format.fprintf out "VecLoadLane(%a)" pp_vec_laneop o
  | VecStoreLane o -> Format.fprintf out "VecSoreLane(%a)" pp_vec_laneop o
  | RefNull rt -> Format.fprintf out "RefNull (%a)" Types.pp_ref_type rt
  | Const c -> Format.fprintf out "Const(%a)" pp_num c
  | Compare c -> Format.fprintf out "Compare(%a)" pp_relop c
  | Unary c -> Format.fprintf out "Unary (%a)" pp_unop c
  | Binary c -> Format.fprintf out "Binary (%a)" pp_binop c
  | Convert c -> Format.fprintf out "Convert(%a)" pp_cvtop c
  | VecConst c -> Format.fprintf out "VecConst (%a)" pp_vec c
  | _ -> Stdlib.failwith "Unsupported instruction"

let pp_instr = Source.pp_phrase pp_instr'

let pp_vector pp out v =
  (* Force evaluation of the vector. *)
  let _ = Lwt_main.run @@ Lazy_vector.LwtInt32Vector.to_list v in
  Lazy_vector.LwtInt32Vector.pp pp out v

let pp_vector_z pp out v =
  (* Force evaluation of the vector. *)
  let _ = Lwt_main.run @@ Lazy_vector.LwtZVector.to_list v in
  Lazy_vector.LwtZVector.pp pp out v

let pp_resul_type = pp_vector Types.pp_value_type

let pp_func_type out = function
  | Types.FuncType (pt, rt) ->
      Format.fprintf out "FuncType (%a, %a)" pp_resul_type pt pp_resul_type rt

let pp_func =
  Source.pp_phrase @@ fun out {Ast.ftype; locals; body} ->
  Format.fprintf
    out
    "@[<hv 2>{ftype = %a;@; locals = %a;@; body = %a}@]"
    pp_var
    ftype
    (pp_vector Types.pp_value_type)
    locals
    pp_block_label
    body

let pp_func out func =
  match func with
  | Func.AstFunc (ft, _, f) ->
      Format.fprintf
        out
        "AstFunc @[<hv 2>(%a,@; %a)@]"
        pp_func_type
        ft
        pp_func
        f
  | Func.HostFunc (ft, n) ->
      Format.fprintf out "HostFunc @[<hv 2>(%a,@; %s)@]" pp_func_type ft n

let pp_limit pp out {Types.min; Types.max} =
  Format.fprintf out "{min = %a; max = %a}" pp min (pp_opt pp) max

let pp_table_type out (Types.TableType (limit, ref_type)) =
  Format.fprintf
    out
    "Types.TableType (%a, %a)"
    (pp_limit pp_int32)
    limit
    Types.pp_ref_type
    ref_type

let pp_ref out = function
  | Values.NullRef rt -> Format.fprintf out "NullRef (%a)" Types.pp_ref_type rt
  | Values.ExternRef n -> Format.fprintf out "ExternRef(%a)" pp_int32 n
  | _ -> Stdlib.failwith "Unsupported value ref"

let pp_memory_type out (Types.MemoryType limit) =
  Format.fprintf out "MemoryType %a" (pp_limit pp_int32) limit

let pp_chunk_byte_vector out chunks =
  let bs = Lwt_main.run @@ Chunked_byte_vector.Lwt.to_string chunks in
  (* We just show the hash of the chunk in order to avoid too much noise. *)
  let hash = Hashtbl.hash bs in
  Format.fprintf out "#%d" hash

let pp_table out t =
  let ty = Partial_table.type_of t in
  let c = Partial_table.content t in
  Format.fprintf
    out
    "@[<hv 2>{ty = %a;@; content = (%a)}@]"
    pp_table_type
    ty
    (pp_vector pp_ref)
    c

let pp_value_num = pp_value_op pp_int32 pp_int64

let pp_value out = function
  | Values.Num n -> Format.fprintf out "Num %a" pp_value_num n
  | Values.Ref r -> Format.fprintf out "Ref %a" pp_ref r
  | Values.Vec (V128 v) ->
      let hash = Hashtbl.hash @@ V128.to_string v in
      Format.fprintf out "Vec (V128 (#%d))" hash

let pp_memory out memory =
  let ty = Memory.type_of memory in
  let content = Memory.content memory in
  Format.fprintf
    out
    "@[<hv 2>{ty = %a;@; content = %a}@]"
    pp_memory_type
    ty
    pp_chunk_byte_vector
    content

let pp_global out global =
  let ty = Global.type_of global in
  let content = Global.load global in
  Format.fprintf
    out
    "@[<hv 2>{ty = %a;@; content = %a}@]"
    Types.pp_global_type
    ty
    pp_value
    content

let pp_extern out = function
  | Instance.ExternFunc f -> Format.fprintf out "ExternFunc %a" pp_func f
  | Instance.ExternTable t -> Format.fprintf out "ExternTable %a" pp_table t
  | Instance.ExternMemory m -> Format.fprintf out "ExternMemory %a" pp_memory m
  | Instance.ExternGlobal g -> Format.fprintf out "ExternGlobal %a" pp_global g

let pp_map pp out map =
  let pp_name_list = pp_list Format.pp_print_int in
  pp_list (pp_pair pp_name_list pp) out (Instance.NameMap.loaded_bindings map)

let pp_elems out ref = pp_vector pp_ref out !ref

let pp_blocks_table = pp_vector (pp_vector pp_instr)

let pp_datas_table = pp_vector pp_chunk_byte_vector

let pp_allocations out allocations =
  Format.fprintf
    out
    "@[<v 2>{blocks = %a;@;datas = %a;@;}@]"
    pp_blocks_table
    allocations.Ast.blocks
    pp_datas_table
    allocations.Ast.datas

let pp_data_inst out ref = pp_data_label out !ref

let pp_module out
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
    } =
  Format.fprintf
    out
    "@[<v 2>{types = %a;@;\
     funcs = %a;@;\
     tables = %a;@;\
     memories = %a;@;\
     globals = %a;@;\
     exports = %a;@;\
     elems = %a;@;\
     datas = %a;@;\
     allocations = %a;@;\
     }@]"
    (pp_vector pp_func_type)
    types
    (pp_vector pp_func)
    funcs
    (pp_vector pp_table)
    tables
    (pp_vector pp_memory)
    memories
    (pp_vector pp_global)
    globals
    (pp_map pp_extern)
    exports
    (pp_vector pp_elems)
    elems
    (pp_vector pp_data_inst)
    datas
    pp_allocations
    allocations

let pp_frame out frame =
  let open Eval in
  let (Module_key key) = frame.inst in
  Format.fprintf
    out
    "@[<v 2>{module = %s;@;locals = %a;@;}@]"
    key
    (Format.pp_print_list pp_value)
    (List.map ( ! ) frame.locals)

let rec pp_admin_instr' out instr =
  let open Eval in
  match instr with
  | From_block (block, index) ->
      Format.fprintf
        out
        "From_block @[<hv 2>(%a,@; %li)@]"
        pp_block_label
        block
        index
  | Plain instr -> Format.fprintf out "Plain @[<hv 2>%a@]" pp_instr' instr
  | Refer ref_ -> Format.fprintf out "Refer @[<hv 2>%a@]" pp_ref ref_
  | Invoke func -> Format.fprintf out "Invoke @[<hv 2>%a@]" pp_func func
  | Trapping msg ->
      Format.fprintf out "Trapping @[<hv 2>%a@]" Format.pp_print_string msg
  | Returning values ->
      Format.fprintf
        out
        "Returning @[<hv 2>%a@]"
        (Format.pp_print_list pp_value)
        values
  | Breaking (index, values) ->
      Format.fprintf
        out
        "Breaking @[<hv 2>(%li,@; %a)@]"
        index
        (Format.pp_print_list pp_value)
        values
  | Label (index, final_instrs, (values, instrs)) ->
      Format.fprintf
        out
        "Label @[<hv 2>(%li,@; %a,@; %a,@; %a)@]"
        index
        (Format.pp_print_list pp_instr)
        final_instrs
        (Format.pp_print_list pp_value)
        values
        (Format.pp_print_list pp_admin_instr)
        instrs
  | Frame (index, frame, (values, instrs)) ->
      Format.fprintf
        out
        "Frame @[<hv 2>(%li,@; %a,@; %a,@; %a)@]"
        index
        pp_frame
        frame
        (Format.pp_print_list pp_value)
        values
        (Format.pp_print_list pp_admin_instr)
        instrs

and pp_admin_instr out instr = pp_admin_instr' out instr.Source.it

let pp_input_message out message =
  let open Input_buffer in
  Format.fprintf
    out
    "@[<v 2>{rtype = %li;@;\
     raw_level = %li;@;\
     message_counter = %s;@;\
     payload = %a;@;\
     }@]"
    message.rtype
    message.raw_level
    (Z.to_string message.message_counter)
    Hex.pp
    (Hex.of_bytes message.payload)

let pp_input_buffer out input =
  let open Input_buffer in
  Format.fprintf
    out
    "@[<v 2>{content = %a;@;num_elements = %s;@;}@]"
    (pp_vector_z pp_input_message)
    (Lazy_vector.Mutable.LwtZVector.snapshot input.content)
    (Z.to_string input.num_elements)

let pp_config out
    Eval.{frame; input; code = values, instrs; host_funcs = _; budget} =
  Format.fprintf
    out
    "@[<v 2>{frame = %a;@;\
     input = %a;@;\
     instructions = %a;@;\
     values = %a;@;\
     budget = %i;@;\
     }@]"
    pp_frame
    frame
    pp_input_buffer
    input
    (Format.pp_print_list pp_admin_instr)
    instrs
    (Format.pp_print_list pp_value)
    values
    budget
