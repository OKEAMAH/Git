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

open Tx_rollup_l2_storage

type signature

val signature_encoding : signature Data_encoding.t

(** An integer used to identified a layer-2 address. See
    {!Tx_rollup_l2_address.index}. *)
type address_index = Tx_rollup_l2_address.Indexable.index

(** An integer used to identified a layer-1 ticket deposited in a
    transaction rollup. *)
type ticket_index = Tx_rollup_l2_batch.Ticket_indexable.index

(** The metadata associated to a layer-2 address.

    The counter is an counter-measure against replay attack. Each
    operation is signed with an integer (its counter). The counter
    is incremented when the operation is applied. This prevents the
    operation to be applied once again, since its integer will not
    be in sync with the counter of the account.  The choice of [int64]
    for the type of the counter theoretically the rollup to an integer
    overflow. However, it can only happen if a single account makes
    more than [1.8446744e+19] operations. If an account sends 1000
    operations per seconds, it would take them more than 5845420
    centuries to achieve that.

    The [public_key] allows to authenticate the owner of the address,
    by verifying BLS signatures. *)
type metadata = {counter : int64; public_key : Bls_signature.pk}

type error +=
  | Balance_too_low
  | Balance_overflow
  | Unknown_address_index of address_index

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
  val bls_verify : (Bls_signature.pk * bytes) list -> signature -> bool m

  (** The metadata associated to an address. *)
  module Address_metadata : sig
    (** [get ctxt idx] returns the current metadata associated to the
        address indexed by [idx]. *)
    val get : t -> address_index -> metadata option m

    (** [incr_counter ctxt idx] increments the counter of the
        address indexed by [idx].

        This function can fails with [Unknown_address_index] if [idx]
        has not been associated with a layer-2 address already. *)
    val incr_counter : t -> address_index -> t m

    (** [init_with_public_key ctxt idx pk] initializes the metadata
        associated to the address indexed by [idx].

        This can fails with [Metadata_already_initialized] if this
        function has already been called with [idx]. *)
    val init_with_public_key : t -> address_index -> Bls_signature.pk -> t m
  end

  (** Mapping between {!Tx_rollup_l2_address.address} and {!address_index}. *)
  module Address_index : sig
    (** [associate_index ctxt addr] associates a fresh [address_index]
        to [addr], and returns it.

        This function can fails with [Too_many_l2_addresses] iff there
        is no fresh index available.

        {b Note:} It is the responsibility of the caller to verify that
        [addr] has not been associated to another index already. *)
    val associate_index : t -> Tx_rollup_l2_address.t -> (t * address_index) m

    (** [get ctxt addr] returns the index associated to [addr], if
        any. *)
    val get : t -> Tx_rollup_l2_address.t -> address_index option m

    (** [count ctxt] returns the number of addresses that have been
        involved in the transaction rollup. *)
    val count : t -> int32 m
  end

  (** Mapping between {!Ticket_hash_repr.t} and {!ticket_index}. *)
  module Ticket_index : sig
    (** [associate_index ctxt ticket] associates a fresh [ticket_index]
        to [ticket], and returns it.

        This function can fails with [Too_many_l2_tickets] iff there
        is no fresh index available.

        {b Note:} It is the responsibility of the caller to verify that
        [ticket] has not been associated to another index already. *)
    val associate_index : t -> Ticket_hash_repr.t -> (t * ticket_index) m

    (** [get ctxt ticket] returns the index associated to [ticket], if
        any. *)
    val get : t -> Ticket_hash_repr.t -> ticket_index option m

    (** [count ctxt] returns the number of tickets that have been
        involved in the transaction rollup. *)
    val count : t -> int32 m
  end

  (** The ledger of the layer 2 where are registered the amount of a
      given ticket a L2 [account] has in its possession. *)
  module Ticket_ledger : sig
    val get : t -> ticket_index -> address_index -> int64 m

    (** [credit ctxt tidx aidx qty] updates the legder to
        increase the number of tickets indexed by [tidx] the address
        [aidx] owns by [qty] units.

        This function can fails with [Balance_overflow] if adding
        [qty] to the current balance of [aidx] causes an integer
        overflow.

        {b Note:} It is the responsibility of the caller to verify
        that [aidx] and [tidx] have been associated to an address and
        a ticket respectively. *)
    val credit : t -> ticket_index -> address_index -> int64 -> t m

    (** [spend ctxt tidx aidx qty] updates the legder to
        decrease the number of tickets indexed by [tidx] the address
        [aidx] owns by [qty] units.

        This function can fails with [Balance_too_low] if [aidx]
        does not own at least [qty] ticket.

        {b Note:} It is the responsibility of the caller to verify
        that [aidx] and [tidx] have been associated to an address and
        a ticket respectively. *)
    val spend : t -> ticket_index -> address_index -> int64 -> t m
  end
end

(** Using this functor, it is possible to get a [CONTEXT]
    implementation from a [STORAGE] implementation for free. *)
module Make (S : STORAGE) : CONTEXT with type t = S.t and type 'a m = 'a S.m
