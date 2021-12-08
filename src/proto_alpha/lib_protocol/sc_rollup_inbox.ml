(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type hash = Dummy

type t = {hash : hash; offset : int64}

let pp_hash fmtr Dummy = Format.fprintf fmtr "Dummy"

let pp fmtr {hash; offset} =
  Format.fprintf
    fmtr
    "@[<v 2>{ hash = %a;@,offset = %Ld }@]"
    pp_hash
    hash
    offset

let hash_encoding =
  Data_encoding.conv
    (fun Dummy -> ())
    (fun () -> Dummy)
    (Data_encoding.constant "dummy")

let encoding =
  let open Data_encoding in
  conv
    (fun {hash; offset} -> (hash, offset))
    (fun (hash, offset) -> {hash; offset})
    (obj2 (req "hash" hash_encoding) (req "offset" int64))

let available {offset; hash = _} = Z.of_int64 offset

let empty = {hash = Dummy; offset = 0L}

let add_message {hash; offset} _bytes = {hash; offset = Int64.succ offset}

let add_messages inbox messages = List.fold_left add_message inbox messages

let consume_n_messages {hash; offset} ~n =
  if Compare.Int.(n <= 0) then invalid_arg "consume_n_messages" ;
  if Compare.Int64.(Int64.of_int n > offset) then None
  else Some {hash; offset = Int64.sub offset (Int64.of_int n)}
