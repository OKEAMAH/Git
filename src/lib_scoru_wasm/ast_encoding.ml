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

open Tezos_webassembly_interpreter
open Ast
module Values = Values_encoding
module Types = Types_encoding

module IntOp = struct
  open IntOp

  let unop_encoding =
    let open Data_encoding in
    union
      [
        case
          ~title:"Clz"
          (Tag 0)
          (constant "Clz")
          (function Clz -> Some () | _ -> None)
          (fun () -> Clz);
        case
          ~title:"Ctz"
          (Tag 1)
          (constant "Ctz")
          (function Ctz -> Some () | _ -> None)
          (fun () -> Ctz);
        case
          ~title:"Popnct"
          (Tag 2)
          (constant "Popnct")
          (function Popcnt -> Some () | _ -> None)
          (fun () -> Popcnt);
        case
          ~title:"ExtendS"
          (Tag 3)
          (obj1 (req "ExtendS" Types.pack_size_encoding))
          (function ExtendS s -> Some s | _ -> None)
          (fun s -> ExtendS s);
      ]

  let binop_encoding =
    Data_encoding.string_enum
      [
        ("Add", Add);
        ("Sub", Sub);
        ("Mul", Mul);
        ("DivS", DivS);
        ("DivU", DivU);
        ("RemS", RemS);
        ("RemU", RemU);
        ("And", And);
        ("Or", Or);
        ("Xor", Xor);
        ("Shl", Shl);
        ("ShrS", ShrS);
        ("ShrU", ShrU);
        ("Rotl", Rotl);
        ("Rotr", Rotr);
      ]

  let testop_encoding =
    Data_encoding.(conv (fun Eqz -> ()) (fun () -> Eqz) (constant "Eqz"))

  let relop_encoding =
    Data_encoding.string_enum
      [
        ("Eq", Eq);
        ("Ne", Ne);
        ("LtS", LtS);
        ("LtU", LtU);
        ("GtS", GtS);
        ("GtU", GtU);
        ("LeS", LeS);
        ("LeU", LeU);
        ("GeS", GeS);
        ("GeU", GeU);
      ]

  let cvtop_encoding =
    Data_encoding.string_enum
      [
        ("ExtendSI32", ExtendSI32);
        ("ExtendUI32", ExtendUI32);
        ("WrapI64", WrapI64);
        ("TruncSF32", TruncSF32);
        ("TruncUF32", TruncUF32);
        ("TruncSF64", TruncSF64);
        ("TruncUF64", TruncUF64);
        ("TruncSatSF32", TruncSatSF32);
        ("TruncSatUF32", TruncSatUF32);
        ("TruncSatSF64", TruncSatSF64);
        ("TruncSatUF64", TruncSatUF64);
        ("ReinterpretFloat", ReinterpretFloat);
      ]
end

module FloatOp = struct
  open FloatOp

  let unop_encoding =
    Data_encoding.string_enum
      ([
         ("Neg", Neg);
         ("Abs", Abs);
         ("Ceil", Ceil);
         ("Floor", Floor);
         ("Trunc", Trunc);
         ("Nearest", Nearest);
         ("Sqrt", Sqrt);
       ]
        : (string * unop) list)

  let binop_encoding =
    Data_encoding.string_enum
      ([
         ("Add", Add);
         ("Sub", Sub);
         ("Mul", Mul);
         ("Div", Div);
         ("Min", Min);
         ("Max", Max);
         ("CopySign", CopySign);
       ]
        : (string * binop) list)

  let testop_encoding =
    Data_encoding.(
      conv
        (function (_ : testop) -> .)
        (fun () ->
          failwith "FloatOp.testop_encoding"
          (* the testop type cannot be instantiated and is used to fill an
             impossible case in the AST, this shouldn't happen. *))
        null)

  let relop_encoding =
    Data_encoding.string_enum
      ([("Eq", Eq); ("Ne", Ne); ("Lt", Lt); ("Gt", Gt); ("Le", Le); ("Ge", Ge)]
        : (string * relop) list)

  let cvtop_encoding =
    Data_encoding.string_enum
      [
        ("ConvertSI32", ConvertSI32);
        ("ConvertUI32", ConvertUI32);
        ("ConvertSI64", ConvertSI64);
        ("ConvertUI64", ConvertUI64);
        ("PromoteF32", PromoteF32);
        ("DemoteF64", DemoteF64);
        ("ReinterpretInt", ReinterpretInt);
      ]
end

module V128Op = struct
  open Ast.V128Op

  let itestop_encoding =
    Data_encoding.(
      conv (fun AllTrue -> ()) (fun () -> AllTrue) (constant "AllTrue"))

  let iunop_encoding =
    Data_encoding.string_enum
      ([("Abs", Abs); ("Neg", Neg); ("Popcnt", Popcnt)] : (string * iunop) list)

  let funop_encoding =
    Data_encoding.string_enum
      [
        ("Abs", Abs);
        ("Neg", Neg);
        ("Sqrt", Sqrt);
        ("Ceil", Ceil);
        ("Floor", Floor);
        ("Trunc", Trunc);
        ("Nearest", Nearest);
      ]

  let ibinop_encoding =
    let open Data_encoding in
    union
      [
        case
          ~title:"Add"
          (Tag 0)
          (constant "Add")
          (function (Add : ibinop) -> Some () | _ -> None)
          (fun () -> Add);
        case
          ~title:"Sub"
          (Tag 1)
          (constant "Sub")
          (function (Sub : ibinop) -> Some () | _ -> None)
          (fun () -> Sub);
        case
          ~title:"Mul"
          (Tag 2)
          (constant "Mul")
          (function (Mul : ibinop) -> Some () | _ -> None)
          (fun () -> Mul);
        case
          ~title:"MinS"
          (Tag 3)
          (constant "MinS")
          (function MinS -> Some () | _ -> None)
          (fun () -> MinS);
        case
          ~title:"MinU"
          (Tag 4)
          (constant "MinU")
          (function MinU -> Some () | _ -> None)
          (fun () -> MinU);
        case
          ~title:"MaxS"
          (Tag 5)
          (constant "MaxS")
          (function MaxS -> Some () | _ -> None)
          (fun () -> MaxS);
        case
          ~title:"MaxU"
          (Tag 6)
          (constant "MaxU")
          (function MaxU -> Some () | _ -> None)
          (fun () -> MaxU);
        case
          ~title:"AvgrU"
          (Tag 7)
          (constant "AvgrU")
          (function AvgrU -> Some () | _ -> None)
          (fun () -> AvgrU);
        case
          ~title:"AddSatS"
          (Tag 8)
          (constant "AddSatS")
          (function AddSatS -> Some () | _ -> None)
          (fun () -> AddSatS);
        case
          ~title:"AddSatU"
          (Tag 9)
          (constant "AddSatU")
          (function AddSatU -> Some () | _ -> None)
          (fun () -> AddSatU);
        case
          ~title:"SubSatS"
          (Tag 10)
          (constant "SubSatS")
          (function SubSatS -> Some () | _ -> None)
          (fun () -> SubSatS);
        case
          ~title:"SubSatU"
          (Tag 11)
          (constant "SubSatU")
          (function SubSatU -> Some () | _ -> None)
          (fun () -> SubSatU);
        case
          ~title:"DotS"
          (Tag 12)
          (constant "DotS")
          (function DotS -> Some () | _ -> None)
          (fun () -> DotS);
        case
          ~title:"Q15MulRSatS"
          (Tag 13)
          (constant "Q15MulRSatS")
          (function Q15MulRSatS -> Some () | _ -> None)
          (fun () -> Q15MulRSatS);
        case
          ~title:"ExtMulLowS"
          (Tag 14)
          (constant "ExtMulLowS")
          (function ExtMulLowS -> Some () | _ -> None)
          (fun () -> ExtMulLowS);
        case
          ~title:"ExtMulHighS"
          (Tag 15)
          (constant "ExtMulHighS")
          (function ExtMulHighS -> Some () | _ -> None)
          (fun () -> ExtMulHighS);
        case
          ~title:"ExtMulLowU"
          (Tag 16)
          (constant "ExtMulLowU")
          (function ExtMulLowU -> Some () | _ -> None)
          (fun () -> ExtMulLowU);
        case
          ~title:"ExtMulHighU"
          (Tag 17)
          (constant "ExtMulHighU")
          (function ExtMulHighU -> Some () | _ -> None)
          (fun () -> ExtMulHighU);
        case
          ~title:"Swizzle"
          (Tag 18)
          (constant "Swizzle")
          (function Swizzle -> Some () | _ -> None)
          (fun () -> Swizzle);
        case
          ~title:"Shuffle"
          (Tag 19)
          (obj1 (req "Shuffle" (list int31)))
          (function Shuffle l -> Some l | _ -> None)
          (fun l -> Shuffle l);
        case
          ~title:"NarrowS"
          (Tag 20)
          (constant "NarrowS")
          (function NarrowS -> Some () | _ -> None)
          (fun () -> NarrowS);
        case
          ~title:"NarrowU"
          (Tag 21)
          (constant "NarrowU")
          (function NarrowU -> Some () | _ -> None)
          (fun () -> NarrowU);
      ]

  let fbinop_encoding =
    Data_encoding.string_enum
      ([
         ("Add", Add);
         ("Sub", Sub);
         ("Mul", Mul);
         ("Div", Div);
         ("Min", Min);
         ("Max", Max);
         ("Pmin", Pmin);
         ("Pmax", Pmax);
       ]
        : (string * fbinop) list)

  let irelop_encoding =
    Data_encoding.string_enum
      ([
         ("Eq", Eq);
         ("Ne", Ne);
         ("LtS", LtS);
         ("LtU", LtU);
         ("LeS", LeS);
         ("LeU", LeU);
         ("GtS", GtS);
         ("GtU", GtU);
         ("GeS", GeS);
         ("GeU", GeU);
       ]
        : (string * irelop) list)

  let frelop_encoding =
    Data_encoding.string_enum
      [("Eq", Eq); ("Ne", Ne); ("Lt", Lt); ("Le", Le); ("Gt", Gt); ("Ge", Ge)]

  let icvtop_encoding =
    Data_encoding.string_enum
      [
        ("ExtendLowS", ExtendLowS);
        ("ExtendLowU", ExtendLowU);
        ("ExtendHighS", ExtendHighS);
        ("ExtendHighU", ExtendHighU);
        ("ExtAddPairwiseS", ExtAddPairwiseS);
        ("ExtAddPairwiseU", ExtAddPairwiseU);
        ("TruncSatSF32x4", TruncSatSF32x4);
        ("TruncSatUF32x4", TruncSatUF32x4);
        ("TruncSatSZeroF64x2", TruncSatSZeroF64x2);
        ("TruncSatUZeroF64x2", TruncSatUZeroF64x2);
      ]

  let fcvtop_encoding =
    Data_encoding.string_enum
      [
        ("DemoteZeroF64x2", DemoteZeroF64x2);
        ("PromoteLowF32x4", PromoteLowF32x4);
        ("ConvertSI32x4", ConvertSI32x4);
        ("ConvertUI32x4", ConvertUI32x4);
      ]

  let ishiftop_encoding =
    Data_encoding.string_enum [("Shl", Shl); ("ShrS", ShrS); ("ShrU", ShrU)]

  let ibitmaskop_encoding =
    Data_encoding.(
      conv (fun Bitmask -> ()) (fun () -> Bitmask) (constant "Bitmask"))

  let vtestop_encoding =
    Data_encoding.(
      conv (fun AnyTrue -> ()) (fun () -> AnyTrue) (constant "AnyTrue"))

  let vunop_encoding =
    Data_encoding.(conv (fun Not -> ()) (fun () -> Not) (constant "Not"))

  let vbinop_encoding =
    Data_encoding.string_enum
      [("And", And); ("Or", Or); ("Xor", Xor); ("AndNot", AndNot)]

  let vternop_encoding =
    Data_encoding.(
      conv (fun Bitselect -> ()) (fun () -> Bitselect) (constant "Bitselect"))

  let void_encoding : void Data_encoding.t =
    Data_encoding.(
      conv
        (function (_ : void) -> .)
        (fun () ->
          failwith "void_encoding"
          (* the void type cannot be instantiated and is used to fill an
             impossible case in the AST, this shouldn't happen. *))
        null)

  let testop_encoding =
    Values.V128.laneop_encoding
      itestop_encoding
      itestop_encoding
      itestop_encoding
      itestop_encoding
      void_encoding
      void_encoding

  let unop_encoding =
    Values.V128.laneop_encoding
      iunop_encoding
      iunop_encoding
      iunop_encoding
      iunop_encoding
      funop_encoding
      funop_encoding

  let binop_encoding =
    Values.V128.laneop_encoding
      ibinop_encoding
      ibinop_encoding
      ibinop_encoding
      ibinop_encoding
      fbinop_encoding
      fbinop_encoding

  let relop_encoding =
    Values.V128.laneop_encoding
      irelop_encoding
      irelop_encoding
      irelop_encoding
      irelop_encoding
      frelop_encoding
      frelop_encoding

  let cvtop_encoding =
    Values.V128.laneop_encoding
      icvtop_encoding
      icvtop_encoding
      icvtop_encoding
      icvtop_encoding
      fcvtop_encoding
      fcvtop_encoding

  let shiftop_encoding =
    Values.V128.laneop_encoding
      ishiftop_encoding
      ishiftop_encoding
      ishiftop_encoding
      ishiftop_encoding
      void_encoding
      void_encoding

  let bitmaskop_encoding =
    Values.V128.laneop_encoding
      ibitmaskop_encoding
      ibitmaskop_encoding
      ibitmaskop_encoding
      ibitmaskop_encoding
      void_encoding
      void_encoding

  let nsplatop_encoding =
    Data_encoding.(conv (fun Splat -> ()) (fun () -> Splat) (constant "Splat"))

  let nextractop_encoding v_encoding =
    Data_encoding.(
      conv
        (fun (Extract (i, v)) -> (i, v))
        (fun (i, v) -> Extract (i, v))
        (tup2 int31 v_encoding))

  let nreplaceop_encoding =
    Data_encoding.(conv (fun (Replace i) -> i) (fun i -> Replace i) int31)

  let splatop_encoding =
    Values.V128.laneop_encoding
      nsplatop_encoding
      nsplatop_encoding
      nsplatop_encoding
      nsplatop_encoding
      nsplatop_encoding
      nsplatop_encoding

  let extractop_encoding =
    Values.V128.laneop_encoding
      (nextractop_encoding Types.extension_encoding)
      (nextractop_encoding Types.extension_encoding)
      (nextractop_encoding Data_encoding.null)
      (nextractop_encoding Data_encoding.null)
      (nextractop_encoding Data_encoding.null)
      (nextractop_encoding Data_encoding.null)

  let replaceop_encoding =
    Values.V128.laneop_encoding
      nreplaceop_encoding
      nreplaceop_encoding
      nreplaceop_encoding
      nreplaceop_encoding
      nreplaceop_encoding
      nreplaceop_encoding
end

let testop_encoding =
  Values.op_encoding
    IntOp.testop_encoding
    IntOp.testop_encoding
    FloatOp.testop_encoding
    FloatOp.testop_encoding

let unop_encoding =
  Values.op_encoding
    IntOp.unop_encoding
    IntOp.unop_encoding
    FloatOp.unop_encoding
    FloatOp.unop_encoding

let binop_encoding =
  Values.op_encoding
    IntOp.binop_encoding
    IntOp.binop_encoding
    FloatOp.binop_encoding
    FloatOp.binop_encoding

let relop_encoding =
  Values.op_encoding
    IntOp.relop_encoding
    IntOp.relop_encoding
    FloatOp.relop_encoding
    FloatOp.relop_encoding

let cvtop_encoding =
  Values.op_encoding
    IntOp.cvtop_encoding
    IntOp.cvtop_encoding
    FloatOp.cvtop_encoding
    FloatOp.cvtop_encoding

let vec_testop_encoding = Values.vecop_encoding V128Op.testop_encoding

let vec_relop_encoding = Values.vecop_encoding V128Op.relop_encoding

let vec_unop_encoding = Values.vecop_encoding V128Op.unop_encoding

let vec_binop_encoding = Values.vecop_encoding V128Op.binop_encoding

let vec_cvtop_encoding = Values.vecop_encoding V128Op.cvtop_encoding

let vec_shiftop_encoding = Values.vecop_encoding V128Op.shiftop_encoding

let vec_bitmaskop_encoding = Values.vecop_encoding V128Op.bitmaskop_encoding

let vec_vtestop_encoding = Values.vecop_encoding V128Op.vtestop_encoding

let vec_vunop_encoding = Values.vecop_encoding V128Op.vunop_encoding

let vec_vbinop_encoding = Values.vecop_encoding V128Op.vbinop_encoding

let vec_vternop_encoding = Values.vecop_encoding V128Op.vternop_encoding

let vec_splatop_encoding = Values.vecop_encoding V128Op.splatop_encoding

let vec_extractop_encoding = Values.vecop_encoding V128Op.extractop_encoding

let vec_replaceop_encoding = Values.vecop_encoding V128Op.replaceop_encoding

let memop_encoding ty_encoding value_encoding =
  Data_encoding.(
    conv
      (fun {ty; align; offset; pack} -> (ty, align, offset, pack))
      (fun (ty, align, offset, pack) -> {ty; align; offset; pack})
      (obj4
         (req "ty" ty_encoding)
         (req "align" int31)
         (req "offset" int32)
         (req "pack" value_encoding)))

let loadop_encoding =
  Data_encoding.(
    memop_encoding
      Types.num_type_encoding
      (option (tup2 Types.pack_size_encoding Types.extension_encoding)))

let storeop_encoding =
  Data_encoding.(
    memop_encoding Types.num_type_encoding (option Types.pack_size_encoding))

let vec_loadop_encoding =
  Data_encoding.(
    memop_encoding
      Types.vec_type_encoding
      (option (tup2 Types.pack_size_encoding Types.vec_extension_encoding)))

let vec_storeop_encoding =
  memop_encoding Types.vec_type_encoding Data_encoding.null

let vec_laneop_encoding =
  Data_encoding.(
    tup2 (memop_encoding Types.vec_type_encoding Types.pack_size_encoding) int31)

(* Expressions *)

let pos_encoding =
  Data_encoding.(
    conv
      (fun {Source.file; line; column} -> (file, line, column))
      (fun (file, line, column) -> {file; line; column})
      (obj3 (req "file" string) (req "line" int31) (req "column" int31)))

let region_encoding =
  Data_encoding.(
    conv
      (fun {Source.left; right} -> (left, right))
      (fun (left, right) -> {left; right})
      (obj2 (req "left" pos_encoding) (req "right" pos_encoding)))

let full_phrase_encoding value_encoding =
  Data_encoding.(
    conv
      (fun {Source.at; it} -> (at, it))
      (fun (at, it) -> {at; it})
      (obj2 (req "at" region_encoding) (req "it" value_encoding)))

let phrase_encoding value_encoding =
  Data_encoding.(
    conv
      (fun {Source.it; _} -> it)
      (fun it -> {at = Source.no_region; it})
      value_encoding)

let var_encoding = phrase_encoding Data_encoding.int32

let num_encoding = phrase_encoding Values.num_encoding

let vec_encoding = phrase_encoding Values.vec_encoding

let name_encoding = Data_encoding.(list int31)

let block_type_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"VarBlockType"
        (Tag 0)
        var_encoding
        (function VarBlockType v -> Some v | _ -> None)
        (fun v -> VarBlockType v);
      case
        ~title:"ValBlockType"
        (Tag 1)
        (Data_encoding.option Types.value_type_encoding)
        (function ValBlockType v -> Some v | _ -> None)
        (fun v -> ValBlockType v);
    ]

let instr_encoding' =
  let open Data_encoding in
  mu "instr" @@ fun instr_encoding' ->
  let instr_encoding = phrase_encoding instr_encoding' in
  union
    [
      case
        ~title:"Unreachable"
        (Tag 0)
        (constant "Unreachable")
        (function Unreachable -> Some () | _ -> None)
        (fun () -> Unreachable);
      case
        ~title:"Nop"
        (Tag 1)
        (constant "Nop")
        (function Nop -> Some () | _ -> None)
        (fun () -> Nop);
      case
        ~title:"Drop"
        (Tag 2)
        (constant "Drop")
        (function Drop -> Some () | _ -> None)
        (fun () -> Drop);
      case
        ~title:"Select"
        (Tag 3)
        (option (list Types.value_type_encoding))
        (function Select l -> Some l | _ -> None)
        (fun l -> Select l);
      case
        ~title:"Block"
        (Tag 4)
        (obj1 (req "Block" (tup2 block_type_encoding (list instr_encoding))))
        (function Block (bt, il) -> Some (bt, il) | _ -> None)
        (fun (bt, il) -> Block (bt, il));
      case
        ~title:"Loop"
        (Tag 5)
        (obj1 (req "Loop" (tup2 block_type_encoding (list instr_encoding))))
        (function Loop (bt, il) -> Some (bt, il) | _ -> None)
        (fun (bt, il) -> Loop (bt, il));
      case
        ~title:"If"
        (Tag 6)
        (obj1
           (req
              "If"
              (tup3
                 block_type_encoding
                 (list instr_encoding)
                 (list instr_encoding))))
        (function If (bt, il, il') -> Some (bt, il, il') | _ -> None)
        (fun (bt, il, il') -> If (bt, il, il'));
      case
        ~title:"Br"
        (Tag 7)
        (obj1 (req "Br" var_encoding))
        (function Br v -> Some v | _ -> None)
        (fun v -> Br v);
      case
        ~title:"BrIf"
        (Tag 8)
        (obj1 (req "BrIf" var_encoding))
        (function BrIf v -> Some v | _ -> None)
        (fun v -> BrIf v);
      case
        ~title:"BrTable"
        (Tag 9)
        (obj1 (req "BrTable" (tup2 (list var_encoding) var_encoding)))
        (function BrTable (vs, v) -> Some (vs, v) | _ -> None)
        (fun (vs, v) -> BrTable (vs, v));
      case
        ~title:"Return"
        (Tag 10)
        (constant "Return")
        (function Return -> Some () | _ -> None)
        (fun () -> Return);
      case
        ~title:"Call"
        (Tag 11)
        (obj1 (req "Call" var_encoding))
        (function Call v -> Some v | _ -> None)
        (fun v -> Call v);
      case
        ~title:"CallIndirect"
        (Tag 12)
        (obj1 (req "CallIndirect" (tup2 var_encoding var_encoding)))
        (function CallIndirect (v, v') -> Some (v, v') | _ -> None)
        (fun (v, v') -> CallIndirect (v, v'));
      case
        ~title:"LocalGet"
        (Tag 13)
        (obj1 (req "LocalGet" var_encoding))
        (function LocalGet v -> Some v | _ -> None)
        (fun v -> LocalGet v);
      case
        ~title:"LocalSet"
        (Tag 14)
        (obj1 (req "LocalSet" var_encoding))
        (function LocalSet v -> Some v | _ -> None)
        (fun v -> LocalSet v);
      case
        ~title:"LocalTee"
        (Tag 15)
        (obj1 (req "LocalTee" var_encoding))
        (function LocalTee v -> Some v | _ -> None)
        (fun v -> LocalTee v);
      case
        ~title:"GlobalGet"
        (Tag 16)
        (obj1 (req "GlobalGet" var_encoding))
        (function GlobalGet v -> Some v | _ -> None)
        (fun v -> GlobalGet v);
      case
        ~title:"GlobalSet"
        (Tag 17)
        (obj1 (req "GlobalSet" var_encoding))
        (function GlobalSet v -> Some v | _ -> None)
        (fun v -> GlobalSet v);
      case
        ~title:"TableGet"
        (Tag 18)
        (obj1 (req "TableGet" var_encoding))
        (function TableGet v -> Some v | _ -> None)
        (fun v -> TableGet v);
      case
        ~title:"TableSet"
        (Tag 19)
        (obj1 (req "TableSet" var_encoding))
        (function TableSet v -> Some v | _ -> None)
        (fun v -> TableSet v);
      case
        ~title:"TableSize"
        (Tag 20)
        (obj1 (req "TableSize" var_encoding))
        (function TableSize v -> Some v | _ -> None)
        (fun v -> TableSize v);
      case
        ~title:"TableGrow"
        (Tag 21)
        (obj1 (req "TableGrow" var_encoding))
        (function TableGrow v -> Some v | _ -> None)
        (fun v -> TableGrow v);
      case
        ~title:"TableFill"
        (Tag 22)
        (obj1 (req "TableFill" var_encoding))
        (function TableFill v -> Some v | _ -> None)
        (fun v -> TableFill v);
      case
        ~title:"TableCopy"
        (Tag 23)
        (obj1 (req "TableCopy" (tup2 var_encoding var_encoding)))
        (function TableCopy (v, v') -> Some (v, v') | _ -> None)
        (fun (v, v') -> CallIndirect (v, v'));
      case
        ~title:"TableInit"
        (Tag 24)
        (obj1 (req "TableInit" (tup2 var_encoding var_encoding)))
        (function TableInit (v, v') -> Some (v, v') | _ -> None)
        (fun (v, v') -> TableInit (v, v'));
      case
        ~title:"ElemDrop"
        (Tag 25)
        (obj1 (req "ElemDrop" var_encoding))
        (function ElemDrop v -> Some v | _ -> None)
        (fun v -> ElemDrop v);
      case
        ~title:"Load"
        (Tag 26)
        (obj1 (req "Load" loadop_encoding))
        (function Load v -> Some v | _ -> None)
        (fun v -> Load v);
      case
        ~title:"Store"
        (Tag 27)
        (obj1 (req "Store" storeop_encoding))
        (function Store v -> Some v | _ -> None)
        (fun v -> Store v);
      case
        ~title:"VecLoad"
        (Tag 28)
        (obj1 (req "VecLoad" vec_loadop_encoding))
        (function VecLoad v -> Some v | _ -> None)
        (fun v -> VecLoad v);
      case
        ~title:"VecStore"
        (Tag 29)
        (obj1 (req "VecStore" vec_storeop_encoding))
        (function VecStore v -> Some v | _ -> None)
        (fun v -> VecStore v);
      case
        ~title:"VecLoadLane"
        (Tag 30)
        (obj1 (req "VecLoadLane" vec_laneop_encoding))
        (function VecLoadLane v -> Some v | _ -> None)
        (fun v -> VecLoadLane v);
      case
        ~title:"VecStoreLane"
        (Tag 31)
        (obj1 (req "VecStoreLane" vec_laneop_encoding))
        (function VecStoreLane v -> Some v | _ -> None)
        (fun v -> VecStoreLane v);
      case
        ~title:"MemorySize"
        (Tag 32)
        (obj1 (req "MemorySize" (constant "MemorySize")))
        (function MemorySize -> Some () | _ -> None)
        (fun () -> MemorySize);
      case
        ~title:"MemoryGrow"
        (Tag 33)
        (obj1 (req "MemoryGrow" (constant "MemoryGrow")))
        (function MemoryGrow -> Some () | _ -> None)
        (fun () -> MemoryGrow);
      case
        ~title:"MemoryFill"
        (Tag 34)
        (obj1 (req "MemoryFill" (constant "MemoryFill")))
        (function MemoryFill -> Some () | _ -> None)
        (fun () -> MemoryFill);
      case
        ~title:"MemoryCopy"
        (Tag 35)
        (obj1 (req "MemoryCopy" (constant "MemoryCopy")))
        (function MemoryCopy -> Some () | _ -> None)
        (fun () -> MemoryCopy);
      case
        ~title:"MemoryInit"
        (Tag 36)
        (obj1 (req "MemoryInit" var_encoding))
        (function MemoryInit v -> Some v | _ -> None)
        (fun v -> MemoryInit v);
      case
        ~title:"DataDrop"
        (Tag 37)
        (obj1 (req "DataDrop" var_encoding))
        (function DataDrop v -> Some v | _ -> None)
        (fun v -> DataDrop v);
      case
        ~title:"RefNull"
        (Tag 38)
        (obj1 (req "RefNull" Types.ref_type_encoding))
        (function RefNull r -> Some r | _ -> None)
        (fun r -> RefNull r);
      case
        ~title:"RefFunc"
        (Tag 39)
        (obj1 (req "RefFunc" var_encoding))
        (function RefFunc r -> Some r | _ -> None)
        (fun r -> RefFunc r);
      case
        ~title:"RefIsNull"
        (Tag 40)
        (obj1 (req "RefIsNull" (constant "RefIsNull")))
        (function RefIsNull -> Some () | _ -> None)
        (fun () -> RefIsNull);
      case
        ~title:"Const"
        (Tag 41)
        (obj1 (req "Const" num_encoding))
        (function Const n -> Some n | _ -> None)
        (fun n -> Const n);
      case
        ~title:"Test"
        (Tag 42)
        (obj1 (req "Test" testop_encoding))
        (function Test t -> Some t | _ -> None)
        (fun t -> Test t);
      case
        ~title:"Compare"
        (Tag 43)
        (obj1 (req "Compare" relop_encoding))
        (function Compare t -> Some t | _ -> None)
        (fun t -> Compare t);
      case
        ~title:"Unary"
        (Tag 44)
        (obj1 (req "Unary" unop_encoding))
        (function Unary o -> Some o | _ -> None)
        (fun o -> Unary o);
      case
        ~title:"Binary"
        (Tag 45)
        (obj1 (req "Binary" binop_encoding))
        (function Binary o -> Some o | _ -> None)
        (fun o -> Binary o);
      case
        ~title:"Convert"
        (Tag 46)
        (obj1 (req "Convert" cvtop_encoding))
        (function Convert t -> Some t | _ -> None)
        (fun t -> Convert t);
      case
        ~title:"VecConst"
        (Tag 47)
        (obj1 (req "VecConst" vec_encoding))
        (function VecConst t -> Some t | _ -> None)
        (fun t -> VecConst t);
      case
        ~title:"VecTest"
        (Tag 48)
        (obj1 (req "VecTest" vec_testop_encoding))
        (function VecTest t -> Some t | _ -> None)
        (fun t -> VecTest t);
      case
        ~title:"VecCompare"
        (Tag 49)
        (obj1 (req "VecCompare" vec_relop_encoding))
        (function VecCompare t -> Some t | _ -> None)
        (fun t -> VecCompare t);
      case
        ~title:"VecUnary"
        (Tag 50)
        (obj1 (req "VecUnary" vec_unop_encoding))
        (function VecUnary t -> Some t | _ -> None)
        (fun t -> VecUnary t);
      case
        ~title:"VecBinary"
        (Tag 51)
        (obj1 (req "VecBinary" vec_binop_encoding))
        (function VecBinary t -> Some t | _ -> None)
        (fun t -> VecBinary t);
      case
        ~title:"VecConvert"
        (Tag 52)
        (obj1 (req "VecConvert" vec_cvtop_encoding))
        (function VecConvert t -> Some t | _ -> None)
        (fun t -> VecConvert t);
      case
        ~title:"VecShift"
        (Tag 53)
        (obj1 (req "VecShift" vec_shiftop_encoding))
        (function VecShift t -> Some t | _ -> None)
        (fun t -> VecShift t);
      case
        ~title:"VecBitmask"
        (Tag 54)
        (obj1 (req "VecBitmask" vec_bitmaskop_encoding))
        (function VecBitmask t -> Some t | _ -> None)
        (fun t -> VecBitmask t);
      case
        ~title:"VecTestBits"
        (Tag 55)
        (obj1 (req "VecTestBits" vec_vtestop_encoding))
        (function VecTestBits t -> Some t | _ -> None)
        (fun t -> VecTestBits t);
      case
        ~title:"VecUnaryBits"
        (Tag 56)
        (obj1 (req "VecUnaryBits" vec_vunop_encoding))
        (function VecUnaryBits t -> Some t | _ -> None)
        (fun t -> VecUnaryBits t);
      case
        ~title:"VecBinaryBits"
        (Tag 57)
        (obj1 (req "VecBinaryBits" vec_vbinop_encoding))
        (function VecBinaryBits t -> Some t | _ -> None)
        (fun t -> VecBinaryBits t);
      case
        ~title:"VecTernaryBits"
        (Tag 58)
        (obj1 (req "VecTernaryBits" vec_vternop_encoding))
        (function VecTernaryBits t -> Some t | _ -> None)
        (fun t -> VecTernaryBits t);
      case
        ~title:"VecSplat"
        (Tag 59)
        (obj1 (req "VecSplat" vec_splatop_encoding))
        (function VecSplat t -> Some t | _ -> None)
        (fun t -> VecSplat t);
      case
        ~title:"VecExtract"
        (Tag 60)
        (obj1 (req "VecExtract" vec_extractop_encoding))
        (function VecExtract t -> Some t | _ -> None)
        (fun t -> VecExtract t);
      case
        ~title:"VecReplace"
        (Tag 61)
        (obj1 (req "VecReplace" vec_replaceop_encoding))
        (function VecReplace t -> Some t | _ -> None)
        (fun t -> VecReplace t);
    ]

let instr_encoding = phrase_encoding instr_encoding'

let const_encoding = phrase_encoding (Data_encoding.list instr_encoding)

let global_encoding' =
  Data_encoding.(
    conv
      (fun {gtype; ginit} -> (gtype, ginit))
      (fun (gtype, ginit) -> {gtype; ginit})
      (obj2
         (req "gtype" Types.global_type_encoding)
         (req "ginit" const_encoding)))

let global_encoding = phrase_encoding global_encoding'

let func_encoding' =
  Data_encoding.(
    conv
      (fun {ftype; locals; body} -> (ftype, locals, body))
      (fun (ftype, locals, body) -> {ftype; locals; body})
      (obj3
         (req "ftype" var_encoding)
         (req "locals" (list Types.value_type_encoding))
         (req "body" (list instr_encoding))))

let func_encoding = phrase_encoding func_encoding'

let table_encoding' =
  Data_encoding.(
    conv (fun {ttype} -> ttype) (fun ttype -> {ttype}) Types.table_type_encoding)

let table_encoding = phrase_encoding table_encoding'

let memory_encoding' =
  Data_encoding.conv
    (fun {mtype} -> mtype)
    (fun mtype -> {mtype})
    Types.memory_type_encoding

let memory_encoding = phrase_encoding memory_encoding'

let segment_mode_encoding' =
  let open Data_encoding in
  union
    [
      case
        ~title:"Passive"
        (Tag 0)
        (constant "Passive")
        (function Passive -> Some () | _ -> None)
        (fun () -> Passive);
      case
        ~title:"Active"
        (Tag 1)
        (obj1
           (req
              "Active"
              (obj2 (req "index" var_encoding) (req "offset" const_encoding))))
        (function Active {index; offset} -> Some (index, offset) | _ -> None)
        (fun (index, offset) -> Active {index; offset});
      case
        ~title:"Declarative"
        (Tag 2)
        (constant "Declarative")
        (function Declarative -> Some () | _ -> None)
        (fun () -> Declarative);
    ]

let segment_mode_encoding = phrase_encoding segment_mode_encoding'

let elem_segment_encoding' =
  Data_encoding.(
    conv
      (fun {etype; einit; emode} -> (etype, einit, emode))
      (fun (etype, einit, emode) -> {etype; einit; emode})
      (obj3
         (req "etype" Types.ref_type_encoding)
         (req "einit" (list const_encoding))
         (req "emode" segment_mode_encoding)))

let elem_segment_encoding = phrase_encoding elem_segment_encoding'

(* TODO *)
let chunked_byte_vector_encoding : Chunked_byte_vector.Buffer.t Data_encoding.t
    =
  Data_encoding.(conv (fun _ -> assert false) (fun _ -> assert false) null)

let data_segment_encoding' =
  Data_encoding.(
    conv
      (fun {dinit; dmode} -> (dinit, dmode))
      (fun (dinit, dmode) -> {dinit; dmode})
      (obj2
         (req "dinit" chunked_byte_vector_encoding)
         (req "dmode" segment_mode_encoding)))

let data_segment_encoding = phrase_encoding data_segment_encoding'

let export_desc_encoding' =
  let open Data_encoding in
  union
    [
      case
        ~title:"FuncExport"
        (Tag 0)
        (obj1 (req "FuncExport" var_encoding))
        (function FuncExport v -> Some v | _ -> None)
        (fun v -> FuncExport v);
      case
        ~title:"TableExport"
        (Tag 1)
        (obj1 (req "TableExport" var_encoding))
        (function TableExport v -> Some v | _ -> None)
        (fun v -> TableExport v);
      case
        ~title:"MemoryExport"
        (Tag 2)
        (obj1 (req "MemoryExport" var_encoding))
        (function MemoryExport v -> Some v | _ -> None)
        (fun v -> MemoryExport v);
      case
        ~title:"GlobalExport"
        (Tag 3)
        (obj1 (req "GlobalExport" var_encoding))
        (function GlobalExport v -> Some v | _ -> None)
        (fun v -> GlobalExport v);
    ]

let export_desc_encoding = phrase_encoding export_desc_encoding'

let export_encoding' =
  Data_encoding.(
    conv
      (fun {name; edesc} -> (name, edesc))
      (fun (name, edesc) -> {name; edesc})
      (obj2 (req "name" name_encoding) (req "edesc" export_desc_encoding)))

let export_encoding = phrase_encoding export_encoding'

let import_desc_encoding' =
  let open Data_encoding in
  union
    [
      case
        ~title:"FuncImport"
        (Tag 0)
        (obj1 (req "FuncImport" var_encoding))
        (function FuncImport v -> Some v | _ -> None)
        (fun v -> FuncImport v);
      case
        ~title:"TableImport"
        (Tag 1)
        (obj1 (req "TableImport" Types.table_type_encoding))
        (function TableImport v -> Some v | _ -> None)
        (fun v -> TableImport v);
      case
        ~title:"MemoryImport"
        (Tag 2)
        (obj1 (req "MemoryImport" Types.memory_type_encoding))
        (function MemoryImport v -> Some v | _ -> None)
        (fun v -> MemoryImport v);
      case
        ~title:"GlobalImport"
        (Tag 3)
        (obj1 (req "GlobalImport" Types.global_type_encoding))
        (function GlobalImport v -> Some v | _ -> None)
        (fun v -> GlobalImport v);
    ]

let import_desc_encoding = phrase_encoding import_desc_encoding'

let import_encoding' =
  Data_encoding.(
    conv
      (fun {module_name; item_name; idesc} -> (module_name, item_name, idesc))
      (fun (module_name, item_name, idesc) -> {module_name; item_name; idesc})
      (obj3
         (req "module_name" name_encoding)
         (req "item_name" name_encoding)
         (req "idesc" import_desc_encoding)))

let import_encoding = phrase_encoding import_encoding'

let start_encoding' =
  Data_encoding.(
    conv
      (fun {sfunc} -> sfunc)
      (fun sfunc -> {sfunc})
      (obj1 (req "sfunc" var_encoding)))

let start_encoding = phrase_encoding start_encoding'

let type_encoding = phrase_encoding Types.func_type_encoding

let lazy_vector_encoding _value_encoding =
  Data_encoding.(
    conv
      (fun _ -> failwith "lazy_vector encoder placeholder")
      (fun _ -> failwith "lazy_vector decoder placeholder")
      unit)

let module_encoding' =
  Data_encoding.(
    conv
      (fun {
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
           } ->
        ( types,
          globals,
          tables,
          memories,
          funcs,
          start,
          elems,
          datas,
          imports,
          exports ))
      (fun ( types,
             globals,
             tables,
             memories,
             funcs,
             start,
             elems,
             datas,
             imports,
             exports ) ->
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
        })
      (obj10
         (req "types" (lazy_vector_encoding type_encoding))
         (req "globals" (lazy_vector_encoding global_encoding))
         (req "tables" (lazy_vector_encoding table_encoding))
         (req "memories" (lazy_vector_encoding memory_encoding))
         (req "funcs" (lazy_vector_encoding func_encoding))
         (req "start" (option start_encoding))
         (req "elems" (lazy_vector_encoding elem_segment_encoding))
         (req "datas" (lazy_vector_encoding data_segment_encoding))
         (req "imports" (lazy_vector_encoding import_encoding))
         (req "exports" (lazy_vector_encoding export_encoding))))
