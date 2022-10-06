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

exception Key_not_found of key

exception No_tag_matched_on_decoding

exception Decode_error of {key : key; error : Data_encoding.Binary.read_error}

(** Given the tail key, construct a full key. *)
type prefix_key = key -> key

(** [of_key key] constructs a [prefix_key] where [key] is the prefix. *)
let of_key key tail =
  let rec go = function [] -> tail | x :: xs -> x :: go xs in
  go key

(** [append_key prefix key] append [key] to [prefix] in order to create a new
      [prefix_key]. *)
let append_key prefix key tail = prefix (of_key key tail)

type 'a custom = {
  decode : 'tree. 'tree Tree.backend -> 'tree -> prefix_key -> 'a Lwt.t;
}
[@@unboxed]

type 'a t =
  | Custom : 'a custom -> 'a t
  | Map : ('a -> 'b) * 'a t -> 'b t
  | Delayed : (unit -> 'a t) -> 'a t
  | Lwt : 'a Lwt.t -> 'a t
  | Map_lwt : ('a -> 'b Lwt.t) * 'a t -> 'b t
  | Return : 'a -> 'a t
  | Bind : 'a t * ('a -> 'b t) -> 'b t
  | Both : 'a t * 'b t -> ('a * 'b) t
  | Raw : key -> bytes t
  | Value_option : key * 'a Data_encoding.t -> 'a option t
  | Value_default : 'a option * key * 'a Data_encoding.t -> 'a t
  | Scope : key * 'a t -> 'a t
  | FastTaggedUnion :
      (unit -> 'b) option * 'a t * ('a -> 'b decoding_branch)
      -> 'b t

and _ decoding_branch =
  | DecodeBranch : {extract : 'b -> 'a; decode : 'b t} -> 'a decoding_branch

type ('tag, 'a) case =
  | Case : {
      tag : 'tag;
      extract : 'b -> 'a Lwt.t;
      decode : 'b t;
    }
      -> ('tag, 'a) case

let delayed f = Delayed f

let of_lwt lwt = Lwt lwt

let map f decoder = Map (f, decoder)

let map_lwt f decoder = Map_lwt (f, decoder)

module Syntax = struct
  let return value = Return value

  let bind decoder f = Bind (decoder, f)

  let both lhs rhs = Both (lhs, rhs)

  let ( let+ ) m f = map f m

  let ( and+ ) = both

  let ( let* ) = bind

  let ( and* ) = ( and+ )
end

let raw key = Raw key

let value_option key decoder = Value_option (key, decoder)

let value ?default key decoder = Value_default (default, key, decoder)

let subtree backend tree prefix =
  let open Lwt_syntax in
  let+ tree = Tree.find_tree backend tree (prefix []) in
  Option.map (Tree.wrap backend) tree

let scope key decoder = Scope (key, decoder)

let rec eval :
    type a tree. a t -> tree Tree.backend -> tree -> prefix_key -> a Lwt.t =
 fun decoding backend tree prefix ->
  match decoding with
  | Custom {decode} -> decode backend tree prefix
  | Map (f, decoder) -> Lwt.map f (eval decoder backend tree prefix)
  | Lwt promise -> promise
  | Delayed f -> eval (f ()) backend tree prefix
  | Map_lwt (f, decoder) -> Lwt.bind (eval decoder backend tree prefix) f
  | Return a -> Lwt.return a
  | Bind (decoder, f) ->
      Lwt.bind (eval decoder backend tree prefix) (fun x ->
          eval (f x) backend tree prefix)
  | Both (lhs, rhs) ->
      Lwt.both (eval lhs backend tree prefix) (eval rhs backend tree prefix)
  | Raw key -> (
      let open Lwt_syntax in
      let key = prefix key in
      let+ value = Tree.find backend tree key in
      match value with Some value -> value | None -> raise (Key_not_found key))
  | Value_option (key, decoder) -> (
      let open Lwt_syntax in
      let key = prefix key in
      let* value = Tree.find backend tree key in
      match value with
      | Some value -> (
          match Data_encoding.Binary.of_bytes decoder value with
          | Ok value -> return_some value
          | Error error -> raise (Decode_error {key; error}))
      | None -> return_none)
  | Value_default (default, key, decoder) -> (
      let open Lwt_syntax in
      let* value = eval (Value_option (key, decoder)) backend tree prefix in
      match (value, default) with
      | Some value, _ -> return value
      | None, Some default -> return default
      | None, None -> raise (Key_not_found (prefix key)))
  | Scope (key, decoder) -> eval decoder backend tree (append_key prefix key)
  | FastTaggedUnion (None, tag_decoder, select) ->
      let open Lwt_syntax in
      let* target_tag = eval tag_decoder backend tree prefix in
      let (DecodeBranch {decode; extract}) = select target_tag in
      eval (map extract (scope ["value"] decode)) backend tree prefix
  | FastTaggedUnion (Some default, tag_decoder, select) ->
      let open Lwt_syntax in
      Lwt.try_bind
        (fun () -> eval tag_decoder backend tree prefix)
        (fun target_tag ->
          let (DecodeBranch {decode; extract}) = select target_tag in
          eval (map extract (scope ["value"] decode)) backend tree prefix)
        (function Key_not_found _ -> return (default ()) | exn -> raise exn)

let run backend decoder tree = eval decoder backend tree Fun.id

let lazy_mapping to_key field_enc =
  Custom
    {
      decode =
        (fun backend input_tree input_prefix ->
          let open Lwt_syntax in
          let produce_value index =
            eval
              (scope (to_key index) field_enc)
              backend
              input_tree
              input_prefix
          in
          let+ tree = subtree backend input_tree input_prefix in
          (tree, produce_value));
    }

let case_lwt tag decode extract = Case {tag; decode; extract}

let case tag decode extract =
  case_lwt tag decode (fun x -> Lwt.return @@ extract x)

let slow_tagged_union ?default decode_tag cases =
  let tag_decoder = scope ["tag"] decode_tag in
  Custom
    {
      decode =
        (fun backend input_tree prefix ->
          let open Lwt_syntax in
          Lwt.try_bind
            (fun () -> eval tag_decoder backend input_tree prefix)
            (fun target_tag ->
              (* Search through the cases to find a matching branch. *)
              let candidate =
                List.find_map
                  (fun (Case {tag; decode; extract}) ->
                    if tag = target_tag then
                      Some
                        (eval
                           (map_lwt extract (scope ["value"] decode))
                           backend
                           input_tree
                           prefix)
                    else None)
                  cases
              in
              match candidate with
              | Some case -> case
              | None -> raise No_tag_matched_on_decoding)
            (function
              | Key_not_found _ as exn -> (
                  match default with
                  | Some default -> return (default ())
                  | None -> raise exn)
              | exn -> raise exn));
    }

let decode_branch ~extract ~decode = DecodeBranch {extract; decode}

let fast_tagged_union ?default decode_tag select =
  let tag_decoder = scope ["tag"] decode_tag in
  FastTaggedUnion (default, tag_decoder, select)

let wrapped_tree =
  Custom
    {
      decode =
        (fun backend tree prefix ->
          let open Lwt.Syntax in
          let+ tree = subtree backend tree prefix in
          match tree with
          | Some subtree ->
              Tree.Wrapped_tree (Tree.select backend subtree, backend)
          | _ -> raise Not_found);
    }
