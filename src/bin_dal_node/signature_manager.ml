(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type wallet_entry = {
  alias : string;
  address : Aggregate_signature.public_key_hash;
  public_key : Aggregate_signature.public_key option;
  secret_key_uri : Client_keys.aggregate_sk_uri;
}

let get_keys cctxt address =
  let open Lwt_result_syntax in
  let* alias =
    Client_keys.Aggregate_alias.Public_key_hash.rev_find cctxt address
  in
  match alias with
  | None -> return_none
  | Some alias -> (
      let* keys_opt = Client_keys.alias_aggregate_keys cctxt alias in
      match keys_opt with
      | None -> return_none
      | Some (pkh, pk, sk_uri_opt) -> (
          match sk_uri_opt with
          | None -> return_none
          | Some sk_uri ->
              return_some
                {alias; address = pkh; public_key = pk; secret_key_uri = sk_uri}
          ))

let sign_message cctxt ~message wallet_entry =
  Client_keys.aggregate_sign cctxt wallet_entry.secret_key_uri message

let aggregate_signatures signatures =
  let bitmap, rev_valid_signatures, _ =
    List.fold_left
      (fun (bitmap, rev_valid_signatures, current_power) signature ->
        let next_power = Z.mul (Z.of_int 2) current_power in
        match signature with
        | None -> (bitmap, rev_valid_signatures, next_power)
        | Some signature ->
            ( Z.add bitmap current_power,
              signature :: rev_valid_signatures,
              next_power ))
      (Z.zero, [], Z.one)
      signatures
  in
  rev_valid_signatures |> List.rev
  |> Aggregate_signature.aggregate_signature_opt
  |> Option.map (fun signature -> (signature, bitmap))

let aggregate_signature_of_message cctxt ~message ~dac_addresses =
  let open Lwt_result_syntax in
  let sign_opt wallet_entry_opt =
    match wallet_entry_opt with
    | None -> return None
    | Some wallet_entry ->
        let+ signature = sign_message cctxt ~message wallet_entry in
        Some signature
  in
  let+ signatures = List.map_es sign_opt dac_addresses in
  aggregate_signatures signatures
