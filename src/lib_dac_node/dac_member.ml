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

type t = {
  address : Tezos_client_base.Client_keys.Aggregate_type.public_key_hash;
  pk_opt : Tezos_client_base.Client_keys.Aggregate_type.public_key option;
  sk_uri_opt : Tezos_client_base.Client_keys.aggregate_sk_uri option;
}

let get_address_keys cctxt address =
  let open Lwt_result_syntax in
  let open Tezos_client_base.Client_keys in
  let* alias = Aggregate_alias.Public_key_hash.rev_find cctxt address in
  match alias with
  | None ->
      (* TODO: <insert issue here>
         Fetch public key from protocol if alias cannot be found *)
      return {address; pk_opt = None; sk_uri_opt = None}
  | Some alias -> (
      let* keys_opt = alias_aggregate_keys cctxt alias in
      match keys_opt with
      | None -> return {address; pk_opt = None; sk_uri_opt = None}
      | Some (address, pk_opt, sk_uri_opt) ->
          return {address; pk_opt; sk_uri_opt})

let get_keys ~addresses cctxt = List.map_es (get_address_keys cctxt) addresses

let can_sign {sk_uri_opt; _} = Option.is_some sk_uri_opt
