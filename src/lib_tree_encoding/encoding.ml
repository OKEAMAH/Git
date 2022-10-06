(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

type key = string list

exception No_tag_matched_on_encoding

(** [append_key prefix key] append [key] to [prefix] in order to create a new
      [prefix_key]. *)
let append_key prefix key tail = prefix (List.append key tail)

(** Given the tail key, construct a full key. *)
type prefix_key = key -> key

type -'a custom = {
  encode : 'tree. 'tree Tree.backend -> 'a -> prefix_key -> 'tree -> 'tree Lwt.t;
}
[@@unboxed]

type 'tag destruction =
  | Destruction : {tag : 'tag; res : 'b; encode : 'b t} -> 'tag destruction

and 'a t =
  | Custom : 'a custom -> 'a t
  | Tup2 : 'a t * 'b t -> ('a * 'b) t
  | Tup3 : 'a t * 'b t * 'c t -> ('a * 'b * 'c) t
  | Scope : key * 'a t -> 'a t
  | TaggedUnion : 'tag t * ('a -> 'tag destruction) -> 'a t
  | Delayed : (unit -> 'a t) -> 'a t
  | Contramap : ('b -> 'a) * 'a t -> 'b t
  | Raw : key -> bytes t
  | Value_option : key * 'a Data_encoding.t -> 'a option t

let ignore = Custom {encode = (fun _backend _val _key tree -> Lwt.return tree)}

let rec eval :
    type a tree.
    a t -> tree Tree.backend -> a -> prefix_key -> tree -> tree Lwt.t =
 fun encoder backend value prefix tree ->
  let open Lwt.Syntax in
  match encoder with
  | Custom {encode} -> encode backend value prefix tree
  | Tup2 (lhs, rhs) ->
      let l, r = value in
      let* tree = eval lhs backend l prefix tree in
      eval rhs backend r prefix tree
  | Tup3 (encode_a, encode_b, encode_c) ->
      let a, b, c = value in
      let* tree = eval encode_a backend a prefix tree in
      let* tree = eval encode_b backend b prefix tree in
      eval encode_c backend c prefix tree
  | Scope (key, encoder) ->
      eval encoder backend value (append_key prefix key) tree
  | TaggedUnion (tag_encoding, select) ->
      let (Destruction {tag; res; encode}) = select value in
      let encode = Scope (["value"], encode) in
      let* tree = eval tag_encoding backend tag prefix tree in
      eval encode backend res prefix tree
  | Delayed f -> eval (f ()) backend value prefix tree
  | Contramap (f, encoder) -> eval encoder backend (f value) prefix tree
  | Raw suffix -> Tree.add backend tree (prefix suffix) value
  | Value_option (key, enc) -> (
      let venc = Contramap (Data_encoding.Binary.to_bytes_exn enc, Raw key) in
      match value with
      | Some v -> eval venc backend v prefix tree
      | None -> Tree.remove backend tree (prefix key))

let run backend encoder value tree = eval encoder backend value Fun.id tree

let lwt encoder =
  Custom
    {
      encode =
        (fun backend value prefix tree ->
          let open Lwt_syntax in
          let* v = value in
          eval encoder backend v prefix tree);
    }

let delayed f = Delayed f

let contramap f encoder = Contramap (f, encoder)

let contramap_lwt f encoder =
  Custom
    {
      encode =
        (fun backend value prefix tree ->
          let open Lwt_syntax in
          let* v = f value in
          eval encoder backend v prefix tree);
    }

let tup2 lhs rhs = Tup2 (lhs, rhs)

let tup3 encode_a encode_b encode_c = Tup3 (encode_a, encode_b, encode_c)

let raw suffix = Raw suffix

let value suffix enc =
  contramap (Data_encoding.Binary.to_bytes_exn enc) (raw suffix)

let value_option key enc = Value_option (key, enc)

let scope key encoder = Scope (key, encoder)

let lazy_mapping to_key enc_value =
  Custom
    {
      encode =
        (fun backend (origin, bindings) prefix tree ->
          let open Lwt_syntax in
          let* tree =
            match origin with
            | Some origin ->
                Tree.add_tree
                  backend
                  tree
                  (prefix [])
                  (Tree.select backend origin)
            | None -> return tree
          in
          List.fold_left_s
            (fun tree (k, v) ->
              let key = append_key prefix (to_key k) in
              let* tree = Tree.remove backend tree (key []) in
              eval enc_value backend v key tree)
            tree
            bindings);
    }

type ('tag, 'a) case =
  | Case : {
      tag : 'tag;
      probe : 'a -> 'b Lwt.t option;
      encode : 'b t;
    }
      -> ('tag, 'a) case

let case_lwt tag encode probe = Case {tag; encode; probe}

let case tag encode probe =
  let probe x = Option.map Lwt.return @@ probe x in
  case_lwt tag encode probe

let tagged_union encode_tag cases =
  Custom
    {
      encode =
        (fun backend value prefix target_tree ->
          let open Lwt_syntax in
          let encode_tag = scope ["tag"] encode_tag in
          let match_case (Case {probe; tag; encode}) =
            match probe value with
            | Some res ->
                let* target_tree =
                  eval encode_tag backend tag prefix target_tree
                in
                let* value = res in
                let* x =
                  eval (scope ["value"] encode) backend value prefix target_tree
                in
                return (Some x)
            | None -> return None
          in
          let* tree_opt = List.find_map_s match_case cases in
          match tree_opt with
          | None -> raise No_tag_matched_on_encoding
          | Some tree -> return tree);
    }

let wrapped_tree =
  Custom
    {
      encode =
        (fun backend (Tree.Wrapped_tree (subtree, backend')) prefix target_tree ->
          let subtree = Tree.select backend (Tree.wrap backend' subtree) in
          let key = prefix [] in
          Tree.add_tree backend target_tree key subtree);
    }

let destruction ~tag ~res ~encode = Destruction {tag; res; encode}

let fast_tagged_union tag_encoding select =
  let tag_encoding = scope ["tag"] tag_encoding in
  TaggedUnion (tag_encoding, select)
