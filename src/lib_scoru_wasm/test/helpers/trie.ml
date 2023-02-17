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

open Option_syntax
module Map = Map.Make (String)

type 'a t = {
  value : 'a option;
  children : 'a t Map.t;
  keys_count : int;
  nodes_count : int; (* including empty one *)
}

let empty =
  {value = None; children = Map.empty; keys_count = 0; nodes_count = 0}

let replace_value t new_v =
  match t.value with
  | None -> {t with value = Some new_v; keys_count = t.keys_count + 1}
  | Some _ -> {t with value = Some new_v}

let replace_child t step new_c =
  let old_c = Option.value ~default:empty @@ Map.find step t.children in
  let new_c_info = Option.value ~default:empty new_c in
  {
    t with
    children = Map.update step (Fun.const new_c) t.children;
    keys_count = t.keys_count - old_c.keys_count + new_c_info.keys_count;
    nodes_count = t.nodes_count - old_c.nodes_count + new_c_info.nodes_count;
  }

(* Helpers *)
let split_key (key : string) = Some (String.split '/' key)

let guard_opt b = if b then Some () else None

let is_key_readonly = function "readonly" :: _ -> true | _ -> false

let rec create_path (t : 'a t) f_t = function
  | [] -> f_t t
  | k :: rest ->
      let child = Option.value ~default:empty @@ Map.find k t.children in
      let new_child = create_path child f_t rest in
      replace_child t k (Some new_child)

let lookup (key : string) root : 'a t option =
  let* key = split_key key in
  let rec lookup_impl t = function
    | [] -> Some t
    | k :: rest ->
        let* child = Map.find k t.children in
        lookup_impl child rest
  in
  lookup_impl root key

(* Public functions.
   Functions return Some if an operation has completed successfully.
*)
let set_value ~edit_readonly key v root =
  let* key = split_key key in
  let+ () = guard_opt ((not (is_key_readonly key)) || edit_readonly) in
  create_path root (fun t -> replace_value t v) key

let get_value key root =
  Option.join @@ Option.map (fun x -> x.value) @@ lookup key root

let subtrees_size key root =
  Option.fold ~none:0 ~some:(fun x -> Map.cardinal x.children)
  @@ lookup key root

let delete ~edit_readonly key root =
  let* key = split_key key in
  let* () = guard_opt ((not (is_key_readonly key)) || edit_readonly) in
  let is_empty {value; children; _} =
    Option.is_none value && Map.is_empty children
  in
  (* Return None if tree is not changed in result of deletion *)
  let rec delete_tree_impl t = function
    | [] -> None
    | [k] -> Some (replace_child t k None)
    | k :: rest ->
        let* child = Map.find k t.children in
        let+ new_child = delete_tree_impl child rest in
        let new_t = replace_child t k None in
        (* If k is the only child of t and has no value,
           then we should "collapse" this branch *)
        if is_empty new_child && is_empty new_t then empty
          (* If new_child is empty: we don't need to store it anymore *)
        else if is_empty new_child then new_t
          (* Just replace old k with new one*)
        else replace_child t k (Some new_child)
  in
  delete_tree_impl root key

let copy_tree ~edit_readonly (from_key : string) (to_key : string) root :
    'a t option =
  let* to_key = split_key to_key in
  let* from_t = lookup from_key root in
  let+ () = guard_opt ((not (is_key_readonly to_key)) || edit_readonly) in
  create_path root (Fun.const from_t) to_key

let move_tree (from_key : string) (to_key : string) root : 'a t option =
  let* from_key_lst = split_key from_key in
  let* to_key = split_key to_key in
  let* () =
    guard_opt
      ((not (is_key_readonly from_key_lst)) && not (is_key_readonly to_key))
  in
  let* from_t = lookup from_key root in
  let+ root = delete ~edit_readonly:true from_key root in
  create_path root (Fun.const from_t) to_key
