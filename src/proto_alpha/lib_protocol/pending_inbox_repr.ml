(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Tx_rollup_l2_repr

type transactions = {data : bytes; allocated_gas : Gas_limit_repr.Arith.fp}

type stored_operation = Deposit of deposit | Transactions of transactions

let stored_operation_encoding =
  let open Data_encoding in
  union
    [
      case
        (Tag 0)
        ~title:"Deposit"
        (obj1 (req "deposit" deposit_encoding))
        (function Deposit deposit -> Some deposit | _ -> None)
        (fun deposit -> Deposit deposit);
      case
        (Tag 1)
        ~title:"Transactions"
        (obj2
           (req "data" Data_encoding.bytes)
           (req "allocated_gas" Gas_limit_repr.Arith.z_fp_encoding))
        (function
          | Transactions {data; allocated_gas} -> Some (data, allocated_gas)
          | _ -> None)
        (fun (data, allocated_gas) -> Transactions {data; allocated_gas});
    ]

type t = stored_operation list

let encoding = Data_encoding.(list stored_operation_encoding)

let empty = []

let pp fmt t =
  Format.fprintf fmt "pending_inbox: total blocks %d" (List.length t)

(* Operations are stored in reverse order, and reversed when requested *)
let append t txn = txn :: t

let get_operations t = List.rev t
