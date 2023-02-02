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

(** Testing
    -------
    Component:    Lib_scoru_wasm durable
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "^Durable snapshot$"
    Subject:      Tests for the tezos-scoru-wasm durable snapshotting
*)

open Tztest
open Encodings_util
module Context_binary_tree = Tezos_context_memory.Context_binary.Tree

(* This type represents comparison between two different types,
   which might be compared. Also it's useful for cases when
   two types can only be compared within Lwt.
   For now this type is useful to compare Snapshotted and Current
   durable storages.
   Also it will be handy when we replace CBV with immutable CBV
   for Durable.load_bytes.
*)
module Equality2 = struct
  module type S = sig
    type a

    type b

    val pp_a : Format.formatter -> a -> unit

    val pp_b : Format.formatter -> b -> unit

    (* This one might be improved to return `(bool, string) result`
       to return where exactly values diverged.
    *)
    val eq : a -> b -> bool Lwt.t
  end

  type ('a, 'b) t = (module S with type a = 'a and type b = 'b)

  (* Make Equality2.t for values of the same type  *)
  let make (type x) ~pp ~(eq : x -> x -> bool) : (x, x) t =
    (module struct
      type a = x

      type b = x

      let pp_a = pp

      let pp_b = pp

      let eq a b = Lwt.return @@ eq a b
    end)
end

module Testable_durable = struct
  (* This is a projection of tezos_scoru_wasm/durable.mli methods (Current impl in other words),
     which might be tested within this framework.
  *)
  module type S = sig
    type t

    type key

    val encoding : t Tezos_tree_encoding.t

    val max_key_length : int

    val key_of_string_exn : string -> key

    val key_of_string_opt : string -> key option

    val find_value :
      t -> key -> Tezos_lazy_containers.Chunked_byte_vector.t option Lwt.t

    val find_value_exn :
      t -> key -> Tezos_lazy_containers.Chunked_byte_vector.t Lwt.t

    val copy_tree_exn : t -> ?edit_readonly:bool -> key -> key -> t Lwt.t

    val move_tree_exn : t -> key -> key -> t Lwt.t

    val list : t -> key -> string list Lwt.t

    val count_subtrees : t -> key -> int Lwt.t

    val subtree_name_at : t -> key -> int -> string Lwt.t

    val delete : ?edit_readonly:bool -> t -> key -> t Lwt.t

    val hash : t -> key -> Context_hash.t option Lwt.t

    val hash_exn : t -> key -> Context_hash.t Lwt.t

    val set_value_exn : t -> ?edit_readonly:bool -> key -> string -> t Lwt.t

    val write_value_exn :
      t -> ?edit_readonly:bool -> key -> int64 -> string -> t Lwt.t

    val read_value_exn : t -> key -> int64 -> int64 -> string Lwt.t
  end

  module Snapshot = Tezos_scoru_wasm_durable_snapshot.Durable
  module Current = Tezos_scoru_wasm.Durable
  module CBV = Tezos_lazy_containers.Chunked_byte_vector

  module Durables_equality :
    Equality2.S with type a = Snapshot.t and type b = Current.t = struct
    type a = Snapshot.t

    type b = Current.t

    let hash t encoding =
      let open Lwt_syntax in
      let* tree = empty_tree () in
      let+ tree = Tree_encoding_runner.encode encoding t tree in
      Context_binary_tree.hash tree

    let pp_a fmt t =
      let hash = Lwt_main.run @@ hash t Snapshot.encoding in
      Format.fprintf fmt "%a" Context_hash.pp hash

    let pp_b fmt t =
      let hash = Lwt_main.run @@ hash t Current.encoding in
      Format.fprintf fmt "%a" Context_hash.pp hash

    let eq tree_s tree_c =
      let open Lwt_syntax in
      let* hash1 = hash tree_s Snapshot.encoding in
      let+ hash2 = hash tree_c Current.encoding in
      Context_hash.equal hash1 hash2
  end

  (* This is just in case  some tests are slow,
     so we can skip intermididate trees comparisons.
  *)
  module Always_equal_durables :
    Equality2.S with type a = Snapshot.t and type b = Current.t = struct
    type a = Snapshot.t

    type b = Current.t

    let pp_a fmt _ = Format.fprintf fmt ""

    let pp_b fmt _ = Format.fprintf fmt ""

    let eq _ _ = Lwt.return_true
  end

  (* This module implements a durable interface for pair of
     durable storages Snapshot.t * Current.t .
     All the methods are performed on both durables and
     returned values and resulting durables tested on equality.
     Hence, this module aspires to mantain invariant that trees in the pair
     are always equal wrt. passed Eq_durable.
  *)
  module Make_paired_durable
      (Eq_durable : Equality2.S with type a = Snapshot.t and type b = Current.t) :
    S with type t = Snapshot.t * Current.t = struct
    type t = Snapshot.t * Current.t

    type key = Snapshot.key * Current.key

    (* Helper functions *)
    let guard (f : unit -> 'a Lwt.t) =
      Lwt.try_bind
        f
        (fun res -> Lwt.return (Ok res))
        (fun exn -> Lwt.return (Error exn))

    let assert_trees_equality (t_s, t_c) =
      let open Lwt_syntax in
      let+ eq = Eq_durable.eq t_s t_c in
      (* Avoid calling trees' pp unless trees are different *)
      if eq then ()
      else
        Assert.fail_msg
          "Tree states diverged: snapshot = %a vs current = %a"
          Eq_durable.pp_a
          t_s
          Eq_durable.pp_b
          t_c

    (* Motivation behind this function that
       we would like to be able to test exceptions
       thrown from Snapshot durable and Current on equality.

       Without this funtion there are two different types of
       exception, like:
         Tezos_scoru_wasm_durable_snapshot.Durable.Value_not_found
         Tezos_scoru_wasm.Durable.Value_not_found
       even though essentially it's the same exception.
    *)
    let convert_durable_exception (e : exn) =
      match e with
      | Snapshot.Invalid_key k -> Current.Invalid_key k
      | Snapshot.Index_too_large i -> Current.Index_too_large i
      | Snapshot.Value_not_found -> Current.Value_not_found
      | Snapshot.Tree_not_found -> Current.Tree_not_found
      | Snapshot.Out_of_bounds b -> Current.Out_of_bounds b
      | Snapshot.Durable_empty -> Current.Durable_empty
      | Snapshot.Readonly_value -> Current.Readonly_value
      | Snapshot.IO_too_large -> Current.IO_too_large
      | e -> e

    let ensure_same_outcome (type a b) ((module Eq) : (a, b) Equality2.t)
        (f_s : unit -> (a * Snapshot.t) Lwt.t)
        (f_c : unit -> (b * Current.t) Lwt.t) :
        (b * (Snapshot.t * Current.t)) Lwt.t =
      let open Lwt_syntax in
      let* res1 = guard f_s in
      let* res2 = guard f_c in
      let assert_values_equality v_s v_c =
        let+ eq = Eq.eq v_s v_c in
        if eq then ()
        else
          Assert.fail_msg
            "Expected returned value %a but got %a"
            Eq.pp_a
            v_s
            Eq.pp_b
            v_c
      in
      match (res1, res2) with
      | Error e1, Error e2 ->
          Assert.equal
            ~loc:__LOC__
            ~msg:
              (Format.asprintf
                 "Tree methods failed with different exceptions: %s vs %s"
                 (Printexc.to_string e1)
                 (Printexc.to_string e2))
            (convert_durable_exception e1)
            e2 ;
          raise e2
      | Ok (r1, t_s), Ok (r2, t_c) ->
          let* () = assert_values_equality r1 r2 in
          let+ () = assert_trees_equality (t_s, t_c) in
          (r2, (t_s, t_c))
      | Ok (r1, _), Error e2 ->
          Assert.fail_msg
            "Expected returned value %a but failed with error %s"
            Eq.pp_a
            r1
            (Printexc.to_string e2)
      | Error e1, Ok (r2, _) ->
          Assert.fail_msg
            "Expected to fail with error %s but value returned %a"
            (Printexc.to_string e1)
            Eq.pp_b
            r2

    let same_trees (f_s : unit -> Snapshot.t Lwt.t)
        (f_c : unit -> Current.t Lwt.t) : (Snapshot.t * Current.t) Lwt.t =
      let open Lwt_syntax in
      let add_unit r = ((), r) in
      let+ _, trees =
        ensure_same_outcome
          (Equality2.make
             ~pp:(fun fmt () -> Format.fprintf fmt "unit")
             ~eq:(fun _ _ -> true))
          (fun () -> Lwt.map add_unit @@ f_s ())
          (fun () -> Lwt.map add_unit @@ f_c ())
      in
      trees

    let same_values (type a b) (eq : (a, b) Equality2.t)
        (f_s : unit -> (a * Snapshot.t) Lwt.t)
        (f_c : unit -> (b * Current.t) Lwt.t) : b Lwt.t =
      Lwt.map fst @@ ensure_same_outcome eq f_s f_c

    let add_tree tree f () = Lwt.map (fun r -> (r, tree)) f

    (* Actual methods implementation starts here *)

    let encoding =
      let open Tezos_tree_encoding in
      let paired = tup2 ~flatten:true Snapshot.encoding Current.encoding in
      (* Make sure that trees are the same when decoded.
         Check for encoding can be omitted as we anyway support equality invariant.
      *)
      conv_lwt
        (fun t -> Lwt.map (Fun.const t) @@ assert_trees_equality t)
        Lwt.return
        paired

    let max_key_length =
      Assert.Int.equal
        ~loc:__LOC__
        ~msg:"max_key_length different for Snapshot and Current"
        Snapshot.max_key_length
        Current.max_key_length ;
      Current.max_key_length

    let key_of_string_exn key =
      let res1 = try Ok (Snapshot.key_of_string_exn key) with e -> Error e in
      let res2 = try Ok (Current.key_of_string_exn key) with e -> Error e in
      match (res1, res2) with
      | Error e1, Error e2 ->
          Assert.equal
            ~loc:__LOC__
            ~msg:
              (Format.asprintf
                 "key_of_string_exn failed with different exceptions: %s vs %s"
                 (Printexc.to_string e1)
                 (Printexc.to_string e2))
            e1
            e2 ;
          raise e2
      | Ok k1, Ok k2 -> (k1, k2)
      | Ok _k1, Error e2 ->
          Assert.fail_msg
            "Result of key_of_string_exn diverged: Snapshot returned a value, \
             Current failed with error %s for key %s"
            (Printexc.to_string e2)
            key
      | Error e1, Ok _k2 ->
          Assert.fail_msg
            "Result of key_of_string_exn diverged: Snapshot failed with error \
             %s, Current returned a value for key %s"
            (Printexc.to_string e1)
            key

    let key_of_string_opt key =
      match (Snapshot.key_of_string_opt key, Current.key_of_string_opt key) with
      | None, None -> None
      (* TODO: should we compare keys? *)
      | Some k1, Some k2 -> Some (k1, k2)
      | Some _k1, None ->
          Assert.fail_msg
            "Result of key_of_string_opt diverged: Snapshot returned Some, \
             current returned None for key %s"
            key
      | None, Some _k2 ->
          Assert.fail_msg
            "Result of key_of_string_opt diverged: Snapshot returned None, \
             current returned Some for key %s"
            key

    let cbv_to_bytes x = Lwt_main.run @@ CBV.to_bytes x

    let cbv_eq a b = Bytes.equal (cbv_to_bytes a) (cbv_to_bytes b)

    let cbv_pp fmt cbv =
      Format.fprintf fmt "%a" Hex.pp (Hex.of_bytes @@ cbv_to_bytes cbv)

    let find_value (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make
           ~pp:(Format.pp_print_option cbv_pp)
           ~eq:(Option.equal cbv_eq))
        (add_tree tree_s @@ Snapshot.find_value tree_s key_s)
        (add_tree tree_c @@ Current.find_value tree_c key_c)

    let find_value_exn (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make ~pp:cbv_pp ~eq:cbv_eq)
        (add_tree tree_s @@ Snapshot.find_value_exn tree_s key_s)
        (add_tree tree_c @@ Current.find_value_exn tree_c key_c)

    let copy_tree_exn (tree_s, tree_c) ?edit_readonly (from_key_s, from_key_c)
        (to_key_s, to_key_c) =
      same_trees
        (fun () ->
          Snapshot.copy_tree_exn tree_s ?edit_readonly from_key_s to_key_s)
        (fun () ->
          Current.copy_tree_exn tree_c ?edit_readonly from_key_c to_key_c)

    let move_tree_exn (tree_s, tree_c) (from_key_s, from_key_c)
        (to_key_s, to_key_c) =
      same_trees
        (fun () -> Snapshot.move_tree_exn tree_s from_key_s to_key_s)
        (fun () -> Current.move_tree_exn tree_c from_key_c to_key_c)

    let list (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make ~pp:(Fmt.list Fmt.string) ~eq:(List.equal String.equal))
        (add_tree tree_s @@ Snapshot.list tree_s key_s)
        (add_tree tree_c @@ Current.list tree_c key_c)

    let count_subtrees (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make ~pp:Fmt.int ~eq:( = ))
        (add_tree tree_s @@ Snapshot.count_subtrees tree_s key_s)
        (add_tree tree_c @@ Current.count_subtrees tree_c key_c)

    let subtree_name_at (tree_s, tree_c) (key_s, key_c) n =
      same_values
        (Equality2.make ~pp:Fmt.string ~eq:String.equal)
        (add_tree tree_s @@ Snapshot.subtree_name_at tree_s key_s n)
        (add_tree tree_c @@ Current.subtree_name_at tree_c key_c n)

    let delete ?edit_readonly (tree_s, tree_c) (key_s, key_c) =
      same_trees
        (fun () -> Snapshot.delete ?edit_readonly tree_s key_s)
        (fun () -> Current.delete ?edit_readonly tree_c key_c)

    let hash (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make
           ~pp:(Fmt.option Context_hash.pp)
           ~eq:(Option.equal Context_hash.equal))
        (add_tree tree_s @@ Snapshot.hash tree_s key_s)
        (add_tree tree_c @@ Current.hash tree_c key_c)

    let hash_exn (tree_s, tree_c) (key_s, key_c) =
      same_values
        (Equality2.make ~pp:Context_hash.pp ~eq:Context_hash.equal)
        (add_tree tree_s @@ Snapshot.hash_exn tree_s key_s)
        (add_tree tree_c @@ Current.hash_exn tree_c key_c)

    let set_value_exn (tree_s, tree_c) ?edit_readonly (key_s, key_c) bytes =
      same_trees
        (fun () -> Snapshot.set_value_exn tree_s ?edit_readonly key_s bytes)
        (fun () -> Current.set_value_exn tree_c ?edit_readonly key_c bytes)

    let write_value_exn (tree_s, tree_c) ?edit_readonly (key_s, key_c) offset
        bytes =
      same_trees
        (fun () ->
          Snapshot.write_value_exn tree_s ?edit_readonly key_s offset bytes)
        (fun () ->
          Current.write_value_exn tree_c ?edit_readonly key_c offset bytes)

    let read_value_exn (tree_s, tree_c) (key_s, key_c) offset len =
      same_values
        (Equality2.make ~pp:Fmt.string ~eq:String.equal)
        (add_tree tree_s @@ Snapshot.read_value_exn tree_s key_s offset len)
        (add_tree tree_c @@ Current.read_value_exn tree_c key_c offset len)
  end
end

module Paired_durable =
  Testable_durable.Make_paired_durable (Testable_durable.Durables_equality)

let run_scenario (scenario : Paired_durable.t -> 'a Lwt.t) : 'a Lwt.t =
  let open Lwt_syntax in
  let* tree = empty_tree () in
  let* durable = Tree_encoding_runner.decode Paired_durable.encoding tree in
  (* Check pre-conditions:
     max key length is the same for both implementations.
     Perhaps this will be evaluated when the module initialises
  *)
  let _max_key_len = Paired_durable.max_key_length in
  let* result = scenario durable in
  let+ final_state_eq =
    Testable_durable.Durables_equality.eq (fst durable) (snd durable)
  in
  (* Just in case check testing states *)
  Assert.assert_true
    (Format.asprintf
       "Final durable states diverged: snapshot = %a vs current = %a"
       Testable_durable.Durables_equality.pp_a
       (fst durable)
       Testable_durable.Durables_equality.pp_b
       (snd durable))
    final_state_eq ;
  result

(* Actual tests *)

let assert_exception exected_ex run =
  let open Lwt_syntax in
  Lwt.catch
    (fun () ->
      let+ _ = run () in
      assert false)
    (fun caught_exn ->
      match caught_exn with
      | e when e = exected_ex -> Lwt.return_unit
      | x -> raise x)

let test_several_operations () =
  run_scenario @@ fun durable ->
  let open Lwt_syntax in
  let key1 = Paired_durable.key_of_string_exn "/durable/value/to/write1" in
  let key2 = Paired_durable.key_of_string_exn "/durable/value/to/write2" in
  let* durable = Paired_durable.write_value_exn durable key1 0L "hello" in
  let* durable = Paired_durable.write_value_exn durable key2 0L "world" in
  let* res_hello = Paired_durable.read_value_exn durable key1 0L 5L in
  Assert.String.equal ~loc:__LOC__ "hello" res_hello ;
  let* res_still_hello = Paired_durable.read_value_exn durable key1 0L 10L in
  Assert.String.equal ~loc:__LOC__ "hello" res_still_hello ;
  let key_prefix = Paired_durable.key_of_string_exn "/durable/value" in
  let* durable = Paired_durable.delete durable key_prefix in
  let* () =
    assert_exception Tezos_scoru_wasm.Durable.Value_not_found @@ fun () ->
    Paired_durable.read_value_exn durable key1 0L 5L
  in
  return_ok_unit

let tests : unit Alcotest_lwt.test_case trace =
  [tztest "Do several operations om durable" `Quick test_several_operations]
