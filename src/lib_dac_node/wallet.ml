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

module Aggregate_signature = Tezos_crypto.Aggregate_signature

type error +=
  | Committee_member_cannot_sign of Aggregate_signature.public_key_hash

let () =
  register_error_kind
    `Permanent
    ~id:"committee_member_cannot_sign"
    ~title:"Committee member cannot sign messages"
    ~description:
      "Committee member cannot sign messages because the signing key is not \
       available"
    ~pp:(fun ppf pkh ->
      Format.fprintf
        ppf
        "Cannot convert root hash page to byte sequence: %a"
        Aggregate_signature.Public_key_hash.pp
        pkh)
    Data_encoding.(
      obj1 (req "public_key_hash" Aggregate_signature.Public_key_hash.encoding))
    (function Committee_member_cannot_sign pkh -> Some pkh | _ -> None)
    (fun pkh -> Committee_member_cannot_sign pkh)

let get_keys cctxt pkh =
  let open Lwt_result_syntax in
  let open Tezos_client_base.Client_keys in
  let* alias = Aggregate_alias.Public_key_hash.rev_find cctxt pkh in
  match alias with
  | None -> return (pkh, None, None)
  | Some alias -> (
      let* keys_opt = alias_aggregate_keys cctxt alias in
      match keys_opt with
      | None ->
          let*! () = Event.(emit dac_account_not_available pkh) in
          return (pkh, None, None)
      | Some (pkh, pk_opt, sk_uri_opt) -> return (pkh, pk_opt, sk_uri_opt))

let get_public_key cctxt address =
  let open Lwt_result_syntax in
  let+ _, pk_opt, _ = get_keys cctxt address in
  pk_opt

let can_verify (_, pk_opt, _) = Option.is_some pk_opt

module Coordinator = struct
  type t = {
    pkh : Aggregate_signature.public_key_hash;
    pk_opt : Aggregate_signature.public_key option;
  }

  let get_all_committee_members_public_keys pkhs cctxt =
    let open Lwt_result_syntax in
    List.map_es
      (fun pkh ->
        let* ((pkh, pk_opt, _) as wallet) = get_keys cctxt pkh in
        let*! () =
          if can_verify wallet then Lwt.return ()
          else Event.(emit dac_account_cannot_verify pkh)
        in
        return {pkh; pk_opt})
      pkhs
end

module Committee_member = struct
  type t = {
    pkh : Aggregate_signature.public_key_hash;
    sk_uri : Client_keys.aggregate_sk_uri;
  }

  let get_committee_member_signing_key pkh cctxt =
    let open Lwt_result_syntax in
    let* pkh, _, sk_uri_opt = get_keys cctxt pkh in
    match sk_uri_opt with
    | None -> tzfail @@ Committee_member_cannot_sign pkh
    | Some sk_uri -> return {pkh; sk_uri}
end

module Legacy = struct
  type t = {
    pkh : Aggregate_signature.public_key_hash;
    pk_opt : Aggregate_signature.public_key option;
    sk_uri_opt : Client_keys.aggregate_sk_uri option;
  }

  let get_all_committee_members_keys addresses ~threshold cctxt =
    let open Lwt_result_syntax in
    let* wallets =
      List.map_es
        (fun pkh ->
          let+ pkh, pk_opt, sk_uri_opt = get_keys cctxt pkh in
          {pkh; pk_opt; sk_uri_opt})
        addresses
    in
    let*! valid_wallets =
      List.filter_s
        (fun {pkh; sk_uri_opt; _} ->
          if Option.is_some sk_uri_opt then Lwt.return true
          else
            let*! () = Event.(emit dac_account_cannot_sign pkh) in
            Lwt.return false)
        wallets
    in
    let recovered_keys = List.length valid_wallets in
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
    return wallets
end
