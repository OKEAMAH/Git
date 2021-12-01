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

type deposit = {
  destination : Tx_rollup_l2_address_repr.t;
  key_hash : Ticket_hash_repr.t;
  amount : int64;
}

let deposit_encoding =
  let open Data_encoding in
  conv
    (fun {destination; key_hash; amount} -> (destination, key_hash, amount))
    (fun (destination, key_hash, amount) -> {destination; key_hash; amount})
  @@ obj3
       (req "destination" Tx_rollup_l2_address_repr.encoding)
       (req "key_hash" Ticket_hash_repr.encoding)
       (req "amount" int64)

type message = Batch of string | Deposit of deposit

let message_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        (Tag 0)
        ~title:"Batch"
        (obj1 (req "batch" string))
        (function Batch batch -> Some batch | _ -> None)
        (fun batch -> Batch batch);
      case
        (Tag 1)
        ~title:"Deposit"
        (obj1 (req "deposit" deposit_encoding))
        (function Deposit deposit -> Some deposit | _ -> None)
        (fun deposit -> Deposit deposit);
    ]

let message_size = function
  | Batch batch -> String.length batch
  | Deposit {destination = _; key_hash = _; amount = _} ->
      (* Size of a BLS public key, that is the underlying type of a
         l2 address. See [Tx_rollup_l2_address] *)
      let destination_size = 48 in
      (* Size of a a script expr hash, that is the underlying type
         of key hash. See [Ticket_repr] and [Script_expr_hash] *)
      let key_hash_size = 32 in
      (* [int64] *)
      let amount_size = 8 in
      destination_size + key_hash_size + amount_size

let hash_size = 32

module Message_hash =
  Blake2B.Make
    (Base58)
    (struct
      let name = "Tx_rollup_inbox_message_hash"

      let title = "The hash of a a transaction rollup inbox’s message"

      let b58check_prefix = "\001\014\133" (* h2(52) *)

      let size = Some hash_size
    end)

let () = Base58.check_encoded_prefix Message_hash.b58check_encoding "h2" 52

type message_hash = Message_hash.t

let message_hash_pp = Message_hash.pp

let message_hash_encoding = Message_hash.encoding

let hash_message msg =
  Message_hash.hash_bytes
    [Data_encoding.Binary.to_bytes_exn message_encoding msg]

type t = {contents : message_hash list; cumulated_size : int}

let pp fmt {contents; cumulated_size} =
  Format.fprintf
    fmt
    "tx rollup inbox: %d messages using %d bytes"
    (List.length contents)
    cumulated_size

let encoding =
  let open Data_encoding in
  conv
    (fun {contents; cumulated_size} -> (contents, cumulated_size))
    (fun (contents, cumulated_size) -> {contents; cumulated_size})
    (obj2
       (req "contents" @@ list message_hash_encoding)
       (req "cumulated_size" int31))
