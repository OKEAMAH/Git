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

open Tezos_test_helpers
open Tezos_scoru_wasm_helpers.Encodings_util
module Context_binary_tree = Tezos_context_memory.Context_binary.Tree

(* This is a generalised projection of
   durable_snapshot/durable.mli methods,
   which might be tested within snapshotting tests.
*)
module type Testable_durable_sig = sig
  type t

  type key

  type cbv

  (** [key] was too long, or contained invalid steps. *)
  exception Invalid_key of string

  (** Invalid index for a subkey *)
  exception Index_too_large of int

  (** A value was not found in the durable store. *)
  exception Value_not_found

  (** A tree does not exists under key in the durable store. *)
  exception Tree_not_found

  (** Attempted to write/read to/from a value at [offset],
    beyond the [limit]. *)
  exception Out_of_bounds of (int64 * int64)

  (** [Durable_storage.t] was empty. *)
  exception Durable_empty

  (** Cannot modify a readonly value. *)
  exception Readonly_value

  (** Cannot read from or write to more than 2,048 bytes *)
  exception IO_too_large

  val encoding : t Tezos_tree_encoding.t

  val max_key_length : int

  val key_of_string_exn : string -> key

  val key_of_string_opt : string -> key option

  val find_value : t -> key -> cbv option Lwt.t

  val find_value_exn : t -> key -> cbv Lwt.t

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

module type Encodable = sig
  type t

  val encoding : t Tezos_tree_encoding.t
end

(* Creates equality based on encoding durables to irmin trees,
   and its hashes comparison.
*)
module Make_encodable_equality (X : Encodable) (Y : Encodable) :
  Hetero_equality.S with type a = X.t and type b = Y.t = struct
  type a = X.t

  type b = Y.t

  let hash t encoding =
    let open Lwt_syntax in
    let* tree = empty_tree () in
    let+ tree = Tree_encoding_runner.encode encoding t tree in
    Context_binary_tree.hash tree

  let to_string_a t =
    let open Lwt_syntax in
    let+ hash = hash t X.encoding in
    Format.asprintf "%a" Context_hash.pp hash

  let to_string_b t =
    let open Lwt_syntax in
    let+ hash = hash t Y.encoding in
    Format.asprintf "%a" Context_hash.pp hash

  let eq tree_s tree_c =
    let open Lwt_syntax in
    let* hash1 = hash tree_s X.encoding in
    let+ hash2 = hash tree_c Y.encoding in
    Context_hash.equal hash1 hash2
end

(* This is a helper (just in case) to skip
   intermididate trees comparisons,
   if  some tests are slow.
*)
module Make_always_equal (X : sig
  type t
end) (Y : sig
  type t
end) : Hetero_equality.S with type a = X.t and type b = Y.t = struct
  type a = X.t

  type b = Y.t

  let to_string_a _ = Lwt.return "<Current durable>"

  let to_string_b _ = Lwt.return "<Snapshot durable>"

  let eq _ _ = Lwt.return_true
end

module CBV = Tezos_lazy_containers.Chunked_byte_vector

module CBV_equality : Hetero_equality.S with type a = CBV.t and type b = CBV.t =
struct
  type a = CBV.t

  type b = CBV.t

  let to_string_cbv cbv =
    let open Lwt_syntax in
    let+ cbv_bytes = CBV.to_bytes cbv in
    Format.asprintf "%a" Hex.pp (Hex.of_bytes cbv_bytes)

  let to_string_a = to_string_cbv

  let to_string_b = to_string_cbv

  let eq cbv1 cbv2 =
    let open Lwt_syntax in
    let* b1 = CBV.to_bytes cbv1 in
    let+ b2 = CBV.to_bytes cbv2 in
    Bytes.equal b1 b2
end

(* This module implements a durable interface for pair of
   durable storages X.t * Y.t .
   All the methods are performed on both durables and
   returned values and resulting durables tested on equality.
   Hence, this module aspires to mantain invariant that trees in the pair
   are always equal wrt. passed Eq_durable.
*)
module Make_paired_durable
    (Snapshot : Testable_durable_sig)
    (Current : Testable_durable_sig)
    (Eq_durable : Hetero_equality.S
                    with type a = Snapshot.t
                     and type b = Current.t)
    (Eq_cbv : Hetero_equality.S
                with type a = Snapshot.cbv
                 and type b = Current.cbv) :
  Testable_durable_sig
    with type t = Snapshot.t * Current.t
     and type cbv = Current.cbv = struct
  exception Invalid_key of string

  exception Index_too_large = Current.Index_too_large

  exception Value_not_found = Current.Value_not_found

  exception Tree_not_found = Current.Tree_not_found

  exception Out_of_bounds = Current.Out_of_bounds

  exception Durable_empty = Current.Durable_empty

  exception Readonly_value = Current.Readonly_value

  exception IO_too_large = Current.IO_too_large

  type t = Snapshot.t * Current.t

  type key = Snapshot.key * Current.key

  type cbv = Current.cbv

  (* Helper functions *)
  let guard (f : unit -> 'a Lwt.t) =
    Lwt.try_bind
      f
      (fun res -> Lwt.return (Ok res))
      (fun exn -> Lwt.return (Error exn))

  let assert_trees_equality (t_s, t_c) =
    let open Lwt_syntax in
    let* eq = Eq_durable.eq t_s t_c in
    (* Avoid calling trees' pp unless trees are different *)
    if eq then Lwt.return_unit
    else
      let* snapshot_str = Eq_durable.to_string_a t_s in
      let+ current_str = Eq_durable.to_string_b t_c in
      Assert.fail_msg
        "Tree states diverged: snapshot = %s vs current = %s"
        snapshot_str
        current_str

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

  let ensure_same_outcome (type a b) ((module Eq) : (a, b) Hetero_equality.t)
      (f_s : unit -> (a * Snapshot.t) Lwt.t)
      (f_c : unit -> (b * Current.t) Lwt.t) :
      (b * (Snapshot.t * Current.t)) Lwt.t =
    let open Lwt_syntax in
    let* outcome_snapshot = guard f_s in
    let* outcome_current = guard f_c in
    let assert_values_equality val_snapshot val_current =
      let* eq = Eq.eq val_snapshot val_current in
      if eq then Lwt.return_unit
      else
        let* val_snapshot_str = Eq.to_string_a val_snapshot in
        let* val_current_str = Eq.to_string_b val_current in
        Assert.fail_msg
          "Expected returned value %s but got %s"
          val_snapshot_str
          val_current_str
    in
    match (outcome_snapshot, outcome_current) with
    | Error error_snapshot, Error error_current ->
        Assert.equal
          ~loc:__LOC__
          ~msg:
            (Format.asprintf
               "Tree methods failed with different exceptions: %s vs %s"
               (Printexc.to_string error_snapshot)
               (Printexc.to_string error_current))
          (convert_durable_exception error_snapshot)
          error_current ;
        raise error_current
    | Ok (val_snapshot, tree_snapshot), Ok (val_current, tree_current) ->
        let* () = assert_values_equality val_snapshot val_current in
        let+ () = assert_trees_equality (tree_snapshot, tree_current) in
        (val_current, (tree_snapshot, tree_current))
    | Ok (val_snapshot, _), Error error_current ->
        let+ val_str = Eq.to_string_a val_snapshot in
        Assert.fail_msg
          "Expected returned value %s but failed with error %s"
          val_str
          (Printexc.to_string error_current)
    | Error error_snapshot, Ok (val_current, _) ->
        let+ val_str = Eq.to_string_b val_current in
        Assert.fail_msg
          "Expected to fail with error %s but value returned %s"
          (Printexc.to_string error_snapshot)
          val_str

  let same_trees (f_s : unit -> Snapshot.t Lwt.t)
      (f_c : unit -> Current.t Lwt.t) : (Snapshot.t * Current.t) Lwt.t =
    let open Lwt_syntax in
    let add_unit r = ((), r) in
    let+ _, trees =
      ensure_same_outcome
        (Hetero_equality.make
           ~pp:(fun fmt () -> Format.fprintf fmt "unit")
           ~eq:(fun _ _ -> true))
        (fun () -> Lwt.map add_unit @@ f_s ())
        (fun () -> Lwt.map add_unit @@ f_c ())
    in
    trees

  let same_values (type a b) (eq : (a, b) Hetero_equality.t)
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

  let find_value (tree_s, tree_c) (key_s, key_c) =
    same_values
      (Hetero_equality.make_option (module Eq_cbv))
      (add_tree tree_s @@ Snapshot.find_value tree_s key_s)
      (add_tree tree_c @@ Current.find_value tree_c key_c)

  let find_value_exn (tree_s, tree_c) (key_s, key_c) =
    same_values
      (module Eq_cbv)
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
      (Hetero_equality.make
         ~pp:(Fmt.list Fmt.string)
         ~eq:(List.equal String.equal))
      (add_tree tree_s @@ Snapshot.list tree_s key_s)
      (add_tree tree_c @@ Current.list tree_c key_c)

  let count_subtrees (tree_s, tree_c) (key_s, key_c) =
    same_values
      (Hetero_equality.make ~pp:Fmt.int ~eq:( = ))
      (add_tree tree_s @@ Snapshot.count_subtrees tree_s key_s)
      (add_tree tree_c @@ Current.count_subtrees tree_c key_c)

  let subtree_name_at (tree_s, tree_c) (key_s, key_c) n =
    same_values
      (Hetero_equality.make ~pp:Fmt.string ~eq:String.equal)
      (add_tree tree_s @@ Snapshot.subtree_name_at tree_s key_s n)
      (add_tree tree_c @@ Current.subtree_name_at tree_c key_c n)

  let delete ?edit_readonly (tree_s, tree_c) (key_s, key_c) =
    same_trees
      (fun () -> Snapshot.delete ?edit_readonly tree_s key_s)
      (fun () -> Current.delete ?edit_readonly tree_c key_c)

  let hash (tree_s, tree_c) (key_s, key_c) =
    same_values
      (Hetero_equality.make
         ~pp:(Fmt.option Context_hash.pp)
         ~eq:(Option.equal Context_hash.equal))
      (add_tree tree_s @@ Snapshot.hash tree_s key_s)
      (add_tree tree_c @@ Current.hash tree_c key_c)

  let hash_exn (tree_s, tree_c) (key_s, key_c) =
    same_values
      (Hetero_equality.make ~pp:Context_hash.pp ~eq:Context_hash.equal)
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
      (Hetero_equality.make ~pp:Fmt.string ~eq:String.equal)
      (add_tree tree_s @@ Snapshot.read_value_exn tree_s key_s offset len)
      (add_tree tree_c @@ Current.read_value_exn tree_c key_c offset len)
end
