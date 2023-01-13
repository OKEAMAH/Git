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

type 'a t = {content : 'a option; dirs : 'a t Lazy_dirs.t}

let empty () = {content = None; dirs = Lazy_dirs.create ()}

let rec find_tree tree key =
  let open Lwt.Syntax in
  match key with
  | [] -> Lwt.return_some tree
  | step :: steps -> (
      let* maybe_tree = Lazy_dirs.find tree.dirs step in
      match maybe_tree with
      | Some tree -> find_tree tree steps
      | None -> Lwt.return_none)

let find tree key =
  let open Lwt.Syntax in
  let+ tree = find_tree tree key in
  Option.map (fun tree -> tree.content) tree |> Option.join

let rec construct_tree key value_tree =
  match key with
  | [] -> value_tree
  | step :: steps ->
      let values =
        Lazy_dirs.Map.Map.singleton step (construct_tree steps value_tree)
      in
      let dirs = Lazy_dirs.create ~values () in
      {content = None; dirs}

let rec place_tree tree key f =
  let open Lwt.Syntax in
  match key with
  | [] -> Lwt.return (f (Some tree))
  | step :: steps -> (
      let* maybe_tree = Lazy_dirs.find tree.dirs step in
      match maybe_tree with
      | Some tree ->
          let+ new_tree = place_tree tree steps f in
          let dirs = Lazy_dirs.add tree.dirs step new_tree in
          {tree with dirs}
      | None ->
          let dirs =
            Lazy_dirs.add tree.dirs step (construct_tree steps (f None))
          in
          Lwt.return {tree with dirs})

let add_tree tree key value_tree = place_tree tree key (fun _ -> value_tree)

let add tree key value =
  place_tree tree key @@ function
  | None -> {content = Some value; dirs = Lazy_dirs.create ()}
  | Some tree -> {tree with content = Some value}

let rec remove tree key =
  let open Lwt.Syntax in
  match key with
  | [] -> Lwt.return tree
  | [step] -> Lwt.return {tree with dirs = Lazy_dirs.remove tree.dirs step}
  | step :: steps -> (
      let* maybe_tree = Lazy_dirs.find tree.dirs step in
      match maybe_tree with
      | Some tree ->
          let+ new_tree = remove tree steps in
          let dirs = Lazy_dirs.add tree.dirs step new_tree in
          {tree with dirs}
      | None -> Lwt.return tree)

let length tree = Lazy_dirs.length tree.dirs

let list tree = Lazy_dirs.list tree.dirs

let nth_name tree n = Lazy_dirs.nth_name tree.dirs n
