(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

type message = string

let message_encoding = Data_encoding.string

type summary = {length : int32; cumulated_size : int}

type t = summary

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {length; cumulated_size} -> (length, cumulated_size))
    (fun (length, cumulated_size) -> {length; cumulated_size})
    (obj2 (req "length" int32) (req "cumulated_size" int31))

let pp fmt t = Format.fprintf fmt "tx rollup inbox: %ld messages" t.length

type full = {content : message list; cumulated_size : int}

let full_encoding =
  let open Data_encoding in
  conv
    (fun {content; cumulated_size} -> (content, cumulated_size))
    (fun (content, cumulated_size) -> {content; cumulated_size})
    (obj2 (req "content" @@ list message_encoding) (req "cumulated_size" int31))
