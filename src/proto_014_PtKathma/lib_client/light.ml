(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

module Proof = Tezos_context_sigs.Context.Proof_types

module M : Tezos_proxy.Light_proto.PROTO_RPCS = struct
  let merkle_tree (pgi : Tezos_proxy.Proxy.proxy_getter_input) key leaf_kind =
    Protocol_client_context.Alpha_block_services.Context.merkle_tree
      pgi.rpc_context
      ~chain:pgi.chain
      ~block:pgi.block
      ~holey:
        (match leaf_kind with
        | Tezos_context_sigs.Context.Proof_types.Hole -> true
        | Tezos_context_sigs.Context.Proof_types.Raw_context -> false)
      key

  let merkle_tree_v2 (pgi : Tezos_proxy.Proxy.proxy_getter_input) key leaf_kind
      =
    Protocol_client_context.Alpha_block_services.Context.merkle_tree_v2
      pgi.rpc_context
      ~chain:pgi.chain
      ~block:pgi.block
      ~holey:
        (match leaf_kind with Proof.Hole -> true | Proof.Raw_context -> false)
      key
end
