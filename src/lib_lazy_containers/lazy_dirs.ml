(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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

module Names = Set.Make (String)

module Map = Lazy_map.Make (struct
  include String

  let to_string = Fun.id
end)

type 'a t = {names : Names.t; contents : 'a Map.t}

let origin fs = Map.origin @@ fs.contents

let create ?names ?contents () =
  let lazy_value x ~default = match x with Some x -> x | None -> default () in
  {
    names =
      lazy_value names ~default:(fun () ->
          match contents with
          | None -> Names.empty
          | Some contents ->
              Map.loaded_bindings contents |> List.map fst |> Names.of_list);
    contents = lazy_value contents ~default:Map.create;
  }

let is_empty {names; _} = Names.is_empty names

let find tree key =
  let open Lwt.Syntax in
  if Names.mem key tree.names then
    let+ content = Map.get key tree.contents in
    Some content
  else Lwt.return_none

let set tree key value =
  {names = Names.add key tree.names; contents = Map.set key value tree.contents}

let remove tree key =
  {names = Names.remove key tree.names; contents = Map.remove key tree.contents}

let list tree = Names.elements tree.names

let length tree = Names.cardinal tree.names

let nth_name tree n = List.nth_opt (Names.elements tree.names) n

module Encoding = Tezos_tree_encoding.Lazy_dirs_encoding.Make (struct
  type nonrec 'a t = 'a t

  module Names = Names
  module Map = Map

  let contents x = x.contents

  let create = create

  let remove = remove
end)

let encoding = Encoding.lazy_dirs
