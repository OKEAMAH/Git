(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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
open Protocol.Alpha_context

(** The RPC server and the Daemon main loop are sharing a variable of the
    type stored in the Irmin store. The [State] module allows access to this stored
    data. *)

(** A (size 1) cache for a context and its hash.  *)
type context_cache = {
  context : Context.t;
  context_hash : Protocol.Tx_rollup_l2_context_hash.t;
}

type t = private {
  store : Stores.t;
  context_index : Context.index;
  context_cache : context_cache option;
}

(** [init ~data_dir ~context ~rollup ~block_origination_hash]
    checks that the rollup [rollup_id] is created inside the block
    identified by the hash [block_origination_hash], and creates an
    initial state and context for the rollup node if that is the case. *)
val init :
  data_dir:string ->
  context:#Protocol_client_context.full ->
  rollup:Tx_rollup.t ->
  rollup_genesis:Block_hash.t ->
  t tzresult Lwt.t

(** [set_new_head state hash] saves the Tezos head that has just been processed in a
    reference cell. *)
val set_new_head : t -> Block_hash.t -> unit tzresult Lwt.t

(** [get_head state] returns the head that has just been processed from the
    reference cell. *)
val get_head : t -> Block_hash.t option Lwt.t

(** [context_hash state block_hash] returns the rollup context hash associated
    with a Tezos block hash, i.e. the hash of the context resulting from the
    application of the inbox contained in this block. Returns [None] if the block
    [block_hash] has never been handled by the rollup node. *)
val context_hash :
  t -> Block_hash.t -> Protocol.Tx_rollup_l2_context_hash.t option Lwt.t

(** [block_already_seen state block] returns the hash of the context after the
    application of the inbox of block [block] if it has already been processed,
    or [None] otherwise. *)
val block_already_seen :
  t -> Block_hash.t -> Protocol.Tx_rollup_l2_context_hash.t option Lwt.t

(** [save_inbox state hash inbox] saves the inbox relative to the block referenced by
    the hash given as
    an argument. *)
val save_inbox : t -> Block_hash.t -> Inbox.t -> unit tzresult Lwt.t

(** [find_inbox state hash] Find the inbox stored at [hash]. *)
val find_inbox : t -> Block_hash.t -> Inbox.t option Lwt.t

(** [rollup_operation_index] returns the index where are rollup operation (currently
    as manager operation) stored into a [Block_info.t]. *)
val rollup_operation_index : int

(** [save_context_hash state block_hash context_hash] saves the rollup context
    hash resulting from the application of the inbox contained in the block
    [block_hash]. *)
val save_context_hash :
  t ->
  Block_hash.t ->
  Protocol.Tx_rollup_l2_context_hash.t ->
  unit tzresult Lwt.t

(** Cache a context and its hash in the state so as to prevent unnecessary
    checkouts on linear histories (e.g. in the normal mode).  *)
val cache_context : t -> Context.t -> Protocol.Tx_rollup_l2_context_hash.t -> t
