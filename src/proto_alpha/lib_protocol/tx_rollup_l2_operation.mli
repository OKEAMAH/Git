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

type signature = bytes

(** A transactions rollup allows rollup users to exchange L1 tickets
    off-chain. *)
type operation_content =
  | Transfer of {
      destination : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
      amount : int64;
    }

val operation_content_encoding : operation_content Data_encoding.t

type operation = {
  signer : Tx_rollup_l2_address.t;
  counter : int64;
  content : operation_content;
}

val operation_encoding : operation Data_encoding.t

(** A [transaction] in a transactions rollup is a list of operations.

    The semantics of a [transaction] ensures that an operation of a
    transaction [t] is successfully applied ({i i.e.}, is taken into
    account) iff all the other operations of [t] are applied. In other
    words, if the application of any operation of [t] fails, then all
    operations of [t] are discarded. *)
type transaction = operation list

val transaction_encoding : transaction Data_encoding.t

(** A transactions batch gathers a list of transactions, and a BLS
    aggregated signature that encompasses every operations of every
    batches. *)
type transactions_batch = {
  contents : transaction list;
  aggregated_signatures : signature;
}

val transactions_batch_encoding : transactions_batch Data_encoding.t
