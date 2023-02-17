(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech  <contact@trili.tech>                        *)
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

open QCheck2
open Probability_helpers

(* This module defines interface for generation of inputs
   for durable stress tests in Gen_lwt monad.
    Also it provides an implementation based on probabilities.
*)

(* Bunch of helpers *)
let range (i : int) (j : int) =
  let rec aux n acc = if n < i then acc else aux (n - 1) (n :: acc) in
  aux j []

let range_chars (i : char) (j : char) =
  List.map Char.chr @@ range (Char.code i) (Char.code j)

(* Generate a path in format /aaa/bbb/ccc *)
let gen_arbitrary_path ~(max_len : int) ~(max_segments_num : int)
    (alphabet : char Gen.t) =
  (*
    And suffix = /x/y/zz, then:
    suffix_segments = ["x"; "y"; "zz"]
    segments_len = 1 + 1 + 2 = 4 (so only segments lengths counted).
  *)
  let open Gen in
  (* As each suffix segment is followed by /, hence,
     we can't have more than max_len / 2 segments *)
  let* suffix_segments = Gen.(1 -- Int.min max_segments_num (max_len / 2)) in
  (* The same about maximum total length of segments *)
  let max_segments_len = max_len / 2 in
  let* segments_len =
    Gen.frequencyl
    @@ Distributions.centered_distribution_l
         (range suffix_segments max_segments_len)
  in
  let* segments_lens =
    Gen.map Array.to_list
    @@ Gen.make_primitive
         ~gen:(QCheck.Gen.pos_split ~size:suffix_segments segments_len)
         ~shrink:(fun _ -> Seq.empty)
  in
  let+ suffix = Gen.string_size ~gen:alphabet (Gen.return segments_len) in
  let rec split_str s lens =
    match (s, lens) with
    | "", [] -> []
    | s, l :: lens ->
        String.sub s 0 l
        :: split_str (String.sub s l @@ (String.length s - l)) lens
    | _ -> assert false
  in
  let segments = split_str suffix segments_lens in
  let suffix = "/" ^ String.concat "/" segments in
  suffix

(* Acutal essence of the module starts here *)
module type S = sig
  type ctxt

  val generate_input : ctxt -> 'input Durable_operation.t -> 'input Gen.t

  val generate_some_input :
    ctxt -> Durable_operation.some_op -> Durable_operation.some_input Gen.t
end

module Default_key_generator_params = struct
  let key_alphabet : char list =
    List.concat
      [
        ['.'; '-'; '_'];
        range_chars 'a' 'z';
        range_chars 'A' 'Z';
        range_chars '0' '9';
      ]

  let max_key_length : int = 250 - String.length "/durable" - String.length "/@"

  let max_suffix_len_of_nonexisting_key : int = 30

  let max_num_suffix_segments_of_nonexisting_key : int = 5
end

module type Key_generator_params = module type of Default_key_generator_params

module Default_input_probabilities = struct
  (* How often generated key has to exist in durable for all read operations *)
  let key_exists_in_read_operation = Probability.of_percent 50

  (* How often PREFIX of a generated key has to exist in a durable for all read operations.
     So basically this targets validity of underlying Trie implementation.
  *)
  let prefix_exists_in_read_operation = Probability.of_percent 20

  (* How often PREFIX of a generated key has to exist in durable for
     all other operations apart from read once *)
  let prefix_exists_in_operation = Probability.of_percent 10

  (* How often a generated key has to be read-only *)
  let key_to_be_readonly = Probability.of_percent 20

  (* How often a key_from generated for
     copy_tree/move_tree has to exist in a durable *)
  let key_from_exists = Probability.of_percent 70

  (* How often a key_to generated for
     copy_tree/move_tree has to exist in a durable *)
  let key_to_exists = Probability.of_percent 50

  (* How often a key generated for delete operation has to exist in durable *)
  let key_exists_in_delete = Probability.of_percent 40

  (* How often a key generated for set_value has to exist in durable *)
  let key_exists_in_set_value = Probability.of_percent 50

  (* How often a key generated for write_value has to exist in durable *)
  let key_exists_in_write_value = Probability.of_percent 50

  (* How often an offset generated for write_value has to be valid *)
  let valid_offset_in_write_value = Probability.of_percent 95

  (* How often an offset generated for read_value has to be valid *)
  let valid_offset_in_read_value = Probability.of_percent 95
end

module type Input_probabilities = module type of Default_input_probabilities

module Make_probabilistic (KP : Key_generator_params) (P : Input_probabilities) :
  S with type ctxt = int Trie.t = struct
  type ctxt = int Trie.t

  open KP
  open Durable_operation

  let key_alphabet : char Gen.t = Gen.oneofl key_alphabet

  let gen_existing_prefix ~(should_be_key : bool) (root : int Trie.t)
      (init_prefix : string) : string Gen.t =
    let rec traverse_evenly (prefix : string list) (v : int Trie.t) :
        string Gen.t =
      (* Either end up in the current node or recursively proceed to child *)
      let children_frequency can_end_here weight_fun =
        Gen.frequency
        @@ List.append
             (if can_end_here then
              [
                ( 1,
                  Gen.delay @@ fun () ->
                  Gen.pure @@ String.concat "/" @@ List.rev prefix );
              ]
             else [])
             (List.map (fun (k, c) ->
                  ( weight_fun c,
                    Gen.delay (fun () -> traverse_evenly (k :: prefix) c) ))
             @@ Trie.Map.bindings v.children)
      in
      if should_be_key then
        children_frequency (Option.is_some v.value) (fun c -> c.Trie.keys_count)
      else children_frequency true (fun c -> c.Trie.nodes_count)
    in
    let start_node =
      WithExceptions.Option.get ~loc:__LOC__ @@ Trie.lookup init_prefix root
    in
    traverse_evenly
      (List.rev @@ String.split_on_char '/' init_prefix)
      start_node

  (* Key generator.
     We might want to generate existing and non-existing keys
     with different probabilities for different operations.
     It takes current generator context and probability
     for a generated key and prefix to exist in the tree. *)
  let gen_key ~(key_exists : Probability.t) ~(prefix_exists : Probability.t)
      (trie : int Trie.t) : string Gen.t =
    let open Gen in
    (* Just check that sum is less than 1.0 *)
    let _res_prob = Probability.(key_exists + prefix_exists) in
    let existing_key_gen =
      let read_only_exists = Trie.subtrees_size "/readonly" trie > 0 in
      let* p_readonly = gen_bool P.key_to_be_readonly in
      if read_only_exists && p_readonly then
        (* Generate readonly key *)
        gen_existing_prefix ~should_be_key:true trie "/readonly"
      else
        (* Generate write key,
           strictly speaking still possible to generate readonly key *)
        gen_existing_prefix ~should_be_key:true trie ""
    in
    let existing_prefix_gen =
      let read_only_exists = Trie.subtrees_size "/readonly" trie > 0 in
      let* p_readonly = gen_bool P.key_to_be_readonly in
      let* existing_prefix =
        if read_only_exists && p_readonly then
          gen_existing_prefix ~should_be_key:false trie "/readonly"
        else
          (* Generate write prefix,
             strictly speaking still possible to generate readonly prefix *)
          gen_existing_prefix ~should_be_key:false trie ""
      in
      let remain_len = max_key_length - String.length existing_prefix in
      let+ suffix =
        gen_arbitrary_path
          ~max_len:(Int.min remain_len max_suffix_len_of_nonexisting_key)
          ~max_segments_num:max_num_suffix_segments_of_nonexisting_key
          key_alphabet
      in
      existing_prefix ^ suffix
    in
    let non_existing_key_gen =
      let* p_readonly = gen_bool P.key_to_be_readonly in
      let pref = if p_readonly then "/readonly" else "" in
      let remain_len = max_key_length - String.length pref in
      let+ suffix =
        gen_arbitrary_path ~max_len:remain_len ~max_segments_num:20 key_alphabet
      in
      pref ^ suffix
    in
    let trie_is_empty = Trie.subtrees_size "" trie = 0 in
    if trie_is_empty then non_existing_key_gen
    else
      let key_exists = Probability.to_percent key_exists in
      let prefix_exists = Probability.to_percent prefix_exists in
      let probability_rest = 100 - key_exists - prefix_exists in
      Gen.frequency
        [
          (key_exists, existing_key_gen);
          (prefix_exists, existing_prefix_gen);
          (probability_rest, non_existing_key_gen);
        ]

  let value_len trie key = Option.value ~default:0 @@ Trie.get_value key trie

  let generate_input (type input) trie (op : input Durable_operation.t) :
      input Gen.t =
    let open Gen in
    match op with
    | Find_value ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Find_value_exn ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Set_value_exn ->
        let* edit_readonly = Gen.bool in
        let* value = Gen.string_of Gen.char in
        let+ key =
          gen_key
            ~key_exists:P.key_exists_in_set_value
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        (edit_readonly, key, value)
    | Copy_tree_exn ->
        let* edit_readonly = Gen.bool in
        let* key_from =
          gen_key
            ~key_exists:P.key_from_exists
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        let+ key_to =
          gen_key
            ~key_exists:P.key_to_exists
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        (edit_readonly, key_from, key_to)
    | Move_tree_exn ->
        let* key_from =
          gen_key
            ~key_exists:P.key_from_exists
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        let+ key_to =
          gen_key
            ~key_exists:P.key_to_exists
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        (key_from, key_to)
    | Delete ->
        let* edit_readonly = Gen.bool in
        let+ key =
          gen_key
            ~key_exists:P.key_exists_in_delete
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        (edit_readonly, key)
    | List ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Count_subtrees ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Substree_name_at ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_read_operation
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        let subtrees_size = Trie.subtrees_size key trie in
        let* subtree_id = Gen.int_range (-3) (subtrees_size + 3) in
        Gen.return (key, subtree_id)
    | Hash ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Hash_exn ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
          trie
    | Write_value_exn ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_write_value
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        let* edit_readonly = Gen.bool in
        let value_len = value_len trie key in
        let* is_valid_offset = gen_bool P.valid_offset_in_write_value in
        if not is_valid_offset then
          (* Invalid offset *)
          let* offset = Gen.int_range (value_len + 1) (value_len + 100) in
          let+ value = Gen.string_of Gen.char in
          (edit_readonly, key, Int64.of_int offset, value)
        else
          (* max_store_io_size = 2048 *)
          let* value = Gen.string_size ~gen:Gen.char (Gen.int_bound 2048) in
          let* offset = Gen.int_bound (value_len + 1) in
          Gen.return (edit_readonly, key, Int64.of_int offset, value)
    | Read_value_exn ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_read_operation
            ~prefix_exists:P.prefix_exists_in_operation
            trie
        in
        let value_len = value_len trie key in
        let* is_valid_offset = gen_bool P.valid_offset_in_read_value in
        if not is_valid_offset then
          (* Invalid offset *)
          let* offset = Gen.int_range (value_len + 1) (value_len + 100) in
          let+ len = Gen.int in
          (key, Int64.of_int offset, Int64.of_int len)
        else
          let* len = Gen.int_bound (value_len + 100) in
          let+ offset = Gen.int_bound (value_len + 1) in
          (key, Int64.of_int offset, Int64.of_int len)

  let generate_some_input trie (Some_op op) =
    Gen.map (fun inp -> Some_input (op, inp)) @@ generate_input trie op
end

module Input_generator =
  Make_probabilistic
    (Default_key_generator_params)
    (Default_input_probabilities)
