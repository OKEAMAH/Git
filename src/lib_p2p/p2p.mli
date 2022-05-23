(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2019-2020 Nomadic Labs, <contact@nomadic-labs.com>          *)
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

(** Tezos P2p layer - Dynamic overlay network of authenticated peers.

    The P2P layer implements several mechanisms, notably:
    - It maintains pools of known points (P2P servers), peers (authenticated
      P2P servers), connections,
    - it implements an "administrative" protocol for maintaining the network
      topology,
    - it regulates bandwidth usage between connections,
    - it implements an authentication / session agreement protocol,
    - it can ban or greylist peers or IP addresses who don't behave well,
    - it offers the ability to the upper-layer to send, broadcast, or
      receive messages.

    The protocol sends/receives messages to maintain the network topology,
    and also "generic" application messages that can be sent and received
    by the upper-layer. See [P2p_message].

    The protocol may operate in *private* mode, in which only user-provided
    points (a.k.a. *trusted* ) are used. In particular, points
    advertisements and swap requests messages are ignored.

    The module [P2p_pool] maintains pools of points, peers and
    connections.

    Several workers are used:
    - [P2p_maintenance] tries to regulate the number of connections
    - [P2p_welcome] waits for incoming connections
    - [P2p_discovery] looks for points on the local network via UDP messages
    - A protocol worker implements the messaging protocol

    Points can be trusted. This is relevant in private mode
    (see above), but generally peers shouldn't advertise trusted points.

    Addresses and peers can be *banned* (a.k.a. blacklisted). In
    which case, connections to and from them should be ignored.

    Addresses or peers can be *greylisted*. As for banning, greylisting
    can be enforced via the API, but also dynamically when the peer isn't
    able to authenticate. Eventually greylisted peers are whitelisted again.

    Many types used in the P2p layer are parameterized by three type parameters:
    - ['msg]: type of messages exchanged between peers
    - ['peer_meta]: type of the metadata associated with peers (score, etc.)
    - ['conn_meta]: type of the metadata associated with connections

    The concrete types, and functions operating on them, are defined by the
    calling layer, and passed to [P2p.create]. See module [P2p_params]. *)

(** Network configuration *)
type config = P2p_config.config

(** Network capacities *)
type limits = P2p_config.limits

(** Type of a P2P layer instance *)
type ('msg, 'peer_meta, 'conn_meta) t

type ('msg, 'peer_meta, 'conn_meta) net = ('msg, 'peer_meta, 'conn_meta) t

val announced_version : ('msg, 'peer_meta, 'conn_meta) net -> Network_version.t

(** A faked p2p layer, which do not initiate any connection
    nor open any listening socket *)
val faked_network :
  'msg P2p_params.message_config ->
  'peer_meta P2p_params.peer_meta_config ->
  'conn_meta ->
  ('msg, 'peer_meta, 'conn_meta) net

(** Main network initialization function *)
val create :
  config:config ->
  limits:limits ->
  'peer_meta P2p_params.peer_meta_config ->
  'conn_meta P2p_params.conn_meta_config ->
  'msg P2p_params.message_config ->
  ('msg, 'peer_meta, 'conn_meta) net tzresult Lwt.t

val activate : ('msg, 'peer_meta, 'conn_meta) net -> unit

(** Return one's peer_id *)
val peer_id : ('msg, 'peer_meta, 'conn_meta) net -> P2p_peer.Id.t

(* Originally exposed in p2p.mli, unused.

   (** A maintenance operation : try and reach the ideal number of peers *)
   val maintain : ('msg, 'peer_meta, 'conn_meta) net -> unit Lwt.t
*)

(* Originally exposed in p2p.mli, unused.

   (** Voluntarily drop some peers and replace them by new buddies *)
   val roll : ('msg, 'peer_meta, 'conn_meta) net -> unit Lwt.t
*)

(** Close all connections properly *)
val shutdown : ('msg, 'peer_meta, 'conn_meta) net -> unit Lwt.t

(** A connection to a peer *)
type ('msg, 'peer_meta, 'conn_meta) connection

(** Access the domain of active peers *)
val connections :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection list

(** Return the active peer with identity [peer_id] *)
val find_connection_by_peer_id :
  ('msg, 'peer_meta, 'conn_meta) net ->
  P2p_peer.Id.t ->
  ('msg, 'peer_meta, 'conn_meta) connection option

(* Originally exposed in p2p.mli, unused.

   (** Return the active peer corresponding to [point] *)
   val find_connection_by_point :
     ('msg, 'peer_meta, 'conn_meta) net ->
     P2p_point.Id.t ->
     ('msg, 'peer_meta, 'conn_meta) connection option
*)

(** Access the info of an active peer, if available *)
val connection_info :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'conn_meta P2p_connection.Info.t

val connection_local_metadata :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'conn_meta

val connection_remote_metadata :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'conn_meta

(* Originally exposed in p2p.mli, unused.

   val connection_stat :
     ('msg, 'peer_meta, 'conn_meta) net ->
     ('msg, 'peer_meta, 'conn_meta) connection ->
     P2p_stat.t
*)

(** Returns the network version that will be used for this connection.
   This network version is the best version compatible with the versions
   supported by ours and the remote peer. *)
val negotiated_version :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  Network_version.t

(** Cleanly closes a connection. *)
val disconnect :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ?wait:bool ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  unit Lwt.t

(* Originally exposed in p2p.mli, unused.

   val global_stat : ('msg, 'peer_meta, 'conn_meta) net -> P2p_stat.t
*)

(** Accessors for meta information about a global identifier *)
val get_peer_metadata :
  ('msg, 'peer_meta, 'conn_meta) net -> P2p_peer.Id.t -> 'peer_meta

(* Originally exposed in p2p.mli, unused.

   val set_peer_metadata :
     ('msg, 'peer_meta, 'conn_meta) net -> P2p_peer.Id.t -> 'peer_meta -> unit
*)

(* Originally exposed in p2p.mli, unused.

   (** [connect net ?timeout point] attempts to establish a connection to [point]
      within an optional duration [timeout]. *)
   val connect :
     ('msg, 'peer_meta, 'conn_meta) net ->
     ?timeout:Ptime.span ->
     P2p_point.Id.t ->
     ('msg, 'peer_meta, 'conn_meta) connection tzresult Lwt.t
*)

(** Wait for a message from a given connection. *)
val recv :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'msg tzresult Lwt.t

(* Originally exposed in p2p.mli, unused.

   (** Wait for a message from any active connections. *)
   val recv_any :
     ('msg, 'peer_meta, 'conn_meta) net ->
     (('msg, 'peer_meta, 'conn_meta) connection * 'msg) Lwt.t
*)

(** [send net peer msg] is a thread that returns when [msg] has been
    successfully enqueued in the send queue. *)
val send :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'msg ->
  unit tzresult Lwt.t

(** [try_send net peer msg] is [true] if [msg] has been added to the
    send queue for [peer], [false] otherwise *)
val try_send :
  ('msg, 'peer_meta, 'conn_meta) net ->
  ('msg, 'peer_meta, 'conn_meta) connection ->
  'msg ->
  bool

(* Originally exposed in p2p.mli, unused.

   (** Send a message to all peers *)
   val broadcast : ('msg, 'peer_meta, 'conn_meta) net -> 'msg -> unit
*)

val fold_connections :
  ('msg, 'peer_meta, 'conn_meta) net ->
  init:'a ->
  f:(P2p_peer.Id.t -> ('msg, 'peer_meta, 'conn_meta) connection -> 'a -> 'a) ->
  'a

val iter_connections :
  ('msg, 'peer_meta, 'conn_meta) net ->
  (P2p_peer.Id.t -> ('msg, 'peer_meta, 'conn_meta) connection -> unit) ->
  unit

val on_new_connection :
  ('msg, 'peer_meta, 'conn_meta) net ->
  (P2p_peer.Id.t -> ('msg, 'peer_meta, 'conn_meta) connection -> unit) ->
  unit

(* Originally exposed in p2p.mli, unused.

   (** Send a message to all peers *)
   val greylist_addr : ('msg, 'peer_meta, 'conn_meta) net -> P2p_addr.t -> unit
*)

val greylist_peer : ('msg, 'peer_meta, 'conn_meta) net -> P2p_peer.Id.t -> unit

val build_rpc_directory :
  ( 'a,
    Tezos_p2p_services.Peer_metadata.t,
    Tezos_p2p_services.Connection_metadata.t )
  t ->
  unit RPC_directory.t

(**/**)

module Internal_for_tests : sig
  type ('msg, 'peer, 'conn) mocked_network

  val find_handle_opt :
    Network_version.t -> ('msg, 'peer, 'conn) mocked_network option

  val connect_peers :
    ('a, 'b, 'c) mocked_network ->
    a:P2p_peer.Id.t ->
    b:P2p_peer.Id.t ->
    a_meta:'b ->
    b_meta:'b ->
    ab_conn_meta:'c ->
    ba_conn_meta:'c ->
    propagation_delay:float ->
    (unit, string) result

  val disconnect_peers :
    ('a, 'b, 'c) mocked_network ->
    a:P2p_peer.Id.t ->
    b:P2p_peer.Id.t ->
    (unit, string) result

  val neighbourhood :
    ('a, 'b, 'c) mocked_network ->
    P2p_peer.Id.t ->
    (P2p_peer.Id.t * ('a * int * float) Lwt_pipe.Unbounded.t) list

  val iter_neighbourhood :
    ('a, 'b, 'c) mocked_network ->
    P2p_peer.Id.t ->
    (outbound:('a * int * float) Lwt_pipe.Unbounded.t ->
    neighbor:P2p_peer.Id.t ->
    unit) ->
    unit

  val iter_neighbourhood_es :
    ('a, 'b, 'c) mocked_network ->
    P2p_peer.Id.t ->
    (outbound:('a * int * float) Lwt_pipe.Unbounded.t ->
    neighbor:P2p_peer.Id.t ->
    (unit, 'd) result Lwt.t) ->
    (unit, 'd) result Lwt.t

  val sleep_on_deferred_delays :
    ('a, 'b, 'c) mocked_network -> P2p_peer.Id.t -> (unit, string) result Lwt.t
end
