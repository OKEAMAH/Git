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
open Tx_rollup_l2_repr
open Tx_rollup_l2_context
open Tx_rollup_l2_operation

type transaction_status = Success | Failure of {index : int; reason : error}

module Make (Context : CONTEXT) : sig
  open Context

  (** [apply_transactions_batch ctxt batch] applies [batch] —a batch
      of transactions— onto [ctxt].

      It raises an error in the following scenario:

      {ul {- [Not_enough_gas] if there is not enough allocated gas
             declared in the batch.}
          {- [Bad_aggregated_signature] if the signature provided with
             the batch is not correct. Batches are provided with a
             aggregated BLS signature (using the [Augmented] scheme).}}

      The expected semantics for batches raising these errors is to be
      treated as no-operations, {i i.e.}, they are ignored, and the
      transactions rollup context remains constant.

      On the contrary, when it succeeds, this function computes:

      {ul {- A [transaction_status] result for each transaction of the batch}
          {- The amount gas consumed to apply the batch}
          {- A new context, modified according to the operation semantics}} *)
  val apply_transactions_batch :
    t ->
    transactions_batch ->
    ((transaction * transaction_status) list * Alpha_context.Gas.Arith.fp * t) m

  (** [apply_deposit ctxt deposit] applies the effect of [deposit]
      onto [ctxt].

      It can raise an [Invalid_deposit] error, if the [amount] field
      of the [deposit] value is not strictly positive. *)
  val apply_deposit : t -> deposit -> t m

  (** Re-export of private definitions used internally by this module.
      They are provided to be used for testing purposes only. *)
  module Internal_for_tests : sig
    val apply_transaction : t -> transaction -> (transaction_status * t) m
  end
end

type error +=
  | Balance_too_low of {
      account : account;
      ticket_hash : Ticket_balance.key_hash;
      requested : Z.t;
      actual : Z.t;
    }

type error +=
  | Counter_mismatch of {
      account : account;
      requested : counter;
      actual : counter;
    }

type error += Invalid_deposit

type error += Bad_aggregated_signature
