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

(* ---- Constants ----------------------------------------------------------- *)

let max_int8_l = 255l

let max_int16_l = 65535l

let max_int8_L = Int64.of_int32 max_int8_l

let max_int16_L = Int64.of_int32 max_int16_l

let max_int32_L = 4294967295L

type tag = int32

let join_tags tags =
  let ( lor ) = Int32.logor in
  let ( << ) = Int32.shift_left in
  let (tag_value, _tag_len) =
    List.fold_left
      (fun (res, ofs) (tag_value, tag_len) ->
        (res lor (tag_value << ofs), ofs + tag_len))
      (0l, 0)
      tags
  in
  tag_value

let to_int tag_value = Int32.to_int tag_value

module type S = sig
  type input

  type layout

  val layout_equal : layout -> layout -> bool

  val layouts : layout list

  val tag_len : int

  val tag : layout -> tag

  val partial_encoding : layout -> input Data_encoding.t

  val classify : input -> layout

  val json_encoding : input Data_encoding.t
end

type 'a t = (module S with type input = 'a)

let make : type a. ?tag_size:[`Uint8 | `Uint16] -> a t -> a Data_encoding.t =
 fun ?tag_size (module C : S with type input = a) ->
  Data_encoding.(
    splitted
      ~json:C.json_encoding
      ~binary:
        (matching ?tag_size (fun x ->
             let layout = C.classify x in
             matched
               ?tag_size
               (C.tag layout |> to_int)
               (C.partial_encoding layout)
               x)
        @@ List.map
             (fun layout ->
               let tag = to_int (C.tag layout) in
               case
                 ~title:(Format.sprintf "case %d" tag)
                 (Tag tag)
                 (C.partial_encoding layout)
                 (fun x ->
                   if C.layout_equal (C.classify x) layout then Some x else None)
                 (fun x -> x))
             C.layouts))

module List_syntax = struct
  let ( let* ) l f = List.concat_map f l

  let return x = [x]
end

type void = |

let refute = function (_ : void) -> .

let void : void t =
  (module struct
    type input = void

    type layout = void

    let tag_len = 0

    let layouts = []

    let layout_equal = refute

    let classify = refute

    let partial_encoding = refute

    let tag = refute

    let json_encoding =
      Data_encoding.(conv_with_guard refute (fun _ -> Error "no") empty)
  end)

type ('a, 'b) case2 = Case_0 of 'a | Case_1 of 'b

type 'a case = {kind : string; compact : 'a t}

let case kind compact = {kind; compact}

let case2 : type a b. a case -> b case -> (a, b) case2 t =
 fun {kind = a_kind; compact = (module A : S with type input = a)}
     {kind = b_kind; compact = (module B : S with type input = b)} :
     (module S with type input = (a, b) case2) ->
  (module struct
    type input = (A.input, B.input) case2

    type layout = (A.layout, B.layout) case2

    let layout_equal x y =
      match (x, y) with
      | (Case_0 x, Case_0 y) -> A.layout_equal x y
      | (Case_1 x, Case_1 y) -> B.layout_equal x y
      | (_, _) -> false

    let layouts =
      List.append
        (List.map (fun x -> Case_0 x) A.layouts)
        (List.map (fun x -> Case_1 x) B.layouts)

    let tag_len = 1 + Compare.Int.max A.tag_len B.tag_len

    let classify = function
      | Case_0 x -> Case_0 (A.classify x)
      | Case_1 x -> Case_1 (B.classify x)

    let partial_encoding = function
      | Case_0 la ->
          Data_encoding.(
            conv
              (function Case_0 x -> x | _ -> assert false)
              (fun x -> Case_0 x)
              (A.partial_encoding la))
      | Case_1 lb ->
          Data_encoding.(
            conv
              (function Case_1 x -> x | _ -> assert false)
              (fun x -> Case_1 x)
              (B.partial_encoding lb))

    (* We prefix the tag computed by the underlying compact encoding
       by [0] ([Case1]), or [1] ([Case2]). *)
    let tag =
      let ( lor ) = Int32.logor in
      let ( << ) = Int32.shift_left in
      function
      | Case_0 la -> A.tag la | Case_1 lb -> B.tag lb lor (1l << tag_len - 1)

    let json_encoding =
      Data_encoding.(
        conv_with_guard
          (function
            | Case_0 _ as expr -> (a_kind, expr)
            | Case_1 _ as expr -> (b_kind, expr))
          (function
            | (kind, x) when Compare.String.(kind = a_kind) -> ok x
            | (kind, x) when Compare.String.(kind = b_kind) -> ok x
            | _ -> Error "not a valid kind")
          (obj2
             (req "kind" string)
             (req "value"
             @@ union
                  [
                    case
                      (Tag 0)
                      ~title:a_kind
                      A.json_encoding
                      (function Case_0 x -> Some x | _ -> None)
                      (fun x -> Case_0 x);
                    case
                      (Tag 1)
                      ~title:b_kind
                      B.json_encoding
                      (function Case_1 x -> Some x | _ -> None)
                      (fun x -> Case_1 x);
                  ])))
  end)

type ('a, 'b, 'c, 'd) case4 =
  | Case_00 of 'a
  | Case_01 of 'b
  | Case_10 of 'c
  | Case_11 of 'd

let case4 :
    type a b c d. a case -> b case -> c case -> d case -> (a, b, c, d) case4 t =
 fun {kind = a_kind; compact = (module A : S with type input = a)}
     {kind = b_kind; compact = (module B : S with type input = b)}
     {kind = c_kind; compact = (module C : S with type input = c)}
     {kind = d_kind; compact = (module D : S with type input = d)} :
     (module S with type input = (a, b, c, d) case4) ->
  (module struct
    type input = (a, b, c, d) case4

    type layout = (A.layout, B.layout, C.layout, D.layout) case4

    let layout_equal x y =
      match (x, y) with
      | (Case_00 la1, Case_00 la2) -> A.layout_equal la1 la2
      | (Case_01 lb1, Case_01 lb2) -> B.layout_equal lb1 lb2
      | (Case_10 lc1, Case_10 lc2) -> C.layout_equal lc1 lc2
      | (Case_11 ld1, Case_11 ld2) -> D.layout_equal ld1 ld2
      | (_, _) -> false

    let layouts =
      List.concat
        [
          List.map (fun x -> Case_00 x) A.layouts;
          List.map (fun x -> Case_01 x) B.layouts;
          List.map (fun x -> Case_10 x) C.layouts;
          List.map (fun x -> Case_11 x) D.layouts;
        ]

    let tag_len =
      let join_len =
        List.fold_left
          Compare.Int.max
          0
          [A.tag_len; B.tag_len; C.tag_len; D.tag_len]
      in
      2 + join_len

    let classify input =
      match input with
      | Case_00 a -> Case_00 (A.classify a)
      | Case_01 b -> Case_01 (B.classify b)
      | Case_10 c -> Case_10 (C.classify c)
      | Case_11 d -> Case_11 (D.classify d)

    let partial_encoding = function
      | Case_00 la ->
          Data_encoding.(
            conv
              (function Case_00 x -> x | _ -> assert false)
              (fun x -> Case_00 x)
              (A.partial_encoding la))
      | Case_01 lb ->
          Data_encoding.(
            conv
              (function Case_01 x -> x | _ -> assert false)
              (fun x -> Case_01 x)
              (B.partial_encoding lb))
      | Case_10 lc ->
          Data_encoding.(
            conv
              (function Case_10 x -> x | _ -> assert false)
              (fun x -> Case_10 x)
              (C.partial_encoding lc))
      | Case_11 ld ->
          Data_encoding.(
            conv
              (function Case_11 x -> x | _ -> assert false)
              (fun x -> Case_11 x)
              (D.partial_encoding ld))

    (* We prefix the tag computed by the underlying compact encoding
       by [00] ([Case_00]), [01] ([Case_01]), [10] ([Case_10]), or [11]
       ([Case_11]). *)
    let tag =
      let ( lor ) = Int32.logor in
      let ( << ) = Int32.shift_left in
      function
      | Case_00 la -> A.tag la
      | Case_01 lb -> B.tag lb lor (1l << tag_len - 2)
      | Case_10 lc -> C.tag lc lor (2l << tag_len - 2)
      | Case_11 ld -> D.tag ld lor (3l << tag_len - 2)

    let json_encoding =
      Data_encoding.(
        conv_with_guard
          (function
            | Case_00 _ as expr -> (a_kind, expr)
            | Case_01 _ as expr -> (b_kind, expr)
            | Case_10 _ as expr -> (c_kind, expr)
            | Case_11 _ as expr -> (d_kind, expr))
          (function
            | (kind, (Case_00 _ as x)) when Compare.String.(kind = a_kind) ->
                ok x
            | (kind, (Case_01 _ as x)) when Compare.String.(kind = b_kind) ->
                ok x
            | (kind, (Case_10 _ as x)) when Compare.String.(kind = c_kind) ->
                ok x
            | (kind, (Case_11 _ as x)) when Compare.String.(kind = d_kind) ->
                ok x
            | _ -> Error "not a valid kind")
          (obj2
             (req "kind" string)
             (req "value"
             @@ union
                  [
                    case
                      (Tag 0)
                      ~title:a_kind
                      A.json_encoding
                      (function Case_00 x -> Some x | _ -> None)
                      (fun x -> Case_00 x);
                    case
                      (Tag 1)
                      ~title:b_kind
                      B.json_encoding
                      (function Case_01 x -> Some x | _ -> None)
                      (fun x -> Case_01 x);
                    case
                      (Tag 2)
                      ~title:c_kind
                      C.json_encoding
                      (function Case_10 x -> Some x | _ -> None)
                      (fun x -> Case_10 x);
                    case
                      (Tag 3)
                      ~title:d_kind
                      D.json_encoding
                      (function Case_11 x -> Some x | _ -> None)
                      (fun x -> Case_11 x);
                  ])))
  end)

let singleton : type a. a Data_encoding.t -> a t =
 fun encoding : (module S with type input = a) ->
  (module struct
    type input = a

    type layout = unit

    let layout_equal () () = true

    let layouts = [()]

    let tag_len = 0

    let tag _ = 0l

    let classify _ = ()

    let partial_encoding _ = encoding

    let json_encoding = encoding
  end)

let empty = singleton Data_encoding.empty

let conv :
    type a b. ?json:a Data_encoding.t -> (a -> b) -> (b -> a) -> b t -> a t =
 fun ?json f g (module B : S with type input = b) ->
  (module struct
    type input = a

    type layout = B.layout

    let layout_equal = B.layout_equal

    let layouts = B.layouts

    let tag_len = B.tag_len

    let tag = B.tag

    let classify b = B.classify (f b)

    let partial_encoding l = Data_encoding.conv f g (B.partial_encoding l)

    let json_encoding =
      match json with
      | None -> Data_encoding.conv f g B.json_encoding
      | Some encoding -> encoding
  end)

let option compact =
  conv
    ~json:(Data_encoding.option @@ make compact)
    (function Some x -> Case_0 x | None -> Case_1 ())
    (function Case_0 x -> Some x | Case_1 () -> None)
  @@ case2 (case "some" compact) (case "none" empty)

let tup2 : type a b. a t -> b t -> (a * b) t =
 fun (module A : S with type input = a) (module B : S with type input = b) :
     (module S with type input = a * b) ->
  (module struct
    type input = A.input * B.input

    type layout = A.layout * B.layout

    let layout_equal (la1, lb1) (la2, lb2) =
      A.layout_equal la1 la2 && B.layout_equal lb1 lb2

    let tag_len = A.tag_len + B.tag_len

    let layouts =
      let open List_syntax in
      let* a = A.layouts in
      let* b = B.layouts in
      return (a, b)

    let classify (a, b) = (A.classify a, B.classify b)

    let partial_encoding (la, lb) =
      Data_encoding.tup2 (A.partial_encoding la) (B.partial_encoding lb)

    let tag (a, b) = join_tags [(A.tag a, A.tag_len); (B.tag b, B.tag_len)]

    let json_encoding = Data_encoding.tup2 A.json_encoding B.json_encoding
  end)

let tup3 : type a b c. a t -> b t -> c t -> (a * b * c) t =
 fun (module A : S with type input = a)
     (module B : S with type input = b)
     (module C : S with type input = c) : (module S with type input = a * b * c) ->
  (module struct
    type input = A.input * B.input * C.input

    type layout = A.layout * B.layout * C.layout

    let layout_equal (la1, lb1, lc1) (la2, lb2, lc2) =
      A.layout_equal la1 la2 && B.layout_equal lb1 lb2 && C.layout_equal lc1 lc2

    let tag_len = A.tag_len + B.tag_len + C.tag_len

    let layouts =
      let open List_syntax in
      let* a = A.layouts in
      let* b = B.layouts in
      let* c = C.layouts in
      return (a, b, c)

    let classify (a, b, c) = (A.classify a, B.classify b, C.classify c)

    let partial_encoding (la, lb, lc) =
      Data_encoding.tup3
        (A.partial_encoding la)
        (B.partial_encoding lb)
        (C.partial_encoding lc)

    let tag (a, b, c) =
      join_tags
        [(A.tag a, A.tag_len); (B.tag b, B.tag_len); (C.tag c, C.tag_len)]

    let json_encoding =
      Data_encoding.tup3 A.json_encoding B.json_encoding C.json_encoding
  end)

let tup4 : type a b c d. a t -> b t -> c t -> d t -> (a * b * c * d) t =
 fun (module A : S with type input = a)
     (module B : S with type input = b)
     (module C : S with type input = c)
     (module D : S with type input = d) :
     (module S with type input = a * b * c * d) ->
  (module struct
    type input = A.input * B.input * C.input * D.input

    type layout = A.layout * B.layout * C.layout * D.layout

    let layout_equal (la1, lb1, lc1, ld1) (la2, lb2, lc2, ld2) =
      A.layout_equal la1 la2 && B.layout_equal lb1 lb2 && C.layout_equal lc1 lc2
      && D.layout_equal ld1 ld2

    let tag_len = A.tag_len + B.tag_len + C.tag_len + D.tag_len

    let layouts =
      let open List_syntax in
      let* a = A.layouts in
      let* b = B.layouts in
      let* c = C.layouts in
      let* d = D.layouts in
      return (a, b, c, d)

    let classify (a, b, c, d) =
      (A.classify a, B.classify b, C.classify c, D.classify d)

    let partial_encoding (la, lb, lc, ld) =
      Data_encoding.tup4
        (A.partial_encoding la)
        (B.partial_encoding lb)
        (C.partial_encoding lc)
        (D.partial_encoding ld)

    let tag (a, b, c, d) =
      join_tags
        [
          (A.tag a, A.tag_len);
          (B.tag b, B.tag_len);
          (C.tag c, C.tag_len);
          (D.tag d, D.tag_len);
        ]

    let json_encoding =
      Data_encoding.tup4
        A.json_encoding
        B.json_encoding
        C.json_encoding
        D.json_encoding
  end)

type 'a field = {name : string; compact : 'a t}

let req : string -> 'a t -> 'a field = fun name compact -> {name; compact}

let opt : string -> 'a t -> 'a option field =
 fun name compact -> {name; compact = option compact}

let obj1 : type a. a field -> a t =
 fun {name; compact = (module C : S with type input = a)} :
     (module S with type input = a) ->
  (module struct
    include C

    let json_encoding = Data_encoding.(obj1 (req name C.json_encoding))
  end)

let obj2 : type a b. a field -> b field -> (a * b) t =
 fun {name = a_name; compact = (module A : S with type input = a) as a_compact}
     {name = b_name; compact = (module B : S with type input = b) as b_compact}
     : (module S with type input = a * b) ->
  let (module AB) = tup2 a_compact b_compact in
  (module struct
    include AB

    let json_encoding =
      Data_encoding.(
        obj2 (req a_name A.json_encoding) (req b_name B.json_encoding))
  end)

let obj3 : type a b c. a field -> b field -> c field -> (a * b * c) t =
 fun {name = a_name; compact = (module A : S with type input = a) as a_compact}
     {name = b_name; compact = (module B : S with type input = b) as b_compact}
     {name = c_name; compact = (module C : S with type input = c) as c_compact}
     : (module S with type input = a * b * c) ->
  let (module ABC) = tup3 a_compact b_compact c_compact in
  (module struct
    include ABC

    let json_encoding =
      Data_encoding.(
        obj3
          (req a_name A.json_encoding)
          (req b_name B.json_encoding)
          (req c_name C.json_encoding))
  end)

let obj4 :
    type a b c d. a field -> b field -> c field -> d field -> (a * b * c * d) t
    =
 fun {name = a_name; compact = (module A : S with type input = a) as a_compact}
     {name = b_name; compact = (module B : S with type input = b) as b_compact}
     {name = c_name; compact = (module C : S with type input = c) as c_compact}
     {name = d_name; compact = (module D : S with type input = d) as d_compact}
     : (module S with type input = a * b * c * d) ->
  let (module ABCD) = tup4 a_compact b_compact c_compact d_compact in
  (module struct
    include ABCD

    let json_encoding =
      Data_encoding.(
        obj4
          (req a_name A.json_encoding)
          (req b_name B.json_encoding)
          (req c_name C.json_encoding)
          (req d_name D.json_encoding))
  end)

module Compact_bool = struct
  type input = bool

  type layout = bool

  let layouts = [true; false]

  let layout_equal = Compare.Bool.equal

  let tag_len = 1

  let tag = function true -> 1l | false -> 0l

  let partial_encoding : layout -> bool Data_encoding.t =
   fun b ->
    Data_encoding.(
      conv
        (function b' when Compare.Bool.equal b b' -> () | _ -> assert false)
        (fun () -> b)
        empty)

  let classify x = x

  let json_encoding = Data_encoding.bool
end

let bool : bool t = (module Compact_bool)

module Compact_int32 = struct
  type input = int32

  type layout = [`Int8 | `Int16 | `Int32]

  let layout_equal l1 l2 =
    match (l1, l2) with
    | (`Int8, `Int8) | (`Int16, `Int16) | (`Int32, `Int32) -> true
    | _ -> false

  let layouts = [`Int8; `Int16; `Int32]

  (** ---- Tag -------------------------------------------------------------- *)

  let tag_len = 2

  let tag = function `Int8 -> 0l | `Int16 -> 1l | `Int32 -> 2l

  let unused_tag = 3l

  (** ---- Partial encoding ------------------------------------------------- *)

  let int8_l : int32 Data_encoding.t =
    Data_encoding.(conv Int32.to_int Int32.of_int uint8)

  let int16_l : int32 Data_encoding.t =
    Data_encoding.(conv Int32.to_int Int32.of_int uint16)

  let int32_l : int32 Data_encoding.t = Data_encoding.int32

  let partial_encoding : layout -> int32 Data_encoding.t = function
    | `Int8 -> int8_l
    | `Int16 -> int16_l
    | `Int32 -> int32_l

  (** ---- Classifier ------------------------------------------------------- *)

  let classify =
    let open Compare.Int32 in
    function
    | i when 0l <= i && i <= max_int8_l -> `Int8
    | i when max_int8_l < i && i <= max_int16_l -> `Int16
    | _ -> `Int32

  let json_encoding = Data_encoding.int32
end

let int32 : int32 t = (module Compact_int32)

module Compact_int64 = struct
  type input = int64

  type layout = [`Int64 | Compact_int32.layout]

  let layout_equal x y =
    match (x, y) with
    | (`Int64, `Int64) -> true
    | _ -> Compact_int32.layout_equal x y

  let layouts = `Int64 :: Compact_int32.layouts

  (** ---- Tag -------------------------------------------------------------- *)

  let tag_len = 2

  let tag = function `Int8 -> 0l | `Int16 -> 1l | `Int32 -> 2l | `Int64 -> 3l

  (** ---- Partial encoding ------------------------------------------------- *)

  let int8_L : int64 Data_encoding.t =
    Data_encoding.(conv Int64.to_int Int64.of_int uint8)

  let int16_L : int64 Data_encoding.t =
    Data_encoding.(conv Int64.to_int Int64.of_int uint16)

  (* FIXME: Find a better way to encode unsigned int32 values *)
  let int32_L : int64 Data_encoding.t =
    let max_int32_pos = Int64.of_int32 Int32.max_int in
    let min_int32 = -4294967296L in
    Data_encoding.(
      conv
        (fun x ->
          if Compare.Int64.(max_int32_pos < x) then
            Int64.(to_int32 @@ add x min_int32)
          else Int64.to_int32 x)
        (fun x ->
          if Compare.Int32.(x < 0l) then Int64.(sub (of_int32 x) min_int32)
          else Int64.of_int32 x)
        int32)

  let int64_L : int64 Data_encoding.t = Data_encoding.int64

  let partial_encoding : layout -> int64 Data_encoding.t = function
    | `Int8 -> int8_L
    | `Int16 -> int16_L
    | `Int32 -> int32_L
    | `Int64 -> int64_L

  (** ---- Classifier ------------------------------------------------------- *)

  let classify =
    let open Compare.Int64 in
    function
    | i when 0L <= i && i <= max_int8_L -> `Int8
    | i when max_int8_L < i && i <= max_int16_L -> `Int16
    | i when max_int16_L < i && i <= max_int32_L -> `Int32
    | _ -> `Int64

  let json_encoding = Data_encoding.int64
end

let int64 : int64 t = (module Compact_int64)

module Compact_list = struct
  type layout = Small_list of int32 | Big_list

  let layout_equal x y =
    match (x, y) with
    | (Small_list n, Small_list m) -> Compare.Int32.(n = m)
    | (Big_list, Big_list) -> true
    | (_, _) -> false

  let layouts n =
    let n = Int32.(shift_left 1l n |> pred) in
    let rec aux m acc =
      if Compare.Int32.(m < n) then aux (Int32.succ m) (Small_list m :: acc)
      else acc
    in
    List.rev @@ Big_list :: aux 0l []

  (** ---- Tag -------------------------------------------------------------- *)

  let tag n = function
    | Small_list m -> m
    | Big_list -> Int32.(pred @@ shift_left 1l n)

  (** ---- Partial encoding ------------------------------------------------- *)

  let list n encoding =
    let rec aux m =
      Data_encoding.(
        match m with
        | 0 ->
            conv_with_guard
              (function [] -> () | _ -> assert false)
              (function () -> ok [])
              empty
        | 1 ->
            conv_with_guard
              (function [x] -> x | _ -> assert false)
              (function x -> ok [x])
              encoding
        | 2 ->
            conv_with_guard
              (function [x1; x2] -> (x1, x2) | _ -> assert false)
              (function (x1, x2) -> ok [x1; x2])
              (tup2 encoding encoding)
        | 3 ->
            conv_with_guard
              (function [x1; x2; x3] -> (x1, x2, x3) | _ -> assert false)
              (function (x1, x2, x3) -> ok [x1; x2; x3])
              (tup3 encoding encoding encoding)
        | 4 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4] -> (x1, x2, x3, x4) | _ -> assert false)
              (function (x1, x2, x3, x4) -> ok [x1; x2; x3; x4])
              (tup4 encoding encoding encoding encoding)
        | 5 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4; x5] -> (x1, x2, x3, x4, x5)
                | _ -> assert false)
              (function (x1, x2, x3, x4, x5) -> ok [x1; x2; x3; x4; x5])
              (tup5 encoding encoding encoding encoding encoding)
        | 6 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4; x5; x6] -> (x1, x2, x3, x4, x5, x6)
                | _ -> assert false)
              (function
                | (x1, x2, x3, x4, x5, x6) -> ok [x1; x2; x3; x4; x5; x6])
              (tup6 encoding encoding encoding encoding encoding encoding)
        | 7 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4; x5; x6; x7] -> (x1, x2, x3, x4, x5, x6, x7)
                | _ -> assert false)
              (function
                | (x1, x2, x3, x4, x5, x6, x7) ->
                    ok [x1; x2; x3; x4; x5; x6; x7])
              (tup7
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding)
        | 8 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4; x5; x6; x7; x8] ->
                    (x1, x2, x3, x4, x5, x6, x7, x8)
                | _ -> assert false)
              (function
                | (x1, x2, x3, x4, x5, x6, x7, x8) ->
                    ok [x1; x2; x3; x4; x5; x6; x7; x8])
              (tup8
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding)
        | 9 ->
            conv_with_guard
              (function
                | [x1; x2; x3; x4; x5; x6; x7; x8; x9] ->
                    (x1, x2, x3, x4, x5, x6, x7, x8, x9)
                | _ -> assert false)
              (function
                | (x1, x2, x3, x4, x5, x6, x7, x8, x9) ->
                    ok [x1; x2; x3; x4; x5; x6; x7; x8; x9])
              (tup9
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding)
        | m ->
            conv_with_guard
              (function
                | x1 :: x2 :: x3 :: x4 :: x5 :: x6 :: x7 :: x8 :: x9 :: rst ->
                    (x1, x2, x3, x4, x5, x6, x7, x8, x9, rst)
                | _ -> assert false)
              (function
                | (x1, x2, x3, x4, x5, x6, x7, x8, x9, rst) ->
                    ok
                      (x1 :: x2 :: x3 :: x4 :: x5 :: x6 :: x7 :: x8 :: x9 :: rst))
              (tup10
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 encoding
                 (aux (m - 9))))
    in
    aux n

  let partial_encoding : 'a Data_encoding.t -> layout -> 'a list Data_encoding.t
      =
   fun encoding -> function
    | Small_list n -> list (Int32.to_int n) encoding
    | Big_list -> Data_encoding.list encoding

  let json_encoding = Data_encoding.list

  (** ---- Classifier ------------------------------------------------------- *)

  let classify n l =
    let m = Int32.(shift_left 1l n |> pred |> to_int) in
    let rec aux n l =
      if Compare.Int.(n < m) then
        match l with
        | [] -> Small_list (Int32.of_int n)
        | _ :: rst -> aux (n + 1) rst
      else Big_list
    in
    aux 0 l
end

let list : type a. int -> a Data_encoding.t -> a list t =
 fun n encoding ->
  (module struct
    type input = a list

    include Compact_list

    let layouts = layouts n

    let tag_len = n

    let tag = tag n

    let classify = classify n

    let partial_encoding = Compact_list.partial_encoding encoding

    let json_encoding = json_encoding encoding
  end)

module Compact_either_int32 = struct
  type layout = Compact_int32.layout option

  let layouts = None :: List.map Option.some Compact_int32.layouts

  let layout_equal = Option.equal Compact_int32.layout_equal

  (** ---- Tag -------------------------------------------------------------- *)

  let tag_len = Compact_int32.tag_len

  let tag = function
    | Some i -> Compact_int32.tag i
    | None -> Compact_int32.unused_tag

  (** ---- Partial encoding ------------------------------------------------- *)

  let partial_encoding val_encoding =
    let open Data_encoding in
    function
    | Some id ->
        conv
          (function
            | Case_0 i when Compact_int32.(layout_equal (classify i) id) -> i
            | _ -> assert false)
          (fun i -> Case_0 i)
          (Compact_int32.partial_encoding id)
    | None ->
        conv
          (function Case_1 v -> v | _ -> assert false)
          (fun v -> Case_1 v)
          val_encoding

  (** ---- Classifier ------------------------------------------------------- *)

  let classify : (int32, 'a) case2 -> layout = function
    | Case_0 i -> Some (Compact_int32.classify i)
    | _ -> None
end

let or_int32 :
    type a.
    int32_kind:string ->
    alt_kind:string ->
    a Data_encoding.t ->
    (int32, a) case2 t =
 fun ~int32_kind ~alt_kind encoding ->
  (module struct
    type input = (int32, a) case2

    include Compact_either_int32

    let partial_encoding = Compact_either_int32.partial_encoding encoding

    let json_encoding =
      Data_encoding.(
        conv_with_guard
          (function
            | Case_0 _ as expr -> (int32_kind, expr)
            | Case_1 _ as expr -> (alt_kind, expr))
          (function
            | (kind, (Case_0 _ as x)) when Compare.String.(kind = int32_kind) ->
                ok x
            | (kind, (Case_1 _ as x)) when Compare.String.(kind = alt_kind) ->
                ok x
            | _ -> Error "not a valid kind")
          (obj2
             (req "kind" string)
             (req "value"
             @@ union
                  [
                    case
                      (Tag 0)
                      ~title:int32_kind
                      int32
                      (function Case_0 x -> Some x | _ -> None)
                      (fun x -> Case_0 x);
                    case
                      (Tag 1)
                      ~title:alt_kind
                      encoding
                      (function Case_1 x -> Some x | _ -> None)
                      (fun x -> Case_1 x);
                  ])))
  end)

let compact_int32 : int32 Data_encoding.t = make ~tag_size:`Uint8 int32

let compact_int64 : int64 Data_encoding.t = make ~tag_size:`Uint8 int64

let compact_list : int -> 'a Data_encoding.t -> 'a list Data_encoding.t =
 fun n encoding -> make ~tag_size:`Uint8 (list n encoding)

let compact_or_int32 :
    int32_kind:string ->
    alt_kind:string ->
    'a Data_encoding.t ->
    (int32, 'a) case2 Data_encoding.t =
 fun ~int32_kind ~alt_kind encoding ->
  make ~tag_size:`Uint8 (or_int32 ~int32_kind ~alt_kind encoding)

module Internals = struct
  module type S = S

  type tag = int32

  let join_tags = join_tags

  let make x = x
end
