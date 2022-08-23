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

exception No_tag_matched_on_encoding

exception Exceeded_max_num_encoding_steps

(** [append_key prefix key] append [key] to [prefix] in order to create a new
      [prefix_key]. *)
let append_key prefix key tail = prefix (List.append key tail)

(** Given the tail key, construct a full key. *)
type prefix_key = key -> key

type -'a t = {
  encode :
    'tree.
    (* Backend with the tree implementation. *)
    'tree Tree.backend ->
    (* Remaining number of computation steps. *)
    int option ->
    (* The value to encode. *)
    'a ->
    (* The key for where to encode the value. *)
    prefix_key ->
    (* The input tree. *)
    'tree ->
    (* Returns a new tree with the encoded value and the remaining number of
       steps. *)
    ('tree * int option) Lwt.t;
}
[@@unboxed]

(* Decrement the remaining rem_steps budget if given. *)
let consume_step = function
  | None -> None
  | Some n when n <= 0 -> raise Exceeded_max_num_encoding_steps
  | Some n -> Some (n - 1)

let ignore =
  {
    encode =
      (fun _backend rem_steps _val _key tree ->
        Lwt.return (tree, consume_step rem_steps));
  }

let run ?max_num_steps backend {encode} value tree =
  encode backend max_num_steps value Fun.id tree

let with_subtree get_subtree {encode} =
  {
    encode =
      (fun backend rem_steps value prefix input_tree ->
        let rem_steps = consume_step rem_steps in
        let open Lwt_syntax in
        match get_subtree value with
        | Some tree ->
            (* Update the rem_steps twice. One for each tree operation. *)
            let rem_steps = consume_step @@ consume_step rem_steps in
            let* input_tree = Tree.remove backend input_tree (prefix []) in
            let* input_tree =
              Tree.add_tree
                backend
                input_tree
                (prefix [])
                (Tree.select backend tree)
            in
            encode backend rem_steps value prefix input_tree
        | None -> encode backend rem_steps value prefix input_tree);
  }

let lwt {encode} =
  {
    encode =
      (fun backend rem_steps value prefix tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* v = value in
        encode backend rem_steps v prefix tree);
  }

let delayed f =
  {
    encode =
      (fun backend rem_steps x key tree ->
        let rem_steps = consume_step rem_steps in
        let {encode} = f () in
        encode backend rem_steps x key tree);
  }

let contramap f {encode} =
  {
    encode =
      (fun backend rem_steps value ->
        let rem_steps = consume_step rem_steps in
        encode backend rem_steps @@ f value);
  }

let contramap_lwt f {encode} =
  {
    encode =
      (fun backend rem_steps value prefix tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* v = f value in
        encode backend rem_steps v prefix tree);
  }

let tup2 lhs rhs =
  {
    encode =
      (fun backend rem_steps (l, r) prefix tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* tree, rem_steps = lhs.encode backend rem_steps l prefix tree in
        rhs.encode backend rem_steps r prefix tree);
  }

let tup3 encode_a encode_b encode_c =
  {
    encode =
      (fun backend rem_steps (a, b, c) prefix tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step @@ consume_step rem_steps in
        let* tree, rem_steps =
          encode_a.encode backend rem_steps a prefix tree
        in
        let* tree, rem_steps =
          encode_b.encode backend rem_steps b prefix tree
        in
        encode_c.encode backend rem_steps c prefix tree);
  }

let raw suffix =
  {
    encode =
      (fun backend rem_steps bytes prefix tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let* tree = Tree.add backend tree (prefix suffix) bytes in
        return (tree, rem_steps));
  }

let value suffix enc =
  {
    encode =
      (fun backend rem_steps v prefix tree ->
        let rem_steps = consume_step rem_steps in
        let {encode} =
          contramap (Data_encoding.Binary.to_bytes_exn enc) (raw suffix)
        in
        encode backend rem_steps v prefix tree);
  }

let value_option key encoding =
  {
    encode =
      (fun backend rem_steps v prefix tree ->
        let rem_steps = consume_step rem_steps in
        match v with
        | Some v -> (value key encoding).encode backend rem_steps v prefix tree
        | None ->
            let open Lwt_syntax in
            let rem_steps = consume_step rem_steps in
            let* tree = Tree.remove backend tree (prefix key) in
            return (tree, rem_steps));
  }

let scope key {encode} =
  {
    encode =
      (fun backend rem_steps value prefix tree ->
        encode
          backend
          (consume_step rem_steps)
          value
          (append_key prefix key)
          tree);
  }

let lazy_mapping to_key enc_value =
  {
    encode =
      (fun backend rem_steps bindings prefix tree ->
        List.fold_left_s
          (fun (tree, rem_steps) (k, v) ->
            let rem_steps = consume_step rem_steps in
            let key = append_key prefix (to_key k) in
            enc_value.encode backend rem_steps v key tree)
          (tree, rem_steps)
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
  {
    encode =
      (fun backend rem_steps value prefix target_tree ->
        let open Lwt_syntax in
        let rem_steps = consume_step rem_steps in
        let encode_tag = scope ["tag"] encode_tag in
        let match_case (found_value, rem_steps) (Case {probe; tag; encode}) =
          let rem_steps = consume_step rem_steps in
          match found_value with
          | Some value -> return (Some value, rem_steps)
          | None -> (
              match probe value with
              | Some res ->
                  let* target_tree, rem_steps =
                    encode_tag.encode backend rem_steps tag prefix target_tree
                  in
                  let* value = res in
                  let* tree, rem_steps =
                    let {encode} = scope ["value"] encode in
                    encode backend rem_steps value prefix target_tree
                  in
                  return (Some tree, rem_steps)
              | None -> return (None, rem_steps))
        in
        let* tree_opt, rem_steps =
          List.fold_left_s match_case (None, rem_steps) cases
        in
        match tree_opt with
        | None -> raise No_tag_matched_on_encoding
        | Some tree -> return (tree, rem_steps));
  }
