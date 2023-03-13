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

module E = Tezos_tree_encoding
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

let encoding = E.(lazy_fs immutable_chunked_byte_vector)

type key = Writeable of string list | Readonly of string list

let of_storage ~default:_ s = s

let of_storage_exn s = s

let to_storage d = d

(* A key is bounded to 250 bytes, including the implicit '/durable' prefix.
   Additionally, values are implicitly appended with '_'. **)
let max_key_length = 250 - String.length "/durable" - String.length "/_"

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
  module Inmemory_tree = Encodings_util.Tree
  module Lazy_fs = Tezos_lazy_containers.Lazy_fs
  module W = Tezos_tree_encoding.Wrapped

  let value_marker = "@"

  type some_tree =
    | Some_tree :
        't * (module Tezos_tree_encoding.TREE with type tree = 't)
        -> some_tree

  (* This function convert Lazy_fs to irmin tree:
     if we had underlying tree, we just use it,
     otherwise we will encode to in-memory tree *)
  let encode_to_t subtree : some_tree Lwt.t =
    let open Lwt_syntax in
    match Lazy_fs.origin subtree with
    (* If we know the origin, we should decode it
       in order to dump all changed in-memory values,
       then we can return lookup it *)
    | Some t ->
        (* Format.printf "O WE HAVE ORIGIN\n" ; *)
        (* We could preserve this encoding into current durable,
            now it just gets thrown away *)
        (* This part looks so complicated because:
           1. Durable storage "remembers" during first decode in its origin where it was decoded from.
           2. When we try to encode subtree in this fuction using in-memory tree:
              it fails because those "remembered" origin type and in-memory diverge (they match only in tests, in real run - no).
           3. So the solution is to do the similar thing which was done in old durable: to wrap origin with Wrapped tree on decode,
              and unwrap on encode. So here we can dispatch on actually methods of original tree.
           4. However the problem now, that when we try to encode for hashes/subtree/list we face situation,
              that we can't encode into Wrapped tree, we have to encode into underlying tree.
        *)
        Lwt.catch
          (fun () ->
            let (Wrapped_tree (underlying, (module M))) = W.select t in
            let module Underlying_runner = Tezos_tree_encoding.Runner.Make (M) in
            let+ new_uderlying =
              Underlying_runner.encode encoding subtree underlying
            in
            Some_tree (new_uderlying, (module M)))
          (fun exn ->
            Format.printf "EXN: %s\n" (Printexc.to_string exn) ;
            raise exn)
    | None ->
        (* If it happeneded so that we don't know an origin,
           we will fallback to inmemory tree *)
        (* Format.printf
           "Backward_compatible.encode_to_t before Encoding_util.empty_tree\n" ; *)
        let* tree = Encodings_util.empty_tree () in
        (* Format.printf
           "Backward_compatible.encode_to_t before Tree_encoding_runner.encode\n" ; *)
        (* Encode it to empty irmin tree *)
        let+ inmemory =
          Lwt.catch
            (fun () ->
              Encodings_util.Tree_encoding_runner.encode encoding subtree tree)
            (fun exn ->
              Format.printf "EXN: %s\n" (Printexc.to_string exn) ;
              raise exn)
        in
        Some_tree (inmemory, (module Inmemory_tree))

  let hash subtree =
    let open Lwt_syntax in
    Format.printf "Backward_compatible.hash before encoding to irmin tree\n" ;
    let* (Some_tree (tree, (module T))) = encode_to_t subtree in
    Format.printf "Backward_compatible.hash encoded to irmin tree\n" ;
    (* We only need hash of '@' subtree, hence we have to lookup it first.
       This place might is subject for optimization:
       we don't need to encode the WHOLE Lazy_fs subtree,
       it's enough to encode only value to @.
    *)
    let+ opt = T.find_tree tree [value_marker] in
    Format.printf "Backward_compatible.hash found value marker\n" ;
    Option.map T.hash opt

  let list subtree =
    let open Lwt.Syntax in
    let* (Some_tree (tree, (module T))) = encode_to_t subtree in
    let+ subtrees = T.list tree [] in
    List.map (fun (name, _) -> if name = "@" then "" else name) subtrees

  let subtree_name_at subtree index =
    let open Lwt.Syntax in
    let* (Some_tree (tree, (module T))) = encode_to_t subtree in
    let* list = T.list ~offset:index ~length:1 tree [] in
    let nth = List.nth list 0 in
    match nth with
    | Some (step, _) when Compare.String.(step = value_marker) -> Lwt.return ""
    | Some (step, _) -> Lwt.return step
    | None -> raise (Index_too_large index)
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

let count_subtrees (tree : t) key =
  let open Lwt.Syntax in
  let key = key_contents key in
  let+ tree = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  match tree with
  | Some tree ->
      Tezos_lazy_containers.Lazy_dirs.length tree.dirs
      + Option.fold ~none:0 ~some:(fun _ -> 1) tree.content
  | None -> 0

let delete ?(edit_readonly = false) (tree : t) key : t Lwt.t =
  if not edit_readonly then assert_key_writeable key ;
  Tezos_lazy_containers.Lazy_fs.remove tree (key_contents key)

let subtree_name_at tree key (index : int) : string Lwt.t =
  let open Lwt.Syntax in
  let* subtree = find_tree_exn tree key in
  Backward_compatible.subtree_name_at subtree index

let move_tree_exn tree from_key to_key =
  let open Lwt.Syntax in
  assert_key_writeable from_key ;
  assert_key_writeable to_key ;
  let* move_tree = find_tree_exn tree from_key in
  let* tree = delete tree from_key in
  Tezos_lazy_containers.Lazy_fs.add_tree tree (key_contents to_key) move_tree

let hash (tree : t) key : Context_hash.t option Lwt.t =
  let open Lwt_syntax in
  let key = key_contents key in
  (* Find a subtree *)
  let* subtree = Tezos_lazy_containers.Lazy_fs.find_tree tree key in
  Option.fold ~none:Lwt.return_none ~some:Backward_compatible.hash subtree

let hash_exn tree key =
  let open Lwt.Syntax in
  let+ opt = hash tree key in
  match opt with None -> raise Value_not_found | Some hash -> hash

let set_value_exn (tree : t) ?(edit_readonly = false) key str =
  if not edit_readonly then assert_key_writeable key ;
  let key = key_contents key in
  Tezos_lazy_containers.Lazy_fs.add tree key (CBV.of_string str)

let write_value_exn (tree : t) ?(edit_readonly = false) key offset bytes =
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
  Tezos_lazy_containers.Lazy_fs.add tree key value

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
