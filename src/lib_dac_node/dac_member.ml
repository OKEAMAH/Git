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
  | None -> return_none
  | Some alias -> (
      let* keys_opt = alias_aggregate_keys cctxt alias in
      match keys_opt with
      | None ->
          (* DAC/TODO: https://gitlab.com/tezos/tezos/-/issues/4193
             Revisit this once the Dac committee will be spread across
             multiple dac nodes.*)
          let*! () = Event.(emit dac_account_not_available address) in
          return_none
      | Some (address, pk_opt, sk_opt) -> (
          match sk_opt with
          | None ->
              let*! () = Event.(emit dac_account_cannot_sign address) in
              return_none
          | Some sk_uri ->
              return_some {address; pk_opt; sk_uri_opt = Some sk_uri}))

let get_keys ~addresses ~threshold cctxt =
  let open Lwt_result_syntax in
  let* keys = List.map_es (get_address_keys cctxt) addresses in
  let recovered_keys = List.length @@ List.filter Option.is_some keys in
  let*! () =
    (* We emit a warning if the threshold of dac accounts needed to sign a
       root page hash is not reached. We also emit a warning for each DAC
       account whose secret key URI was not recovered.
       We do not stop the dac node at this stage.
    *)
    if recovered_keys < threshold then
      Event.(emit dac_threshold_not_reached (recovered_keys, threshold))
    else Event.(emit dac_is_ready) ()
  in
  return keys
