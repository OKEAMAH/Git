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

type operation_content =
  | Transfer of {
      destination : Tx_rollup_l2_address.t;
      ticket_hash : Ticket_hash.t;
      amount : int64;
    }

let operation_content_encoding =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"Transfer"
        (obj3
           (req "destination" Tx_rollup_l2_address.encoding)
           (req "ticket_hash" Ticket_hash.encoding)
           (req "amount" Data_encoding.int64))
        (function
          | Transfer {destination; ticket_hash; amount} ->
              Some (destination, ticket_hash, amount))
        (fun (destination, ticket_hash, amount) ->
          Transfer {destination; ticket_hash; amount});
    ]

type operation = {
  signer : Tx_rollup_l2_address.t;
  counter : int64;
  content : operation_content;
}

let operation_encoding =
  let open Data_encoding in
  conv
    (function {signer; counter; content} -> (signer, counter, content))
    (function (signer, counter, content) -> {signer; counter; content})
    (obj3
       (req "signer" Tx_rollup_l2_address.encoding)
       (req "counter" Data_encoding.int64)
       (req "content" operation_content_encoding))

type transaction = operation list

let transaction_encoding = Data_encoding.list operation_encoding

type transactions_batch = {
  contents : transaction list;
  aggregated_signatures : signature;
}

let transactions_batch_encoding =
  let open Data_encoding in
  conv
    (function
      | {contents; aggregated_signatures} -> (contents, aggregated_signatures))
    (function
      | (contents, aggregated_signatures) -> {contents; aggregated_signatures})
    (obj2 (req "contents" @@ list transaction_encoding) (req "content" bytes))
