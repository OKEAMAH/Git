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

let withdraw ctxt tx_rollup contract ~rollup_ticket_hash
    ~destination_ticket_hash (count : int64) =
  let count = Z.of_int64 count in
  let key = (ctxt, tx_rollup) in
  ( Storage.Tx_rollup.Ticket_offramp.get key (contract, rollup_ticket_hash)
  >>=? fun (ctxt, remaining) ->
    let key = (ctxt, tx_rollup) in
    let cmp = Z.compare remaining count in
    match cmp with
    | 0 ->
        Storage.Tx_rollup.Ticket_offramp.remove
          key
          (contract, rollup_ticket_hash)
    | 1 ->
        let balance = Z.sub remaining count in
        Storage.Tx_rollup.Ticket_offramp.add
          key
          (contract, rollup_ticket_hash)
          balance
    | _ -> fail Withdraw_balance_too_low )
  >>=? fun (ctxt, _, _) ->
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/2339
     Storage fees for transaction rollup.
     We need to charge for newly allocated storage (as we do for
     Michelson’s big map). This also means taking into account
     the global table of tickets. *)
  Ticket_storage.adjust_balance ctxt rollup_ticket_hash ~delta:(Z.neg count)
  >>=? fun (_, ctxt) ->
  Ticket_storage.adjust_balance ctxt destination_ticket_hash ~delta:count
  >>=? fun (_, ctxt) -> return ctxt

let add_tickets_to_offramp ctxt tx_rollup contract ticket (count : int64) =
  let count = Z.of_int64 count in
  let key = (ctxt, tx_rollup) in
  Storage.Tx_rollup.Ticket_offramp.find key (contract, ticket)
  >>=? fun (ctxt, existing) ->
  let existing = Option.value ~default:Z.zero existing in
  let new_balance = Z.add existing count in
  let key = (ctxt, tx_rollup) in
  Storage.Tx_rollup.Ticket_offramp.add key (contract, ticket) new_balance
  >|=? fun (ctxt, _, _) -> ctxt
