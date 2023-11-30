(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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

type update = {account : Destination.t; amount : Z.t}

type item = {ticket_token : Ticket_token.unparsed_token; updates : update list}

module Map = Map.Make (struct
  type t = Ticket_token.unparsed_token

  let compare = Ticket_token.compare
end)

type t = item Map.t

let update_encoding =
  let open Data_encoding in
  conv
    (fun {account; amount} -> (account, amount))
    (fun (account, amount) -> {account; amount})
    (obj2 (req "account" Destination.encoding) (req "amount" z))

let item_encoding =
  let open Data_encoding in
  conv
    (fun {ticket_token; updates} -> (ticket_token, updates))
    (fun (ticket_token, updates) -> {ticket_token; updates})
    (obj2
       (req "ticket_token" Ticket_token.unparsed_token_encoding)
       (req "updates" (list update_encoding)))

let encoding =
  let open Data_encoding in
  conv
    Map.bindings
    (fun l -> List.fold_left (fun acc (k, v) -> Map.add k v acc) Map.empty l)
    (list (tup2 Ticket_token.unparsed_token_encoding item_encoding))

(* let encoding = Data_encoding.map item_encoding *)

let of_list l =
  let map = Map.empty in
  let _ =
    List.fold_left
      (fun acc {ticket_token; updates} -> Map.add ticket_token updates acc)
      map
      l
  in
  map

let to_list map =
  List.map
    (fun (_k, {ticket_token; updates}) -> {ticket_token; updates})
    (Map.bindings map)
