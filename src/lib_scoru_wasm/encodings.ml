open Tezos_webassembly_interpreter
open Types
open Sigs

let i32_case f = ("i32", f I32Type)

let i64_case f = ("i64", f I64Type)

let num_type_cases f = [i32_case f; i64_case f]

let v128_case f = ("v128", f V128Type)

let vec_type_cases f = [v128_case f]

let funcref_case f = ("funcref", f FuncRefType)

let externref_case f = ("externref", f ExternRefType)

let ref_type_cases f = [funcref_case f; externref_case f]

let ref_type_encoding = Data_encoding.string_enum (ref_type_cases Fun.id)

let value_type_cases f =
  num_type_cases (fun nt -> f (NumType nt))
  @ vec_type_cases (fun vt -> f (VecType vt))
  @ ref_type_cases (fun rt -> f (RefType rt))

let value_type_encoding = Data_encoding.string_enum (value_type_cases Fun.id)

let mutability_encoding =
  Data_encoding.string_enum [("mutable", Mutable); ("immutable", Immutable)]

module Decoded = struct
  type 'a t =
    | Value of 'a
    | PartialValue of (Instance.module_inst Lazy_map.Int32Map.t -> 'a)

  let map f = function
    | Value x -> Value (f x)
    | PartialValue g -> PartialValue (fun m -> f (g m))

  let force m = function Value x -> x | PartialValue f -> f m
end

module Make (T : TreeS) = struct
  module Tree = struct
    include T
    module Encoding = Tree_encoding.Make (T)
  end

  let ref_encoding_for ref_type =
    let open Tree.Encoding in
    let get_value_with enc f =
      let+ value = value ["value"] enc in
      Decoded.Value (f value)
    in
    match ref_type with
    | FuncRefType ->
        let+ modul_id = value ["module"] Data_encoding.int32
        and+ func_id = value ["function"] Data_encoding.int32 in
        Decoded.PartialValue
          (fun modules ->
            let modul = Instance.Int32Map.get modul_id modules in
            Instance.FuncRef
              (Instance.Int32Map.get func_id modul.Instance.funcs))
    | ExternRefType ->
        get_value_with Data_encoding.int32 (fun x -> Script.ExternRef x)

  let ref_encoding =
    let open Tree.Encoding in
    let* ref_type = value ["type"] ref_type_encoding in
    ref_encoding_for ref_type

  let value_encoding =
    let open Tree.Encoding in
    let* value_type = value ["type"] value_type_encoding in
    let get_value_with enc f =
      let+ value = value ["value"] enc in
      Decoded.Value (f value)
    in
    match value_type with
    | NumType I32Type ->
        get_value_with Data_encoding.int32 (fun x -> Values.Num (Values.I32 x))
    | NumType I64Type ->
        get_value_with Data_encoding.int64 (fun x -> Values.Num (Values.I64 x))
    | VecType V128Type ->
        get_value_with Data_encoding.string (fun x ->
            Values.Vec (V128 (V128.of_bits x)))
    | RefType ref_type ->
        let+ ref_value = ref_encoding_for ref_type in
        Decoded.map (fun rv -> Values.Ref rv) ref_value
    | _ -> failwith "Unsupported value_type"

  let memory_encoding =
    let open Tree.Encoding in
    let+ min = value ["min"] Data_encoding.int32
    and+ max = value ["max"] Data_encoding.int32
    and+ pages =
      iterate
        ["pages"]
        (let+ page = raw [] in
         fun address -> (Int64.of_string address, page))
    in
    let memory = Memory.alloc (MemoryType {min; max = Some max}) in
    List.iter
      (fun (address, page_contents) ->
        Memory.store_bytes memory address (Bytes.to_string page_contents))
      pages ;
    memory

  let table_encoding =
    let open Tree.Encoding in
    let+ min = value ["min"] Data_encoding.int32
    and+ max = value ["max"] Data_encoding.int32
    and+ refs =
      iterate
        ["refs"]
        (let+ ref = ref_encoding in
         fun id -> Decoded.map (fun value -> (Int32.of_string id, value)) ref)
    in
    let table =
      Table.alloc
        (TableType ({min; max = Some max}, FuncRefType))
        (Values.NullRef FuncRefType)
    in
    Decoded.PartialValue
      (fun modules ->
        List.iter
          (fun value ->
            let id, ref = Decoded.force modules value in
            Table.store table id ref)
          refs ;
        table)

  let global_encoding =
    let open Tree.Encoding in
    let+ type_ = value ["type"] mutability_encoding
    and+ value = tree ["value"] value_encoding in
    Decoded.map
      (fun value ->
        let ty = GlobalType (Values.type_of_value value, type_) in
        Global.alloc ty value)
      value

  let indexed_instance_encoding field_name tree_encoding =
    let open Tree.Encoding in
    let+ count = value ["num-" ^ field_name] Data_encoding.int32
    and+ instances =
      iterate
        [field_name]
        (let+ value = tree_encoding in
         fun id -> (Int32.of_string id, value))
    in
    List.fold_left
      (fun instances (id, value) -> Instance.Int32Map.set id value instances)
      (Instance.Int32Map.create count)
      instances

  let memory_instance_encoding =
    indexed_instance_encoding "memories" memory_encoding

  let table_instance_encoding =
    indexed_instance_encoding "tables" table_encoding

  let global_instance_encoding =
    indexed_instance_encoding "globals" global_encoding
end
