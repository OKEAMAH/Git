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

  module Internal_for_tests : sig
    val key_to_string : key -> string
  end
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

(* Hetero equality for chunked byte vector *)
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

module CBV_equality_option = Hetero_equality.Make_option (CBV_equality)

(* Adapter of snapshotted durable interface
   with additional cbv type, which it doesn't have *)
module Snapshot :
  Testable_durable_sig
    with type cbv = Tezos_lazy_containers.Chunked_byte_vector.t = struct
  type cbv = Tezos_lazy_containers.Chunked_byte_vector.t

  include Tezos_scoru_wasm_durable_snapshot.Durable
end

(* Adapter of current durable interface
   with additional cbv type, which it doesn't have *)
module Current :
  Testable_durable_sig
    with type cbv = Tezos_lazy_containers.Chunked_byte_vector.t = struct
  type cbv = Tezos_lazy_containers.Chunked_byte_vector.t

  include Tezos_scoru_wasm.Durable
end

module Durables_equality = Make_encodable_equality (Snapshot) (Current)

(* This module implements a durable testable interface
   for a current implementation (Current module) against
   the reference implementation (Snapshot module) .
   All the methods are performed on both durables and
   returned values and resulting durables tested on equality.
   Hence, this module aspires to mantain invariant that trees in the pair
   are always equal wrt. passed Eq_durable.
*)
module Make_paired_durable
    (Eq_durable : Hetero_equality.S
                    with type a = Snapshot.t
                     and type b = Current.t) :
  Testable_durable_sig
    with type t = Snapshot.t * Current.t
     and type cbv = Current.cbv = struct
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

     Without this funtion there are two different sets of
     exceptions:
       Tezos_scoru_wasm_durable_snapshot.Durable.Value_not_found
       Tezos_scoru_wasm.Durable.Value_not_found
     even though essentially it's the same exception.
  *)
  let convert_to_snapshot_durable_exception (e : exn) =
    Tezos_scoru_wasm_durable_snapshot.Durable.(
      match e with
      | Tezos_scoru_wasm.Durable.Invalid_key k -> Invalid_key k
      | Tezos_scoru_wasm.Durable.Index_too_large i -> Index_too_large i
      | Tezos_scoru_wasm.Durable.Value_not_found -> Value_not_found
      | Tezos_scoru_wasm.Durable.Tree_not_found -> Tree_not_found
      | Tezos_scoru_wasm.Durable.Out_of_bounds b -> Out_of_bounds b
      | Tezos_scoru_wasm.Durable.Durable_empty -> Durable_empty
      | Tezos_scoru_wasm.Durable.Readonly_value -> Readonly_value
      | Tezos_scoru_wasm.Durable.IO_too_large -> IO_too_large
      | e -> e)

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
          error_snapshot
          (convert_to_snapshot_durable_exception error_current) ;
        raise error_snapshot
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
        (module Hetero_equality.Unit)
        (fun () -> Lwt.map add_unit @@ f_s ())
        (fun () -> Lwt.map add_unit @@ f_c ())
    in
    trees

  let same_values (type a b) (eq : (a, b) Hetero_equality.t)
      (f_s : unit -> (a * Snapshot.t) Lwt.t)
      (f_c : unit -> (b * Current.t) Lwt.t) : b Lwt.t =
    Lwt.map fst @@ ensure_same_outcome eq f_s f_c

  let add_tree tree f = Lwt.map (fun r -> (r, tree)) f

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
      (module CBV_equality_option)
      (fun () -> add_tree tree_s @@ Snapshot.find_value tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.find_value tree_c key_c)

  let find_value_exn (tree_s, tree_c) (key_s, key_c) =
    same_values
      (module CBV_equality)
      (fun () -> add_tree tree_s @@ Snapshot.find_value_exn tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.find_value_exn tree_c key_c)

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
      (module Hetero_equality.String_list)
      (fun () -> add_tree tree_s @@ Snapshot.list tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.list tree_c key_c)

  let count_subtrees (tree_s, tree_c) (key_s, key_c) =
    same_values
      (module Hetero_equality.Int)
      (fun () -> add_tree tree_s @@ Snapshot.count_subtrees tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.count_subtrees tree_c key_c)

  let subtree_name_at (tree_s, tree_c) (key_s, key_c) n =
    same_values
      (module Hetero_equality.String)
      (fun () -> add_tree tree_s @@ Snapshot.subtree_name_at tree_s key_s n)
      (fun () -> add_tree tree_c @@ Current.subtree_name_at tree_c key_c n)

  let delete ?edit_readonly (tree_s, tree_c) (key_s, key_c) =
    same_trees
      (fun () -> Snapshot.delete ?edit_readonly tree_s key_s)
      (fun () -> Current.delete ?edit_readonly tree_c key_c)

  let hash (tree_s, tree_c) (key_s, key_c) =
    same_values
      (module Hetero_equality.Context_hash_option)
      (fun () -> add_tree tree_s @@ Snapshot.hash tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.hash tree_c key_c)

  let hash_exn (tree_s, tree_c) (key_s, key_c) =
    same_values
      (module Hetero_equality.Context_hash)
      (fun () -> add_tree tree_s @@ Snapshot.hash_exn tree_s key_s)
      (fun () -> add_tree tree_c @@ Current.hash_exn tree_c key_c)

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
      (module Hetero_equality.String)
      (fun () ->
        add_tree tree_s @@ Snapshot.read_value_exn tree_s key_s offset len)
      (fun () ->
        add_tree tree_c @@ Current.read_value_exn tree_c key_c offset len)

  module Internal_for_tests = struct
    let key_to_string (_k, k) = Current.Internal_for_tests.key_to_string k
  end
end

(* Convenient list of all testable operations *)
module Durable_operation = struct
  (* GADT type, each constructor's type represents a type parameters
     which are taken as input of corresponding operation *)
  type _ t =
    (* key *)
    | Find_value : string t
    (* edit_readonly, key, value *)
    | Find_value_exn : string t
    (* edit_readonly, key, value *)
    | Set_value_exn : (bool * string * string) t
    (* edit_readonly, key_from, key_to *)
    | Copy_tree_exn : (bool * string * string) t
    (* key_from, key_to *)
    | Move_tree_exn : (string * string) t
    (* edit_readonly, key *)
    | Delete : (bool * string) t
    (* key *)
    | List : string t
    (* key *)
    | Count_subtrees : string t
    (* key, idx*)
    | Substree_name_at : (string * int) t
    (* key *)
    | Hash : string t
    (* key *)
    | Hash_exn : string t
    (* edit_readonly, key, offset, value *)
    | Write_value_exn : (bool * string * int64 * string) t
    (* key, offset, len *)
    | Read_value_exn : (string * int64 * int64) t

  let pp (type a) fmt (x : a t) =
    match x with
    | Find_value -> Format.fprintf fmt "find_value"
    | Find_value_exn -> Format.fprintf fmt "find_value_exn"
    | Set_value_exn -> Format.fprintf fmt "set_value_exn"
    | Copy_tree_exn -> Format.fprintf fmt "copy_tree_exn"
    | Move_tree_exn -> Format.fprintf fmt "move_tree_exn"
    | Delete -> Format.fprintf fmt "delete"
    | List -> Format.fprintf fmt "list"
    | Count_subtrees -> Format.fprintf fmt "count_subtrees"
    | Substree_name_at -> Format.fprintf fmt "substree_name_at"
    | Hash -> Format.fprintf fmt "hash"
    | Hash_exn -> Format.fprintf fmt "hash_exn"
    | Write_value_exn -> Format.fprintf fmt "write_value_exn"
    | Read_value_exn -> Format.fprintf fmt "read_value_exn"

  type some_op = Some_op : 'a t -> some_op

  let pp_some_op fmt (x : some_op) = match x with Some_op op -> pp fmt op

  type some_input = Some_input : 'a t * 'a -> some_input

  let pp_some_input fmt (x : some_input) =
    match x with
    | Some_input (Find_value, key) ->
        Format.fprintf fmt "%a(%s)" pp Find_value key
    | Some_input (Find_value_exn, key) ->
        Format.fprintf fmt "%a(%s)" pp Find_value_exn key
    | Some_input (Set_value_exn, (edit_readonly, key, _value)) ->
        Format.fprintf
          fmt
          "%a(edit_readonly: %a, key: %s, value: %s)"
          pp
          Set_value_exn
          Fmt.bool
          edit_readonly
          key
          "<value>"
    | Some_input (Copy_tree_exn, (edit_readonly, from, to_)) ->
        Format.fprintf
          fmt
          "%a(edit_readonly: %a, from: %s, to: %s)"
          pp
          Copy_tree_exn
          Fmt.bool
          edit_readonly
          from
          to_
    | Some_input (Move_tree_exn, (from, to_)) ->
        Format.fprintf fmt "%a(from: %s, to: %s)" pp Move_tree_exn from to_
    | Some_input (Delete, (edit_readonly, key)) ->
        Format.fprintf
          fmt
          "%a(edit_readonly: %a, key: %s)"
          pp
          Delete
          Fmt.bool
          edit_readonly
          key
    | Some_input (List, key) -> Format.fprintf fmt "%a(%s)" pp List key
    | Some_input (Count_subtrees, key) ->
        Format.fprintf fmt "%a(%s)" pp Count_subtrees key
    | Some_input (Substree_name_at, (key, idx)) ->
        Format.fprintf fmt "%a(key: %s, index: %d)" pp Substree_name_at key idx
    | Some_input (Hash, key) -> Format.fprintf fmt "%a(%s)" pp Hash key
    | Some_input (Hash_exn, key) -> Format.fprintf fmt "%a(%s)" pp Hash_exn key
    | Some_input (Write_value_exn, (edit_readonly, key, offset, _value)) ->
        Format.fprintf
          fmt
          "%a(edit_readonly: %a, key: %s, offset: %Ld, value: %s)"
          pp
          Write_value_exn
          Fmt.bool
          edit_readonly
          key
          offset
          "<value>"
    | Some_input (Read_value_exn, (key, offset, len)) ->
        Format.fprintf
          fmt
          "%a(key: %s, offset: %Ld, len: %Ld)"
          pp
          Read_value_exn
          key
          offset
          len

  module Map = Map.Make (struct
    type t = some_op

    let compare = Stdlib.compare
  end)

  module Set = Set.Make (struct
    type t = some_op

    let compare = Stdlib.compare
  end)

  let write_operations : some_op list =
    [Some_op Write_value_exn; Some_op Set_value_exn]

  let read_operations : some_op list =
    [Some_op Find_value; Some_op Read_value_exn; Some_op Find_value_exn]

  let structure_inspection_operations : some_op list =
    [
      Some_op Hash;
      Some_op List;
      Some_op Count_subtrees;
      Some_op Substree_name_at;
      Some_op Hash_exn;
    ]

  let structure_modification_operations : some_op list =
    [Some_op Delete; Some_op Copy_tree_exn; Some_op Move_tree_exn]

  let all_operations : some_op list =
    let all =
      List.concat
        [
          write_operations;
          read_operations;
          structure_modification_operations;
          structure_inspection_operations;
        ]
    in
    Assert.Int.equal
      ~loc:__LOC__
      ~msg:"Not exhaust list of durable operations"
      (List.length all)
      13 ;
    all
end

(* Wrapper around tested durable which keeps track some
   statistic, also might be used for debug tracing.
*)
module Traceable_durable = struct
  module type S = sig
    include Testable_durable_sig

    val print_collected_statistic : unit -> unit
  end

  module Default_traceable_config = struct
    let print_operations : Durable_operation.Set.t = Durable_operation.Set.empty

    let count_methods_invocations = true
  end

  module type Traceable_config = module type of Default_traceable_config

  module Make (Config : Traceable_config) (D : Testable_durable_sig) :
    S with type t = D.t and type key = D.key and type cbv = D.cbv = struct
    open Durable_operation

    type st = {succ : int; fails : int}

    let method_invocations : st Map.t ref = ref Durable_operation.Map.empty

    let tot_method_invocations : int ref = ref 0

    type t = D.t

    type key = D.key

    type cbv = D.cbv

    let is_op_printable (op : _ Durable_operation.t) =
      Set.mem (Some_op op) Config.print_operations

    let inspect_op (type input) (op : input Durable_operation.t) (inp : input)
        (is_succ : 'a -> bool) (operation : unit -> 'a Lwt.t) : 'a Lwt.t =
      let inc f =
        if Config.count_methods_invocations then
          method_invocations :=
            Map.update
              (Some_op op)
              (Option.fold
                 ~none:(Some (f {succ = 0; fails = 0}))
                 ~some:(fun x -> Some (f x)))
              !method_invocations
        else ()
      in
      let inc_succ () = inc (fun t -> {t with succ = t.succ + 1}) in
      let inc_fails () = inc (fun t -> {t with fails = t.fails + 1}) in
      tot_method_invocations := !tot_method_invocations + 1 ;
      Lwt.try_bind
        operation
        (fun a ->
          if is_succ a then inc_succ () else inc_fails () ;
          if is_op_printable op then
            Format.printf
              "%4d: %a completed normally\n\n"
              !tot_method_invocations
              Durable_operation.pp_some_input
              (Some_input (op, inp)) ;
          Lwt.return a)
        (fun exn ->
          inc_fails () ;
          if is_op_printable op then
            Format.printf
              "%4d: %a completed with an exception: %s\n\n"
              !tot_method_invocations
              Durable_operation.pp_some_input
              (Some_input (op, inp))
              (Printexc.to_string exn) ;
          raise exn)

    let encoding = D.encoding

    let max_key_length = D.max_key_length

    let key_of_string_exn = D.key_of_string_exn

    let key_of_string_opt = D.key_of_string_opt

    let find_value dur key =
      inspect_op
        Find_value
        (D.Internal_for_tests.key_to_string key)
        Option.is_some
      @@ fun () -> D.find_value dur key

    let find_value_exn dur key =
      inspect_op
        Find_value_exn
        (D.Internal_for_tests.key_to_string key)
        (Fun.const true)
      @@ fun () -> D.find_value_exn dur key

    let copy_tree_exn dur ?(edit_readonly = false) key_from key_to =
      inspect_op
        Copy_tree_exn
        ( edit_readonly,
          D.Internal_for_tests.key_to_string key_from,
          D.Internal_for_tests.key_to_string key_to )
        (Fun.const true)
      @@ fun () -> D.copy_tree_exn dur ~edit_readonly key_from key_to

    let move_tree_exn dur key_from key_to =
      inspect_op
        Move_tree_exn
        ( D.Internal_for_tests.key_to_string key_from,
          D.Internal_for_tests.key_to_string key_to )
        (Fun.const true)
      @@ fun () -> D.move_tree_exn dur key_from key_to

    let list dur key =
      inspect_op List (D.Internal_for_tests.key_to_string key) (fun l ->
          not (List.is_empty l))
      @@ fun () -> D.list dur key

    let count_subtrees dur key =
      inspect_op
        Count_subtrees
        (D.Internal_for_tests.key_to_string key)
        (fun l -> l > 0)
      @@ fun () -> D.count_subtrees dur key

    let subtree_name_at dur key sibling_id =
      inspect_op
        Substree_name_at
        (D.Internal_for_tests.key_to_string key, sibling_id)
        (Fun.const true)
      @@ fun () -> D.subtree_name_at dur key sibling_id

    let delete ?(edit_readonly = false) dur key =
      inspect_op
        Delete
        (edit_readonly, D.Internal_for_tests.key_to_string key)
        (Fun.const true)
      @@ fun () -> D.delete ~edit_readonly dur key

    let hash dur key =
      inspect_op Hash (D.Internal_for_tests.key_to_string key) Option.is_some
      @@ fun () -> D.hash dur key

    let hash_exn dur key =
      inspect_op
        Hash_exn
        (D.Internal_for_tests.key_to_string key)
        (Fun.const true)
      @@ fun () -> D.hash_exn dur key

    let set_value_exn dur ?(edit_readonly = false) key value =
      inspect_op
        Set_value_exn
        (edit_readonly, D.Internal_for_tests.key_to_string key, value)
        (Fun.const true)
      @@ fun () -> D.set_value_exn dur ~edit_readonly key value

    let write_value_exn dur ?(edit_readonly = false) key offset value =
      inspect_op
        Write_value_exn
        (edit_readonly, D.Internal_for_tests.key_to_string key, offset, value)
        (Fun.const true)
      @@ fun () -> D.write_value_exn dur ~edit_readonly key offset value

    let read_value_exn dur key offset len =
      inspect_op
        Read_value_exn
        (D.Internal_for_tests.key_to_string key, offset, len)
        (Fun.const true)
      @@ fun () -> D.read_value_exn dur key offset len

    module Internal_for_tests = D.Internal_for_tests

    let print_collected_statistic () =
      let collected = Map.bindings !method_invocations in
      let sm = !tot_method_invocations in
      let to_perc (x : int) (tot : int) =
        Float.(div (of_int (Int.mul 100 x)) (of_int tot))
      in
      Format.printf "Methods invocation statistic, total invocations: %d\n" sm ;
      List.iter
        (fun (op, st) ->
          Format.printf
            "%4s%a: %.1f%% of all ops\n%8sSuccessful: %.1f%% / Fails: %.1f%%\n"
            ""
            Durable_operation.pp_some_op
            op
            (to_perc (st.succ + st.fails) sm)
            ""
            (to_perc st.succ (st.succ + st.fails))
            (to_perc st.fails (st.succ + st.fails)))
        collected
  end
end

module Paired_durable = Make_paired_durable (Durables_equality)
