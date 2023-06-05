(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trili Tech <contact@trili.tech>                        *)
(* Copyright (c) 2023 Marigold  <contact@marigold.dev>                       *)
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

(** [RPC_handlers] is a module with handlers for DAC API endpoints. *)

type error +=
  | DAC_node_not_ready of string
  | Cannot_construct_external_message
  | Cannot_deserialize_external_message

(** [handle_get_health_live] is a handler for "GET dac/health/live". *)
val handle_get_health_live : Node_context.t -> (bool, error trace) result Lwt.t

(** [handle_get_health_ready] is a handler for "GET dac/health/ready". *)
val handle_get_health_ready : Node_context.t -> (bool, error trace) result Lwt.t

(** [Shared_by_V0_and_V1] encapsulates handlers that are common to
    both [V0] and [V1] API. *)
module Shared_by_V0_and_V1 : sig
  (** [handle_get_page] is a handler shared by both "GET v0/preimage" 
      and "GET v1/pages". It fetches a page that corresponds
      to a given [raw_hash]. *)
  val handle_get_page :
    Dac_plugin.t ->
    Page_store.Filesystem.t ->
    Dac_plugin.raw_hash ->
    (bytes, tztrace) result Lwt.t
end

(** [V0] encapsulates handlers specific to [V0] API. *)
module V0 : sig
  (** [handle_post_store_preimage] is a handler for "POST v0/store_preimage". *)
  val handle_post_store_preimage :
    Dac_plugin.t ->
    #Client_context.wallet ->
    Client_keys.aggregate_sk_uri option trace ->
    Page_store.Filesystem.t ->
    Dac_plugin.raw_hash Data_streamer.t ->
    bytes * Pagination_scheme.t ->
    (Dac_plugin.raw_hash * bytes, tztrace) result Lwt.t

  (** [handle_get_verify_signature] is a handler for "GET v0/verify_signature". *)
  val handle_get_verify_signature :
    Dac_plugin.t ->
    Tezos_crypto.Aggregate_signature.public_key option trace ->
    string option ->
    (bool, error trace) result Lwt.t

  (** [handle_monitor_root_hashes] is a handler for  subscribing to the
      streaming of root hashes via "GET v0/monitor/root_hashes" RPC call. *)
  val handle_monitor_root_hashes :
    Dac_plugin.raw_hash Data_streamer.t ->
    Dac_plugin.raw_hash Tezos_rpc__RPC_answer.t Lwt.t

  (** [handle_get_certificate] is a handler for "GET v0/certificate". *)
  val handle_get_certificate :
    Dac_plugin.t ->
    [> `Read] Store.Irmin_store.t ->
    Dac_plugin.raw_hash ->
    (Certificate_repr.t option, tztrace) result Lwt.t

  (** [handle_get_serialized_certificate] is the handler for "GET v0/serialized_certificates". *)
  val handle_get_serialized_certificate :
    Dac_plugin.t ->
    [> `Read] Store.Irmin_store.t ->
    Dac_plugin.raw_hash ->
    (String.t option, tztrace) result Lwt.t

  (** [Coordinator] encapsulates, Coordinator's mode specific handlers
      of [V0] API. *)
  module Coordinator : sig
    (** [handle_post_preimage] is a handler for "PUT v0/preimage". *)
    val handle_post_preimage :
      Dac_plugin.t ->
      Page_store.Filesystem.t ->
      Dac_plugin.raw_hash Data_streamer.t ->
      bytes ->
      (Dac_plugin.raw_hash, tztrace) result Lwt.t

    (** [handle_monitor_certificate] is a handler for  subscribing to the stream
        of certificate updates via "GET v0/monitor/certificate" RPC call. *)
    val handle_monitor_certificate :
      Dac_plugin.t ->
      [> `Read] Store.Irmin_store.t ->
      Certificate_streamers.t ->
      Dac_plugin.raw_hash ->
      'a trace ->
      ( (unit -> Certificate_repr.t option Lwt.t) * (unit -> unit),
        tztrace )
      result
      Lwt.t
  end

  (** [Observer] encapsulates, Observer's mode specific handlers
      of [V0] API. *)
  module Observer : sig
    (** [handle_get_missing_page] is a handler for "GET v0/missing_page". *)
    val handle_get_missing_page :
      float ->
      Dac_node_client.cctxt trace ->
      Page_store.Filesystem.t ->
      Dac_plugin.t ->
      Dac_plugin.raw_hash ->
      (bytes, tztrace) result Lwt.t
  end
end
