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
open Values

module I32 = struct
  type t = I32.t

  let encoding = Data_encoding.int32
end

module I64 = struct
  type t = I64.t

  let encoding = Data_encoding.int64
end

module F32 = struct
  type t = F32.t

  (* TODO: Floats are not used, but there's probably a better encoding. *)
  let encoding =
    Data_encoding.conv F32.to_string F32.of_string Data_encoding.string
end

module F64 = struct
  type t = F64.t

  (* TODO: Floats are not used, but there's probably a better encoding. *)
  let encoding =
    Data_encoding.conv F64.to_string F64.of_string Data_encoding.string
end

module V128 = struct
  type t = V128.t

  let encoding =
    Data_encoding.conv V128.to_bits V128.of_bits Data_encoding.string

  open V128

  let laneop_encoding i8x16_encoding i16x8_encoding i32x4_encoding
      i64x2_encoding f32x4_encoding f64x2_encoding =
    let open Data_encoding in
    union
      [
        case
          ~title:"I8x16"
          (Tag 0)
          (obj1 (req "I8x16" i8x16_encoding))
          (function I8x16 v -> Some v | _ -> None)
          (fun v -> I8x16 v);
        case
          ~title:"I16x8"
          (Tag 1)
          (obj1 (req "I16x8" i16x8_encoding))
          (function I16x8 v -> Some v | _ -> None)
          (fun v -> I16x8 v);
        case
          ~title:"I32x4"
          (Tag 2)
          (obj1 (req "I32x4" i32x4_encoding))
          (function I32x4 v -> Some v | _ -> None)
          (fun v -> I32x4 v);
        case
          ~title:"I64x2"
          (Tag 3)
          (obj1 (req "I64x2" i64x2_encoding))
          (function I64x2 v -> Some v | _ -> None)
          (fun v -> I64x2 v);
        case
          ~title:"F32x4"
          (Tag 4)
          (obj1 (req "F32x4" f32x4_encoding))
          (function F32x4 v -> Some v | _ -> None)
          (fun v -> F32x4 v);
        case
          ~title:"F64x2"
          (Tag 5)
          (obj1 (req "F64x2" f64x2_encoding))
          (function F64x2 v -> Some v | _ -> None)
          (fun v -> F64x2 v);
      ]
end

let op_encoding i32_encoding i64_encoding f32_encoding f64_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"I32"
        (Tag 0)
        (obj1 (req "I32" i32_encoding))
        (function I32 v -> Some v | _ -> None)
        (fun v -> I32 v);
      case
        ~title:"I64"
        (Tag 1)
        (obj1 (req "I64" i64_encoding))
        (function I64 v -> Some v | _ -> None)
        (fun v -> I64 v);
      case
        ~title:"F32"
        (Tag 2)
        (obj1 (req "F32" f32_encoding))
        (function F32 v -> Some v | _ -> None)
        (fun v -> F32 v);
      case
        ~title:"F64"
        (Tag 3)
        (obj1 (req "F64" f64_encoding))
        (function F64 v -> Some v | _ -> None)
        (fun v -> F64 v);
    ]

let vecop_encoding v128_encoding =
  Data_encoding.(conv (fun (V128 v) -> v) (fun v -> V128 v) v128_encoding)

let num_encoding =
  op_encoding I32.encoding I64.encoding F32.encoding F64.encoding

let vec_encoding = vecop_encoding V128.encoding

(* TODO placeholder *)
let func_inst_encoding =
  Data_encoding.(
    conv
      (fun _ -> failwith "func_inst_encoding")
      (fun _ -> failwith "func_inst_encoding")
      unit)

let ref_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"NullRef"
        (Tag 0)
        (obj1 (req "NullRef" Types_encoding.ref_type_encoding))
        (function Values.NullRef r -> Some r | _ -> None)
        (fun r -> Values.NullRef r);
      case
        ~title:"FuncRef"
        (Tag 1)
        (obj1 (req "FuncRef" func_inst_encoding))
        (function Instance.FuncRef r -> Some r | _ -> None)
        (fun r -> Instance.FuncRef r);
      case
        ~title:"ExternRef"
        (Tag 2)
        (obj1 (req "ExternRef" int32))
        (function Script.ExternRef r -> Some r | _ -> None)
        (fun r -> Script.ExternRef r);
    ]

let values_encoding =
  let open Data_encoding in
  union
    [
      case
        ~title:"Num"
        (Tag 0)
        (obj1 (req "Num" num_encoding))
        (function Num n -> Some n | _ -> None)
        (fun n -> Num n);
      case
        ~title:"Vec"
        (Tag 1)
        (obj1 (req "Vec" vec_encoding))
        (function Vec v -> Some v | _ -> None)
        (fun v -> Vec v);
      case
        ~title:"Ref"
        (Tag 2)
        (obj1 (req "Ref" ref_encoding))
        (function Ref r -> Some r | _ -> None)
        (fun r -> Ref r);
    ]
