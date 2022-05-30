(* Decoding stream *)

type stream =
  {
    name : string;
    bytes : string;
    pos : int ref;
  }

exception EOS

let stream name bs = {name; bytes = bs; pos = ref 0}

let len s = String.length s.bytes
let pos s = !(s.pos)
let eos s = (pos s = len s)

let check n s = if pos s + n > len s then raise EOS
let skip n s = if n < 0 then raise EOS else check n s; s.pos := !(s.pos) + n

let read s = Char.code (s.bytes.[!(s.pos)])
let peek s = if eos s then None else Some (read s)
let get s = check 1 s; let b = read s in skip 1 s; b
let get_string n s = let i = pos s in skip n s; String.sub s.bytes i n


(* Errors *)

module Code = Error.Make ()
exception Code = Code.Error

let string_of_byte b = Printf.sprintf "%02x" b
let string_of_multi n = Printf.sprintf "%02lx" n

let position s pos = Source.({file = s.name; line = -1; column = pos})
let region s left right =
  Source.({left = position s left; right = position s right})

let error s pos msg = raise (Code (region s pos pos, msg))
let require b s pos msg = if not b then error s pos msg

let guard f s =
  try f s with EOS -> error s (len s) "unexpected end of section or function"

let get = guard get
let get_string n = guard (get_string n)
let skip n = guard (skip n)

let expect b s msg = require (guard get s = b) s (pos s - 1) msg
let illegal s pos b = error s pos ("illegal opcode " ^ string_of_byte b)
let illegal2 s pos b n =
  error s pos ("illegal opcode " ^ string_of_byte b ^ " " ^ string_of_multi n)

let at f s =
  let left = pos s in
  let x = f s in
  let right = pos s in
  Source.(x @@ region s left right)



(* Generic values *)

let u8 s =
  get s

let u16 s =
  let lo = u8 s in
  let hi = u8 s in
  hi lsl 8 + lo

let u32 s =
  let lo = Int32.of_int (u16 s) in
  let hi = Int32.of_int (u16 s) in
  Int32.(add lo (shift_left hi 16))

let u64 s =
  let lo = I64_convert.extend_i32_u (u32 s) in
  let hi = I64_convert.extend_i32_u (u32 s) in
  Int64.(add lo (shift_left hi 32))

(* TODO safe? *)
let rec vuN n s =
  require (n > 0) s (pos s) "integer representation too long";
  let b = u8 s in
  require (n >= 7 || b land 0x7f < 1 lsl n) s (pos s - 1) "integer too large";
  let x = Int64.of_int (b land 0x7f) in
  if b land 0x80 = 0 then x else Int64.(logor x (shift_left (vuN (n - 7) s) 7))

(* TODO safe? *)
let rec vsN n s =
  require (n > 0) s (pos s) "integer representation too long";
  let b = u8 s in
  let mask = (-1 lsl (n - 1)) land 0x7f in
  require (n >= 7 || b land mask = 0 || b land mask = mask) s (pos s - 1)
    "integer too large";
  let x = Int64.of_int (b land 0x7f) in
  if b land 0x80 = 0
  then (if b land 0x40 = 0 then x else Int64.(logor x (logxor (-1L) 0x7fL)))
  else Int64.(logor x (shift_left (vsN (n - 7) s) 7))

let vu1 s = Int64.to_int (vuN 1 s)
let vu32 s = Int64.to_int32 (vuN 32 s)
let vs7 s = Int64.to_int (vsN 7 s)
let vs32 s = Int64.to_int32 (vsN 32 s)
let vs33 s = I32_convert.wrap_i64 (vsN 33 s)
let vs64 s = vsN 64 s
let f32 s = F32.of_bits (u32 s)
let f64 s = F64.of_bits (u64 s)
let v128 s = V128.of_bits (get_string (Types.vec_size Types.V128Type) s)

let len32 s =
  let pos = pos s in
  let n = vu32 s in
  if I32.le_u n (Int32.of_int (len s - pos)) then Int32.to_int n else
    error s pos "length out of bounds"

let bool s = (vu1 s = 1)
let string s = let n = len32 s in get_string n s
(* TODO safe? *)
let rec list f n s = if n = 0 then [] else let x = f s in x :: list f (n - 1) s
let opt f b s = if b then Some (f s) else None
let vec f s = let n = len32 s in list f n s

let name s =
  let pos = pos s in
  try Utf8.decode (string s) with Utf8.Utf8 ->
    error s pos "malformed UTF-8 encoding"

let sized f s =
  let size = len32 s in
  let start = pos s in
  let x = f size s in
  require (pos s = start + size) s start "section size mismatch";
  x


(* Types *)

open Types

let num_type s =
  match vs7 s with
  | -0x01 -> I32Type
  | -0x02 -> I64Type
  | -0x03 -> F32Type
  | -0x04 -> F64Type
  | _ -> error s (pos s - 1) "malformed number type"

let vec_type s =
  match vs7 s with
  | -0x05 -> V128Type
  | _ -> error s (pos s - 1) "malformed vector type"

let ref_type s =
  match vs7 s with
  | -0x10 -> FuncRefType
  | -0x11 -> ExternRefType
  | _ -> error s (pos s - 1) "malformed reference type"

let value_type s =
  match peek s with
  | Some n when n >= ((-0x04) land 0x7f) -> NumType (num_type s)
  | Some n when n >= ((-0x0f) land 0x7f) -> VecType (vec_type s)
  | _ -> RefType (ref_type s)

let result_type s = vec value_type s
let func_type s =
  match vs7 s with
  | -0x20 ->
    let ins = result_type s in
    let out = result_type s in
    FuncType (ins, out)
  | v -> error s (pos s - 1) (Format.sprintf "malformed function type: %d" v)

let limits vu s =
  let has_max = bool s in
  let min = vu s in
  let max = opt vu has_max s in
  {min; max}

let table_type s =
  let t = ref_type s in
  let lim = limits vu32 s in
  TableType (lim, t)

let memory_type s =
  let lim = limits vu32 s in
  MemoryType lim

let mutability s =
  match u8 s with
  | 0 -> Immutable
  | 1 -> Mutable
  | _ -> error s (pos s - 1) "malformed mutability"

let global_type s =
  let t = value_type s in
  let mut = mutability s in
  GlobalType (t, mut)


(* Decode instructions *)

open Ast
open Operators

let var s = vu32 s

let op s = u8 s
let end_ s = expect 0x0b s "END opcode expected"
let zero s = expect 0x00 s "zero byte expected"

let memop s =
  let align = vu32 s in
  require (I32.le_u align 32l) s (pos s - 1) "malformed memop flags";
  let offset = vu32 s in
  Int32.to_int align, offset

let block_type s =
  match peek s with
  | Some 0x40 -> skip 1 s; ValBlockType None
  | Some b when b land 0xc0 = 0x40 -> ValBlockType (Some (value_type s))
  | _ -> VarBlockType (at vs33 s)

type instr_block_kont =
  | IK_Stop of instr list
  | IK_Rev of instr list * instr list
  | IK_Next of instr list
  | IK_Block of block_type * int
  | IK_Loop of block_type * int
  | IK_If1 of block_type * int
  | IK_If2 of block_type * int * instr list

let instr s pos tag =
  match tag with
  | 0x02 | 0x03 | 0x04 -> assert false
  | 0x00 -> unreachable
  | 0x01 -> nop

  | 0x05 -> error s pos "misplaced ELSE opcode"
  | 0x06| 0x07 | 0x08 | 0x09 | 0x0a as b -> illegal s pos b
  | 0x0b -> error s pos "misplaced END opcode"

  | 0x0c -> br (at var s)
  | 0x0d -> br_if (at var s)
  | 0x0e ->
    let xs = vec (at var) s in
    let x = at var s in
    br_table xs x
  | 0x0f -> return

  | 0x10 -> call (at var s)
  | 0x11 ->
    let y = at var s in
    let x = at var s in
    call_indirect x y

  | 0x12 | 0x13 | 0x14 | 0x15 | 0x16 | 0x17 | 0x18 | 0x19 as b -> illegal s pos b

  | 0x1a -> drop
  | 0x1b -> select None
  | 0x1c -> select (Some (vec value_type s))

  | 0x1d | 0x1e | 0x1f as b -> illegal s pos b

  | 0x20 -> local_get (at var s)
  | 0x21 -> local_set (at var s)
  | 0x22 -> local_tee (at var s)
  | 0x23 -> global_get (at var s)
  | 0x24 -> global_set (at var s)
  | 0x25 -> table_get (at var s)
  | 0x26 -> table_set (at var s)

  | 0x27 as b -> illegal s pos b

  | 0x28 -> let a, o = memop s in i32_load a o
  | 0x29 -> let a, o = memop s in i64_load a o
  | 0x2a -> let a, o = memop s in f32_load a o
  | 0x2b -> let a, o = memop s in f64_load a o
  | 0x2c -> let a, o = memop s in i32_load8_s a o
  | 0x2d -> let a, o = memop s in i32_load8_u a o
  | 0x2e -> let a, o = memop s in i32_load16_s a o
  | 0x2f -> let a, o = memop s in i32_load16_u a o
  | 0x30 -> let a, o = memop s in i64_load8_s a o
  | 0x31 -> let a, o = memop s in i64_load8_u a o
  | 0x32 -> let a, o = memop s in i64_load16_s a o
  | 0x33 -> let a, o = memop s in i64_load16_u a o
  | 0x34 -> let a, o = memop s in i64_load32_s a o
  | 0x35 -> let a, o = memop s in i64_load32_u a o

  | 0x36 -> let a, o = memop s in i32_store a o
  | 0x37 -> let a, o = memop s in i64_store a o
  | 0x38 -> let a, o = memop s in f32_store a o
  | 0x39 -> let a, o = memop s in f64_store a o
  | 0x3a -> let a, o = memop s in i32_store8 a o
  | 0x3b -> let a, o = memop s in i32_store16 a o
  | 0x3c -> let a, o = memop s in i64_store8 a o
  | 0x3d -> let a, o = memop s in i64_store16 a o
  | 0x3e -> let a, o = memop s in i64_store32 a o

  | 0x3f -> zero s; memory_size
  | 0x40 -> zero s; memory_grow

  | 0x41 -> i32_const (at vs32 s)
  | 0x42 -> i64_const (at vs64 s)
  | 0x43 -> f32_const (at f32 s)
  | 0x44 -> f64_const (at f64 s)

  | 0x45 -> i32_eqz
  | 0x46 -> i32_eq
  | 0x47 -> i32_ne
  | 0x48 -> i32_lt_s
  | 0x49 -> i32_lt_u
  | 0x4a -> i32_gt_s
  | 0x4b -> i32_gt_u
  | 0x4c -> i32_le_s
  | 0x4d -> i32_le_u
  | 0x4e -> i32_ge_s
  | 0x4f -> i32_ge_u

  | 0x50 -> i64_eqz
  | 0x51 -> i64_eq
  | 0x52 -> i64_ne
  | 0x53 -> i64_lt_s
  | 0x54 -> i64_lt_u
  | 0x55 -> i64_gt_s
  | 0x56 -> i64_gt_u
  | 0x57 -> i64_le_s
  | 0x58 -> i64_le_u
  | 0x59 -> i64_ge_s
  | 0x5a -> i64_ge_u

  | 0x5b -> f32_eq
  | 0x5c -> f32_ne
  | 0x5d -> f32_lt
  | 0x5e -> f32_gt
  | 0x5f -> f32_le
  | 0x60 -> f32_ge

  | 0x61 -> f64_eq
  | 0x62 -> f64_ne
  | 0x63 -> f64_lt
  | 0x64 -> f64_gt
  | 0x65 -> f64_le
  | 0x66 -> f64_ge

  | 0x67 -> i32_clz
  | 0x68 -> i32_ctz
  | 0x69 -> i32_popcnt
  | 0x6a -> i32_add
  | 0x6b -> i32_sub
  | 0x6c -> i32_mul
  | 0x6d -> i32_div_s
  | 0x6e -> i32_div_u
  | 0x6f -> i32_rem_s
  | 0x70 -> i32_rem_u
  | 0x71 -> i32_and
  | 0x72 -> i32_or
  | 0x73 -> i32_xor
  | 0x74 -> i32_shl
  | 0x75 -> i32_shr_s
  | 0x76 -> i32_shr_u
  | 0x77 -> i32_rotl
  | 0x78 -> i32_rotr

  | 0x79 -> i64_clz
  | 0x7a -> i64_ctz
  | 0x7b -> i64_popcnt
  | 0x7c -> i64_add
  | 0x7d -> i64_sub
  | 0x7e -> i64_mul
  | 0x7f -> i64_div_s
  | 0x80 -> i64_div_u
  | 0x81 -> i64_rem_s
  | 0x82 -> i64_rem_u
  | 0x83 -> i64_and
  | 0x84 -> i64_or
  | 0x85 -> i64_xor
  | 0x86 -> i64_shl
  | 0x87 -> i64_shr_s
  | 0x88 -> i64_shr_u
  | 0x89 -> i64_rotl
  | 0x8a -> i64_rotr

  | 0x8b -> f32_abs
  | 0x8c -> f32_neg
  | 0x8d -> f32_ceil
  | 0x8e -> f32_floor
  | 0x8f -> f32_trunc
  | 0x90 -> f32_nearest
  | 0x91 -> f32_sqrt
  | 0x92 -> f32_add
  | 0x93 -> f32_sub
  | 0x94 -> f32_mul
  | 0x95 -> f32_div
  | 0x96 -> f32_min
  | 0x97 -> f32_max
  | 0x98 -> f32_copysign

  | 0x99 -> f64_abs
  | 0x9a -> f64_neg
  | 0x9b -> f64_ceil
  | 0x9c -> f64_floor
  | 0x9d -> f64_trunc
  | 0x9e -> f64_nearest
  | 0x9f -> f64_sqrt
  | 0xa0 -> f64_add
  | 0xa1 -> f64_sub
  | 0xa2 -> f64_mul
  | 0xa3 -> f64_div
  | 0xa4 -> f64_min
  | 0xa5 -> f64_max
  | 0xa6 -> f64_copysign

  | 0xa7 -> i32_wrap_i64
  | 0xa8 -> i32_trunc_f32_s
  | 0xa9 -> i32_trunc_f32_u
  | 0xaa -> i32_trunc_f64_s
  | 0xab -> i32_trunc_f64_u
  | 0xac -> i64_extend_i32_s
  | 0xad -> i64_extend_i32_u
  | 0xae -> i64_trunc_f32_s
  | 0xaf -> i64_trunc_f32_u
  | 0xb0 -> i64_trunc_f64_s
  | 0xb1 -> i64_trunc_f64_u
  | 0xb2 -> f32_convert_i32_s
  | 0xb3 -> f32_convert_i32_u
  | 0xb4 -> f32_convert_i64_s
  | 0xb5 -> f32_convert_i64_u
  | 0xb6 -> f32_demote_f64
  | 0xb7 -> f64_convert_i32_s
  | 0xb8 -> f64_convert_i32_u
  | 0xb9 -> f64_convert_i64_s
  | 0xba -> f64_convert_i64_u
  | 0xbb -> f64_promote_f32

  | 0xbc -> i32_reinterpret_f32
  | 0xbd -> i64_reinterpret_f64
  | 0xbe -> f32_reinterpret_i32
  | 0xbf -> f64_reinterpret_i64

  | 0xc0 -> i32_extend8_s
  | 0xc1 -> i32_extend16_s
  | 0xc2 -> i64_extend8_s
  | 0xc3 -> i64_extend16_s
  | 0xc4 -> i64_extend32_s

  | 0xc5 | 0xc6 | 0xc7 | 0xc8 | 0xc9 | 0xca | 0xcb
  | 0xcc | 0xcd | 0xce | 0xcf as b -> illegal s pos b

  | 0xd0 -> ref_null (ref_type s)
  | 0xd1 -> ref_is_null
  | 0xd2 -> ref_func (at var s)

  | 0xfc as b ->
    (match vu32 s with
     | 0x00l -> i32_trunc_sat_f32_s
     | 0x01l -> i32_trunc_sat_f32_u
     | 0x02l -> i32_trunc_sat_f64_s
     | 0x03l -> i32_trunc_sat_f64_u
     | 0x04l -> i64_trunc_sat_f32_s
     | 0x05l -> i64_trunc_sat_f32_u
     | 0x06l -> i64_trunc_sat_f64_s
     | 0x07l -> i64_trunc_sat_f64_u

     | 0x08l ->
       let x = at var s in
       zero s; memory_init x
     | 0x09l -> data_drop (at var s)
     | 0x0al -> zero s; zero s; memory_copy
     | 0x0bl -> zero s; memory_fill

     | 0x0cl ->
       let y = at var s in
       let x = at var s in
       table_init x y
     | 0x0dl -> elem_drop (at var s)
     | 0x0el ->
       let x = at var s in
       let y = at var s in
       table_copy x y
     | 0x0fl -> table_grow (at var s)
     | 0x10l -> table_size (at var s)
     | 0x11l -> table_fill (at var s)

     | n -> illegal2 s pos b n
    )

  | 0xfd ->
    (match vu32 s with
     | 0x00l -> let a, o = memop s in v128_load a o
     | 0x01l -> let a, o = memop s in v128_load8x8_s a o
     | 0x02l -> let a, o = memop s in v128_load8x8_u a o
     | 0x03l -> let a, o = memop s in v128_load16x4_s a o
     | 0x04l -> let a, o = memop s in v128_load16x4_u a o
     | 0x05l -> let a, o = memop s in v128_load32x2_s a o
     | 0x06l -> let a, o = memop s in v128_load32x2_u a o
     | 0x07l -> let a, o = memop s in v128_load8_splat a o
     | 0x08l -> let a, o = memop s in v128_load16_splat a o
     | 0x09l -> let a, o = memop s in v128_load32_splat a o
     | 0x0al -> let a, o = memop s in v128_load64_splat a o
     | 0x0bl -> let a, o = memop s in v128_store a o
     | 0x0cl -> v128_const (at v128 s)
     | 0x0dl -> i8x16_shuffle (List.init 16 (fun x -> u8 s))
     | 0x0el -> i8x16_swizzle
     | 0x0fl -> i8x16_splat
     | 0x10l -> i16x8_splat
     | 0x11l -> i32x4_splat
     | 0x12l -> i64x2_splat
     | 0x13l -> f32x4_splat
     | 0x14l -> f64x2_splat
     | 0x15l -> let i = u8 s in i8x16_extract_lane_s i
     | 0x16l -> let i = u8 s in i8x16_extract_lane_u i
     | 0x17l -> let i = u8 s in i8x16_replace_lane i
     | 0x18l -> let i = u8 s in i16x8_extract_lane_s i
     | 0x19l -> let i = u8 s in i16x8_extract_lane_u i
     | 0x1al -> let i = u8 s in i16x8_replace_lane i
     | 0x1bl -> let i = u8 s in i32x4_extract_lane i
     | 0x1cl -> let i = u8 s in i32x4_replace_lane i
     | 0x1dl -> let i = u8 s in i64x2_extract_lane i
     | 0x1el -> let i = u8 s in i64x2_replace_lane i
     | 0x1fl -> let i = u8 s in f32x4_extract_lane i
     | 0x20l -> let i = u8 s in f32x4_replace_lane i
     | 0x21l -> let i = u8 s in f64x2_extract_lane i
     | 0x22l -> let i = u8 s in f64x2_replace_lane i
     | 0x23l -> i8x16_eq
     | 0x24l -> i8x16_ne
     | 0x25l -> i8x16_lt_s
     | 0x26l -> i8x16_lt_u
     | 0x27l -> i8x16_gt_s
     | 0x28l -> i8x16_gt_u
     | 0x29l -> i8x16_le_s
     | 0x2al -> i8x16_le_u
     | 0x2bl -> i8x16_ge_s
     | 0x2cl -> i8x16_ge_u
     | 0x2dl -> i16x8_eq
     | 0x2el -> i16x8_ne
     | 0x2fl -> i16x8_lt_s
     | 0x30l -> i16x8_lt_u
     | 0x31l -> i16x8_gt_s
     | 0x32l -> i16x8_gt_u
     | 0x33l -> i16x8_le_s
     | 0x34l -> i16x8_le_u
     | 0x35l -> i16x8_ge_s
     | 0x36l -> i16x8_ge_u
     | 0x37l -> i32x4_eq
     | 0x38l -> i32x4_ne
     | 0x39l -> i32x4_lt_s
     | 0x3al -> i32x4_lt_u
     | 0x3bl -> i32x4_gt_s
     | 0x3cl -> i32x4_gt_u
     | 0x3dl -> i32x4_le_s
     | 0x3el -> i32x4_le_u
     | 0x3fl -> i32x4_ge_s
     | 0x40l -> i32x4_ge_u
     | 0x41l -> f32x4_eq
     | 0x42l -> f32x4_ne
     | 0x43l -> f32x4_lt
     | 0x44l -> f32x4_gt
     | 0x45l -> f32x4_le
     | 0x46l -> f32x4_ge
     | 0x47l -> f64x2_eq
     | 0x48l -> f64x2_ne
     | 0x49l -> f64x2_lt
     | 0x4al -> f64x2_gt
     | 0x4bl -> f64x2_le
     | 0x4cl -> f64x2_ge
     | 0x4dl -> v128_not
     | 0x4el -> v128_and
     | 0x4fl -> v128_andnot
     | 0x50l -> v128_or
     | 0x51l -> v128_xor
     | 0x52l -> v128_bitselect
     | 0x53l -> v128_any_true
     | 0x54l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_load8_lane a o lane
     | 0x55l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_load16_lane a o lane
     | 0x56l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_load32_lane a o lane
     | 0x57l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_load64_lane a o lane
     | 0x58l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_store8_lane a o lane
     | 0x59l ->
       let a, o = memop s in
       let lane = u8 s in
       v128_store16_lane a o lane
     | 0x5al ->
       let a, o = memop s in
       let lane = u8 s in
       v128_store32_lane a o lane
     | 0x5bl ->
       let a, o = memop s in
       let lane = u8 s in
       v128_store64_lane a o lane
     | 0x5cl -> let a, o = memop s in v128_load32_zero a o
     | 0x5dl -> let a, o = memop s in v128_load64_zero a o
     | 0x5el -> f32x4_demote_f64x2_zero
     | 0x5fl -> f64x2_promote_low_f32x4
     | 0x60l -> i8x16_abs
     | 0x61l -> i8x16_neg
     | 0x62l -> i8x16_popcnt
     | 0x63l -> i8x16_all_true
     | 0x64l -> i8x16_bitmask
     | 0x65l -> i8x16_narrow_i16x8_s
     | 0x66l -> i8x16_narrow_i16x8_u
     | 0x67l -> f32x4_ceil
     | 0x68l -> f32x4_floor
     | 0x69l -> f32x4_trunc
     | 0x6al -> f32x4_nearest
     | 0x6bl -> i8x16_shl
     | 0x6cl -> i8x16_shr_s
     | 0x6dl -> i8x16_shr_u
     | 0x6el -> i8x16_add
     | 0x6fl -> i8x16_add_sat_s
     | 0x70l -> i8x16_add_sat_u
     | 0x71l -> i8x16_sub
     | 0x72l -> i8x16_sub_sat_s
     | 0x73l -> i8x16_sub_sat_u
     | 0x74l -> f64x2_ceil
     | 0x75l -> f64x2_floor
     | 0x76l -> i8x16_min_s
     | 0x77l -> i8x16_min_u
     | 0x78l -> i8x16_max_s
     | 0x79l -> i8x16_max_u
     | 0x7al -> f64x2_trunc
     | 0x7bl -> i8x16_avgr_u
     | 0x7cl -> i16x8_extadd_pairwise_i8x16_s
     | 0x7dl -> i16x8_extadd_pairwise_i8x16_u
     | 0x7el -> i32x4_extadd_pairwise_i16x8_s
     | 0x7fl -> i32x4_extadd_pairwise_i16x8_u
     | 0x80l -> i16x8_abs
     | 0x81l -> i16x8_neg
     | 0x82l -> i16x8_q15mulr_sat_s
     | 0x83l -> i16x8_all_true
     | 0x84l -> i16x8_bitmask
     | 0x85l -> i16x8_narrow_i32x4_s
     | 0x86l -> i16x8_narrow_i32x4_u
     | 0x87l -> i16x8_extend_low_i8x16_s
     | 0x88l -> i16x8_extend_high_i8x16_s
     | 0x89l -> i16x8_extend_low_i8x16_u
     | 0x8al -> i16x8_extend_high_i8x16_u
     | 0x8bl -> i16x8_shl
     | 0x8cl -> i16x8_shr_s
     | 0x8dl -> i16x8_shr_u
     | 0x8el -> i16x8_add
     | 0x8fl -> i16x8_add_sat_s
     | 0x90l -> i16x8_add_sat_u
     | 0x91l -> i16x8_sub
     | 0x92l -> i16x8_sub_sat_s
     | 0x93l -> i16x8_sub_sat_u
     | 0x94l -> f64x2_nearest
     | 0x95l -> i16x8_mul
     | 0x96l -> i16x8_min_s
     | 0x97l -> i16x8_min_u
     | 0x98l -> i16x8_max_s
     | 0x99l -> i16x8_max_u
     | 0x9bl -> i16x8_avgr_u
     | 0x9cl -> i16x8_extmul_low_i8x16_s
     | 0x9dl -> i16x8_extmul_high_i8x16_s
     | 0x9el -> i16x8_extmul_low_i8x16_u
     | 0x9fl -> i16x8_extmul_high_i8x16_u
     | 0xa0l -> i32x4_abs
     | 0xa1l -> i32x4_neg
     | 0xa3l -> i32x4_all_true
     | 0xa4l -> i32x4_bitmask
     | 0xa7l -> i32x4_extend_low_i16x8_s
     | 0xa8l -> i32x4_extend_high_i16x8_s
     | 0xa9l -> i32x4_extend_low_i16x8_u
     | 0xaal -> i32x4_extend_high_i16x8_u
     | 0xabl -> i32x4_shl
     | 0xacl -> i32x4_shr_s
     | 0xadl -> i32x4_shr_u
     | 0xael -> i32x4_add
     | 0xb1l -> i32x4_sub
     | 0xb5l -> i32x4_mul
     | 0xb6l -> i32x4_min_s
     | 0xb7l -> i32x4_min_u
     | 0xb8l -> i32x4_max_s
     | 0xb9l -> i32x4_max_u
     | 0xbal -> i32x4_dot_i16x8_s
     | 0xbcl -> i32x4_extmul_low_i16x8_s
     | 0xbdl -> i32x4_extmul_high_i16x8_s
     | 0xbel -> i32x4_extmul_low_i16x8_u
     | 0xbfl -> i32x4_extmul_high_i16x8_u
     | 0xc0l -> i64x2_abs
     | 0xc1l -> i64x2_neg
     | 0xc3l -> i64x2_all_true
     | 0xc4l -> i64x2_bitmask
     | 0xc7l -> i64x2_extend_low_i32x4_s
     | 0xc8l -> i64x2_extend_high_i32x4_s
     | 0xc9l -> i64x2_extend_low_i32x4_u
     | 0xcal -> i64x2_extend_high_i32x4_u
     | 0xcbl -> i64x2_shl
     | 0xccl -> i64x2_shr_s
     | 0xcdl -> i64x2_shr_u
     | 0xcel -> i64x2_add
     | 0xd1l -> i64x2_sub
     | 0xd5l -> i64x2_mul
     | 0xd6l -> i64x2_eq
     | 0xd7l -> i64x2_ne
     | 0xd8l -> i64x2_lt_s
     | 0xd9l -> i64x2_gt_s
     | 0xdal -> i64x2_le_s
     | 0xdbl -> i64x2_ge_s
     | 0xdcl -> i64x2_extmul_low_i32x4_s
     | 0xddl -> i64x2_extmul_high_i32x4_s
     | 0xdel -> i64x2_extmul_low_i32x4_u
     | 0xdfl -> i64x2_extmul_high_i32x4_u
     | 0xe0l -> f32x4_abs
     | 0xe1l -> f32x4_neg
     | 0xe3l -> f32x4_sqrt
     | 0xe4l -> f32x4_add
     | 0xe5l -> f32x4_sub
     | 0xe6l -> f32x4_mul
     | 0xe7l -> f32x4_div
     | 0xe8l -> f32x4_min
     | 0xe9l -> f32x4_max
     | 0xeal -> f32x4_pmin
     | 0xebl -> f32x4_pmax
     | 0xecl -> f64x2_abs
     | 0xedl -> f64x2_neg
     | 0xefl -> f64x2_sqrt
     | 0xf0l -> f64x2_add
     | 0xf1l -> f64x2_sub
     | 0xf2l -> f64x2_mul
     | 0xf3l -> f64x2_div
     | 0xf4l -> f64x2_min
     | 0xf5l -> f64x2_max
     | 0xf6l -> f64x2_pmin
     | 0xf7l -> f64x2_pmax
     | 0xf8l -> i32x4_trunc_sat_f32x4_s
     | 0xf9l -> i32x4_trunc_sat_f32x4_u
     | 0xfal -> f32x4_convert_i32x4_s
     | 0xfbl -> f32x4_convert_i32x4_u
     | 0xfcl -> i32x4_trunc_sat_f64x2_s_zero
     | 0xfdl -> i32x4_trunc_sat_f64x2_u_zero
     | 0xfel -> f64x2_convert_low_i32x4_s
     | 0xffl -> f64x2_convert_low_i32x4_u
     | n -> illegal s pos (I32.to_int_u n)
    )

  | b -> illegal s pos b

let instr_block_step s cont =
  match cont with
  | IK_Stop res :: [] -> invalid_arg "instr_block"
  | IK_Stop res :: IK_Block (bt, pos) :: IK_Next es :: rest ->
    end_ s;
    let e = Source.(block bt res @@ region s pos pos) in
    IK_Next (e :: es) :: rest
  | IK_Stop res :: IK_Loop (bt, pos) :: IK_Next es :: rest ->
    end_ s;
    let e = Source.(loop bt res @@ region s pos pos) in
    IK_Next (e :: es) :: rest
  | IK_Stop res :: IK_If1 (bt, pos) :: IK_Next es :: rest ->
    if peek s = Some 0x05 then begin
      skip 1 s ;
      IK_Next [] :: IK_If2 (bt, pos, res) :: IK_Next es :: rest
    end else begin
      end_ s;
      let e = Source.(if_ bt res [] @@ region s pos pos) in
      IK_Next (e :: es) :: rest
    end
  | IK_Stop res2 :: IK_If2 (bt, pos, res1) :: IK_Next es :: rest ->
    end_ s;
    let e = Source.(if_ bt res1 res2 @@ region s pos pos) in
    IK_Next (e :: es) :: rest
  | IK_Rev ([], es) :: ks -> IK_Stop es :: ks
  | IK_Rev (e :: rest, es) :: ks -> IK_Rev (rest, e :: es) :: ks
  | IK_Next es :: ks ->
    (match peek s with
     | None | Some (0x05 | 0x0b) -> IK_Rev (es, []) :: ks
     | _ ->
       let pos = pos s in
       let tag = op s in
       match tag with
       | 0x02 ->
         let bt = block_type s in
         IK_Next [] :: IK_Block (bt, pos) :: IK_Next es :: ks
       | 0x03 ->
         let bt = block_type s in
         IK_Next [] :: IK_Loop (bt, pos) :: IK_Next es :: ks
       | 0x04 ->
         let bt = block_type s in
         IK_Next [] :: IK_If1 (bt, pos) :: IK_Next es :: ks
       | _ ->
         let e = instr s pos tag in
         let es = Source.(e @@ region s pos pos) :: es in
         IK_Next es :: ks)
  | _ -> assert false

let instr_block s =
  (* TODO Safe? *)
  let rec loop  = function
    | [ IK_Stop res ] -> res
    | k -> loop (instr_block_step s k) in
  loop [IK_Next []]

let const s =
  let c = at instr_block s in
  end_ s;
  c


(* Sections *)

let id s =
  let bo = peek s in
  Lib.Option.map
    (function
      | 0 -> `CustomSection
      | 1 -> `TypeSection
      | 2 -> `ImportSection
      | 3 -> `FuncSection
      | 4 -> `TableSection
      | 5 -> `MemorySection
      | 6 -> `GlobalSection
      | 7 -> `ExportSection
      | 8 -> `StartSection
      | 9 -> `ElemSection
      | 10 -> `CodeSection
      | 11 -> `DataSection
      | 12 -> `DataCountSection
      | _ -> error s (pos s) "malformed section id"
    ) bo

let section_with_size tag f default s =
  match id s with
  | Some tag' when tag' = tag -> ignore (u8 s); sized f s
  | _ -> default

let section tag f default s =
  section_with_size tag (fun _ -> f) default s


(* Type section *)

let type_ s = at func_type s

let _type_section s =
  section `TypeSection (vec type_) [] s


(* Import section *)

let import_desc s =
  match u8 s with
  | 0x00 -> FuncImport (at var s)
  | 0x01 -> TableImport (table_type s)
  | 0x02 -> MemoryImport (memory_type s)
  | 0x03 -> GlobalImport (global_type s)
  | _ -> error s (pos s - 1) "malformed import kind"

let import s =
  let module_name = name s in
  let item_name = name s in
  let idesc = at import_desc s in
  {module_name; item_name; idesc}

let _import_section s =
  section `ImportSection (vec (at import)) [] s


(* Function section *)

let _func_section s =
  section `FuncSection (vec (at var)) [] s


(* Table section *)

let table s =
  let ttype = table_type s in
  {ttype}

let _table_section s =
  section `TableSection (vec (at table)) [] s


(* Memory section *)

let memory s =
  let mtype = memory_type s in
  {mtype}

let _memory_section s =
  section `MemorySection (vec (at memory)) [] s


(* Global section *)

let global s =
  let gtype = global_type s in
  let ginit = const s in
  {gtype; ginit}

let _global_section s =
  section `GlobalSection (vec (at global)) [] s


(* Export section *)

let export_desc s =
  match u8 s with
  | 0x00 -> FuncExport (at var s)
  | 0x01 -> TableExport (at var s)
  | 0x02 -> MemoryExport (at var s)
  | 0x03 -> GlobalExport (at var s)
  | _ -> error s (pos s - 1) "malformed export kind"

let export s =
  let name = name s in
  let edesc = at export_desc s in
  {name; edesc}

let _export_section s =
  section `ExportSection (vec (at export)) [] s


(* Start section *)

let start s =
  let sfunc = at var s in
  {sfunc}

let start_section s =
  section `StartSection (opt (at start) true) None s


(* Code section *)

let local s =
  let n = vu32 s in
  let t = value_type s in
  n, t

let code _ s =
  let pos = pos s in
  let nts = vec local s in
  (* TODO is List. stuff safe? *)
  let ns = List.map (fun (n, _) -> I64_convert.extend_i32_u n) nts in
  require (I64.lt_u (List.fold_left I64.add 0L ns) 0x1_0000_0000L)
    s pos "too many locals";
  let locals = List.flatten (List.map (Lib.Fun.uncurry Lib.List32.make) nts) in
  let body = instr_block s in
  end_ s;
  {locals; body; ftype = Source.((-1l) @@ Source.no_region)}

type ('a, 'b) vec_map_kont = Collect of int * 'a list | Rev of 'a list * 'b list

type 'a vec_kont = ('a, 'a) vec_map_kont

type pos = int

type size = { size: int; start: pos}

type code_kont =
  | CK_Start
  | CK_Locals of
      { left: pos;
        size : size;
        pos : pos;
        vec_kont: (int32 * value_type, value_type) vec_map_kont;
        locals_size: Int64.t;
      }
  | CK_Body of
      { left: pos;
        size : size;
        locals: value_type list;
        const_kont: instr_block_kont list;
      }
  | CK_Stop of func

(* Originaly `sized` split in two *)
let size s =
  let size = len32 s in
  let start = pos s in
  { size; start }

let check_size { size; start } s =
  require (pos s = start + size) s start "section size mismatch"


let at' left s x =
  let right = pos s in
  Source.(x @@ region s left right)


let code_step s = function
  | CK_Start ->
    (* `at` left *)
    let left = pos s in
    let size = size s in
    let pos = pos s in
    (* `vec` size *)
    let n = len32 s in
    CK_Locals {
      left;
      size;
      pos;
      vec_kont = Collect (n, []);
      locals_size = 0L;
    }

  | CK_Locals { left; size; pos; vec_kont = Collect (0, l); locals_size; } ->
    require (I64.lt_u locals_size 0x1_0000_0000L)
      s pos "too many locals";
    CK_Locals { left; size; pos; vec_kont = Rev (l, []); locals_size; }
  | CK_Locals { left; size; pos; vec_kont =  Collect (n, l); locals_size; } ->
    let local = local s in (* small enough to fit in a tick *)
    let locals_size =
      I64.add locals_size (I64_convert.extend_i32_u (fst local)) in
    CK_Locals
      { left; size; pos; vec_kont = Collect (n - 1, local :: l); locals_size; }

  | CK_Locals
      { left; size; pos; vec_kont = Rev ([], locals);
        locals_size; }->
    CK_Body { left; size; locals; const_kont = [ IK_Next [] ] }
  | CK_Locals
      { left; size; pos; vec_kont = Rev ((0l, t) :: l, l'); locals_size } ->
    CK_Locals { left; size; pos; vec_kont = Rev (l, l'); locals_size; }
  | CK_Locals
      { left; size; pos; vec_kont = Rev ((n, t) :: l, l'); locals_size; } ->
    let n' = I32.sub n 1l in
    CK_Locals
      { left; size; pos; vec_kont = Rev ((n', t) :: l, t :: l'); locals_size; }


  | CK_Body { left; size; locals; const_kont = [ IK_Stop body ] } ->
    end_ s;
    check_size size s;
    let func =
      at' left s @@ {locals; body; ftype = Source.((-1l) @@ Source.no_region)} in
    CK_Stop func
  | CK_Body { left; size; locals; const_kont } ->
    CK_Body { left; size; locals; const_kont = instr_block_step s const_kont }

  | CK_Stop _ -> assert false (* final step, cannot reduce *)

let _code_section s =
  section `CodeSection (vec (at (sized code))) [] s


(* Element section *)

let passive s =
  Passive

let active s =
  let index = at var s in
  let offset = const s in
  Active {index; offset}

let active_zero s =
  let index = Source.(0l @@ Source.no_region) in
  let offset = const s in
  Active {index; offset}

let declarative s =
  Declarative

let elem_index s =
  let x = at var s in
  [Source.(ref_func x @@ x.at)]

let elem_kind s =
  match u8 s with
  | 0x00 -> FuncRefType
  | _ -> error s (pos s - 1) "malformed element kind"

let elem s =
  match vu32 s with
  | 0x00l ->
    let emode = at active_zero s in
    let einit = vec (at elem_index) s in
    {etype = FuncRefType; einit; emode}
  | 0x01l ->
    let emode = at passive s in
    let etype = elem_kind s in
    let einit = vec (at elem_index) s in
    {etype; einit; emode}
  | 0x02l ->
    let emode = at active s in
    let etype = elem_kind s in
    let einit = vec (at elem_index) s in
    {etype; einit; emode}
  | 0x03l ->
    let emode = at declarative s in
    let etype = elem_kind s in
    let einit = vec (at elem_index) s in
    {etype; einit; emode}
  | 0x04l ->
    let emode = at active_zero s in
    let einit = vec const s in
    {etype = FuncRefType; einit; emode}
  | 0x05l ->
    let emode = at passive s in
    let etype = ref_type s in
    let einit = vec const s in
    {etype; einit; emode}
  | 0x06l ->
    let emode = at active s in
    let etype = ref_type s in
    let einit = vec const s in
    {etype; einit; emode}
  | 0x07l ->
    let emode = at declarative s in
    let etype = ref_type s in
    let einit = vec const s in
    {etype; einit; emode}
  | _ -> error s (pos s - 1) "malformed elements segment kind"

type ref_index = Indexed | Const

type elem_kont =
  | EK_Start
  | EK_Mode of int32 Source.phrase * ref_index * ref_type option * instr_block_kont list
  | EK_Init_indexed of segment_mode' * ref_type * const vec_kont
  | EK_Init_const of segment_mode' * ref_type * const vec_kont * instr_block_kont list
  | EK_Stop of elem_segment'

let ek_start s =
  let v = vu32 s in
  match v with
  | 0x00l ->
    (* active_zero *)
    let index = Source.(0l @@ Source.no_region) in
    EK_Mode (index, Indexed, Some FuncRefType, (IK_Next []) :: [])
  | 0x01l ->
    (* passive *)
    let ref_type = elem_kind s in
    let n = len32 s in
    EK_Init_indexed (Passive, ref_type, Collect (n, []))
  | 0x02l ->
    (* active *)
    let index = at var s in
    EK_Mode (index, Indexed, None, (IK_Next []) :: [])
  | 0x03l ->
    (* declarative *)
    let ref_type = elem_kind s in
    let n = len32 s in
    EK_Init_indexed (Declarative, ref_type, Collect (n,  []))
  | 0x04l ->
    (* active_zero *)
    let index = Source.(0l @@ Source.no_region) in
    EK_Mode (index, Const, Some FuncRefType, (IK_Next []) :: [])
  | 0x05l ->
    (* passive *)
    let ref_type = ref_type s in
    let n = len32 s in
    (* Format.printf "Length of vec: %d\n%!" n; *)
    EK_Init_const (Passive, ref_type, Collect (n, []),  IK_Next [] ::  [])
  | 0x06l ->
    (* active *)
    let index = at var s in
    EK_Mode (index, Const, None, (IK_Next []) :: [])
  | 0x07l ->
    (* declarative *)
    let ref_type = ref_type s in
    let n = len32 s in
    EK_Init_const (Declarative, ref_type, Collect (n, []), IK_Next [] ::  [])
  | _ -> error s (pos s - 1) "malformed elements segment kind"

let elem_step : stream -> elem_kont -> elem_kont  =
  function s ->
  function
  | EK_Start -> ek_start s
  | EK_Mode (index, ref_index, ref_type_opt, [IK_Stop offset]) ->
    end_ s;
    let offset = Source.(offset @@ no_region) in (* locations lost *)
    let ref_type =
      match ref_type_opt with
      | Some t -> t
      | None -> if ref_index = Indexed then elem_kind s else ref_type s
    in
    (* `vec` size *)
    let n = len32 s in
    if ref_index = Indexed then
      EK_Init_indexed
        (Active {index; offset},
         ref_type,
         Collect (n, []))
    else
      EK_Init_const
        (Active {index; offset},
         ref_type,
         Collect (n, []),
         IK_Next [] :: [])
  | EK_Mode (index, ref_index, ref_type, k) ->
    EK_Mode (index, ref_index, ref_type, instr_block_step s k)

  (* COLLECT Indexed *)
  | EK_Init_indexed (emode, etype, Collect(0, l)) ->
    EK_Init_indexed (emode, etype, Rev(l, []))
  | EK_Init_indexed (emode, etype, Collect(n, l)) ->
    let elem_index = Source.(elem_index s @@ no_region) in (* locations lost *)
    EK_Init_indexed (emode, etype, Collect(n-1, elem_index :: l))

  (* COLLECT CONST *)
  | EK_Init_const (emode, etype, Collect(0, l), _) ->
    EK_Init_const (emode, etype, Rev(l, []), [])
  | EK_Init_const (emode, etype, Collect(n, l), [ IK_Stop einit ]) ->
    end_ s;
    let einit = Source.(einit @@ no_region) in (* locations lost *)
    EK_Init_const (emode, etype, Collect(n-1, einit :: l), [IK_Next []])

  | EK_Init_const (emode, etype, Collect(n, l), instr_kont) ->
    let instr_kont' = instr_block_step s instr_kont in
    EK_Init_const (emode, etype, Collect(n, l), instr_kont')

  (* REV *)
  | EK_Init_const (emode, etype, Rev ([], einit), _)
  | EK_Init_indexed (emode, etype, Rev ([], einit)) ->
    let emode = Source.(emode @@ no_region) in
    EK_Stop {etype; einit; emode}
  | EK_Init_const (emode, etype, Rev (c :: l, l'), instr_kont) ->
    EK_Init_const (emode, etype, Rev (l, c :: l'), instr_kont)
  | EK_Init_indexed (emode, etype, Rev (c :: l, l')) ->
    EK_Init_indexed (emode, etype, Rev (l, c :: l'))

  | EK_Stop _  -> assert false (* Final step, cannot reduce *)


let _elem_section s =
  section `ElemSection (vec (at elem)) [] s


(* Data section *)

let data s =
  match vu32 s with
  | 0x00l ->
    let dmode = at active_zero s in
    let dinit = string s in
    {dinit; dmode}
  | 0x01l ->
    let dmode = at passive s in
    let dinit = string s in
    {dinit; dmode}
  | 0x02l ->
    let dmode = at active s in
    let dinit = string s in
    {dinit; dmode}
  | _ -> error s (pos s - 1) "malformed data segment kind"

type data_kont =
  | DK_Start
  | DK_Mode of int32 Source.phrase * instr_block_kont list
  | DK_Stop of data_segment'

let data_start s =
  match vu32 s with
  | 0x00l ->
    (* active_zero *)
    let index = Source.(0l @@ Source.no_region) in
    DK_Mode (index, (IK_Next []) :: [])
  | 0x01l ->
    (* passive *)
    let dinit = string s in
    let dmode = Source.(Passive @@ no_region) in
    DK_Stop {dmode; dinit}
  | 0x02l ->
    (* active *)
    let index = at var s in
    DK_Mode (index, (IK_Next []) :: [])
  | _ -> error s (pos s - 1) "malformed data segment kind"

let data_step s =
  function
  | DK_Start -> data_start s
  | DK_Mode (index, [ IK_Stop offset ]) ->
    end_ s;
    let offset = Source.(offset @@ no_region) in (* locations lost *)
    let dmode = Source.(Active {index; offset} @@ no_region) in
    let dinit = string s in
    DK_Stop {dmode; dinit}
  | DK_Mode (index, instr_kont) ->
    DK_Mode (index, instr_block_step s instr_kont)
  | DK_Stop _ -> assert false (* final step, cannot reduce *)

let _data_section s =
  section `DataSection (vec (at data)) [] s


(* DataCount section *)

let data_count s =
  Some (vu32 s)

let data_count_section s =
  section `DataCountSection data_count None s


(* Custom section *)

let custom size s =
  let start = pos s in
  let id = name s in
  let bs = get_string (size - (pos s - start)) s in
  Some (id, bs)

let custom_section s =
  section_with_size `CustomSection custom None s

let non_custom_section s =
  match id s with
  | None | Some `CustomSection -> None
  | _ -> skip 1 s; sized skip s; Some ()


(* Modules *)

let magic = 0x6d736100l

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

type field =
  | Vec_field : 'a field_type * 'a list -> field
  | Single_field : 'a field_type * 'a option -> field

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

type module_kont =
  (* Yield the given module*)
  | MK_Stop of module_' (* TODO: actually, should be module_ *)
  (* Start parsing a module *)
  | MK_Start
  (* Build a module with the given fields *)
  | MK_Next of field list
  (* Skip n>0 custom sections *)
  | MK_Skip_custom

  (* TODO ?? *)
  | MK_Field_collect : 'a field_type * size * int * 'a list -> module_kont
  | MK_Field_rev : 'a field_type * size * 'a list * 'a list -> module_kont
  | MK_Field : 'a field_type * section_tag -> module_kont

  | MK_Global of global_type * int * instr_block_kont list

  | MK_Elem of elem_kont * int
  | MK_Data of data_kont * int
  | MK_Code of code_kont * int

(*
 TODO this is small step, but is the tree modification actually bounded?

 Need to check both lookahead (e.g. that stream reads don't explode)
 and module updates.

 TODO what is actually in the official test suite?

 TODO wrap this into something that
    1) lazily reads stream/kont from a tree
    2) lazily updates a tree with the updated stream state/new kont
 *)
let step : stream -> module_kont list -> module_kont list =
    function s -> (
    function
    | MK_Start :: []  ->
      (* Module header *)
      let header = u32 s in
      require (header = magic) s 0 "magic header not detected";
      let version = u32 s in
      require (version = Encode.version) s 4 "unknown binary version";
      (* Module header *)
      MK_Skip_custom
      :: MK_Field (TypeField,`TypeSection)
      :: MK_Next []

    | MK_Skip_custom :: ks ->
      (match id s with
       | Some `CustomSection ->
         (* section_with_size *)
         ignore (u8 s);
         (* sized *)
         let l = len32 s in
         (* custom *)
         let start = pos s in
         let _id = name s in
         let _bs = get_string (l - (pos s - start)) s in
         MK_Skip_custom :: ks
       | _ ->
         (* Format.printf "No custom section\n%!";  *)ks)

    | MK_Field (DataCountField, `DataCountSection) :: MK_Next fields :: [] ->
      let v = data_count_section s in
      MK_Skip_custom
      :: MK_Field (CodeField, `CodeSection)
      :: MK_Next (Single_field (DataCountField, v) :: fields) :: []

    | MK_Field (StartField, `StartSection) :: MK_Next fields :: [] ->
      let v = start_section s in
      MK_Skip_custom
      :: MK_Field (ElemField, `ElemSection)
      :: MK_Next (Single_field (StartField, v) :: fields) :: []

    | MK_Field (ty, tag) :: (MK_Next fields :: [] as rest) ->
      (match id s with
       | Some t when t = tag->
         ignore (u8 s);
         let size = size s in
         (* length of `vec` *)
         let l = len32 s in
         MK_Field_collect (ty, size, l, []) :: rest
       | _ ->
         let size = { size = 0; start = pos s } in
         MK_Field_rev (ty, size, [], []) :: rest)
    | MK_Field_collect (ty, size, 0, l) :: (MK_Next _ :: [] as rest) ->
      MK_Field_rev (ty, size, [], l) :: rest
    | MK_Field_collect (ty, size, n, l) :: rest as collect ->
      (match ty with
       | TypeField ->
         let f = type_ s in (* TODO: check if small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | ImportField ->
         let f = at import s in (* TODO: check if small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | FuncField ->
         let f = at var s in (* small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | TableField ->
         let f = at table s in (* small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | MemoryField ->
         let f = at memory s in (* small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | GlobalField ->
         let gtype = global_type s in
         MK_Global (gtype, pos s, [IK_Next []]) :: collect
       | ExportField ->
         let f = at export s in (* small enough to fit in a tick *)
         MK_Field_collect (ty, size, n - 1, f :: l) :: rest
       | StartField ->
         (* not a vector *)
         assert false
       | ElemField ->
         MK_Elem (EK_Start, pos s) :: collect
       | DataCountField ->
         (* not a vector *)
         assert false
       | CodeField ->
         MK_Code (CK_Start, pos s) :: collect
       | DataField ->
         MK_Data (DK_Start, pos s) :: collect
      )

    | MK_Global (gtype, left, [ IK_Stop res]) :: MK_Field_collect (GlobalField, size, n, l) :: rest ->
      end_ s ;
      let ginit = Source.(res @@ region s left (pos s)) in
      let f = Source.({gtype; ginit} @@ region s left (pos s)) in
      MK_Field_collect (GlobalField, size, (n - 1), f :: l) :: rest
    | MK_Global (ty, pos, [ IK_Stop res]) :: _ ->
      assert false
    | MK_Global (ty, pos, k) :: rest ->
      MK_Global (ty, pos, instr_block_step s k) :: rest

    | MK_Elem (EK_Stop elem, left) :: MK_Field_collect (ElemField, size, n, l) :: rest ->
      let elem = Source.(elem @@ region s left (pos s)) in
      MK_Field_collect (ElemField, size, (n - 1), elem :: l) :: rest
    | MK_Elem (EK_Stop _, _) :: _ ->
      assert false
    | MK_Elem (elem_kont, pos) :: rest ->
      MK_Elem (elem_step s elem_kont, pos) :: rest

    | MK_Data (DK_Stop data, left) :: MK_Field_collect (DataField, size, n, l) :: rest ->
      let data = Source.(data @@ region s left (pos s)) in
      MK_Field_collect (DataField, size, (n - 1), data :: l) :: rest
    | MK_Data (DK_Stop _, _) :: _ ->
      assert false
    | MK_Data (data_kont, pos) :: rest ->
      MK_Data (data_step s data_kont, pos) :: rest

    | MK_Code (CK_Stop func, left) :: MK_Field_collect (CodeField, size, n, l) :: rest ->
      MK_Field_collect (CodeField, size, (n - 1), func :: l) :: rest
    | MK_Code (CK_Stop _, _) :: _ ->
      assert false
    | MK_Code (code_kont, pos) :: rest ->
      MK_Code (code_step s code_kont, pos) :: rest

    | MK_Field_rev (ty, size, l, f :: fs) :: rest ->
      MK_Field_rev (ty, size, f :: l, fs) :: rest

    (* Type -> Import *)
    | MK_Field_rev (TypeField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      (* TODO: maybe we can factor-out these similarly shaped module section transitions *)
      MK_Skip_custom
      :: MK_Field (ImportField, `ImportSection)
      :: MK_Next (Vec_field (TypeField, l) :: fields)  :: []

    (* Import -> Func *)
    | MK_Field_rev (ImportField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (FuncField, `FuncSection)
      :: MK_Next (Vec_field (ImportField, l) :: fields) :: []

    (* Func -> Table *)
    | MK_Field_rev (FuncField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (TableField, `TableSection)
      :: MK_Next (Vec_field (FuncField, l) :: fields) :: []

    | MK_Field_rev (TableField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (MemoryField, `MemorySection)
      :: MK_Next (Vec_field (TableField, l) :: fields) :: []
    | MK_Field_rev (MemoryField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (GlobalField, `GlobalSection)
      :: MK_Next (Vec_field (MemoryField, l) :: fields) :: []
    | MK_Field_rev (GlobalField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (ExportField, `ExportSection)
      :: MK_Next (Vec_field (GlobalField, l) :: fields) :: []
    | MK_Field_rev (ExportField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (StartField, `StartSection)
      :: MK_Next (Vec_field (ExportField, l) :: fields) :: []
    | MK_Field_rev (ElemField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (DataCountField, `DataCountSection)
      :: MK_Next (Vec_field (ElemField, l) :: fields) :: []
    (* Code -> Data *)
    | MK_Field_rev (CodeField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Field (DataField, `DataSection)
      :: MK_Next (Vec_field (CodeField, l) :: fields) :: []
    (* Data is the last section *)
    | MK_Field_rev (DataField, size, l, []) :: MK_Next fields :: rest ->
      check_size size s;
      MK_Skip_custom
      :: MK_Next (Vec_field (DataField, l) :: fields) :: []

    (* Penultimate step.

       Extract the fields of each kind (type, func, element segment, etc) and build
       the module.

       TODO this looks linear in the size of the module tree??
     *)
    | MK_Next fields :: [] ->
      (* TODO is this let rec safe? *)
      let rec find_vec
        : type t. t field_type -> _ -> t list
        = fun ty fields -> match fields with
          | [] -> assert false
          | Single_field _ :: rest -> find_vec ty rest
          | Vec_field (ty', v) :: rest ->
            match ty, ty' with (* TODO: factor this out with a Leibnitz equality witness *)
            | TypeField, TypeField -> v
            | ImportField, ImportField -> v
            | FuncField, FuncField -> v
            | TableField, TableField -> v
            | MemoryField, MemoryField -> v
            | GlobalField, GlobalField -> v
            | ExportField, ExportField -> v
            | StartField, StartField -> v
            | ElemField, ElemField -> v
            | DataCountField, DataCountField -> v
            | CodeField, CodeField -> v
            | DataField, DataField -> v
            | _ -> find_vec ty rest
      in
      (* TODO is this let rec safe? *)
      let rec find_single
        : type t. t field_type -> _ -> t option
        = fun ty fields -> match fields with
          | [] -> assert false
          | Vec_field _ :: rest -> find_single ty rest
          | Single_field (ty', v) :: rest ->
            match ty, ty' with
            | TypeField, TypeField -> v
            | ImportField, ImportField -> v
            | FuncField, FuncField -> v
            | TableField, TableField -> v
            | MemoryField, MemoryField -> v
            | GlobalField, GlobalField -> v
            | ExportField, ExportField -> v
            | StartField, StartField -> v
            | ElemField, ElemField -> v
            | DataCountField, DataCountField -> v
            | CodeField, CodeField -> v
            | DataField, DataField -> v
            | _ -> find_single ty rest
      in
      let types = find_vec TypeField fields in
      let func_types = find_vec FuncField fields in
      let func_bodies = find_vec CodeField fields in
      let data_count = find_single DataCountField fields in
      let datas = find_vec DataField fields in
      let elems = find_vec ElemField fields in
      let start = find_single StartField fields in
      let tables = find_vec TableField fields in
      let memories = find_vec MemoryField fields in
      let globals = find_vec GlobalField fields in
      let imports = find_vec ImportField fields in
      let exports = find_vec ExportField fields in
      ignore types;
      (* TODO is list stuff safe? *)
      require (pos s = len s) s (len s) "unexpected content after last section";
      require (List.length func_types = List.length func_bodies)
        s (len s) "function and code section have inconsistent lengths";
      require (data_count = None || data_count = Some (Lib.List32.length datas))
        s (len s) "data count and data section have inconsistent lengths";
      require (data_count <> None ||
               List.for_all Free.(fun f -> (func f).datas = Set.empty) func_bodies)
        s (len s) "data count section required";
      let funcs =
        (* TODO: maybe make this incremental *)
        List.map2 Source.(fun t f -> {f.it with ftype = t} @@ f.at)
          func_types func_bodies
      in
      [ MK_Stop {types; tables; memories; globals; funcs; imports; exports; elems; datas; start} ]
    | _ -> assert false
    )

let module_ (s : stream) : Ast.module_' =
  let rec loop = function
    | [ MK_Stop m ] -> m
    | k -> loop (step s k) in
  loop [ MK_Start ]

let decode name bs = at module_ (stream name bs)

let rec iterate f s = if f s <> None then iterate f s

let all_custom tag s =
  let header = u32 s in
  require (header = magic) s 0 "magic header not detected";
  let version = u32 s in
  require (version = Encode.version) s 4 "unknown binary version";
  let rec collect () =
    iterate non_custom_section s;
    match custom_section s with
    | None -> []
    | Some (n, s) when n = tag -> s :: collect ()
    | Some _ -> collect ()
  in collect ()

let _decode_custom tag name bs = all_custom tag (stream name bs)

(* Incremental parser TODO list:
   - Make extra sure that the input consumed at each tick is less than some limit << L1 op size
   - Make extra sure to limit the part of the state consumed at each tick
   - Sections marked `faiwith "HERE" are not implemented
   - Make the input shallow-able, probably keep the imperative structure
   - Make the state shallow-able (insert Merkelized cuts)
   - Drop the dead synchronous utility functions, or turn them into small step ones
   - Remove the wildcard patterns in the continuation stack matches *)
