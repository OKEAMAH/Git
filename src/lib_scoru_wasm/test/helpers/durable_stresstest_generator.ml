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
open Durable_snapshot_util

(* Weighted operations list:
   operations will be generated proportionally to their weight *)
type operations_distribution = (int * Durable_operation.some_op) list

module Durable_operation_generator
    (Durable : Durable_snapshot_util.Testable_durable_sig) =
struct
  module type S = sig
    type ctxt

    module State : Monads_util.State with type t = ctxt

    (* Given generator for key and Durable storage,
       generated a Durable operation and invoke it on the durable *)
    val apply_op : Durable.t -> Durable.t Gen_lwt(State).t
  end

  module Make_probabilistic_generator (IG : Durable_input_generator.S) = struct
    (* Actually we don't modify operations_distribution in this generator,
       but lest's keep it in State monad anyway.
    *)
    type ctxt = IG.ctxt * operations_distribution

    (* This type is only needed to call generate_input *)
    module Gen_substate =
      Gen_substate
        (struct
          type t = IG.ctxt
        end)
        (struct
          type t = operations_distribution
        end)

    module State = struct
      type t = ctxt
    end

    module Gen_lwt = Gen_lwt (State)
    module Gen_lwt_syntax = Gen_lwt_syntax (State)
    open Gen_lwt_syntax

    let generate_input (type input) (op : input Durable_operation.t) :
        input Gen_lwt.t =
      Gen_substate.lift (IG.generate_input op)

    let durable_exn_handler (act : unit -> 'a Lwt.t)
        (cont : ('a, exn) result -> 'b Lwt.t) =
      Lwt.try_bind
        act
        (fun res -> cont @@ Ok res)
        (fun e ->
          Tezos_scoru_wasm_durable_snapshot.Durable.(
            match e with
            | Invalid_key _ | Index_too_large _ | Value_not_found
            | Tree_not_found | Out_of_bounds _ | Durable_empty | Readonly_value
            | IO_too_large ->
                cont @@ Error e
            (* This one below is thrown from Durable as well
               but are not exposed in public API.
               I don't think it's nice design *)
            | exn
              when Printexc.to_string exn
                   = "Tezos_tree_encoding__Decoding.Key_not_found(_)" ->
                cont @@ Error e
            (* If it's another kind of exn:
               something went wrong, re-throw it*)
            | _ -> raise e))

    (* Stress test doesn't care about exceptions
       thrown out of functions.
       It's implied that underlying Durable has already checked them.
    *)
    let supress_durable_exn dur (act : unit -> 'a Lwt.t) =
      durable_exn_handler act (fun _ -> Lwt.return dur)

    let find_value dur =
      let* key = generate_input Durable_operation.Find_value in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.find_value dur (Durable.key_of_string_exn key)

    let find_value_exn dur =
      let* key = generate_input Durable_operation.Find_value_exn in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.find_value_exn dur (Durable.key_of_string_exn key)

    let set_value dur =
      let* edit_readonly, key, value =
        generate_input Durable_operation.Set_value_exn
      in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.set_value_exn
        ~edit_readonly
        dur
        (Durable.key_of_string_exn key)
        value

    let copy_tree dur =
      let* edit_readonly, key_from, key_to =
        generate_input Durable_operation.Copy_tree_exn
      in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.copy_tree_exn
        ~edit_readonly
        dur
        (Durable.key_of_string_exn key_from)
        (Durable.key_of_string_exn key_to)

    let move_tree dur =
      let* key_from, key_to = generate_input Durable_operation.Move_tree_exn in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.move_tree_exn
        dur
        (Durable.key_of_string_exn key_from)
        (Durable.key_of_string_exn key_to)

    let delete_tree dur =
      let* edit_readonly, key = generate_input Durable_operation.Delete in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.delete ~edit_readonly dur (Durable.key_of_string_exn key)

    let count_subtrees dur =
      let* key = generate_input Durable_operation.Count_subtrees in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.count_subtrees dur (Durable.key_of_string_exn key)

    let subtree_name dur =
      let* key, subtree_id =
        generate_input Durable_operation.Substree_name_at
      in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.subtree_name_at dur (Durable.key_of_string_exn key) subtree_id

    let list dur =
      let* key = generate_input Durable_operation.List in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.list dur (Durable.key_of_string_exn key)

    let hash dur =
      let* key = generate_input Durable_operation.Hash in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.hash dur (Durable.key_of_string_exn key)

    let hash_exn dur =
      let* key = generate_input Durable_operation.Hash_exn in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () -> Durable.hash_exn dur (Durable.key_of_string_exn key)

    let write_value dur =
      let* edit_readonly, key, offset, value =
        generate_input Durable_operation.Write_value_exn
      in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.write_value_exn
        ~edit_readonly
        dur
        (Durable.key_of_string_exn key)
        offset
        value

    let read_value dur =
      let* key, offset, len = generate_input Durable_operation.Read_value_exn in
      Gen_lwt.lift_lwt @@ supress_durable_exn dur
      @@ fun () ->
      Durable.read_value_exn dur (Durable.key_of_string_exn key) offset len

    let apply_op dur =
      let open Durable_operation in
      let* _, operations_probability_distribution = Gen_lwt.get_state in
      let*? invoke_op = Gen.frequencyl operations_probability_distribution in
      let operations : (Durable.t -> Durable.t Gen_lwt.t) Map.t =
        Map.of_seq @@ List.to_seq
        @@ [
             (Some_op Find_value, find_value);
             (Some_op Find_value_exn, find_value_exn);
             (Some_op Set_value_exn, set_value);
             (Some_op Copy_tree_exn, copy_tree);
             (Some_op Move_tree_exn, move_tree);
             (Some_op Delete, delete_tree);
             (Some_op Count_subtrees, count_subtrees);
             (Some_op Substree_name_at, subtree_name);
             (Some_op List, list);
             (Some_op Hash, hash);
             (Some_op Hash_exn, hash_exn);
             (Some_op Write_value_exn, write_value);
             (Some_op Read_value_exn, read_value);
           ]
      in
      let op_f =
        WithExceptions.Option.get ~loc:__LOC__
        @@ Map.find_opt invoke_op operations
      in
      op_f dur
  end
end
