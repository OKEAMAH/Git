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
open Tx_rollup_l2_context
open Tx_rollup_l2_operation

type transaction_status = Success | Failure of {index : int; reason : error}

module Make (Context : CONTEXT) : sig
  open Context

  (** [apply_transactions_batch ctxt batch] applies [batch] —a batch
      of transactions— onto [ctxt].

      It raises the [Bad_aggregated_signature] error iff the signature
      provided with the batch is not correct. Batches are provided
      with a aggregated BLS signature (using the [Augmented] scheme).

      In this case, the operations within the batch is treated as
      no-operations, {i i.e.}, they are ignored, and the transactions
      rollup context remains constant. As a consequences, they need to
      be submitted again, with a proper signature this time.

      On the contrary, when it succeeds, this function computes:

      {ul {- A [transaction_status] result for each transaction of the batch}
          {- The amount gas consumed to apply the batch}
          {- A new context, modified according to the operation semantics}} *)
  val apply_transactions_batch :
    t -> transactions_batch -> ((transaction * transaction_status) list * t) m

  (** [apply_deposit ctxt deposit] applies the effect of [deposit]
      onto [ctxt].

      It can raise an [Invalid_deposit] error, if the [amount] field
      of the [deposit] value is not strictly positive. If it happens,
      it means there is a bug in the implementaiton of the deposit
      operation in layer-1. It can also raise [Balance_overflow] if
      applying the deposit would make the ledger overflow. *)
  val apply_deposit : t -> Tx_rollup_inbox.deposit -> t m

  (** Re-export of private definitions used internally by this module.
      They are provided to be used for testing purposes only. *)
  module Internal_for_tests : sig
    val apply_transaction : t -> transaction -> (transaction_status * t) m
  end
end

type error +=
  | Balance_too_low of {
      account : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
      requested : int64;
      actual : int64;
    }

type error +=
  | Balance_overflow of {
      account : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
    }

type error +=
  | Counter_mismatch of {
      account : Tx_rollup_l2_address.t;
      requested : int64;
      actual : int64;
    }

type error += Invalid_deposit

type error += Invalid_transfer

type error += Bad_aggregated_signature
