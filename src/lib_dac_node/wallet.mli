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

(** Module that implements W functionalities. *)

(** [get_public_key cctxt pkh] returns the public key associated with the given [pkh] if it can
      be found in [cctxt].
  *)
val get_public_key :
  #Client_context.wallet ->
  Tezos_crypto.Aggregate_signature.public_key_hash ->
  Tezos_crypto.Aggregate_signature.public_key option tzresult Lwt.t

module Coordinator : sig
  type t = {
    pkh : Tezos_crypto.Aggregate_signature.public_key_hash;
    pk_opt : Tezos_crypto.Aggregate_signature.public_key option;
  }

  val get_all_committee_members_public_keys :
    Tezos_crypto.Aggregate_signature.public_key_hash list ->
    #Client_context.wallet ->
    t list tzresult Lwt.t
end

module Committee_member : sig
  type t = {
    pkh : Tezos_crypto.Aggregate_signature.public_key_hash;
    sk_uri : Client_keys.aggregate_sk_uri;
  }

  val get_committee_member_signing_key :
    Tezos_crypto.Aggregate_signature.public_key_hash ->
    #Client_context.wallet ->
    t tzresult Lwt.t
end

module Legacy : sig
  type t = {
    pkh : Tezos_crypto.Aggregate_signature.public_key_hash;
    pk_opt : Tezos_crypto.Aggregate_signature.public_key option;
    sk_uri_opt : Client_keys.aggregate_sk_uri option;
  }

  (** [get_all_committee_members_keys ~addresses ~threshold cctxt config]
      returns the aliases and keys associated with the aggregate signature
      addresses in [config] pkh in the tezos wallet of [cctxt]. *)
  val get_all_committee_members_keys :
    Tezos_crypto.Aggregate_signature.public_key_hash list ->
    threshold:int ->
    #Client_context.wallet ->
    t list tzresult Lwt.t
end
