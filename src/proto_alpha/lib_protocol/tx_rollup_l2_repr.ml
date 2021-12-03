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

module Account = struct
  type t = Bls_signature.pk

  let compare (t1 : Bls_signature.pk) (t2 : Bls_signature.pk) =
    Bytes.compare (Bls_signature.pk_to_bytes t1) (Bls_signature.pk_to_bytes t2)
end

type account = Account.t

let account_encoding : account Data_encoding.t =
  Data_encoding.(
    conv
      Bls_signature.pk_to_bytes
      (fun bytes ->
        match Bls_signature.pk_of_bytes_opt bytes with
        | Some x -> x
        | None -> raise (Invalid_argument "account_encoding"))
      bytes)

type signature = Bytes.t

let signature_encoding : signature Data_encoding.t = Data_encoding.bytes

type ticket_sort = {
  ticketer : Contract_repr.t;
  typ : Script_repr.expr;
  contents : Script_repr.expr;
}

let ticket_sort_encoding : ticket_sort Data_encoding.t =
  Data_encoding.(
    conv
      (fun {ticketer; typ; contents} -> (ticketer, typ, contents))
      (fun (ticketer, typ, contents) -> {ticketer; typ; contents})
    @@ obj3
         (req "ticketer" Contract_repr.encoding)
         (req "typ" Script_repr.expr_encoding)
         (req "contents" Script_repr.expr_encoding))

(** A specialized Blake2B implementation for hashing tickets. *)
module Ticket_hash = struct
  let ticket_hash = "\001\093\199" (* tk(52) *)

  include
    Blake2B.Make
      (Base58)
      (struct
        let name = "Ticket_hash"

        let title = "The hash used to identified a ticket"

        let b58check_prefix = ticket_hash

        let size = None (* 32 by default *)
      end)

  let () = Base58.check_encoded_prefix b58check_encoding "tk" 52

  include Path_encoding.Make_hex (struct
    type nonrec t = t

    let to_bytes = to_bytes

    let of_bytes_opt = of_bytes_opt
  end)
end

type ticket_hash = Ticket_hash.t

let hash_ticket_sort : ticket_sort -> ticket_hash =
 fun ticket ->
  let payload = Data_encoding.Binary.to_bytes_exn ticket_sort_encoding ticket in
  Ticket_hash.hash_bytes [payload]

let ticket_hash_encoding : ticket_hash Data_encoding.t = Ticket_hash.encoding

type deposit = {destination : account; ticket_hash : ticket_hash; amount : Z.t}

let deposit_encoding =
  let open Data_encoding in
  conv
    (fun {destination; ticket_hash; amount} ->
      (destination, ticket_hash, amount))
    (fun (destination, ticket_hash, amount) ->
      {destination; ticket_hash; amount})
    (obj3
       (req "destination" account_encoding)
       (req "ticket_hash" ticket_hash_encoding)
       (req "amount" Data_encoding.z))
