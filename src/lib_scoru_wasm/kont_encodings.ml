open Tezos_webassembly_interpreter.Ast
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

let type_ : type_ Data_encoding.t = assert false

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
