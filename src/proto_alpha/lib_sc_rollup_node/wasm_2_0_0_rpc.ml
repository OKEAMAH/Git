(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Trili Tech <contact@trili.tech>                        *)
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

open RPC_directory_helpers

module Make_RPC
    (Durable_state : Wasm_2_0_0_pvm.Durable_state with type tree = Context.tree) =
struct
  module Block_directory = Make_directory (struct
    include Sc_rollup_services.Global.Block

    type context = Node_context.ro * Block_hash.t

    let context_of_prefix node_ctxt (((), block) : prefix) =
      let open Lwt_result_syntax in
      let+ block = Block_directory_helpers.block_of_prefix node_ctxt block in
      (Node_context.readonly node_ctxt, block)
  end)

  let get_state (node_ctxt : _ Node_context.t) block_hash =
    let open Lwt_result_syntax in
    let* ctxt = Node_context.checkout_context node_ctxt block_hash in
    let*! state = Context.PVMState.find ctxt in
    match state with None -> failwith "No state" | Some state -> return state

  let register () =
    let open Protocol.Alpha_context.Sc_rollup in
    ( Block_directory.register0
        (Sc_rollup_services.Global.Block.durable_state_value Kind.Wasm_2_0_0)
    @@ fun (node_ctxt, block) {key} () ->
      let open Lwt_result_syntax in
      let* state = get_state node_ctxt block in
      let*! value = Durable_state.lookup state.Context.optimistic key in
      return value ) ;

    ( Block_directory.register0
        (Sc_rollup_services.Global.Block.durable_state_length Kind.Wasm_2_0_0)
    @@ fun (node_ctxt, block) {key} () ->
      let open Lwt_result_syntax in
      let* state = get_state node_ctxt block in
      let*! leng = Durable_state.value_length state.Context.optimistic key in
      return leng ) ;

    Block_directory.register0
      (Sc_rollup_services.Global.Block.durable_state_subkeys Kind.Wasm_2_0_0)
    @@ fun (node_ctxt, block) {key} () ->
    let open Lwt_result_syntax in
    let* state = get_state node_ctxt block in
    let*! subkeys = Durable_state.list state.Context.optimistic key in
    return subkeys

  let build_directory node_ctxt =
    register () ;
    Block_directory.build_directory node_ctxt
end
