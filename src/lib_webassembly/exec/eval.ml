open Lwt.Syntax
open Values
open Types
open Instance
open Ast
open Source

(* Errors *)

module Link = Error.Make ()

module Trap = Error.Make ()

module Crash = Error.Make ()

module Exhaustion = Error.Make ()

exception Link = Link.Error

exception Trap = Trap.Error

exception Crash = Crash.Error (* failure that cannot happen in valid code *)

exception Exhaustion = Exhaustion.Error

let table_error at = function
  | Table.Bounds -> "out of bounds table access"
  | Table.SizeOverflow -> "table size overflow"
  | Table.SizeLimit -> "table size limit reached"
  | Table.Type -> Crash.error at "type mismatch at table access"
  | Lazy_map.UnexpectedAccess -> "unexpected access in lazy map"
  | exn -> raise exn

let memory_error at = function
  | Memory.Bounds -> "out of bounds memory access"
  | Memory.SizeOverflow -> "memory size overflow"
  | Memory.SizeLimit -> "memory size limit reached"
  | Memory.Type -> Crash.error at "type mismatch at memory access"
  | Lazy_map.UnexpectedAccess -> "unexpected access in lazy map"
  | exn -> raise exn

let numeric_error at = function
  | Ixx.Overflow -> "integer overflow"
  | Ixx.DivideByZero -> "integer divide by zero"
  | Ixx.InvalidConversion -> "invalid conversion to integer"
  | Values.TypeError (i, v, t) ->
      Crash.error
        at
        ("type error, expected " ^ Types.string_of_num_type t ^ " as operand "
       ^ string_of_int i ^ ", got "
        ^ Types.string_of_num_type (type_of_num v))
  | exn -> raise exn

(* Administrative Expressions & Configurations *)

type 'a stack = 'a list

type frame = {inst : module_key; locals : value ref list}

type code = value stack * admin_instr list

and admin_instr = admin_instr' phrase

and admin_instr' =
  | From_block of block_label * int32
  | Plain of instr'
  | Refer of ref_
  | Invoke of func_inst
  | Trapping of string
  | Returning of value stack
  | Breaking of int32 * value stack
  | Label of int32 * instr list * code
  | Frame of int32 * frame * code

type config = {
  frame : frame;
  input : input_inst;
  code : code;
  host_funcs : Host_funcs.registry;
  budget : int; (* to model stack overflow *)
}

let frame inst locals = {inst; locals}

let config ?(input = Input_buffer.alloc ()) host_funcs inst vs es =
  {frame = frame inst []; input; code = (vs, es); budget = 300; host_funcs}

let plain e = Plain e.it @@ e.at

let lookup category list x =
  try Lib.List32.nth list x.it
  with Failure _ ->
    Crash.error x.at ("undefined " ^ category ^ " " ^ Int32.to_string x.it)

let lookup_intmap category store x =
  Lwt.catch
    (fun () -> Instance.Vector.get x.it store)
    (function
      | Lazy_vector.Bounds ->
          Crash.error x.at ("undefined " ^ category ^ " " ^ Int32.to_string x.it)
      | Lazy_map.UnexpectedAccess ->
          Crash.error
            x.at
            ("unexpected access in lazy map for " ^ category ^ " "
           ^ Int32.to_string x.it)
      | exn -> Lwt.fail exn)

let type_ (inst : module_inst) x = lookup_intmap "type" inst.types x

let func (inst : module_inst) x = lookup_intmap "function" inst.funcs x

let table (inst : module_inst) x = lookup_intmap "table" inst.tables x

let memory (inst : module_inst) x = lookup_intmap "memory" inst.memories x

let global (inst : module_inst) x = lookup_intmap "global" inst.globals x

let elem (inst : module_inst) x = lookup_intmap "element segment" inst.elems x

let data (inst : module_inst) x = lookup_intmap "data segment" inst.datas x

let local (frame : frame) x = lookup "local" frame.locals x

let any_ref inst x i at =
  Lwt.catch
    (fun () ->
      let* tbl = table inst x in
      Table.load tbl i)
    (function
      | Table.Bounds -> Trap.error at ("undefined element " ^ Int32.to_string i)
      | exn -> Lwt.fail exn)

let func_ref inst x i at =
  let+ value = any_ref inst x i at in
  match value with
  | FuncRef f -> f
  | NullRef _ -> Trap.error at ("uninitialized element " ^ Int32.to_string i)
  | _ -> Crash.error at ("type mismatch for element " ^ Int32.to_string i)

let func_type_of = function
  | Func.AstFunc (t, _inst, _f) -> t
  | Func.HostFunc (t, _) -> t

let block_type inst bt =
  let empty () = Lazy_vector.Int32Vector.create 0l in
  let singleton i = Lazy_vector.Int32Vector.(create 1l |> set 0l i) in
  match bt with
  | VarBlockType x -> type_ inst x
  | ValBlockType None -> FuncType (empty (), empty ()) |> Lwt.return
  | ValBlockType (Some t) -> FuncType (empty (), singleton t) |> Lwt.return

let take n (vs : 'a stack) at =
  try Lib.List32.take n vs with Failure _ -> Crash.error at "stack underflow"

let drop n (vs : 'a stack) at =
  try Lib.List32.drop n vs with Failure _ -> Crash.error at "stack underflow"

(* Evaluation *)

(*
 * Conventions:
 *   e  : instr
 *   v  : value
 *   es : instr list
 *   vs : value stack
 *   c : config
 *)

let mem_oob module_reg frame x i n =
  let* inst = resolve_module_ref module_reg frame.inst in
  let+ mem = memory inst x in
  I64.gt_u
    (I64.add (I64_convert.extend_i32_u i) (I64_convert.extend_i32_u n))
    (Memory.bound mem)

let data_oob module_reg frame x i n =
  let* inst = resolve_module_ref module_reg frame.inst in
  let* data_label = data inst x in
  let+ data = Ast.get_data !data_label inst.allocations.datas in
  I64.gt_u
    (I64.add (I64_convert.extend_i32_u i) (I64_convert.extend_i32_u n))
    (Chunked_byte_vector.length data)

let table_oob module_reg frame x i n =
  let* inst = resolve_module_ref module_reg frame.inst in
  let+ tbl = table inst x in
  I64.gt_u
    (I64.add (I64_convert.extend_i32_u i) (I64_convert.extend_i32_u n))
    (I64_convert.extend_i32_u (Table.size tbl))

let elem_oob module_reg frame x i n =
  let* inst = resolve_module_ref module_reg frame.inst in
  let+ elem = elem inst x in
  I64.gt_u
    (I64.add (I64_convert.extend_i32_u i) (I64_convert.extend_i32_u n))
    (Int64.of_int32 (Instance.Vector.num_elements !elem))

let rec step (module_reg : module_reg) (c : config) : config Lwt.t =
  let {frame; code = vs, es; _} = c in
  match es with
  | {it = From_block (Block_label b, i); at} :: es ->
      let* inst = resolve_module_ref module_reg frame.inst in
      let* block = Vector.get b inst.allocations.blocks in
      let length = Vector.num_elements block in
      if i = length then Lwt.return {c with code = (vs, es)}
      else
        let* e, es =
          let* instr = Vector.get i block in
          Lwt.return
            ( Plain instr.it @@ instr.at,
              {it = From_block (Block_label b, Int32.succ i); at} :: es )
        in
        step_resolved module_reg c frame vs e es
  | e :: es -> step_resolved module_reg c frame vs e es
  | [] -> Lwt.return c

and step_resolved module_reg (c : config) frame vs e es : config Lwt.t =
  let+ vs', es' =
    match (e.it, vs) with
    | From_block _, _ -> assert false (* resolved by [step] *)
    | Plain e', vs -> (
        match (e', vs) with
        | Unreachable, vs ->
            Lwt.return (vs, [Trapping "unreachable executed" @@ e.at])
        | Nop, vs -> Lwt.return (vs, [])
        | Block (bt, es'), vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ (FuncType (ts1, ts2)) = block_type inst bt in
            let n1 = Lazy_vector.Int32Vector.num_elements ts1 in
            let n2 = Lazy_vector.Int32Vector.num_elements ts2 in
            let args, vs' = (take n1 vs e.at, drop n1 vs e.at) in
            ( vs',
              [Label (n2, [], (args, [From_block (es', 0l) @@ e.at])) @@ e.at]
            )
        | Loop (bt, es'), vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ (FuncType (ts1, _)) = block_type inst bt in
            let n1 = Lazy_vector.Int32Vector.num_elements ts1 in
            let args, vs' = (take n1 vs e.at, drop n1 vs e.at) in
            ( vs',
              [
                Label (n1, [e' @@ e.at], (args, [From_block (es', 0l) @@ e.at]))
                @@ e.at;
              ] )
        | If (bt, es1, es2), Num (I32 i) :: vs' ->
            Lwt.return
              (if i = 0l then (vs', [Plain (Block (bt, es2)) @@ e.at])
              else (vs', [Plain (Block (bt, es1)) @@ e.at]))
        | Br x, vs -> Lwt.return ([], [Breaking (x.it, vs) @@ e.at])
        | BrIf x, Num (I32 i) :: vs' ->
            Lwt.return
              (if i = 0l then (vs', []) else (vs', [Plain (Br x) @@ e.at]))
        | BrTable (xs, x), Num (I32 i) :: vs' ->
            Lwt.return
              (if I32.ge_u i (Lib.List32.length xs) then
               (vs', [Plain (Br x) @@ e.at])
              else (vs', [Plain (Br (Lib.List32.nth xs i)) @@ e.at]))
        | Return, vs -> Lwt.return ([], [Returning vs @@ e.at])
        | Call x, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ func = func inst x in
            (vs, [Invoke func @@ e.at])
        | CallIndirect (x, y), Num (I32 i) :: vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* func = func_ref inst x i e.at and* type_ = type_ inst y in
            let+ check_eq = Types.func_types_equal type_ (Func.type_of func) in
            if not check_eq then
              (vs, [Trapping "indirect call type mismatch" @@ e.at])
            else (vs, [Invoke func @@ e.at])
        | Drop, _ :: vs' -> Lwt.return (vs', [])
        | Select _, Num (I32 i) :: v2 :: v1 :: vs' ->
            Lwt.return (if i = 0l then (v2 :: vs', []) else (v1 :: vs', []))
        | LocalGet x, vs -> Lwt.return (!(local frame x) :: vs, [])
        | LocalSet x, v :: vs' ->
            Lwt.return
              (local frame x := v ;
               (vs', []))
        | LocalTee x, v :: vs' ->
            Lwt.return
              (local frame x := v ;
               (v :: vs', []))
        | GlobalGet x, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ glob = global inst x in
            let value = Global.load glob in
            (value :: vs, [])
        | GlobalSet x, v :: vs' ->
            Lwt.catch
              (fun () ->
                let* inst = resolve_module_ref module_reg frame.inst in
                let+ glob = global inst x in
                Global.store glob v ;
                (vs', []))
              (function
                | Global.NotMutable ->
                    Crash.error e.at "write to immutable global"
                | Global.Type ->
                    Crash.error e.at "type mismatch at global write"
                | exn -> Lwt.fail exn)
        | TableGet x, Num (I32 i) :: vs' ->
            Lwt.catch
              (fun () ->
                let* inst = resolve_module_ref module_reg frame.inst in
                let* tbl = table inst x in
                let+ value = Table.load tbl i in
                (Ref value :: vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (table_error e.at exn) @@ e.at]))
        | TableSet x, Ref r :: Num (I32 i) :: vs' ->
            Lwt.catch
              (fun () ->
                let* inst = resolve_module_ref module_reg frame.inst in
                let+ tbl = table inst x in
                Table.store tbl i r ;
                (vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (table_error e.at exn) @@ e.at]))
        | TableSize x, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ tbl = table inst x in
            (Num (I32 (Table.size tbl)) :: vs, [])
        | TableGrow x, Num (I32 delta) :: Ref r :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ tab = table inst x in
            let old_size = Table.size tab in
            let result =
              try
                Table.grow tab delta r ;
                old_size
              with Table.SizeOverflow | Table.SizeLimit | Table.OutOfMemory ->
                -1l
            in
            (Num (I32 result) :: vs', [])
        | TableFill x, Num (I32 n) :: Ref r :: Num (I32 i) :: vs' ->
            let+ oob = table_oob module_reg frame x i n in
            if oob then (vs', [Trapping (table_error e.at Table.Bounds) @@ e.at])
            else if n = 0l then (vs', [])
            else
              let _ = assert (I32.lt_u i 0xffff_ffffl) in
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 i @@ e.at));
                    Refer r;
                    Plain (TableSet x);
                    Plain (Const (I32 (I32.add i 1l) @@ e.at));
                    Refer r;
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain (TableFill x);
                  ] )
        | TableCopy (x, y), Num (I32 n) :: Num (I32 s) :: Num (I32 d) :: vs' ->
            let+ oob_d = table_oob module_reg frame x d n
            and+ oob_s = table_oob module_reg frame y s n in
            if oob_d || oob_s then
              (vs', [Trapping (table_error e.at Table.Bounds) @@ e.at])
            else if n = 0l then (vs', [])
            else if I32.le_u d s then
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 d @@ e.at));
                    Plain (Const (I32 s @@ e.at));
                    Plain (TableGet y);
                    Plain (TableSet x);
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain (TableCopy (x, y));
                  ] )
            else
              (* d > s *)
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain (TableCopy (x, y));
                    Plain (Const (I32 d @@ e.at));
                    Plain (Const (I32 s @@ e.at));
                    Plain (TableGet y);
                    Plain (TableSet x);
                  ] )
        | TableInit (x, y), Num (I32 n) :: Num (I32 s) :: Num (I32 d) :: vs' ->
            let* oob_d = table_oob module_reg frame x d n in
            let* oob_s = elem_oob module_reg frame y s n in
            if oob_d || oob_s then
              Lwt.return
                (vs', [Trapping (table_error e.at Table.Bounds) @@ e.at])
            else if n = 0l then Lwt.return (vs', [])
            else
              let* inst = resolve_module_ref module_reg frame.inst in
              let* seg = elem inst y in
              let+ value = Instance.Vector.get s !seg in
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 d @@ e.at));
                    (* Note, the [Instance.Vector.get] is logarithmic in the number of
                       contained elements in [seg]. However, in a scenario where the PVM
                       runs, only the element that will be looked up is in the map
                       making the look up cheap. *)
                    Refer value;
                    Plain (TableSet x);
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain (TableInit (x, y));
                  ] )
        | ElemDrop x, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ seg = elem inst x in
            seg := Instance.Vector.create 0l ;
            (vs, [])
        | Load {offset; ty; pack; _}, Num (I32 i) :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ n =
                  match pack with
                  | None -> Memory.load_num mem i offset ty
                  | Some (sz, ext) ->
                      Memory.load_num_packed sz ext mem i offset ty
                in
                (Num n :: vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | Store {offset; pack; _}, Num n :: Num (I32 i) :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ () =
                  match pack with
                  | None -> Memory.store_num mem i offset n
                  | Some sz -> Memory.store_num_packed sz mem i offset n
                in
                (vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | VecLoad {offset; ty; pack; _}, Num (I32 i) :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ v =
                  match pack with
                  | None -> Memory.load_vec mem i offset ty
                  | Some (sz, ext) ->
                      Memory.load_vec_packed sz ext mem i offset ty
                in
                (Vec v :: vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | VecStore {offset; _}, Vec v :: Num (I32 i) :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ () = Memory.store_vec mem i offset v in
                (vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | VecLoadLane ({offset; pack; _}, j), Vec (V128 v) :: Num (I32 i) :: vs'
          ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ v =
                  match pack with
                  | Pack8 ->
                      let+ mem =
                        Memory.load_num_packed Pack8 SX mem i offset I32Type
                      in
                      V128.I8x16.replace_lane j v (I32Num.of_num 0 mem)
                  | Pack16 ->
                      let+ mem =
                        Memory.load_num_packed Pack16 SX mem i offset I32Type
                      in
                      V128.I16x8.replace_lane j v (I32Num.of_num 0 mem)
                  | Pack32 ->
                      let+ mem = Memory.load_num mem i offset I32Type in
                      V128.I32x4.replace_lane j v (I32Num.of_num 0 mem)
                  | Pack64 ->
                      let+ mem = Memory.load_num mem i offset I64Type in
                      V128.I64x2.replace_lane j v (I64Num.of_num 0 mem)
                in
                (Vec (V128 v) :: vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | ( VecStoreLane ({offset; pack; _}, j),
            Vec (V128 v) :: Num (I32 i) :: vs' ) ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let* mem = memory inst (0l @@ e.at) in
            Lwt.catch
              (fun () ->
                let+ () =
                  match pack with
                  | Pack8 ->
                      Memory.store_num_packed
                        Pack8
                        mem
                        i
                        offset
                        (I32 (V128.I8x16.extract_lane_s j v))
                  | Pack16 ->
                      Memory.store_num_packed
                        Pack16
                        mem
                        i
                        offset
                        (I32 (V128.I16x8.extract_lane_s j v))
                  | Pack32 ->
                      Memory.store_num
                        mem
                        i
                        offset
                        (I32 (V128.I32x4.extract_lane_s j v))
                  | Pack64 ->
                      Memory.store_num
                        mem
                        i
                        offset
                        (I64 (V128.I64x2.extract_lane_s j v))
                in
                (vs', []))
              (fun exn ->
                Lwt.return (vs', [Trapping (memory_error e.at exn) @@ e.at]))
        | MemorySize, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ mem = memory inst (0l @@ e.at) in
            (Num (I32 (Memory.size mem)) :: vs, [])
        | MemoryGrow, Num (I32 delta) :: vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ mem = memory inst (0l @@ e.at) in
            let old_size = Memory.size mem in
            let result =
              try
                Memory.grow mem delta ;
                old_size
              with
              | Memory.SizeOverflow | Memory.SizeLimit | Memory.OutOfMemory ->
                -1l
            in
            (Num (I32 result) :: vs', [])
        | MemoryFill, Num (I32 n) :: Num k :: Num (I32 i) :: vs' ->
            let+ oob = mem_oob module_reg frame (0l @@ e.at) i n in
            if oob then
              (vs', [Trapping (memory_error e.at Memory.Bounds) @@ e.at])
            else if n = 0l then (vs', [])
            else
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 i @@ e.at));
                    Plain (Const (k @@ e.at));
                    Plain
                      (Store
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some Pack8;
                         });
                    Plain (Const (I32 (I32.add i 1l) @@ e.at));
                    Plain (Const (k @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain MemoryFill;
                  ] )
        | MemoryCopy, Num (I32 n) :: Num (I32 s) :: Num (I32 d) :: vs' ->
            let+ oob_s = mem_oob module_reg frame (0l @@ e.at) s n
            and+ oob_d = mem_oob module_reg frame (0l @@ e.at) d n in
            if oob_s || oob_d then
              (vs', [Trapping (memory_error e.at Memory.Bounds) @@ e.at])
            else if n = 0l then (vs', [])
            else if I32.le_u d s then
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 d @@ e.at));
                    Plain (Const (I32 s @@ e.at));
                    Plain
                      (Load
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some (Pack8, ZX);
                         });
                    Plain
                      (Store
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some Pack8;
                         });
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain MemoryCopy;
                  ] )
            else
              (* d > s *)
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain MemoryCopy;
                    Plain (Const (I32 d @@ e.at));
                    Plain (Const (I32 s @@ e.at));
                    Plain
                      (Load
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some (Pack8, ZX);
                         });
                    Plain
                      (Store
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some Pack8;
                         });
                  ] )
        | MemoryInit x, Num (I32 n) :: Num (I32 s) :: Num (I32 d) :: vs' ->
            let* mem_oob = mem_oob module_reg frame (0l @@ e.at) d n in
            let* data_oob = data_oob module_reg frame x s n in
            if mem_oob || data_oob then
              Lwt.return
                (vs', [Trapping (memory_error e.at Memory.Bounds) @@ e.at])
            else if n = 0l then Lwt.return (vs', [])
            else
              let* inst = resolve_module_ref module_reg frame.inst in
              let* seg = data inst x in
              let* seg = Ast.get_data !seg inst.allocations.datas in
              let+ b = Chunked_byte_vector.load_byte seg (Int64.of_int32 s) in
              let b = Int32.of_int b in
              ( vs',
                List.map
                  (at e.at)
                  [
                    Plain (Const (I32 d @@ e.at));
                    Plain (Const (I32 b @@ e.at));
                    Plain
                      (Store
                         {
                           ty = I32Type;
                           align = 0;
                           offset = 0l;
                           pack = Some Pack8;
                         });
                    Plain (Const (I32 (I32.add d 1l) @@ e.at));
                    Plain (Const (I32 (I32.add s 1l) @@ e.at));
                    Plain (Const (I32 (I32.sub n 1l) @@ e.at));
                    Plain (MemoryInit x);
                  ] )
        | DataDrop x, vs ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ seg = data inst x in
            seg := Data_label 0l ;
            (vs, [])
        | RefNull t, vs' -> Lwt.return (Ref (NullRef t) :: vs', [])
        | RefIsNull, Ref r :: vs' ->
            Lwt.return
              (match r with
              | NullRef _ -> (Num (I32 1l) :: vs', [])
              | _ -> (Num (I32 0l) :: vs', []))
        | RefFunc x, vs' ->
            let* inst = resolve_module_ref module_reg frame.inst in
            let+ f = func inst x in
            (Ref (FuncRef f) :: vs', [])
        | Const n, vs -> Lwt.return (Num n.it :: vs, [])
        | Test testop, Num n :: vs' ->
            Lwt.return
              (try (value_of_bool (Eval_num.eval_testop testop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | Compare relop, Num n2 :: Num n1 :: vs' ->
            Lwt.return
              (try (value_of_bool (Eval_num.eval_relop relop n1 n2) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | Unary unop, Num n :: vs' ->
            Lwt.return
              (try (Num (Eval_num.eval_unop unop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | Binary binop, Num n2 :: Num n1 :: vs' ->
            Lwt.return
              (try (Num (Eval_num.eval_binop binop n1 n2) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | Convert cvtop, Num n :: vs' ->
            Lwt.return
              (try (Num (Eval_num.eval_cvtop cvtop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecConst v, vs -> Lwt.return (Vec v.it :: vs, [])
        | VecTest testop, Vec n :: vs' ->
            Lwt.return
              (try (value_of_bool (Eval_vec.eval_testop testop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecUnary unop, Vec n :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_unop unop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecBinary binop, Vec n2 :: Vec n1 :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_binop binop n1 n2) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecCompare relop, Vec n2 :: Vec n1 :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_relop relop n1 n2) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecConvert cvtop, Vec n :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_cvtop cvtop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecShift shiftop, Num s :: Vec v :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_shiftop shiftop v s) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecBitmask bitmaskop, Vec v :: vs' ->
            Lwt.return
              (try (Num (Eval_vec.eval_bitmaskop bitmaskop v) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecTestBits vtestop, Vec n :: vs' ->
            Lwt.return
              (try (value_of_bool (Eval_vec.eval_vtestop vtestop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecUnaryBits vunop, Vec n :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_vunop vunop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecBinaryBits vbinop, Vec n2 :: Vec n1 :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_vbinop vbinop n1 n2) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecTernaryBits vternop, Vec v3 :: Vec v2 :: Vec v1 :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_vternop vternop v1 v2 v3) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecSplat splatop, Num n :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_splatop splatop n) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecExtract extractop, Vec v :: vs' ->
            Lwt.return
              (try (Num (Eval_vec.eval_extractop extractop v) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | VecReplace replaceop, Num r :: Vec v :: vs' ->
            Lwt.return
              (try (Vec (Eval_vec.eval_replaceop replaceop v r) :: vs', [])
               with exn -> (vs', [Trapping (numeric_error e.at exn) @@ e.at]))
        | _ ->
            let s1 = string_of_values (List.rev vs) in
            let s2 =
              string_of_value_types (List.map type_of_value (List.rev vs))
            in
            Crash.error
              e.at
              ("missing or ill-typed operand on stack (" ^ s1 ^ " : " ^ s2 ^ ")")
        )
    | Refer r, vs -> Lwt.return (Ref r :: vs, [])
    | Trapping _, _ -> assert false
    | Returning _, _ -> Crash.error e.at "undefined frame"
    | Breaking _, _ -> Crash.error e.at "undefined label"
    | Label (_, _, (vs', [])), vs -> Lwt.return (vs' @ vs, [])
    | Label (_, _, (_, {it = Trapping msg; at} :: _)), vs ->
        Lwt.return (vs, [Trapping msg @@ at])
    | Label (_, _, (_, {it = Returning vs0; at} :: _)), vs ->
        Lwt.return (vs, [Returning vs0 @@ at])
    | Label (n, es0, (_, {it = Breaking (0l, vs0); _} :: _)), vs ->
        Lwt.return (take n vs0 e.at @ vs, List.map plain es0)
    | Label (_, _, (_, {it = Breaking (k, vs0); at} :: _)), vs ->
        Lwt.return (vs, [Breaking (Int32.sub k 1l, vs0) @@ at])
    | Label (n, es0, code'), vs ->
        let+ c' = step module_reg {c with code = code'} in
        (vs, [Label (n, es0, c'.code) @@ e.at])
    | Frame (_, _, (vs', [])), vs -> Lwt.return (vs' @ vs, [])
    | Frame (_, _, (_, {it = Trapping msg; at} :: _)), vs ->
        Lwt.return (vs, [Trapping msg @@ at])
    | Frame (n, _, (_, {it = Returning vs0; _} :: _)), vs ->
        Lwt.return (take n vs0 e.at @ vs, [])
    | Frame (n, frame', code'), vs ->
        let+ c' =
          step
            module_reg
            {
              frame = frame';
              code = code';
              budget = c.budget - 1;
              input = c.input;
              host_funcs = c.host_funcs;
            }
        in
        (vs, [Frame (n, c'.frame, c'.code) @@ e.at])
    | Invoke _, _ when c.budget = 0 ->
        Exhaustion.error e.at "call stack exhausted"
    | Invoke func, vs -> (
        let (FuncType (ins, out)) = func_type_of func in
        let n1, n2 =
          (Instance.Vector.num_elements ins, Instance.Vector.num_elements out)
        in
        let args, vs' = (take n1 vs e.at, drop n1 vs e.at) in
        match func with
        | Func.AstFunc (_, inst', f) ->
            (* TODO: https://gitlab.com/tezos/tezos/-/issues/3366 &
               https://gitlab.com/tezos/tezos/-/issues/3082

               This conversion to list can probably be avoided by using
               Lazy_vector in the config for local variables. *)
            let+ locals = Lazy_vector.Int32Vector.to_list f.it.locals in
            let locals' = List.rev args @ List.map default_value locals in
            let frame' = {inst = inst'; locals = List.map ref locals'} in
            let instr' =
              [
                Label (n2, [], ([], [From_block (f.it.body, 0l) @@ f.at]))
                @@ f.at;
              ]
            in
            (vs', [Frame (n2, frame', ([], instr')) @@ e.at])
        | Func.HostFunc (_, global_name) ->
            Lwt.catch
              (fun () ->
                let (Host_funcs.Host_func f) =
                  Host_funcs.lookup ~global_name c.host_funcs
                in
                let* inst = resolve_module_ref module_reg frame.inst in
                let+ res = f c.input inst (List.rev args) in
                (List.rev res @ vs', []))
              (function
                | Crash (_, msg) -> Crash.error e.at msg | exn -> raise exn))
  in
  {c with code = (vs', es' @ es)}

let rec eval module_reg (c : config) : value stack Lwt.t =
  match c.code with
  | vs, [] -> Lwt.return vs
  | _, {it = Trapping msg; at} :: _ -> Trap.error at msg
  | _, _ ->
      let* c = step module_reg c in
      eval module_reg c

(* Functions & Constants *)

let invoke ~module_reg ~caller ?(input = Input_buffer.alloc ()) host_funcs
    (func : func_inst) (vs : value list) : value list Lwt.t =
  let at = match func with Func.AstFunc (_, _, f) -> f.at | _ -> no_region in
  let (FuncType (ins, _out)) = Func.type_of func in
  let* ins_l = Lazy_vector.Int32Vector.to_list ins in
  if List.length vs <> (Lazy_vector.Int32Vector.num_elements ins |> Int32.to_int)
  then Crash.error at "wrong number of arguments" ;
  (* Invoke is only used to call individual functions from a module,
     and never used by the PVM. Thus is does not need to be
     tickified and going from and to list is acceptable. *)
  if not (List.for_all2 (fun v -> ( = ) (type_of_value v)) vs ins_l) then
    Crash.error at "wrong types of arguments" ;
  let inst =
    match func with
    | Func.AstFunc (_, inst, _) -> inst
    | Func.HostFunc (_, _) -> caller
  in
  let c = config ~input host_funcs inst (List.rev vs) [Invoke func @@ at] in
  Lwt.catch
    (fun () ->
      let+ values = eval module_reg c in
      List.rev values)
    (function
      | Stack_overflow -> Exhaustion.error at "call stack exhausted"
      | exn -> Lwt.fail exn)

let eval_const module_reg (inst : module_key) (const : const) : value Lwt.t =
  let c =
    config (Host_funcs.empty ()) inst [] [From_block (const.it, 0l) @@ const.at]
  in
  let+ vs = eval module_reg c in
  match vs with
  | [v] -> v
  | _ -> Crash.error const.at "wrong number of results on stack"

(* Modules *)

let create_func module_reg (inst_ref : module_key) (f : func) : func_inst Lwt.t
    =
  let* inst = resolve_module_ref module_reg inst_ref in
  let+ type_ = type_ inst f.it.ftype in
  Func.alloc type_ inst_ref f

let create_table (tab : table) : table_inst =
  let {ttype} = tab.it in
  let (TableType (_lim, t)) = ttype in
  Table.alloc ttype (NullRef t)

let create_memory (mem : memory) : memory_inst =
  let {mtype} = mem.it in
  Memory.alloc mtype

let create_global module_reg (inst : module_key) (glob : global) :
    global_inst Lwt.t =
  let {gtype; ginit} = glob.it in
  let+ v = eval_const module_reg inst ginit in
  Global.alloc gtype v

let create_export (inst : module_inst) (ex : export) : export_inst Lwt.t =
  let {name; edesc} = ex.it in
  let+ ext =
    match edesc.it with
    | FuncExport x ->
        let+ func = func inst x in
        ExternFunc func
    | TableExport x ->
        let+ tbl = table inst x in
        ExternTable tbl
    | MemoryExport x ->
        let+ mem = memory inst x in
        ExternMemory mem
    | GlobalExport x ->
        let+ glob = global inst x in
        ExternGlobal glob
  in
  (name, ext)

let create_elem module_reg (inst : module_key) (seg : elem_segment) :
    elem_inst Lwt.t =
  let {einit; _} = seg.it in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/3076
     [einit] should be changed to a lazy structure. We want to avoid traversing
     it whole. *)
  let* einit = Lazy_vector.Int32Vector.to_list einit in
  let+ init =
    TzStdLib.List.map_s
      (fun v ->
        let+ r = eval_const module_reg inst v in
        as_ref r)
      einit
  in
  ref (Instance.Vector.of_list init)

let create_data (seg : data_segment) : data_inst =
  let {dinit; _} = seg.it in
  ref dinit

let add_import (m : module_) (ext : extern) (im : import) (inst : module_inst) :
    module_inst Lwt.t =
  let* t = import_type m im in
  let* type_match = match_extern_type (extern_type_of ext) t in
  let+ () =
    if not type_match then
      let* module_name = Utf8.encode im.it.module_name in
      let+ item_name = Utf8.encode im.it.item_name in
      Link.error
        im.at
        ("incompatible import type for " ^ "\"" ^ module_name ^ "\" " ^ "\""
       ^ item_name ^ "\": " ^ "expected "
        ^ Types.string_of_extern_type t
        ^ ", got "
        ^ Types.string_of_extern_type (extern_type_of ext))
    else Lwt.return_unit
  in
  match ext with
  | ExternFunc func -> {inst with funcs = Vector.cons func inst.funcs}
  | ExternTable tab -> {inst with tables = Vector.cons tab inst.tables}
  | ExternMemory mem -> {inst with memories = Vector.cons mem inst.memories}
  | ExternGlobal glob -> {inst with globals = Vector.cons glob inst.globals}

let run_elem i elem =
  let at = elem.it.emode.at in
  let x = i @@ at in
  match elem.it.emode.it with
  | Passive -> []
  | Active {index; offset} ->
      (From_block (offset.it, 0l) @@ offset.at)
      :: List.map
           plain
           [
             Const (I32 0l @@ at) @@ at;
             Const
               (I32 (Lazy_vector.Int32Vector.num_elements elem.it.einit) @@ at)
             @@ at;
             TableInit (index, x) @@ at;
             ElemDrop x @@ at;
           ]
  | Declarative -> List.map plain [ElemDrop x @@ at]

let run_data (inst : module_inst) i data =
  let at = data.it.dmode.at in
  let x = i @@ at in
  match data.it.dmode.it with
  | Passive -> Lwt.return []
  | Active {index; offset} ->
      assert (index.it = 0l) ;
      let+ data = Ast.get_data data.it.dinit inst.allocations.datas in
      (From_block (offset.it, 0l) @@ offset.at)
      :: List.map
           plain
           [
             Const (I32 0l @@ at) @@ at;
             Const
               (I32
                  (Int32.of_int
                     (Int64.to_int (Chunked_byte_vector.length data)))
               @@ at)
             @@ at;
             MemoryInit x @@ at;
             DataDrop x @@ at;
           ]
  | Declarative -> assert false

let run_start start = [plain (Call start.it.sfunc @@ start.at)]

type ('a, 'b, 'acc) fold_right2_kont = {
  acc : 'acc;
  lv : 'a Vector.t;
  rv : 'b Vector.t;
  offset : int32;
}

let fold_right2_kont (m : module_) acc lv rv =
  if Vector.num_elements lv <> Vector.num_elements rv then
    Link.error m.at "wrong number of imports provided for initialisation"
  else {acc; lv; rv; offset = Int32.pred (Vector.num_elements lv)}

let fold_right2_completed {offset; _} = offset = -1l

let fold_right2_step {acc; lv; rv; offset} f =
  let open Lwt.Syntax in
  let* x = Vector.get offset lv in
  let* y = Vector.get offset rv in
  let+ acc = f x y acc in
  {acc; lv; rv; offset = Int32.pred offset}

type ('a, 'b) map_kont = {
  origin : 'a Vector.t;
  destination : 'b Vector.t;
  offset : int32;
}

let map_kont v =
  {origin = v; destination = Vector.create (Vector.num_elements v); offset = 0l}

let map_completed {origin; offset; _} = offset = Vector.num_elements origin

let map_step {origin; destination; offset} f =
  let open Lwt.Syntax in
  let+ x = Vector.get offset origin in
  let destination = Vector.set offset (f x) destination in
  {origin; destination; offset = Int32.succ offset}

let map_i_step {origin; destination; offset} f =
  let open Lwt.Syntax in
  let+ x = Vector.get offset origin in
  let destination = Vector.set offset (f offset x) destination in
  {origin; destination; offset = Int32.succ offset}

let map_s_step {origin; destination; offset} f =
  let open Lwt.Syntax in
  let* x = Vector.get offset origin in
  let+ y = f x in
  let destination = Vector.set offset y destination in
  {origin; destination; offset = Int32.succ offset}

let map_i_s_step {origin; destination; offset} f =
  let open Lwt.Syntax in
  let* x = Vector.get offset origin in
  let+ y = f offset x in
  let destination = Vector.set offset y destination in
  {origin; destination; offset = Int32.succ offset}

type 'a concat_kont = {
  lv : 'a Vector.t;
  rv : 'a Vector.t;
  res : 'a Vector.t;
  offset : int32;
}

let concat_kont lv rv =
  let lv_len = Vector.num_elements lv in
  let rv_len = Vector.num_elements rv in
  let len = Int32.(add lv_len rv_len) in
  if Int32.(unsigned_compare len lv_len < 0 || unsigned_compare len rv_len < 0)
  then raise Lazy_vector.SizeOverflow
  else {lv; rv; res = Vector.create len; offset = 0l}

let concat_step {lv; rv; res; offset} =
  let lv_len = Vector.num_elements lv in
  let+ x =
    if offset < lv_len then Vector.get offset lv
    else Vector.get Int32.(sub offset lv_len) rv
  in
  {lv; rv; res = Vector.set offset x res; offset = Int32.succ offset}

let concat_completed {lv; rv; offset; _} =
  let lv_len = Vector.num_elements lv in
  let rv_len = Vector.num_elements rv in
  Int32.add lv_len rv_len <= offset

type ('a, 'b) fold_left_kont = {origin : 'a Vector.t; acc : 'b; offset : int32}

let fold_left_kont v acc = {origin = v; acc; offset = 0l}

let fold_left_completed {origin; offset; _} =
  offset = Vector.num_elements origin

let fold_left_s_step {origin; acc; offset} f =
  let open Lwt.Syntax in
  let* x = Vector.get offset origin in
  let+ acc = f acc x in
  {origin; acc; offset = Int32.succ offset}

type (_, _) init_section =
  | Func : (func, func_inst) init_section
  | Global : (global, global_inst) init_section
  | Table : (table, table_inst) init_section
  | Memory : (memory, memory_inst) init_section

let section_fetch_vec :
    type a b. module_inst -> (a, b) init_section -> b Vector.t =
 fun inst sec ->
  match sec with
  | Func -> inst.funcs
  | Global -> inst.globals
  | Table -> inst.tables
  | Memory -> inst.memories

let section_set_vec :
    type a b. module_inst -> (a, b) init_section -> b Vector.t -> module_inst =
 fun inst sec vec ->
  match (sec, vec) with
  | Func, funcs -> {inst with funcs}
  | Global, globals -> {inst with globals}
  | Table, tables -> {inst with tables}
  | Memory, memories -> {inst with memories}

type 'b join_kont =
  | J_Init of 'b Vector.t Vector.t
  | J_Next of 'b concat_kont * 'b Vector.t Vector.t
  | J_Stop of 'b Vector.t

let join_kont vec = J_Init vec

let join_completed = function
  | J_Init v when Vector.num_elements v = 0l -> Some (Vector.create 0l)
  | J_Stop v -> Some v
  | _ -> None

let join_step =
  let open Lwt.Syntax in
  function
  | J_Init v when 1l < Vector.num_elements v ->
      let* x = Vector.get 0l v in
      let v = Vector.pop v in
      let+ y = Vector.get 0l v in
      let v = Vector.pop v in
      J_Next (concat_kont x y, v)
  | J_Init v when Vector.num_elements v = 1l ->
      let+ v = Vector.get 0l v in
      J_Stop v
  | J_Next (tick, acc)
    when concat_completed tick && Vector.num_elements acc = 0l ->
      Lwt.return (J_Stop tick.res)
  | J_Next (tick, acc) when concat_completed tick ->
      let+ x = Vector.get 0l acc in
      let acc = Vector.pop acc in
      J_Next (concat_kont tick.res x, acc)
  | J_Next (tick, acc) ->
      let+ tick = concat_step tick in
      J_Next (tick, acc)
  | J_Init _ ->
      (* [num_elements = 0l], so [join_completed] returns [Some], should not be called in this state *)
      assert false
  | J_Stop _ -> assert false

type ('a, 'b) map_concat_kont =
  | MC_Map of ('a, 'b Vector.t) map_kont
  | MC_Join of 'b join_kont

let map_concat_kont v = MC_Map (map_kont v)

let map_concat_completed = function MC_Join v -> join_completed v | _ -> None

let map_concat_step f = function
  | MC_Map map when map_completed map ->
      Lwt.return (MC_Join (join_kont map.destination))
  | MC_Map map ->
      let+ map = f map in
      MC_Map map
  | MC_Join tick -> (
      match join_completed tick with
      | Some _ ->
          (* [map_concat_completed] would have returned [Some], so
             illegal state to call this function *)
          assert false
      | None ->
          let+ tick = join_step tick in
          MC_Join tick)

type init_kont =
  | IK_Start
  | IK_Add_import of (extern, import, module_inst) fold_right2_kont
  | IK_Type of module_inst * (type_, func_type) map_kont
  | IK_Aggregate :
      module_inst * ('a, 'b) init_section * ('a, 'b) map_kont
      -> init_kont
  | IK_Aggregate_concat :
      module_inst * ('a, 'b) init_section * 'b concat_kont
      -> init_kont
  | IK_Exports of module_inst * (export, extern NameMap.t) fold_left_kont
  | IK_Elems of module_inst * (elem_segment, elem_inst) map_kont
  | IK_Datas of module_inst * (data_segment, data_inst) map_kont
  | IK_Es_elems of module_inst * (elem_segment, admin_instr) map_concat_kont
  | IK_Es_datas of
      module_inst
      * (data_segment, admin_instr) map_concat_kont
      * admin_instr Vector.t
  | IK_Join_admin of module_inst * admin_instr join_kont
  | IK_Eval of module_inst * config
  | IK_Stop of module_inst

let section_next_init_kont :
    type a b. module_ -> module_inst -> (a, b) init_section -> init_kont =
 fun m inst0 sec ->
  match sec with
  | Func -> IK_Aggregate (inst0, Global, map_kont m.it.globals)
  | Global -> IK_Aggregate (inst0, Table, map_kont m.it.tables)
  | Table -> IK_Aggregate (inst0, Memory, map_kont m.it.memories)
  | Memory -> IK_Exports (inst0, fold_left_kont m.it.exports (NameMap.create ()))

let section_step :
    type a b.
    module_inst ModuleMap.t -> module_key -> (a, b) init_section -> a -> b Lwt.t
    =
 fun module_reg self -> function
  | Func -> create_func module_reg self
  | Global -> create_global module_reg self
  | Table -> fun x -> Lwt.return (create_table x)
  | Memory -> fun x -> Lwt.return (create_memory x)

let section_update_module_ref : type a b. (a, b) init_section -> bool = function
  | Func -> true
  | Global -> false
  | Table -> false
  | Memory -> true

let init_step ~module_reg ~self host_funcs (m : module_) (exts : extern list) =
  function
  | IK_Start ->
      (* Initialize as empty module. *)
      update_module_ref module_reg self empty_module_inst ;
      Lwt.return
        (IK_Add_import
           (fold_right2_kont
              m
              empty_module_inst
              (* This is safe as long as we provide an empty list in
                 the PVM. *)
              (Vector.of_list exts)
              m.it.imports))
  | IK_Add_import tick when fold_right2_completed tick ->
      update_module_ref module_reg self tick.acc ;
      Lwt.return (IK_Type (tick.acc, map_kont m.it.types))
  | IK_Add_import tick ->
      let+ tick = fold_right2_step tick (add_import m) in
      IK_Add_import tick
  | IK_Type (inst0, tick) when map_completed tick ->
      let inst0 =
        {inst0 with types = tick.destination; allocations = m.it.allocations}
      in
      update_module_ref module_reg self inst0 ;
      Lwt.return (IK_Aggregate (inst0, Func, map_kont m.it.funcs))
  | IK_Type (inst0, tick) ->
      let+ tick = map_step tick (fun x -> x.it) in
      IK_Type (inst0, tick)
  | IK_Aggregate (inst0, sec, tick) when map_completed tick ->
      Lwt.return
        (IK_Aggregate_concat
           ( inst0,
             sec,
             concat_kont (section_fetch_vec inst0 sec) tick.destination ))
  | IK_Aggregate (inst0, sec, tick) ->
      let+ tick = map_s_step tick (section_step module_reg self sec) in
      IK_Aggregate (inst0, sec, tick)
  | IK_Aggregate_concat (inst0, sec, tick) when concat_completed tick ->
      let inst1 = section_set_vec inst0 sec tick.res in
      if section_update_module_ref sec then
        update_module_ref module_reg self inst1 ;
      Lwt.return (section_next_init_kont m inst1 sec)
  | IK_Aggregate_concat (inst0, sec, tick) ->
      let+ tick = concat_step tick in
      IK_Aggregate_concat (inst0, sec, tick)
  | IK_Exports (inst0, tick) when fold_left_completed tick ->
      let inst0 = {inst0 with exports = tick.acc} in
      Lwt.return (IK_Elems (inst0, map_kont m.it.elems))
  | IK_Exports (inst0, tick) ->
      let+ tick =
        fold_left_s_step tick (fun map export ->
            let* k, v = create_export inst0 export in
            let+ k = Instance.Vector.to_list k in
            NameMap.set k v map)
      in
      IK_Exports (inst0, tick)
  | IK_Elems (inst0, tick) when map_completed tick ->
      let inst0 = {inst0 with elems = tick.destination} in
      Lwt.return (IK_Datas (inst0, map_kont m.it.datas))
  | IK_Elems (inst0, tick) ->
      let+ tick = map_s_step tick (create_elem module_reg self) in
      IK_Elems (inst0, tick)
  | IK_Datas (inst0, tick) when map_completed tick ->
      let inst = {inst0 with datas = tick.destination} in
      update_module_ref module_reg self inst ;
      Lwt.return (IK_Es_elems (inst, map_concat_kont m.it.elems))
  | IK_Datas (inst0, tick) ->
      let+ tick = map_step tick create_data in
      IK_Datas (inst0, tick)
  | IK_Es_elems (inst0, tick) -> (
      match map_concat_completed tick with
      | Some es_elem ->
          Lwt.return (IK_Es_datas (inst0, map_concat_kont m.it.datas, es_elem))
      | None ->
          let+ tick =
            map_concat_step
              (fun tick ->
                map_i_step tick (fun i x -> run_elem i x |> Vector.of_list))
              tick
          in
          IK_Es_elems (inst0, tick))
  | IK_Es_datas (inst0, tick, es_elem) -> (
      match map_concat_completed tick with
      | Some es_data ->
          let es_start =
            Vector.of_list
              (Lib.Option.get (Lib.Option.map run_start m.it.start) [])
          in
          let v = Vector.of_list [es_elem; es_data; es_start] in
          Lwt.return (IK_Join_admin (inst0, join_kont v))
      | None ->
          let+ tick =
            map_concat_step
              (fun tick ->
                map_i_s_step tick (fun i x ->
                    let+ x = run_data inst0 i x in
                    Vector.of_list x))
              tick
          in
          IK_Es_datas (inst0, tick, es_elem))
  | IK_Join_admin (inst0, tick) -> (
      match join_completed tick with
      | Some res ->
          (* TODO: https://gitlab.com/tezos/tezos/-/issues/3076
             [config] should use lazy vector, not lists *)
          let+ res = Vector.to_list res in
          IK_Eval (inst0, config host_funcs self [] res)
      | None ->
          let+ tick = join_step tick in
          IK_Join_admin (inst0, tick))
  | IK_Eval (inst, config) ->
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/3076
         The call to [eval] should be tickify. *)
      let+ (_ : Values.value stack) = eval module_reg config in
      IK_Stop inst
  | IK_Stop _ -> raise (Invalid_argument "init_step")

let init ~module_reg ~self host_funcs (m : module_) (exts : extern list) :
    module_inst Lwt.t =
  let open Lwt.Syntax in
  let rec go = function
    | IK_Stop inst -> Lwt.return inst
    | kont ->
        let* kont = init_step ~module_reg ~self host_funcs m exts kont in
        go kont
  in
  go IK_Start
