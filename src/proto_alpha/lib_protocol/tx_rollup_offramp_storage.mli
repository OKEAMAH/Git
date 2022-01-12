(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

type error += (* `Permanent *) Withdraw_balance_too_low

(** [withdraw ctxt tx_rollup contract ticket_hash amount] withdraws tickets
    tickets from a rollup and transfers them to the given contract.  It
    fails if the balance in the offramp for this commitment is too low. *)
val withdraw :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Contract_repr.t ->
  rollup_ticket_hash:Ticket_hash_repr.t ->
  destination_ticket_hash:Ticket_hash_repr.t ->
  int64 ->
  Raw_context.t tzresult Lwt.t

(** [add_tickets_to_offramp ctxt tx_rollup contract ticket_hash amount]
      prepares tickets for withdrawal by adding them to the offramp.  This
      should only be called when resolving a L2 withdraw operation.
  *)
val add_tickets_to_offramp :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Contract_repr.t ->
  Ticket_hash_repr.t ->
  int64 ->
  Raw_context.t tzresult Lwt.t
