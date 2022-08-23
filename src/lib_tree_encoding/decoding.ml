(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

exception Exceeded_max_num_decoding_steps

(** Given the tail key, construct a full key. *)
type prefix_key = key -> key

(** [of_key key] constructs a [prefix_key] where [key] is the prefix. *)
let of_key key tail =
  let rec go = function [] -> tail | x :: xs -> x :: go xs in
  go key

(** [append_key prefix key] append [key] to [prefix] in order to create a new
      [prefix_key]. *)
let append_key prefix key tail = prefix (of_key key tail)

type 'a t = {
  decode :
    'tree.
    (* The tree backend. *)
    'tree Tree.backend ->
    (* The maximum number of remaining computation steps. *)
    int option ->
    (* The tree to decode from. *)
    'tree ->
    (* The key to read from. *)
    prefix_key ->
    (* Returns a value along with the remaining computation steps. *)
    ('a * int option) Lwt.t;
}
[@@unboxed]

(* Decrement the remaining rem_steps budget if given. *)
let consume_step = function
  | None -> None
  | Some n when n <= 0 -> raise Exceeded_max_num_decoding_steps
  | Some n -> Some (n - 1)

type ('tag, 'a) case =
  | Case : {
      tag : 'tag;
      extract : 'b -> 'a Lwt.t;
      decode : 'b t;
    }
      -> ('tag, 'a) case

let delayed f =
  {
    decode =
      (fun backend rem_steps ->
        let rem_steps = consume_step rem_steps in
        let {decode} = f () in
        decode backend rem_steps);
  }

let of_lwt lwt =
  {
    decode =
      (fun _backend rem_steps _tree _prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* value = lwt in
        return (value, rem_steps));
  }

let map f {decode} =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let+ value, rem_steps = decode backend rem_steps tree prefix in
        (f value, rem_steps));
  }

let map_lwt f {decode} =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* value, rem_steps =
          decode backend (consume_step rem_steps) tree prefix
        in
        let* value = f value in
        return (value, rem_steps));
  }

module Syntax = struct
  let return value =
    {
      decode =
        (fun _backend rem_steps _tree _prefix ->
          Lwt.return (value, consume_step rem_steps));
    }

  let bind {decode} f =
    {
      decode =
        (fun backend rem_steps tree prefix ->
          let open Lwt_syntax in
          let rem_steps = consume_step rem_steps in
          let* value, rem_steps = decode backend rem_steps tree prefix in
          let rem_steps = consume_step rem_steps in
          let {decode} = f value in
          decode backend rem_steps tree prefix);
    }

  let both lhs rhs =
    {
      decode =
        (fun backend rem_steps tree prefix ->
          let open Lwt_syntax in
          let rem_steps = consume_step rem_steps in
          let* x, rem_steps = lhs.decode backend rem_steps tree prefix in
          let rem_steps = consume_step rem_steps in
          let* y, rem_steps = rhs.decode backend rem_steps tree prefix in
          return ((x, y), rem_steps));
    }

  let ( let+ ) m f = map f m

  let ( and+ ) = both

  let ( let* ) = bind

  let ( and* ) = ( and+ )
end

let run ?max_num_steps backend {decode} tree =
  Lwt.map fst @@ decode backend max_num_steps tree Fun.id

let raw key =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let key = prefix key in
        let rem_steps = consume_step rem_steps in
        let+ value = Tree.find backend tree key in
        match value with
        | Some value -> (value, rem_steps)
        | None -> raise (Key_not_found key));
  }

let value_option key decoder =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let key = prefix key in
        let rem_steps = consume_step rem_steps in
        let* value = Tree.find backend tree key in
        match value with
        | Some value -> (
            let rem_steps = consume_step rem_steps in
            match Data_encoding.Binary.of_bytes decoder value with
            | Ok value -> return (Some value, rem_steps)
            | Error error -> raise (Decode_error {key; error}))
        | None -> return (None, rem_steps));
  }

let value ?default key decoder =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* value, rem_steps =
          let {decode} = value_option key decoder in
          decode backend rem_steps tree prefix
        in
        match (value, default) with
        | Some value, _ -> return (value, rem_steps)
        | None, Some default -> return (default, rem_steps)
        | None, None -> raise (Key_not_found (prefix key)));
  }

let subtree =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let+ tree = Tree.find_tree backend tree (prefix []) in
        match tree with
        | Some tree -> (Some (Tree.wrap backend tree), rem_steps)
        | None -> (None, rem_steps));
  }

let scope key {decode} =
  {
    decode =
      (fun backend rem_steps tree prefix ->
        let rem_steps = consume_step rem_steps in
        decode backend rem_steps tree (append_key prefix key));
  }

let lazy_mapping to_key field_enc =
  {
    decode =
      (fun backend rem_steps input_tree input_prefix ->
        let open Lwt_syntax in
        let produce_value index =
          let {decode} = scope (to_key index) field_enc in
          let* value, _rem_steps =
            decode backend rem_steps input_tree input_prefix
          in
          return value
        in
        return (produce_value, consume_step rem_steps));
  }

let case_lwt tag decode extract = Case {tag; decode; extract}

let case tag decode extract =
  case_lwt tag decode (fun x -> Lwt.return @@ extract x)

let tagged_union ?default decode_tag cases =
  {
    decode =
      (fun backend rem_steps input_tree prefix ->
        let open Lwt_syntax in
        Lwt.try_bind
          (fun () ->
            let rem_steps = consume_step rem_steps in
            let {decode} = scope ["tag"] decode_tag in
            decode backend rem_steps input_tree prefix)
          (fun (target_tag, rem_steps) ->
            let rem_steps = consume_step rem_steps in
            (* Search through the cases to find a matching branch. *)
            let* candidate, rem_steps =
              List.fold_left_s
                (fun (found_value, rem_steps) (Case {tag; decode; extract}) ->
                  match found_value with
                  | Some value -> return (Some value, consume_step rem_steps)
                  | None ->
                      let rem_steps = consume_step rem_steps in
                      if tag = target_tag then
                        let {decode} =
                          map_lwt extract (scope ["value"] decode)
                        in
                        let* value, rem_steps =
                          decode backend rem_steps input_tree prefix
                        in
                        return (Some value, rem_steps)
                      else return (None, rem_steps))
                (None, rem_steps)
                cases
            in
            match candidate with
            | Some case -> return (case, rem_steps)
            | None -> raise No_tag_matched_on_decoding)
          (function
            | Key_not_found _ as exn -> (
                match default with
                | Some default -> return (default, rem_steps)
                | None -> raise exn)
            | exn -> raise exn));
  }
