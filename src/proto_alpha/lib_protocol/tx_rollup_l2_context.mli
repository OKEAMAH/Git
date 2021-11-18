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
open Tx_rollup_l2_repr

(** This module type describes the API of the [Tx_rollup] context,
    which is used to implement the semantics of the L2 operations. *)
module type CONTEXT = sig
  (** The state of the [Tx_rollup] context.

      The context provides a type-safe, carbonated, functional API to
      interact with the state of a transaction rollup. The gas
      accounting ({i i.e.}, carbonation of certain operations) can be
      enabled by setting a gas limit (see [set_gas_limit]), or
      disabled (see [unset_gas_limit]).

      The functions of this module, manipulating and creating values
      of type [t] are called “context operations” afterwards. *)
  type t

  (** The monad used by the context.

      It is likely to be the monad of the underlying storage. *)
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

  (** [set_gas_limit ctxt gas] enables the gas accounting for the following
      context operations.

      If these operations require more than the remaining gas, then
      the [Not_enough_gas] error is raised. *)
  val set_gas_limit : t -> Gas.Arith.fp -> t

  (** [unset_gas_limit ctxt] disables the gas accounting.

      Further context operations will not consume any gas. *)
  val unset_gas_limit : t -> t

  (** [consume_gas ctxt gas] removes [gas] from the remaining gas
      limit of [ctxt] iff the gas accounting is enabled ({i i.e.},
      [set_gas_limit] has been called).

      It raises the [Not_enough_gas] error iff the gas accounting is
      enabled and [gas] is greater or equal to the remaining gas of
      [ctxt]. *)
  val consume_gas : t -> Gas.Arith.fp -> t m

  (** [remaining_gas ctxt] returns the remaining gas in [ctxt] if the
      gas accounting is enabled, [None] otherwise. *)
  val remaining_gas : t -> Gas.Arith.fp option

  (** [consumed_gas ctxt ~since:ctxt'] computes the amount of gas
      consumed by the operations executed since [ctxt'] up to
      [ctxt]. *)
  val consumed_gas : t -> since:t -> Gas.Arith.fp option

  (** [bls_aggregate_verify] is a carbonated version of
      {!Bls_signature.aggregate_verify}. *)
  val bls_verify : t -> (account * bytes) list -> bytes -> (bool * t) m

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
    val get : t -> account -> (int64 * t) m

    val set : t -> account -> int64 -> t m
  end

  (** The ledger of the layer 2 where are registered the amount of a
      given ticket a L2 [account] has.

      The [get] and [set] functions of this module are carbonated,
      which means they can raise a [Not_enough_gas] error in case of
      gas exhaustion.

      {b Warning:} The number of a given ticket a given account can
      hold is bounded, due to the use of the [int64] type. This choice
      is made so that the size of the proofs of the L2 [apply]
      function is predictable. *)
  module Ticket_ledger : sig
    val get : t -> Ticket_balance.key_hash -> account -> (int64 * t) m

    val set : t -> Ticket_balance.key_hash -> account -> int64 -> t m
  end
end

(** A generic implementation of a context providing a type-safe,
    carbonated interface on top of an underlying, untyped storage. *)
type 'a context = {storage : 'a; remaining_gas : Gas.Arith.integral option}

(** Using this functor, it is possible to get a [CONTEXT]
    implementation from a [STORAGE] implementation for free. *)
module Make (S : STORAGE) :
  CONTEXT with type t = S.t context and type 'a m = 'a S.m

type error += Not_enough_gas

(** Used by the protocol benchmarks *)
module Internal_for_tests : sig
  type _ key =
    | Counter : account -> int64 key
    | Ticket_ledger : Ticket_balance.key_hash * account -> int64 key

  type packed_key = Key : 'a key -> packed_key

  val packed_key_encoding : packed_key Data_encoding.t
end
