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

open QCheck
open Monads_util
open Probability_helpers
open Durable_snapshot_util

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
    Gen.map Array.to_list @@ Gen.pos_split ~size:suffix_segments segments_len
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

  module State : Monads_util.State with type t = ctxt

  val generate_input : 'input Durable_operation.t -> 'input Gen_lwt(State).t
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

(* Contains small subset of methods needed to generate input keys *)
module Traversable_trie = struct
  module type S = sig
    type t

    val list : t -> string -> string list Lwt.t

    val list_size : t -> string -> int Lwt.t

    val value_len : t -> string -> int Lwt.t
  end

  module Make_from_durable (D : Testable_durable_sig with type cbv = CBV.t) :
    S with type t = D.t = struct
    type t = D.t

    let list t k = D.list t @@ D.key_of_string_exn k

    let list_size t k = D.count_subtrees t @@ D.key_of_string_exn k

    let value_len t key =
      Lwt.map
        (Option.fold ~none:0 ~some:(fun x -> Int64.to_int @@ CBV.length x))
      @@ Lwt.try_bind
           (fun () -> D.find_value t (D.key_of_string_exn key))
           (fun res -> Lwt.return res)
           (fun exn ->
             (* Well, once again for some reason it throws an exception
                instead of returning a None *)
             if
               Printexc.to_string exn
               = "Tezos_tree_encoding__Decoding.Key_not_found(_)"
             then Lwt.return_none
             else raise exn)
  end
end

module Make_probabilistic
    (Trie : Traversable_trie.S)
    (KP : Key_generator_params)
    (P : Input_probabilities) : S with type ctxt = Trie.t = struct
  type ctxt = Trie.t

  module State = struct
    type t = ctxt
  end

  module Gen_lwt = Gen_lwt (State)
  open KP
  open Durable_operation

  open Gen_lwt_syntax (State)

  let key_alphabet : char Gen.t = Gen.oneofl key_alphabet

  let rec gen_existing_prefix ~(should_be_key : bool) (t : Trie.t)
      (prefix : string) : string Gen_lwt.t =
    let*! size = Trie.list_size t prefix in
    (* Terminal stop, no way to traverse further *)
    if size = 0 then Gen_lwt.return prefix
    else
      (* Ideally, we should generate probabilities proportionally to subtree sizes,
         in order to generate prefixes evenly distributed. However,
         I didn't find anything resembling in Store.Tree.
      *)
      let*? p = Gen.int_bound (if should_be_key then size - 1 else size) in
      if p = size then Gen_lwt.return prefix
      else
        let*! children = Trie.list t prefix in
        let child =
          WithExceptions.Option.get ~loc:__LOC__ @@ List.nth children p
        in
        (* We ended up going in a node storing value at @ *)
        if child = "" then Gen_lwt.return prefix
        else
          (gen_existing_prefix [@tailcall])
            ~should_be_key
            t
            (prefix ^ "/" ^ child)

  (* Key generator.
     We might want to generate existing and non-existing keys
     with different probabilities for different operations.
     It takes current generator context and probability
     for a generated key and prefix to exist in the tree. *)
  let gen_key ~(key_exists : Probability.t) ~(prefix_exists : Probability.t) :
      string Gen_lwt.t =
    let* trie = Gen_lwt.get_state in
    (* Just check that sum is less than 1.0 *)
    let _res_prob = Probability.(key_exists + prefix_exists) in
    let existing_key_gen =
      let*! read_only_exists =
        Lwt.map (List.exists (fun x -> x = "readonly")) @@ Trie.list trie ""
      in
      let*? p_readonly = gen_bool P.key_to_be_readonly in
      if read_only_exists && p_readonly then
        (* Generate readonly key *)
        gen_existing_prefix ~should_be_key:true trie "/readonly"
      else
        (* Generate write key,
           strictly speaking still possible to generate readonly key *)
        gen_existing_prefix ~should_be_key:true trie ""
    in
    let existing_prefix_gen =
      let*! read_only_exists =
        Lwt.map (List.exists (fun x -> x = "readonly")) @@ Trie.list trie ""
      in
      let*? p_readonly = gen_bool P.key_to_be_readonly in
      let* existing_prefix =
        if read_only_exists && p_readonly then
          gen_existing_prefix ~should_be_key:false trie "/readonly"
        else
          (* Generate write prefix,
             strictly speaking still possible to generate readonly prefix *)
          gen_existing_prefix ~should_be_key:false trie ""
      in
      let remain_len = max_key_length - String.length existing_prefix in
      let*? suffix =
        gen_arbitrary_path
          ~max_len:(Int.min remain_len max_suffix_len_of_nonexisting_key)
          ~max_segments_num:max_num_suffix_segments_of_nonexisting_key
          key_alphabet
      in
      Gen_lwt.return @@ existing_prefix ^ suffix
    in
    let non_existing_key_gen =
      let*? p_readonly = gen_bool P.key_to_be_readonly in
      let pref = if p_readonly then "/readonly" else "" in
      let remain_len = max_key_length - String.length pref in
      let*? suffix =
        gen_arbitrary_path ~max_len:remain_len ~max_segments_num:20 key_alphabet
      in
      Gen_lwt.return @@ pref ^ suffix
    in
    let*? p = gen_probability in
    if p < key_exists then existing_key_gen
    else if Probability.(p < key_exists + prefix_exists) then
      existing_prefix_gen
    else non_existing_key_gen

  let generate_input (type input) (op : input Durable_operation.t) :
      input Gen_lwt.t =
    match op with
    | Find_value ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Find_value_exn ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Set_value_exn ->
        let*? edit_readonly = Gen.bool in
        let*? value = Gen.string ~gen:Gen.char in
        let+ key =
          gen_key
            ~key_exists:P.key_exists_in_set_value
            ~prefix_exists:P.prefix_exists_in_operation
        in
        (edit_readonly, key, value)
    | Copy_tree_exn ->
        let*? edit_readonly = Gen.bool in
        let* key_from =
          gen_key
            ~key_exists:P.key_from_exists
            ~prefix_exists:P.prefix_exists_in_operation
        in
        let+ key_to =
          gen_key
            ~key_exists:P.key_to_exists
            ~prefix_exists:P.prefix_exists_in_operation
        in
        (edit_readonly, key_from, key_to)
    | Move_tree_exn ->
        let* key_from =
          gen_key
            ~key_exists:P.key_from_exists
            ~prefix_exists:P.prefix_exists_in_operation
        in
        let+ key_to =
          gen_key
            ~key_exists:P.key_to_exists
            ~prefix_exists:P.prefix_exists_in_operation
        in
        (key_from, key_to)
    | Delete ->
        let*? edit_readonly = Gen.bool in
        let+ key =
          gen_key
            ~key_exists:P.key_exists_in_delete
            ~prefix_exists:P.prefix_exists_in_operation
        in
        (edit_readonly, key)
    | List ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Count_subtrees ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Substree_name_at ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_read_operation
            ~prefix_exists:P.prefix_exists_in_operation
        in
        let* t = Gen_lwt.get_state in
        let*! children_size = Trie.list_size t key in
        let*? subtree_id = Gen.int_range (-3) (children_size + 3) in
        Gen_lwt.return (key, subtree_id)
    | Hash ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Hash_exn ->
        gen_key
          ~key_exists:P.key_exists_in_read_operation
          ~prefix_exists:P.prefix_exists_in_operation
    | Write_value_exn ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_write_value
            ~prefix_exists:P.prefix_exists_in_operation
        in
        let* t = Gen_lwt.get_state in
        let*? edit_readonly = Gen.bool in
        let*! value_len = Trie.value_len t key in
        let*? is_valid_offset = gen_bool P.valid_offset_in_write_value in
        if not is_valid_offset then
          (* Invalid offset *)
          let*? offset = Gen.int_range (value_len + 1) (value_len + 100) in
          let*? value = Gen.string ~gen:Gen.char in
          Gen_lwt.return (edit_readonly, key, Int64.of_int offset, value)
        else
          (* max_store_io_size = 2048 *)
          let*? value = Gen.string_size ~gen:Gen.char (Gen.int_bound 2048) in
          let*? offset = Gen.int_bound (value_len + 1) in
          Gen_lwt.return (edit_readonly, key, Int64.of_int offset, value)
    | Read_value_exn ->
        let* key =
          gen_key
            ~key_exists:P.key_exists_in_read_operation
            ~prefix_exists:P.prefix_exists_in_operation
        in
        let* t = Gen_lwt.get_state in
        let*! value_len = Trie.value_len t key in
        let*? is_valid_offset = gen_bool P.valid_offset_in_read_value in
        if not is_valid_offset then
          (* Invalid offset *)
          let*? offset = Gen.int_range (value_len + 1) (value_len + 100) in
          let*? len = Gen.int in
          Gen_lwt.return (key, Int64.of_int offset, Int64.of_int len)
        else
          let*? len = Gen.int_bound (value_len + 100) in
          let*? offset = Gen.int_bound (value_len + 1) in
          Gen_lwt.return (key, Int64.of_int offset, Int64.of_int len)
end

module Make_default_input_generator
    (D : Testable_durable_sig with type cbv = CBV.t) =
  Make_probabilistic
    (Traversable_trie.Make_from_durable (D)) (Default_key_generator_params)
    (Default_input_probabilities)
