exception Code of Source.region * string

val decode : string -> string -> Ast.module_ (* raises Code *)

val decode_custom : Ast.name -> string -> string -> string list (* raises Code *)

(* ------ Tick functions and dependencies ----------------------------------- *)

open Ast
open Types

(* We re-export these types to be able to write encodings in
   [lib_scoru_wasm]. *)

type section_tag =
  [ `CodeSection
  | `CustomSection
  | `DataCountSection
  | `DataSection
  | `ElemSection
  | `ExportSection
  | `FuncSection
  | `GlobalSection
  | `ImportSection
  | `MemorySection
  | `StartSection
  | `TableSection
  | `TypeSection ]

(** Sections representation. *)
type _ field_type =
  | TypeField : type_ field_type
  | ImportField : import field_type
  | FuncField : var field_type
  | TableField : table field_type
  | MemoryField : memory field_type
  | GlobalField : global field_type
  | ExportField : export field_type
  | StartField : start field_type
  | ElemField : elem_segment field_type
  | DataCountField : int32 field_type
  | CodeField : func field_type
  | DataField : data_segment field_type

(** Result of a section parsing, being either a single value or a vector. *)
type field =
  | VecField : 'a field_type * 'a list * int -> field
  | SingleField : 'a field_type * 'a option -> field

(** Vector and size continuations *)

(** Vector accumulator, used in two steps: first accumulating the values, then
    reversing them and possibly mapping them, counting the number of values in
    the list. Continuation passing style transformation of {!List.map} also
    returning length. *)
type ('a, 'b) vec_map_kont =
    Collect of int * 'a list
  | Rev of 'a list * 'b list * int

type 'a vec_kont = ('a, 'a) vec_map_kont

type pos = int

type size = { size: int; start: pos}

type name_step =
  | NKStart
  (** UTF8 name starting point. *)
  | NKParse of pos * (int, int) vec_map_kont
  (** UTF8 char parsing. *)
  | NKStop of int list
  (** UTF8 name final step.*)

type utf8 = int list

type import_kont =
  | ImpKStart
  (** Import parsing starting point. *)
  | ImpKModuleName of name_step
  (** Import module name parsing UTF8 char per char step. *)
  | ImpKItemName of utf8 * name_step
  (** Import item name parsing UTF8 char per char step. *)
  | ImpKStop of import'
  (** Import final step. *)

type export_kont =
  | ExpKStart
  (** Export parsing starting point. *)
  | ExpKName of name_step
  (** Export name parsing UTF8 char per char step. *)
  | ExpKStop of export'
  (** Export final step. *)

(** Instruction parsing continuations. *)
type instr_block_kont =
  | IKStop of instr list
  (** Final step of a block parsing. *)
  | IKRev of instr list * instr list
  (** Reversal of lists of instructions. *)
  | IKNext of instr list
  (** Tag parsing, containing the accumulation of already parsed values. *)
  | IKBlock of block_type * int
  (** Block parsing step. *)
  | IKLoop of block_type * int
  (** Loop parsing step. *)
  | IKIf1 of block_type * int
  (** If parsing step. *)
  | IKIf2 of block_type * int * instr list
  (** If .. else parsing step. *)

type index_kind = Indexed | Const

type elem_kont =
  | EKStart
  (** Starting point of an element segment parsing. *)
  | EKMode of
      {
        left: pos;
        index : int32 Source.phrase;
        index_kind: index_kind;
        early_ref_type : ref_type option;
        offset_kont: pos * instr_block_kont list
      }
  (** Element segment mode parsing step. *)
  | EKInitIndexed of
      { mode: segment_mode;
        ref_type: ref_type;
        einit_vec: const vec_kont
      }
  (** Element segment initialization code parsing step for referenced values. *)
  | EKInitConst of
      { mode: segment_mode;
        ref_type: ref_type;
        einit_vec: const vec_kont;
        einit_kont: pos * instr_block_kont list
      }
  (** Element segment initialization code parsing step for constant values. *)
  | EKStop of elem_segment'
  (** Final step of a segment parsing. *)

(** Incremental chunked byte vector creation (from implicit input). *)
type byte_vector_kont =
  | VKStart
  (** Initial step. *)
  | VKRead of Chunked_byte_vector.Buffer.t * int * int
  (** Reading step, containing the current position in the string and the
      length, reading byte per byte. *)
  | VKStop of Chunked_byte_vector.Buffer.t
  (** Final step, cannot reduce. *)

(** Code section parsing. *)
type code_kont =
  | CKStart
  (** Starting point of a function parsing. *)
  | CKLocals of
      { left: pos;
        size : size;
        pos : pos;
        vec_kont: (int32 * value_type, value_type) vec_map_kont;
        locals_size: Int64.t;
      }
  (** Parsing step of local values of a function. *)
  | CKBody of
      { left: pos;
        size : size;
        locals: value_type list;
        const_kont: instr_block_kont list;
      }
  (** Parsing step of the body of a function. *)
  | CKStop of func
  (** Final step of a parsed function, irreducible. *)

type data_kont =
  | DKStart
  (** Starting point of a data segment parsing. *)
  | DKMode of
      { left : pos;
        index: int32 Source.phrase;
        offset_kont: pos * instr_block_kont list
      }
  (** Data segment mode parsing step. *)
  | DKInit of { dmode: segment_mode; init_kont: byte_vector_kont }
  | DKStop of data_segment'
  (** Final step of a data segment parsing. *)

(** Module parsing steps *)
type module_kont' =
  | MKStart
  (** Initial state of a module parsing *)
  | MKSkipCustom : ('a field_type * section_tag) option -> module_kont'
  (** Custom section which are skipped, with the next section to parse. *)
  | MKFieldStart : 'a field_type * section_tag -> module_kont'
  (** Starting point of a section, handles parsing generic section header. *)
  | MKField : 'a field_type * size * 'a vec_kont -> module_kont'
  (** Section currently parsed, accumulating each element from the underlying vector. *)
  | MKElaborateFunc : var list * func list * func vec_kont * bool -> module_kont'
  (** Elaboration of functions from the code section with their declared type in
      the func section, and accumulating invariants conditions associated to
      functions. *)
  | MKBuild of func list option * bool
  (** Accumulating the parsed sections vectors into a module and checking
      invariants. *)
  | MKStop of module_' (* TODO (#3120): actually, should be module_ *)
  (** Final step of the parsing, cannot reduce. *)

  (* For the next continuations, the vectors are only used for accumulation, and
     reduce to `MK_Field(.., Rev ..)`. *)
  | MKImport of import_kont * pos * size * import vec_kont
  (** Import section parsing. *)
  | MKExport of export_kont * pos * size * export vec_kont
  (** Export section parsing. *)
  | MKGlobal of global_type * int * instr_block_kont list * size * global vec_kont
  (** Globals section parsing, containing the starting position, the
      continuation of the current global block instruction, and the size of the
      section. *)
  | MKElem of elem_kont * int * size * elem_segment vec_kont
  (** Element segments section parsing, containing the current element parsing
      continuation, the starting position of the current element, the size of
      the section. *)
  | MKData of data_kont * int * size * data_segment vec_kont
  (** Data segments section parsing, containing the current data parsing
      continuation, the starting position of the current data, the size of the
      section. *)
  | MKCode of code_kont * int * size * func vec_kont
  (** Code section parsing, containing the current function parsing
      continuation, the starting position of the current function, the size of
      the section. *)

type module_kont =
  { building_state : field list; (** Accumulated parsed sections. *)
    kont : module_kont' }

type stream =
{
  name : string;
  bytes : string;
  pos : int ref;
}

type decode_kont =
  | D_Start of { name : string; input : string}
  | D_Next of {start : int; input : stream; step : module_kont}
  | D_Result of module_

val decode_step : decode_kont -> decode_kont
