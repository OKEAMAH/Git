open Tezos_webassembly_interpreter.Decode

(** The encoding of the types currently using a [list] will have to be
    replaced with tree decoder and encoders. *)

(* Useful to encode part of a GADT *)
type ('a, 'b) eq = Eq_refl : ('a, 'a) eq | Neq : ('a, 'b) eq

let section_tag : section_tag Data_encoding.t =
  let open Data_encoding in
  union
    [
      case
        ~title:"code_section"
        (Tag 0)
        (constant "code_section")
        (function `CodeSection -> Some () | _ -> None)
        (fun () -> `CodeSection);
      case
        ~title:"custom_section"
        (Tag 1)
        (constant "custom_section")
        (function `CustomSection -> Some () | _ -> None)
        (fun () -> `CustomSection);
      case
        ~title:"data_count_section"
        (Tag 2)
        (constant "data_count_section")
        (function `DataCountSection -> Some () | _ -> None)
        (fun () -> `DataCountSection);
      case
        ~title:"data_section"
        (Tag 3)
        (constant "data_section")
        (function `DataSection -> Some () | _ -> None)
        (fun () -> `DataSection);
      case
        ~title:"elem_section"
        (Tag 4)
        (constant "elem_section")
        (function `ElemSection -> Some () | _ -> None)
        (fun () -> `ElemSection);
      case
        ~title:"export_section"
        (Tag 5)
        (constant "export_section")
        (function `ExportSection -> Some () | _ -> None)
        (fun () -> `ExportSection);
      case
        ~title:"func_section"
        (Tag 6)
        (constant "func_section")
        (function `FuncSection -> Some () | _ -> None)
        (fun () -> `FuncSection);
      case
        ~title:"global_section"
        (Tag 7)
        (constant "global_section")
        (function `GlobalSection -> Some () | _ -> None)
        (fun () -> `GlobalSection);
      case
        ~title:"import_section"
        (Tag 8)
        (constant "import_section")
        (function `ImportSection -> Some () | _ -> None)
        (fun () -> `ImportSection);
      case
        ~title:"memory_section"
        (Tag 9)
        (constant "memory_section")
        (function `MemorySection -> Some () | _ -> None)
        (fun () -> `MemorySection);
      case
        ~title:"start_section"
        (Tag 10)
        (constant "start_section")
        (function `StartSection -> Some () | _ -> None)
        (fun () -> `StartSection);
      case
        ~title:"table_section"
        (Tag 11)
        (constant "table_section")
        (function `TableSection -> Some () | _ -> None)
        (fun () -> `TableSection);
      case
        ~title:"type_section"
        (Tag 12)
        (constant "type_section")
        (function `TypeSection -> Some () | _ -> None)
        (fun () -> `TypeSection);
    ]

type packed_field_type = Packed : 'a field_type -> packed_field_type

let packed_field_type : packed_field_type Data_encoding.t =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"type_field"
        (constant "type_field")
        (function Packed TypeField -> Some () | _ -> None)
        (fun () -> Packed TypeField);
      case
        (Tag 1)
        ~title:"import_field"
        (constant "import_field")
        (function Packed ImportField -> Some () | _ -> None)
        (fun () -> Packed ImportField);
      case
        (Tag 2)
        ~title:"func_field"
        (constant "func_field")
        (function Packed FuncField -> Some () | _ -> None)
        (fun () -> Packed FuncField);
      case
        (Tag 3)
        ~title:"table_field"
        (constant "table_field")
        (function Packed TableField -> Some () | _ -> None)
        (fun () -> Packed TableField);
      case
        (Tag 4)
        ~title:"memory_field"
        (constant "memory_field")
        (function Packed MemoryField -> Some () | _ -> None)
        (fun () -> Packed MemoryField);
      case
        (Tag 5)
        ~title:"global_field"
        (constant "global_field")
        (function Packed GlobalField -> Some () | _ -> None)
        (fun () -> Packed GlobalField);
      case
        (Tag 6)
        ~title:"export_field"
        (constant "export_field")
        (function Packed ExportField -> Some () | _ -> None)
        (fun () -> Packed ExportField);
      case
        (Tag 7)
        ~title:"start_field"
        (constant "start_field")
        (function Packed StartField -> Some () | _ -> None)
        (fun () -> Packed StartField);
      case
        (Tag 8)
        ~title:"start_field"
        (constant "start_field")
        (function Packed StartField -> Some () | _ -> None)
        (fun () -> Packed StartField);
      case
        (Tag 9)
        ~title:"elem_field"
        (constant "elem_field")
        (function Packed ElemField -> Some () | _ -> None)
        (fun () -> Packed ElemField);
      case
        (Tag 10)
        ~title:"data_count_field"
        (constant "data_count_field")
        (function Packed DataCountField -> Some () | _ -> None)
        (fun () -> Packed DataCountField);
      case
        (Tag 11)
        ~title:"code_field"
        (constant "code_field")
        (function Packed CodeField -> Some () | _ -> None)
        (fun () -> Packed CodeField);
      case
        (Tag 12)
        ~title:"data_field"
        (constant "data_field")
        (function Packed DataField -> Some () | _ -> None)
        (fun () -> Packed DataField);
    ]

let title_for_field_type : type a. a field_type -> string = function
  | TypeField -> "type_field"
  | ImportField -> "import_field"
  | FuncField -> "func_field"
  | TableField -> "table_field"
  | MemoryField -> "memory_field"
  | GlobalField -> "global_field"
  | ExportField -> "export_field"
  | StartField -> "start_field"
  | ElemField -> "elem_field"
  | DataCountField -> "data_count_field"
  | CodeField -> "code_field"
  | DataField -> "data_field"

let encoding_for_field_type : type a. a field_type -> a Data_encoding.t =
  function
  | TypeField -> Ast_encoding.type_encoding
  | ImportField -> Ast_encoding.import_encoding
  | FuncField -> Ast_encoding.var_encoding
  | TableField -> Ast_encoding.table_encoding
  | MemoryField -> Ast_encoding.memory_encoding
  | GlobalField -> Ast_encoding.global_encoding
  | ExportField -> Ast_encoding.export_encoding
  | StartField -> Ast_encoding.start_encoding
  | ElemField -> Ast_encoding.elem_segment_encoding
  | DataCountField -> Data_encoding.int32
  | CodeField -> Ast_encoding.func_encoding
  | DataField -> Ast_encoding.data_segment_encoding

let field_type_eq : type a b. a field_type -> b field_type -> (a, b) eq =
 fun f1 f2 ->
  match (f1, f2) with
  | TypeField, TypeField -> Eq_refl
  | ImportField, ImportField -> Eq_refl
  | FuncField, FuncField -> Eq_refl
  | TableField, TableField -> Eq_refl
  | MemoryField, MemoryField -> Eq_refl
  | GlobalField, GlobalField -> Eq_refl
  | ExportField, ExportField -> Eq_refl
  | StartField, StartField -> Eq_refl
  | ElemField, ElemField -> Eq_refl
  | DataCountField, DataCountField -> Eq_refl
  | CodeField, CodeField -> Eq_refl
  | DataField, DataField -> Eq_refl
  | _ -> Neq

let cases_for_field_type :
    type a. int -> a field_type -> field Data_encoding.case list =
 fun tag field ->
  let open Data_encoding in
  [
    (let title = "vec_" ^ title_for_field_type field in
     case
       ~title
       (Tag (2 * tag))
       (obj3
          (req "kind" (constant title))
          (req "values" (list @@ encoding_for_field_type field))
          (req "len" int31))
       (fun f ->
         match f with
         | VecField (field', l, i) -> (
             match field_type_eq field field' with
             | Eq_refl -> Some ((), l, i)
             | Neq -> None)
         | _ -> None)
       (fun ((), l, i) -> VecField (field, l, i)));
    (let title = "single_" ^ title_for_field_type field in
     case
       ~title
       (Tag ((2 * tag) + 1))
       (obj2
          (req "kind" (constant title))
          (req "value" (option @@ encoding_for_field_type field)))
       (fun f ->
         match f with
         | SingleField (field', o) -> (
             match field_type_eq field field' with
             | Eq_refl -> Some ((), o)
             | Neq -> None)
         | _ -> None)
       (fun ((), o) -> SingleField (field, o)));
  ]

let field : field Data_encoding.t =
  let open Data_encoding in
  union
  @@ List.concat
       [
         cases_for_field_type 0 TypeField;
         cases_for_field_type 1 ImportField;
         cases_for_field_type 2 FuncField;
         cases_for_field_type 3 TableField;
         cases_for_field_type 4 MemoryField;
         cases_for_field_type 5 GlobalField;
         cases_for_field_type 6 ExportField;
         cases_for_field_type 7 StartField;
         cases_for_field_type 8 ElemField;
         cases_for_field_type 9 DataCountField;
         cases_for_field_type 10 CodeField;
         cases_for_field_type 11 DataField;
       ]

let vec_map_kont :
    'a Data_encoding.t ->
    'b Data_encoding.t ->
    ('a, 'b) vec_map_kont Data_encoding.t =
 fun in_encoding out_encoding ->
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"collect"
        (obj2 (req "index" int31) (req "input" @@ list in_encoding))
        (function Collect (i, l) -> Some (i, l) | _ -> None)
        (fun (i, l) -> Collect (i, l));
      case
        (Tag 1)
        ~title:"rev"
        (obj3
           (req "input" @@ list in_encoding)
           (req "output" @@ list out_encoding)
           (req "index" int31))
        (function Rev (i, o, x) -> Some (i, o, x) | _ -> None)
        (fun (i, o, x) -> Rev (i, o, x));
    ]

let vec_kont : 'a Data_encoding.t -> 'a vec_kont Data_encoding.t =
 fun encoding -> vec_map_kont encoding encoding

let pos = Data_encoding.int31

let size =
  Data_encoding.(
    conv
      (fun {size; start} -> (size, start))
      (fun (size, start) -> {size; start})
      (obj2 (req "size" int31) (req "start" pos)))

let name_step =
  let open Data_encoding in
  union
    [
      case
        ~title:"NKStart"
        (Tag 0)
        (obj1 (req "kind" @@ constant "NKStart"))
        (function NKStart -> Some () | _ -> None)
        (fun () -> NKStart);
      case
        ~title:"MKParse"
        (Tag 1)
        (obj3
           (req "kind" @@ constant "MKParse")
           (req "pos" pos)
           (req "vec" @@ vec_kont int31))
        (function NKParse (pos, vec) -> Some ((), pos, vec) | _ -> None)
        (fun ((), pos, vec) -> NKParse (pos, vec));
      case
        ~title:"NKStop"
        (Tag 2)
        (obj2 (req "kind" @@ constant "NKStop") (req "result" @@ list int31))
        (function NKStop res -> Some ((), res) | _ -> None)
        (fun ((), res) -> NKStop res);
    ]

let utf8 = Data_encoding.(list int31)

let import_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"ImpKStart"
        (obj1 (req "kind" @@ constant "ImpKStart"))
        (function ImpKStart -> Some () | _ -> None)
        (fun () -> ImpKStart);
      case
        (Tag 1)
        ~title:"ImpKModuleName"
        (obj2
           (req "kind" @@ constant "ImpKModuleName")
           (req "name_step" name_step))
        (function ImpKModuleName step -> Some ((), step) | _ -> None)
        (fun ((), step) -> ImpKModuleName step);
      case
        (Tag 2)
        ~title:"ImpKItemName"
        (obj3
           (req "kind" @@ constant "ImpKItemName")
           (req "utf8" utf8)
           (req "name_step" name_step))
        (function
          | ImpKItemName (utf8, name_step) -> Some ((), utf8, name_step)
          | _ -> None)
        (fun ((), utf8, name_step) -> ImpKItemName (utf8, name_step));
      case
        (Tag 3)
        ~title:"ImpKStop"
        (obj2
           (req "kind" @@ constant "ImpKStop")
           (req "res" Ast_encoding.import_encoding'))
        (function ImpKStop res -> Some ((), res) | _ -> None)
        (fun ((), res) -> ImpKStop res);
    ]

let export_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"ExpKStart"
        (obj1 (req "kind" @@ constant "ExpKStart"))
        (function ExpKStart -> Some () | _ -> None)
        (fun () -> ExpKStart);
      case
        (Tag 1)
        ~title:"ExpKName"
        (obj2 (req "kind" @@ constant "ExpKName") (req "name_step" name_step))
        (function ExpKName name_step -> Some ((), name_step) | _ -> None)
        (fun ((), name_step) -> ExpKName name_step);
      case
        (Tag 2)
        ~title:"ExpKStop"
        (obj2
           (req "kind" @@ constant "ExpKStop")
           (req "export" Ast_encoding.export_encoding'))
        (function ExpKStop export -> Some ((), export) | _ -> None)
        (fun ((), export) -> ExpKStop export);
    ]

let instr_block_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"IKStop"
        (obj2
           (req "kind" @@ constant "IKStop")
           (req "result" @@ list Ast_encoding.instr_encoding))
        (function IKStop res -> Some ((), res) | _ -> None)
        (fun ((), res) -> IKStop res);
      case
        (Tag 1)
        ~title:"IKRev"
        (obj3
           (req "kind" @@ constant "IKRev")
           (req "input" @@ list Ast_encoding.instr_encoding)
           (req "output" @@ list Ast_encoding.instr_encoding))
        (function
          | IKRev (input, output) -> Some ((), input, output) | _ -> None)
        (fun ((), input, output) -> IKRev (input, output));
      case
        (Tag 2)
        ~title:"IKNext"
        (obj2
           (req "kind" @@ constant "IKNext")
           (req "accumulator" @@ list Ast_encoding.instr_encoding))
        (function IKNext res -> Some ((), res) | _ -> None)
        (fun ((), res) -> IKNext res);
      case
        (Tag 3)
        ~title:"IKBlock"
        (obj3
           (req "kind" @@ constant "IKBlock")
           (req "block_type" @@ Ast_encoding.block_type_encoding)
           (req "top" int31))
        (function
          | IKBlock (block_type, idx) -> Some ((), block_type, idx) | _ -> None)
        (fun ((), block_type, idx) -> IKBlock (block_type, idx));
      case
        (Tag 4)
        ~title:"IKLoop"
        (obj3
           (req "kind" @@ constant "IKLoop")
           (req "block_type" @@ Ast_encoding.block_type_encoding)
           (req "top" int31))
        (function
          | IKLoop (block_type, idx) -> Some ((), block_type, idx) | _ -> None)
        (fun ((), block_type, idx) -> IKLoop (block_type, idx));
      case
        (Tag 5)
        ~title:"IKIf1"
        (obj3
           (req "kind" @@ constant "IKIf1")
           (req "block_type" @@ Ast_encoding.block_type_encoding)
           (req "top" int31))
        (function
          | IKIf1 (block_type, idx) -> Some ((), block_type, idx) | _ -> None)
        (fun ((), block_type, idx) -> IKIf1 (block_type, idx));
      case
        (Tag 6)
        ~title:"IKIf2"
        (obj4
           (req "kind" @@ constant "IKIf2")
           (req "block_type" @@ Ast_encoding.block_type_encoding)
           (req "top" int31)
           (req "instructinos" @@ list Ast_encoding.instr_encoding))
        (function
          | IKIf2 (block_type, idx, instrs) -> Some ((), block_type, idx, instrs)
          | _ -> None)
        (fun ((), block_type, idx, instrs) -> IKIf2 (block_type, idx, instrs));
    ]

let index_kind =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"Indexed"
        (constant "indexed")
        (function Indexed -> Some () | _ -> None)
        (fun () -> Indexed);
      case
        (Tag 1)
        ~title:"Const"
        (constant "indexed")
        (function Const -> Some () | _ -> None)
        (fun () -> Const);
    ]

let elem_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"EKStart"
        (obj1 (req "kind" @@ constant "EKStart"))
        (function EKStart -> Some () | _ -> None)
        (fun () -> EKStart);
      case
        (Tag 1)
        ~title:"EKMode"
        (obj6
           (req "kind" @@ constant "EKMode")
           (req "left" pos)
           (req "index" @@ Ast_encoding.phrase_encoding int32)
           (req "index_kind" index_kind)
           (req "early_ref_type" @@ option Types_encoding.ref_type_encoding)
           (req "offset_kont" (tup2 pos (list instr_block_kont))))
        (function
          | EKMode {left; index; index_kind; early_ref_type; offset_kont} ->
              Some ((), left, index, index_kind, early_ref_type, offset_kont)
          | _ -> None)
        (fun ((), left, index, index_kind, early_ref_type, offset_kont) ->
          EKMode {left; index; index_kind; early_ref_type; offset_kont});
      case
        (Tag 2)
        ~title:"EKInitIndexed"
        (obj4
           (req "kind" @@ constant "EKInitIndexed")
           (req "mode" Ast_encoding.segment_mode_encoding)
           (req "ref_type" Types_encoding.ref_type_encoding)
           (req "einit_vec" @@ vec_kont Ast_encoding.const_encoding))
        (function
          | EKInitIndexed {mode; ref_type; einit_vec} ->
              Some ((), mode, ref_type, einit_vec)
          | _ -> None)
        (fun ((), mode, ref_type, einit_vec) ->
          EKInitIndexed {mode; ref_type; einit_vec});
      case
        (Tag 3)
        ~title:"EKInitConst"
        (obj5
           (req "kind" @@ constant "EKInitConst")
           (req "mode" Ast_encoding.segment_mode_encoding)
           (req "ref_type" Types_encoding.ref_type_encoding)
           (req "einit_vec" @@ vec_kont Ast_encoding.const_encoding)
           (req "einit_kont" @@ tup2 pos (list instr_block_kont)))
        (function
          | EKInitConst {mode; ref_type; einit_vec; einit_kont} ->
              Some ((), mode, ref_type, einit_vec, einit_kont)
          | _ -> None)
        (fun ((), mode, ref_type, einit_vec, einit_kont) ->
          EKInitConst {mode; ref_type; einit_vec; einit_kont});
      case
        (Tag 4)
        ~title:"EKStop"
        (obj2
           (req "kind" @@ constant "EKStop")
           (req "elem" Ast_encoding.elem_segment_encoding'))
        (function EKStop elem -> Some ((), elem) | _ -> None)
        (fun ((), elem) -> EKStop elem);
    ]

let byte_vector_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"VKStart"
        (obj1 (req "kind" @@ constant "VKStart"))
        (function VKStart -> Some () | _ -> None)
        (fun () -> VKStart);
      case
        (Tag 1)
        ~title:"VKRead"
        (obj4
           (req "kind" @@ constant "VKRead")
           (req "buffer" Lazy_encoding.chunked_byte_vector)
           (req "pos" int31)
           (req "len" int31))
        (function
          | VKRead (buffer, pos, len) -> Some ((), buffer, pos, len) | _ -> None)
        (fun ((), buffer, pos, len) -> VKRead (buffer, pos, len));
      case
        (Tag 2)
        ~title:"VKStop"
        (obj2
           (req "kind" @@ constant "VKRead")
           (req "buffer" Lazy_encoding.chunked_byte_vector))
        (function VKStop buffer -> Some ((), buffer) | _ -> None)
        (fun ((), buffer) -> VKStop buffer);
    ]

let code_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"CKStart"
        (obj1 (req "kind" @@ constant "CKStart"))
        (function CKStart -> Some () | _ -> None)
        (fun () -> CKStart);
      case
        (Tag 1)
        ~title:"CKLocals"
        (obj6
           (req "kind" @@ constant "CKLocals")
           (req "left" pos)
           (req "size" size)
           (req "pos" pos)
           (req "vec_kont"
           @@ vec_map_kont
                (tup2 int32 Types_encoding.value_type_encoding)
                Types_encoding.value_type_encoding)
           (req "locals_size" int64))
        (function
          | CKLocals {left; size; pos; vec_kont; locals_size} ->
              Some ((), left, size, pos, vec_kont, locals_size)
          | _ -> None)
        (fun ((), left, size, pos, vec_kont, locals_size) ->
          CKLocals {left; size; pos; vec_kont; locals_size});
      case
        (Tag 2)
        ~title:"CKBody"
        (obj5
           (req "kind" @@ constant "CKBody")
           (req "left" pos)
           (req "size" size)
           (req "locals" @@ list Types_encoding.value_type_encoding)
           (req "const_kont" @@ list instr_block_kont))
        (function
          | CKBody {left; size; locals; const_kont} ->
              Some ((), left, size, locals, const_kont)
          | _ -> None)
        (fun ((), left, size, locals, const_kont) ->
          CKBody {left; size; locals; const_kont});
      case
        (Tag 3)
        ~title:"CKStop"
        (obj2
           (req "kind" @@ constant "CKStop")
           (req "res" Ast_encoding.func_encoding))
        (function CKStop res -> Some ((), res) | _ -> None)
        (fun ((), res) -> CKStop res);
    ]

let data_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"DKStart"
        (obj1 (req "kind" @@ constant "DKStart"))
        (function DKStart -> Some () | _ -> None)
        (fun () -> DKStart);
      case
        (Tag 1)
        ~title:"DKMode"
        (obj4
           (req "kind" @@ constant "DKMode")
           (req "left" pos)
           (req "index" @@ Ast_encoding.phrase_encoding int32)
           (req "offset_kont" (tup2 pos (list instr_block_kont))))
        (function
          | DKMode {left; index; offset_kont} ->
              Some ((), left, index, offset_kont)
          | _ -> None)
        (fun ((), left, index, offset_kont) ->
          DKMode {left; index; offset_kont});
      case
        (Tag 2)
        ~title:"DKInit"
        (obj3
           (req "kind" @@ constant "DKInit")
           (req "dmode" Ast_encoding.segment_mode_encoding)
           (req "init_kont" byte_vector_kont))
        (function
          | DKInit {dmode; init_kont} -> Some ((), dmode, init_kont) | _ -> None)
        (fun ((), dmode, init_kont) -> DKInit {dmode; init_kont});
      case
        (Tag 3)
        ~title:"DKStop"
        (obj2
           (req "kind" @@ constant "DKStop")
           (req "res" Ast_encoding.data_segment_encoding'))
        (function DKStop res -> Some ((), res) | _ -> None)
        (fun ((), res) -> DKStop res);
    ]

type packed_field_type_and_vec =
  | Packed_field_type_and_vec :
      'a field_type * 'a vec_kont
      -> packed_field_type_and_vec

let cases_for_field_type_and_vec :
    type a.
    int -> a field_type -> packed_field_type_and_vec Data_encoding.case list =
 fun tag field ->
  let open Data_encoding in
  [
    (let title = title_for_field_type field in
     case
       ~title
       (Tag tag)
       (obj2
          (req "field_type" packed_field_type)
          (req "vec_kont" @@ vec_kont (encoding_for_field_type field)))
       (function
         | Packed_field_type_and_vec (f, v) -> (
             match field_type_eq field f with
             | Eq_refl -> Some (Packed f, v)
             | _ -> None))
       (fun (Packed f', v) ->
         match field_type_eq field f' with
         | Eq_refl -> Packed_field_type_and_vec (field, v)
         | _ -> raise (Invalid_argument "unexpected field_type")));
  ]

let field_type_and_vec : packed_field_type_and_vec Data_encoding.t =
  let open Data_encoding in
  union
  @@ List.concat
       [
         cases_for_field_type_and_vec 0 TypeField;
         cases_for_field_type_and_vec 1 ImportField;
         cases_for_field_type_and_vec 2 FuncField;
         cases_for_field_type_and_vec 3 TableField;
         cases_for_field_type_and_vec 4 MemoryField;
         cases_for_field_type_and_vec 5 GlobalField;
         cases_for_field_type_and_vec 6 ExportField;
         cases_for_field_type_and_vec 7 StartField;
         cases_for_field_type_and_vec 8 ElemField;
         cases_for_field_type_and_vec 9 DataCountField;
         cases_for_field_type_and_vec 10 CodeField;
         cases_for_field_type_and_vec 11 DataField;
       ]

let module_kont' =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"MKStart"
        (obj1 (req "kind" @@ constant "MKStart"))
        (function MKStart -> Some () | _ -> None)
        (fun () -> MKStart);
      case
        (Tag 1)
        ~title:"MKSkipCustom"
        (obj2
           (req "kind" @@ constant "MKSkipCustom")
           (req "value" @@ option (tup2 packed_field_type section_tag)))
        (function
          | MKSkipCustom (Some (f, value)) -> Some ((), Some (Packed f, value))
          | MKSkipCustom None -> Some ((), None)
          | _ -> None)
        (function
          | (), Some (Packed f, value) -> MKSkipCustom (Some (f, value))
          | (), None -> MKSkipCustom None);
      case
        (Tag 2)
        ~title:"MKFieldStart"
        (obj3
           (req "kind" @@ constant "MKFieldStart")
           (req "field_type" packed_field_type)
           (req "section_tag" section_tag))
        (function
          | MKFieldStart (f, value) -> Some ((), Packed f, value) | _ -> None)
        (function (), Packed f, value -> MKFieldStart (f, value));
      case
        (Tag 3)
        ~title:"MKField"
        (obj3
           (req "kind" @@ constant "MKField")
           (req "field_type_and_vec" field_type_and_vec)
           (req "size" size))
        (function
          | MKField (ft, size, vec_kont) ->
              Some ((), Packed_field_type_and_vec (ft, vec_kont), size)
          | _ -> None)
        (function
          | (), Packed_field_type_and_vec (ft, vec_kont), size ->
              MKField (ft, size, vec_kont));
      case
        (Tag 4)
        ~title:"MKElaborateFunc"
        (obj5
           (req "kind" @@ constant "MKElaborateFunc")
           (req "vars" @@ list Ast_encoding.var_encoding)
           (req "funcs" @@ list Ast_encoding.func_encoding)
           (req "vec_kont" @@ vec_kont Ast_encoding.func_encoding)
           (req "flag" bool))
        (function
          | MKElaborateFunc (vars, funcs, vec_kont, flag) ->
              Some ((), vars, funcs, vec_kont, flag)
          | _ -> None)
        (function
          | (), vars, funcs, vec_kont, flag ->
              MKElaborateFunc (vars, funcs, vec_kont, flag));
      case
        (Tag 5)
        ~title:"MKElaborateFunc"
        (obj5
           (req "kind" @@ constant "MKElaborateFunc")
           (req "vars" @@ list Ast_encoding.var_encoding)
           (req "funcs" @@ list Ast_encoding.func_encoding)
           (req "vec_kont" @@ vec_kont Ast_encoding.func_encoding)
           (req "flag" bool))
        (function
          | MKElaborateFunc (vars, funcs, vec_kont, flag) ->
              Some ((), vars, funcs, vec_kont, flag)
          | _ -> None)
        (function
          | (), vars, funcs, vec_kont, flag ->
              MKElaborateFunc (vars, funcs, vec_kont, flag));
      case
        (Tag 6)
        ~title:"MKBuild"
        (obj3
           (req "kind" @@ constant "MKBuild")
           (req "parsed_sections" @@ option (list Ast_encoding.func_encoding))
           (req "flag" bool))
        (function MKBuild (l, f) -> Some ((), l, f) | _ -> None)
        (fun ((), l, f) -> MKBuild (l, f));
      case
        (Tag 7)
        ~title:"MKStop"
        (obj2
           (req "kind" @@ constant "MKStop")
           (req "res" Ast_encoding.module_encoding'))
        (function MKStop m -> Some ((), m) | _ -> None)
        (fun ((), m) -> MKStop m);
      case
        (Tag 8)
        ~title:"MKImport"
        (obj5
           (req "kind" @@ constant "MKImport")
           (req "import_kont" import_kont)
           (req "pos" pos)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.import_encoding))
        (function
          | MKImport (import_kont, pos, size, vec_kont) ->
              Some ((), import_kont, pos, size, vec_kont)
          | _ -> None)
        (fun ((), import_kont, pos, size, vec_kont) ->
          MKImport (import_kont, pos, size, vec_kont));
      case
        (Tag 9)
        ~title:"MKExport"
        (obj5
           (req "kind" @@ constant "MKExport")
           (req "export_kont" export_kont)
           (req "pos" pos)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.export_encoding))
        (function
          | MKExport (export_kont, pos, size, vec_kont) ->
              Some ((), export_kont, pos, size, vec_kont)
          | _ -> None)
        (fun ((), export_kont, pos, size, vec_kont) ->
          MKExport (export_kont, pos, size, vec_kont));
      case
        (Tag 10)
        ~title:"MKGlobal"
        (obj6
           (req "kind" @@ constant "MKGlobal")
           (req "gobal_type" Types_encoding.global_type_encoding)
           (req "pos" int31)
           (req "instrs" @@ list instr_block_kont)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.global_encoding))
        (function
          | MKGlobal (global_type, pos, instrs, size, vec_kont) ->
              Some ((), global_type, pos, instrs, size, vec_kont)
          | _ -> None)
        (fun ((), global_type, pos, instrs, size, vec_kont) ->
          MKGlobal (global_type, pos, instrs, size, vec_kont));
      case
        (Tag 11)
        ~title:"MKElem"
        (obj5
           (req "kind" @@ constant "MKElem")
           (req "elem_kont" elem_kont)
           (req "pos" pos)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.elem_segment_encoding))
        (function
          | MKElem (elem_kont, pos, size, vec_kont) ->
              Some ((), elem_kont, pos, size, vec_kont)
          | _ -> None)
        (fun ((), elem_kont, pos, size, vec_kont) ->
          MKElem (elem_kont, pos, size, vec_kont));
      case
        (Tag 12)
        ~title:"MKData"
        (obj5
           (req "kind" @@ constant "MKData")
           (req "data_kont" data_kont)
           (req "pos" pos)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.data_segment_encoding))
        (function
          | MKData (data_kont, pos, size, vec_kont) ->
              Some ((), data_kont, pos, size, vec_kont)
          | _ -> None)
        (fun ((), data_kont, pos, size, vec_kont) ->
          MKData (data_kont, pos, size, vec_kont));
      case
        (Tag 13)
        ~title:"MKCode"
        (obj5
           (req "kind" @@ constant "MKCode")
           (req "code_kont" code_kont)
           (req "pos" pos)
           (req "size" size)
           (req "vec_kont" @@ vec_kont Ast_encoding.func_encoding))
        (function
          | MKCode (code_kont, pos, size, vec_kont) ->
              Some ((), code_kont, pos, size, vec_kont)
          | _ -> None)
        (fun ((), code_kont, pos, size, vec_kont) ->
          MKCode (code_kont, pos, size, vec_kont));
    ]

let module_kont =
  Data_encoding.(
    conv
      (fun {building_state; kont} -> (building_state, kont))
      (fun (building_state, kont) -> {building_state; kont})
      (obj2 (req "building_state" @@ list field) (req "kont" module_kont')))

let stream =
  Data_encoding.(
    conv
      (fun {name; bytes; pos} -> (name, bytes, !pos))
      (fun (name, bytes, pos) -> {name; bytes; pos = ref pos})
      (obj3 (req "name" string) (req "bytes" string) (req "pos" int31)))

let decode_kont =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"D_Start"
        (obj3
           (req "kind" @@ constant "D_Start")
           (req "name" string)
           (req "input" string))
        (function D_Start {name; input} -> Some ((), name, input) | _ -> None)
        (fun ((), name, input) -> D_Start {name; input});
      case
        (Tag 1)
        ~title:"D_Next"
        (obj4
           (req "kind" @@ constant "D_Start")
           (req "start" int31)
           (req "input" stream)
           (req "step" module_kont))
        (function
          | D_Next {start; input; step} -> Some ((), start, input, step)
          | _ -> None)
        (fun ((), start, input, step) -> D_Next {start; input; step});
      case
        (Tag 2)
        ~title:"D_Result"
        (obj2
           (req "kind" @@ constant "D_Result")
           (req "result" @@ Ast_encoding.(phrase_encoding module_encoding')))
        (function D_Result result -> Some ((), result) | _ -> None)
        (fun ((), result) -> D_Result result);
    ]
