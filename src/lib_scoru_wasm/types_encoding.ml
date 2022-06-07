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
open Types

(* TODO: placeholder, implemented in !5484 *)
let vec_type_encoding =
  Data_encoding.(
    conv (fun V128Type -> ()) (fun () -> V128Type) (constant "V128Type"))

let pack_size_encoding =
  Data_encoding.string_enum
    [
      ("Pack8", Pack8);
      ("Pack16", Pack16);
      ("Pack32", Pack32);
      ("Pack64", Pack64);
    ]

let pack_shape_encoding =
  Data_encoding.string_enum
    [("Pack8x8", Pack8x8); ("Pack16x4", Pack16x4); ("Pack32x2", Pack32x2)]

let extension_encoding = Data_encoding.string_enum [("SX", SX); ("ZX", ZX)]

let vec_extension_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"ExtLane"
        (Tag 0)
        (obj1 (req "ExtLane" (tup2 pack_shape_encoding extension_encoding)))
        (function ExtLane (s, e) -> Some (s, e) | _ -> None)
        (fun (s, e) -> ExtLane (s, e));
      case
        ~title:"ExtSplat"
        (Tag 1)
        (constant "ExtSplat")
        (function ExtSplat -> Some () | _ -> None)
        (fun () -> ExtSplat);
      case
        ~title:"ExtZero"
        (Tag 2)
        (constant "ExtZero")
        (function ExtZero -> Some () | _ -> None)
        (fun () -> ExtZero);
    ]

let num_type_encoding : num_type Data_encoding.t =
  Data_encoding.string_enum
    [
      ("I32Type", I32Type);
      ("I64Type", I64Type);
      ("F32Type", F32Type);
      ("F64Type", F64Type);
    ]

let ref_type_encoding : ref_type Data_encoding.t =
  Data_encoding.string_enum
    [("FuncRefType", FuncRefType); ("ExternRefType", ExternRefType)]

let value_type_encoding : value_type Data_encoding.t =
  Data_encoding.(
    union
      [
        case
          (Tag 0)
          ~title:"NumType"
          num_type_encoding
          (function NumType x -> Some x | _ -> None)
          (fun x -> NumType x);
        case
          (Tag 1)
          ~title:"VecType"
          vec_type_encoding
          (function VecType x -> Some x | _ -> None)
          (fun x -> VecType x);
        case
          (Tag 2)
          ~title:"RefType"
          ref_type_encoding
          (function RefType x -> Some x | _ -> None)
          (fun x -> RefType x);
      ])

let mutability_encoding : mutability Data_encoding.t =
  Data_encoding.string_enum [("immutable", Immutable); ("mutable", Mutable)]

let global_type_encoding =
  Data_encoding.(
    conv
      (function GlobalType (v, m) -> (v, m))
      (fun (v, m) -> GlobalType (v, m))
      (obj2
         (req "value_type" value_type_encoding)
         (req "mutability" mutability_encoding)))

let limits_encoding value_encoding : _ limits Data_encoding.t =
  Data_encoding.(
    conv
      (fun {min; max} -> (min, max))
      (fun (min, max) -> {min; max})
      (obj2 (req "min" value_encoding) (req "max" @@ option value_encoding)))

let table_type_encoding =
  Data_encoding.(
    conv
      (fun (TableType (l, r)) -> (l, r))
      (fun (l, r) -> TableType (l, r))
      (tup2 (limits_encoding int32) ref_type_encoding))

let memory_type_encoding =
  Data_encoding.(
    conv
      (fun (MemoryType l) -> l)
      (fun l -> MemoryType l)
      (limits_encoding int32))

let result_type_encoding = Data_encoding.(list value_type_encoding)

let func_type_encoding : func_type Data_encoding.t =
  Data_encoding.(
    conv
      (function FuncType (x, y) -> (x, y))
      (fun (x, y) -> FuncType (x, y))
      (tup2 result_type_encoding result_type_encoding))
