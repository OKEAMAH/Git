(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

open Octez_smart_rollup_node.Layer1

(** [fetch_tezos_block cctxt hash] returns a block info given a block hash.
    Looks for the block in the blocks cache first, and fetches it from the L1
    node otherwise. *)
val fetch_tezos_block :
  t ->
  Block_hash.t ->
  Protocol_client_context.Alpha_block_services.block_info tzresult Lwt.t

(** [prefetch_tezos_blocks l1_ctxt blocks] prefetches the blocks
    asynchronously. NOTE: the number of blocks to prefetch must not be greater
    than the size of the blocks cache otherwise they will be lost. *)
val prefetch_tezos_blocks : t -> head list -> unit

val get_last_cemented_commitment :
  Protocol_client_context.full -> Address.t -> Node_context.lcc tzresult Lwt.t

val get_last_published_commitment :
  Protocol_client_context.full ->
  Address.t ->
  Signature.public_key_hash ->
  Commitment.t option tzresult Lwt.t

val get_kind :
  Protocol_client_context.full -> Address.t -> Kind.t tzresult Lwt.t

val genesis_inbox :
  Protocol_client_context.full ->
  genesis_level:int32 ->
  Octez_smart_rollup.Inbox.t tzresult Lwt.t

val constants_of_parametric :
  Protocol.Alpha_context.Constants.Parametric.t ->
  Node_context.protocol_constants

val retrieve_constants :
  Protocol_client_context.full -> Node_context.protocol_constants tzresult Lwt.t

val retrieve_genesis_info :
  Protocol_client_context.full ->
  Address.t ->
  Node_context.genesis_info tzresult Lwt.t
