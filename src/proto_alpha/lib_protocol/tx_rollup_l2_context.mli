(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

open Alpha_context
open Tx_rollup_l2_storage

(** This module type describes the API of the [Tx_rollup] context,
    which is used to implement the semantics of the L2 operations. *)
module type CONTEXT = sig
  (** The state of the [Tx_rollup] context.

      The context provides a type-safe, functional API to interact
      with the state of a transaction rollup.  The functions of this
      module, manipulating and creating values of type [t] are called
      “context operations” afterwards. *)
  type t

  (** The monad used by the context.

      {b Note:} It is likely to be the monad of the underlying
      storage. In the case of the proof verifier, as it is expected to
      be run into the L1, the monad will also be used to perform gas
      accounting. This is why all the functions of this module type
      needs to be inside the monad [m]. *)
  type 'a m

  (** The necessary monadic operators the storage monad is required to
      provide. *)
  module Syntax : sig
    val ( let+ ) : 'a m -> ('a -> 'b) -> 'b m

    val ( let* ) : 'a m -> ('a -> 'b m) -> 'b m

    (** [fail err] shortcuts the current computation by raising an
        error.

        Said error can be handled with the [catch] combinator. *)
    val fail : error -> 'a m

    (** [catch p k h] tries to executes the monadic computation [p].
        If [p] terminates without an error, then its result is passed
        to the continuation [k]. On the contrary, if an error [err] is
        raised, it is passed to the error handler [h]. *)
    val catch : 'a m -> ('a -> 'b m) -> (error -> 'b m) -> 'b m

    (** [return x] is the simplest computation inside the monad [m] which simply
        computes [x] and nothing else. *)
    val return : 'a -> 'a m

    (** [list_fold_left_m f] is a monadic version of [List.fold_left
        f], wherein [f] is not a pure computation, but a computation
        in the monad [m]. *)
    val list_fold_left_m : ('a -> 'b -> 'a m) -> 'a -> 'b list -> 'a m

    (** [fail_unless cond err] raises [err] iff [cond] is [false]. *)
    val fail_unless : bool -> error -> unit m
  end

  (** [bls_aggregate_verify] allows to verify the aggregated signature
      of a batch. *)
  val bls_verify :
    (Tx_rollup_l2_address.t * bytes) list ->
    Tx_rollup_l2_operation.signature ->
    bool m

  (** A mapping from L2 account public keys to their counter.

      The counter is an counter-measure against replay attack. Each
      operation is signed with an integer (its counter). The counter
      is incremented when the operation is applied. This prevents the
      operation to be applied once again, since its integer will not
      be in sync with the counter of the account.

      The choice of [int64] for the type of the counter theoretically
      the rollup to an integer overflow. However, it can only happen
      if a single account makes more than [1.8446744e+19]
      operations. If an account sends 1000 operations per seconds, it
      would take them more than 5845420 centuries to achieve that. *)
  module Counter : sig
    val get : t -> Tx_rollup_l2_address.t -> int64 m

    val set : t -> Tx_rollup_l2_address.t -> int64 -> t m
  end

  (** The ledger of the layer 2 where are registered the amount of a
      given ticket a L2 [account] has.

      {b Warning:} The number of a given ticket a given account can
      hold is bounded, due to the use of the [int64] type. This choice
      is made so that the size of the proofs of the L2 [apply]
      function is predictable. *)
  module Ticket_ledger : sig
    val get : t -> Ticket_hash.t -> Tx_rollup_l2_address.t -> int64 m

    val set : t -> Ticket_hash.t -> Tx_rollup_l2_address.t -> int64 -> t m
  end
end

(** Using this functor, it is possible to get a [CONTEXT]
    implementation from a [STORAGE] implementation for free. *)
module Make (S : STORAGE) : CONTEXT with type t = S.t and type 'a m = 'a S.m
