(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

module T = Tezos_tree_encoding.Wrapped
module Runner = Tezos_tree_encoding.Runner.Make (Tezos_tree_encoding.Wrapped)
module E = Tezos_tree_encoding
module Storage = Tezos_webassembly_interpreter.Durable_storage
module CBV = Tezos_lazy_containers.Immutable_chunked_byte_vector

type t = CBV.t Tezos_lazy_containers.Lazy_fs.t

(* The maximum size of bytes allowed to be read/written at once. *)
let max_store_io_size = 2048L

exception Invalid_key of string

exception Index_too_large of int

exception Value_not_found

exception Tree_not_found

exception Out_of_bounds of (int64 * int64)

exception IO_too_large

exception Readonly_value

exception Durable_empty

let encoding = Tezos_lazy_containers.Lazy_fs.encoding CBV.encoding

type kind = Value | Directory

type key = Writeable of string list | Readonly of string list

let of_storage ~default s =
  match Storage.to_tree s with Some t -> t | None -> default

let of_storage_exn s = Storage.to_tree_exn s

let to_storage d = Storage.of_tree d

(* A key is bounded to 250 bytes, including the implicit '/durable' prefix.
   Additionally, values are implicitly appended with '_'. **)
let max_key_length = 250 - String.length "/durable" - String.length "/@"

let key_of_string_exn s =
  if String.length s > max_key_length then raise (Invalid_key s) ;
  let key =
    match String.split '/' s with
    | "" :: tl -> tl (* Must start with '/' *)
    | _ -> raise (Invalid_key s)
  in
  let assert_valid_char = function
    | '.' | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-' | '_' -> ()
    | _ -> raise (Invalid_key s)
  in
  let all_steps_valid =
    List.for_all (fun x ->
        x <> ""
        &&
        (String.iter assert_valid_char x ;
         true))
  in
  if all_steps_valid key then
    match key with "readonly" :: _ | [] -> Readonly key | _ -> Writeable key
  else raise (Invalid_key s)

let key_of_string_opt s =
  try Some (key_of_string_exn s) with Invalid_key _ -> None

let assert_key_writeable = function
  | Readonly _ -> raise Readonly_value
  | Writeable _ -> ()

let assert_max_bytes max_bytes =
  if max_store_io_size < max_bytes then raise IO_too_large

let key_contents = function Readonly k | Writeable k -> k

(* This module contains helpers,
   that used to implement Durable storage functions
   from the previous versions,
   in order to keep backward compatibility
*)
module Backward_compatible = struct
  module E = Tezos_tree_encoding
  module Lazy_fs = Tezos_lazy_containers.Lazy_fs

  let value_marker = "@"

  (* This function encodes either Lazy_fs subtree to irmin tree
      or just value, depending on [kind].
      If origin of the Lazy_fs is known,
      we encode a tree to this origin,
      otherwise we will encode to a freshly created in-memory tree.

      The function might return None if the all subkeys were removed
      in the passed Lazy_fs instance.

      This function doesn't retain encoded tree as a new origin.
      This might cause perfomance degrade (for instance,
      for repeating invocation of [subtree_name_at]).
      TODO: https://gitlab.com/tezos/tezos/-/issues/5287
  *)
  let encode_to_tree ?(kind = Directory) subtree : E.wrapped_tree option Lwt.t =
    let open Lwt_syntax in
    let value = subtree.Lazy_fs.content in
    let value_encoding = E.scope_option ["@"] CBV.encoding in
    let E.Wrapped_tree (underlying, (module M)), origin_soruce =
      Lazy_fs.tree_instance subtree
    in
    let unaccessible_path = ["@"; "unaccessible_path"] in
    let module M_runner = E.Runner.Make (M) in
    let+ new_uderlying =
      match (kind, origin_soruce) with
      | Directory, Origin ->
          Lwt.map Option.some @@ M_runner.encode encoding subtree underlying
      | Directory, From_parent ->
          let* tree =
            M_runner.encode
              (E.scope unaccessible_path encoding)
              subtree
              underlying
          in
          M.find_tree tree unaccessible_path
      | Value, Origin ->
          Lwt.map Option.some @@ M_runner.encode value_encoding value underlying
      | Value, From_parent ->
          let* tree =
            M_runner.encode
              (E.scope unaccessible_path value_encoding)
              value
              underlying
          in
          M.find_tree tree unaccessible_path
    in
    Option.map
      (fun new_uderlying -> E.Wrapped_tree (new_uderlying, (module M)))
      new_uderlying

  let hash ~kind subtree =
    let open Lwt_syntax in
    let* wrapped_opt = encode_to_tree ~kind subtree in
    match wrapped_opt with
    | None -> Lwt.return_none
    | Some (E.Wrapped_tree (tree, (module T))) ->
        let+ opt_tree =
          match kind with
          | Value -> T.find_tree tree [value_marker]
          | Directory -> Lwt.return_some tree
        in
        Option.map T.hash opt_tree

  let list subtree =
    let open Lwt.Syntax in
    let* wrapped_opt = encode_to_tree subtree in
    match wrapped_opt with
    | None -> Lwt.return []
    | Some (E.Wrapped_tree (tree, (module T))) ->
        let+ subtrees = T.list tree [] in
        List.map (fun (name, _) -> if name = "@" then "" else name) subtrees

  let subtree_name_at subtree index =
    let open Lwt.Syntax in
    let* wrapped_opt = encode_to_tree subtree in
    match wrapped_opt with
    | None -> raise (Index_too_large index)
    | Some (E.Wrapped_tree (tree, (module T))) -> (
        let* list = T.list ~offset:index ~length:1 tree [] in
        let nth = List.nth list 0 in
        match nth with
        | Some (step, _) when Compare.String.(step = value_marker) ->
            Lwt.return ""
        | Some (step, _) -> Lwt.return step
        | None -> raise (Index_too_large index))
end

let find_value (tree : t) key =
  let key = key_contents key in
  Tezos_lazy_containers.Lazy_fs.find tree key

let find_value_exn tree key =
  let open Lwt.Syntax in
  let+ opt = find_value tree key in
  match opt with None -> raise Value_not_found | Some value -> value

(** helper function used in the copy/move *)
let find_tree_exn (tree : t) key =
  let open Lwt.Syntax in
  let key = key_contents key in
  let+ opt = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  match opt with None -> raise Tree_not_found | Some subtree -> subtree

let copy_tree_exn (tree : t) ?(edit_readonly = false) from_key to_key =
  let open Lwt.Syntax in
  if not edit_readonly then assert_key_writeable to_key ;
  let* move_tree = find_tree_exn tree from_key in
  let to_key = key_contents to_key in
  Tezos_lazy_containers.Lazy_fs.add_tree tree to_key move_tree

let list (tree : t) key =
  let open Lwt.Syntax in
  let key = key_contents key in
  let* subtree = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  match subtree with
  | None -> Lwt.return []
  | Some subtree -> Backward_compatible.list subtree

let count_subtrees tree key =
  let open Lwt.Syntax in
  let key = key_contents key in
  let+ tree = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  match tree with
  | Some tree ->
      Tezos_lazy_containers.Lazy_dirs.length tree.dirs
      + Option.fold ~none:0 ~some:(fun _ -> 1) tree.content
  | None -> 0

let delete ?(edit_readonly = false) ~kind tree key =
  if not edit_readonly then assert_key_writeable key ;
  match kind with
  | Value -> Tezos_lazy_containers.Lazy_fs.remove_value tree (key_contents key)
  | Directory -> Tezos_lazy_containers.Lazy_fs.remove tree (key_contents key)

let subtree_name_at tree key (index : int) : string Lwt.t =
  let open Lwt.Syntax in
  let* subtree = find_tree_exn tree key in
  Backward_compatible.subtree_name_at subtree index

let move_tree_exn tree from_key to_key =
  let open Lwt.Syntax in
  assert_key_writeable from_key ;
  assert_key_writeable to_key ;
  let* move_tree = find_tree_exn tree from_key in
  let* tree = delete ~kind:Directory tree from_key in
  Tezos_lazy_containers.Lazy_fs.add_tree tree (key_contents to_key) move_tree

let hash ~kind (tree : t) key : Context_hash.t option Lwt.t =
  let open Lwt.Syntax in
  let key = key_contents key in
  let* subtree = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  Option.fold
    ~none:Lwt.return_none
    ~some:(Backward_compatible.hash ~kind)
    subtree

let hash_exn ~kind tree key =
  let open Lwt.Syntax in
  let+ opt = hash ~kind tree key in
  match opt with
  | None ->
      let exn =
        match kind with Value -> Value_not_found | Directory -> Tree_not_found
      in
      raise exn
  | Some hash -> hash

let set_value_exn (tree : t) ?(edit_readonly = false) key str =
  if not edit_readonly then assert_key_writeable key ;
  let key = key_contents key in
  Tezos_lazy_containers.Lazy_fs.set tree key (CBV.of_string str)

let create_value_exn tree ?(edit_readonly = false) key size =
  let open Lwt.Syntax in
  if not edit_readonly then assert_key_writeable key ;
  let key = key_contents key in
  let* opt = Tezos_lazy_containers.Lazy_fs.find tree key in
  match opt with
  | None ->
      Lwt.map Option.some
      @@ Tezos_lazy_containers.Lazy_fs.set tree key (CBV.allocate size)
  | Some _subtree -> Lwt.return_none

let write_value_exn tree ?(edit_readonly = false) key offset bytes =
  if not edit_readonly then assert_key_writeable key ;

  let open Lwt.Syntax in
  let num_bytes = Int64.of_int @@ String.length bytes in
  assert_max_bytes num_bytes ;

  let key = key_contents key in
  let* opt = Tezos_lazy_containers.Lazy_fs.find tree key in
  let value = match opt with None -> CBV.allocate 0L | Some cbv -> cbv in
  let vec_len = CBV.length value in
  if offset > vec_len then raise (Out_of_bounds (offset, vec_len)) ;
  let grow_by = Int64.(num_bytes |> add offset |> Fun.flip sub vec_len) in
  let value =
    if Int64.compare grow_by 0L > 0 then CBV.grow value grow_by else value
  in
  let* value = CBV.store_bytes value offset @@ Bytes.of_string bytes in
  Tezos_lazy_containers.Lazy_fs.set tree key value

let read_value_exn tree key offset num_bytes =
  let open Lwt.Syntax in
  assert_max_bytes num_bytes ;

  let* value = find_value_exn tree key in
  let vec_len = CBV.length value in

  if offset < 0L || offset >= vec_len then
    raise (Out_of_bounds (offset, vec_len)) ;

  let num_bytes =
    Int64.(num_bytes |> add offset |> min vec_len |> Fun.flip sub offset)
  in
  let+ bytes = CBV.load_bytes value offset num_bytes in
  Bytes.to_string bytes

module Internal_for_tests = struct
  let key_is_readonly = function Readonly _ -> true | Writeable _ -> false

  let key_to_list = key_contents
end
