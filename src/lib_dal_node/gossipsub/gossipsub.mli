(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori,     <contact@functori.com>                   *)
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

(** This module exposes the instantiations of the Gossipsub and Octez-p2p
    libraries to be used by the DAL node to connect to and exchange data with
    peers. *)

(** The worker module exposes instantiation of the Gossipsub worker functor,
    alongside the config used to instantiate the functor and the default values
    of the GS parameters. *)
module Worker : sig
  module Config :
    module type of Gs_interface.Worker_config
      with type GS.Topic.t = Types.Topic.t
       and type GS.Message_id.t = Types.Message_id.t
       and type GS.Message.t = Types.Message.t
       and type GS.Peer.t = Types.Peer.t
       and type GS.Span.t = Types.Span.t
       and type 'a Monad.t = 'a Lwt.t

  module Default_parameters : module type of Gs_default_parameters

  include
    Gossipsub_intf.WORKER
      with type GS.Topic.t = Types.Topic.t
       and type GS.Message_id.t = Types.Message_id.t
       and type GS.Message.t = Types.Message.t
       and type GS.Peer.t = Types.Peer.t
       and type GS.Span.t = Types.Span.t

  module Logging : sig
    val event : event -> unit Monad.t
  end

  (** A hook to set or update messages and messages IDs validation
      function. Should be called once at startup and every time the DAL
      parameters change. *)
  module Validate_message_hook : sig
    val set :
      (?message:GS.Message.t ->
      message_id:GS.Message_id.t ->
      unit ->
      [`Valid | `Unknown | `Outdated | `Invalid]) ->
      unit
  end
end

(** The transport layer module exposes the needed primitives, interface and
    default parameters for the instantiation of the Octez-p2p library. *)
module Transport_layer : sig
  module Interface : module type of Transport_layer_interface

  module Default_parameters : module type of Transport_layer_default_parameters

  type t

  (** [create ~network_name ~is_bootstrap_peer ~public_addr config limits]
      creates a new instance of type {!t}. It is a wrapper on top of
      {!P2p.create}. *)
  val create :
    network_name:string ->
    public_addr:P2p_point.Id.t ->
    is_bootstrap_peer:bool ->
    P2p.config ->
    P2p_limits.t ->
    t tzresult Lwt.t

  (** [activate ?additional_points t] activates the given transport layer [t]. It
      is a wrapper on top of {!P2p.activate}. If some [additional_points] are
      given, they are added to [t]'s known points. *)
  val activate : ?additional_points:P2p_point.Id.t list -> t -> unit Lwt.t

  (** [connect t ?timeout point] initiates a connection to the point
      [point]. The promise returned by this function is resolved once
      the P2P handhshake successfully completes. If the [timeout] is
      set, an error is returned if the P2P handshake takes more than
      [timeout] to complete. *)
  val connect :
    t -> ?timeout:Ptime.Span.t -> P2p_point.Id.t -> unit tzresult Lwt.t

  (** [disconnect_point t ?wait point] initiaties a disconnection to
      the point [point]. The promise returned by this function is
      fullfiled when the socket is closed on our side. If [wait] is
      [true], we do not close the socket before having canceled all
      the current messages in the write buffer. Should not matter in
      practice.

      Due to the following issue https://gitlab.com/tezos/tezos/-/issues/5319

      it may occur that a discconnection takes several minutes. *)
  val disconnect_point : t -> ?wait:bool -> P2p_point.Id.t -> unit Lwt.t

  (** [disconnect_peer t ?wait point] initiaties a disconnection to
      the point [peer]. The promise returned by this function is
      fullfiled when the socket is closed on our side. If [wait] is
      [true], we do not close the socket before having canceled all
      the current messages in the write buffer. Should not matter in
      practice.

      Due to the following issue https://gitlab.com/tezos/tezos/-/issues/5319

      it may occur that a discconnection takes several minutes. *)
  val disconnect_peer :
    t -> ?wait:bool -> Crypto_box.Public_key_hash.t -> unit Lwt.t

  val get_points : t -> P2p_point.Id.t list tzresult Lwt.t
end

(** This module implements the list of hooks that allow interconnecting the
    Gossipsub worker with the transport layer. They are exposed via the
    {!Transport_layer_hooks.activate} function below. *)
module Transport_layer_hooks : sig
  (** See {!Gs_transport_connection.activate}. *)
  val activate :
    Worker.t ->
    Transport_layer.t ->
    app_messages_callback:
      (Types.Message.t -> Types.Message_id.t -> unit tzresult Lwt.t) ->
    unit Lwt.t
end
