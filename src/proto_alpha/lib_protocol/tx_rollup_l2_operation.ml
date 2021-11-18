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

type operation_content =
  | Transfer of {
      destination : account;
      ticket_hash : Ticket_balance.key_hash;
      amount : Z.t;
    }

let operation_content_encoding =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"Transfer"
        (obj3
           (req "destination" account_encoding)
           (req "ticket_hash" Ticket_balance.key_hash_encoding)
           (req "amount" Data_encoding.z))
        (function
          | Transfer {destination; ticket_hash; amount} ->
              Some (destination, ticket_hash, amount))
        (fun (destination, ticket_hash, amount) ->
          Transfer {destination; ticket_hash; amount});
    ]

type operation = {
  signer : account;
  counter : counter;
  content : operation_content;
}

let operation_encoding =
  let open Data_encoding in
  conv
    (function {signer; counter; content} -> (signer, counter, content))
    (function (signer, counter, content) -> {signer; counter; content})
    (obj3
       (req "signer" account_encoding)
       (req "counter" Data_encoding.z)
       (req "content" operation_content_encoding))

type transaction = operation list

let transaction_encoding = Data_encoding.list operation_encoding

type transactions_batch = {
  contents : transaction list;
  aggregated_signatures : signature;
  allocated_gas : Gas.Arith.fp;
}

type deposit = {
  destination : account;
  ticket_hash : Ticket_balance.key_hash;
  amount : Z.t;
}
