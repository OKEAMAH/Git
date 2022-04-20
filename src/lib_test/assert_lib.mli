(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

(** [assert_lib] contains Alcotest convenience assertions depending on Tezos_base. *)

module Crypto : sig
  (** [equal_operation msg op0 op1] checks that the operations [op0] and [op1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_operation :
    ?msg:string ->
    Tezos_base.Operation.t option ->
    Tezos_base.Operation.t option ->
    unit

  (** [equal_block msg b0 b1] checks that the blocks [b0] and [b1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_block :
    ?msg:string ->
    Tezos_base.Block_header.t ->
    Tezos_base.Block_header.t ->
    unit

  (** [equal_block_set msg bs0 bs1] checks that the block sets [bs0] and [bs1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_block_set :
    ?msg:string ->
    Tezos_crypto.Block_hash.Set.t ->
    Tezos_crypto.Block_hash.Set.t ->
    unit

  (** [equal_block_map msg bm0 bm1] checks that the block maps [bm0] and [bm1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_block_map :
    ?msg:string ->
    eq:('a -> 'a -> bool) ->
    'a Tezos_crypto.Block_hash.Map.t ->
    'a Tezos_crypto.Block_hash.Map.t ->
    unit

  (** [equal_block_hash_list msg bhl0 bhl1] checks that the block hashes list [bhl0] and [bhl1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_block_hash_list :
    ?msg:string ->
    Tezos_crypto.Block_hash.t list ->
    Tezos_crypto.Block_hash.t list ->
    unit

  (** [equal_block_descriptor msg bd0 bd1] checks that the block descriptors [bd0] and [bd1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_block_descriptor :
    ?msg:string ->
    int32 * Tezos_crypto.Block_hash.t ->
    int32 * Tezos_crypto.Block_hash.t ->
    unit
end

module Shell_services : sig
  (** [equal_history_mode msg hm0 hm1] checks that the history modes [hm0] and [hm1] are
        equal. Will fail with the message [msg] otherwise *)
  val equal_history_mode :
    ?msg:string ->
    Tezos_shell_services.History_mode.t ->
    Tezos_shell_services.History_mode.t ->
    unit
end
