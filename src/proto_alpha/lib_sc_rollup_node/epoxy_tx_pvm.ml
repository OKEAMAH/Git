(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Protocol
open Alpha_context

(** This module manifests the proof format used by the Arith PVM as defined by
    the Layer 1 implementation for it.

    It is imperative that this is aligned with the protocol's implementation.
*)
module Epoxy_tx_proof_format =
  Context.Proof
    (struct
      include Sc_rollup.State_hash

      let of_context_hash = Sc_rollup.State_hash.context_hash_to_state_hash
    end)
    (struct
      let proof_encoding =
        Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V2.Tree2
        .tree_proof_encoding
    end)

module Impl : Pvm.S = struct
  module PVM = Sc_rollup.Epoxy_tx.Make (Epoxy_tx_proof_format)
  include PVM
  module TxTypes = Epoxy_tx.Types.P
  module TxLogic = Epoxy_tx.Tx_rollup.P

  let kind = Sc_rollup.Kind.Example_arith

  let diff_commitments = true

  type state_diff = {
    optimistic : Sc_rollup.State_hash.t;
    instant : TxTypes.state;
  }

  let state_diff_to_node_context_diff {optimistic; instant} =
    (optimistic, instant)

  let state_diff_of_node_context_diff (optimistic, instant) =
    {optimistic; instant}

  let compute_diff (old_state : state) (new_state : state) =
    let optimistic = Epoxy_tx_proof_format.hash_tree new_state.optimistic in
    let instant =
      TxLogic.compute_diff
        (Stdlib.Option.get old_state.instant)
        (Stdlib.Option.get new_state.instant)
    in
    {optimistic; instant}

  let diff_hash (d : state_diff) =
    let instant_root_bytes =
      Epoxy_tx.Utils.scalar_to_bytes @@ TxLogic.state_scalar d.instant
    in
    let optimistic_hash_bytes = Sc_rollup.State_hash.to_bytes d.optimistic in
    Sc_rollup.Diff_hash.hash_bytes [instant_root_bytes; optimistic_hash_bytes]

  module State = Context.PVMState

  let new_dissection = Game_helpers.default_new_dissection

  let string_of_status status =
    match status with
    | Halted -> "Halted"
    | Parsing -> "Parsing"
    | Waiting_for_input_message -> "Waiting for input message"
    | Waiting_for_reveal -> "Waiting for reveal"
    | Waiting_for_metadata -> "Waiting for metadata"
    | Evaluating -> "Evaluating"

  let eval_many ~reveal_builtins:_ ~write_debug:_ ?stop_at_snapshot ~max_steps
      initial_state =
    ignore stop_at_snapshot ;
    let open Lwt.Syntax in
    let rec go state step =
      let* () = Event.kernel_debug ("go: " ^ Int64.to_string step) in
      let* is_input_required = is_input_state state in
      if is_input_required = No_input_required && step < max_steps then
        let open Lwt.Syntax in
        (* Note: This is not an efficient implementation because the state is
           decoded/encoded to/from the tree at each step but for Epoxy-tx PVM
           it doesn't matter
        *)
        let root =
          let open Context in
          let instant = Stdlib.Option.get state.instant in
          Epoxy_tx.Tx_rollup.(Merkle.root instant.accounts_tree)
        in
        let* () =
          Event.kernel_debug ("old root: " ^ Bls12_381.Fr.to_string root)
        in
        let* next_state = eval state in
        let root =
          let open Context in
          let instant = Stdlib.Option.get next_state.instant in
          Epoxy_tx.Tx_rollup.(Merkle.root instant.accounts_tree)
        in
        let* () =
          Event.kernel_debug ("new root: " ^ Bls12_381.Fr.to_string root)
        in
        go next_state (Int64.succ step)
      else Lwt.return (state, step)
    in
    go initial_state 0L
end

include Impl
