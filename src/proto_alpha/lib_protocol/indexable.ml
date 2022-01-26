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

type ('state, 'a) indexable =
  | Value : 'a -> ([> `Value], 'a) indexable
  | Index : int32 -> ([> `Id], 'a) indexable

type unknown = [`Value | `Id]

type index_only = [`Id]

type 'a t = (unknown, 'a) indexable

type 'a index = (index_only, 'a) indexable

let index h : 'a t -> 'a index tzresult Lwt.t = function
  | Value x -> h x >|=? fun x -> Index x
  | Index x -> return (Index x)

let compact : 'a Data_encoding.t -> 'a t Compact_encoding.t =
  let open Compact_encoding in
  fun val_encoding ->
    conv
      ~json:
        Data_encoding.(
          union
            [
              case
                (Tag 0)
                ~title:"index"
                int32
                (function Index x -> Some x | _ -> None)
                (fun x -> Index x);
              case
                (Tag 1)
                ~title:"value"
                val_encoding
                (function Value x -> Some x | _ -> None)
                (fun x -> Value x);
            ])
      (function Index x -> Case_0 x | Value x -> Case_1 x)
      (function Case_0 x -> Index x | Case_1 x -> Value x)
      (or_int32 ~int32_kind:"index" ~alt_kind:"value" val_encoding)

let encoding : 'a Data_encoding.t -> 'a t Data_encoding.t =
 fun val_encoding ->
  Compact_encoding.make ~tag_size:`Uint8 @@ compact val_encoding

let pp : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a t -> unit =
 fun ppv fmt -> function
  | Index x -> Format.(fprintf fmt "#%ld" x)
  | Value x -> Format.(fprintf fmt "%a" ppv x)

let in_memory_size ims =
  let open Cache_memory_helpers in
  function
  | Value x -> header_size +! word_size +! ims x
  | Index _ -> header_size +! word_size +! int32_size

let size s = function Value x -> 1 + s x | Index _ -> 1 (* tag *) + 4
(* int32 *)

let compare c x y =
  match (x, y) with
  | (Index x, Index y) -> Compare.Int32.compare x y
  | (Value x, Value y) -> c x y
  | (Index _, Value _) -> -1
  | (Value _, Index _) -> 1

module type VALUE = sig
  type t

  val encoding : t Data_encoding.t

  val compare : t -> t -> int

  val pp : Format.formatter -> t -> unit
end

module type INDEXABLE = sig
  type value

  type nonrec 'state indexable = ('state, value) indexable

  type nonrec index = value index

  type nonrec t = value t

  val encoding : t Data_encoding.t

  val compact : t Compact_encoding.t

  val compare : t -> t -> int

  val pp : Format.formatter -> t -> unit
end

module Make (V : VALUE) :
  INDEXABLE with type value = V.t and type t = V.t t and type index = V.t index =
struct
  type value = V.t

  type nonrec 'state indexable = ('state, V.t) indexable

  type nonrec index = V.t index

  type nonrec t = V.t t

  let compact = compact V.encoding

  let encoding = encoding V.encoding

  let pp = pp V.pp

  let compare = compare V.compare
end
