(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs  <contact@nomadic-labs.com>               *)
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

exception Missing_key of string

module Dict = Map.Make (String)

type tree = ..

type 'a producer = tree option -> string -> 'a Lwt.t

type ('k, 'a) t = {
  origin : tree option;
  string_of_key : 'k -> string;
  produce_value : 'a producer;
  mutable values : 'a Dict.t;
}

let create ?origin ?produce_value string_of_key =
  match (origin, produce_value) with
  | Some _, Some produce_value ->
      {origin; string_of_key; produce_value; values = Dict.empty}
  | None, Some produce_value ->
      {origin; string_of_key; produce_value; values = Dict.empty}
  | None, None ->
      {
        origin = None;
        string_of_key;
        produce_value = (fun _tree key -> Lwt.fail (Missing_key key));
        values = Dict.empty;
      }
  | Some _, None -> raise (Invalid_argument "create: missing backend")

let get key dict =
  let open Lwt.Syntax in
  let key = dict.string_of_key key in
  match Dict.find_opt key dict.values with
  | Some v -> Lwt.return v
  | None ->
      let+ v = dict.produce_value dict.origin key in
      dict.values <- Dict.add key v dict.values ;
      v

let set key v dict =
  {dict with values = Dict.add (dict.string_of_key key) v dict.values}

let loaded_bindings dict = Dict.bindings dict.values
