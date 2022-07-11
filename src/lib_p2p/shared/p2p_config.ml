(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** Configuration and limits type definitions for the peer-to-peer layer. *)

(** Network configuration *)
type config = {
  listening_port : P2p_addr.port option;
      (** Tells if incoming connections accepted, specifying the TCP port
      on which the peer can be reached (default: [9732])*)
  listening_addr : P2p_addr.t option;
      (** When incoming connections are accepted, precise on which
      IP address the node listen (default: [[::]]). *)
  advertised_port : P2p_addr.port option;
      (** If incoming connections accepted, specifying the TCP port other peers
      should use to connect to this peer (default: listening_port). Can be used
      when this peer is behind NAT. *)
  discovery_port : P2p_addr.port option;
      (** Tells if local peer discovery is enabled, specifying the TCP port
      on which the peer can be reached (default: [10732]) *)
  discovery_addr : Ipaddr.V4.t option;
      (** When local peer discovery is enabled, precise on which
      IP address messages are broadcast (default: [255.255.255.255]). *)
  trusted_points : (P2p_point.Id.t * P2p_peer.Id.t option) list;
      (** List of hard-coded known peers to bootstrap the network from. *)
  peers_file : string;
      (** The path to the JSON file where the metadata associated to
      peer_ids are loaded / stored. *)
  private_mode : bool;
      (** If [true], only open outgoing/accept incoming connections
      to/from peers whose addresses are in [trusted_peers], and inform
      these peers that the identity of this node should not be revealed to
      the rest of the network. *)
  identity : P2p_identity.t;  (** Cryptographic identity of the peer. *)
  proof_of_work_target : Crypto_box.pow_target;
      (** Expected level of proof of work of peers' identity. *)
  trust_discovered_peers : bool;
      (** If [true], peers discovered on the local network will be trusted. *)
  reconnection_config : P2p_point_state.Info.reconnection_config;
      (** The reconnection delat configuration. *)
}

type limits = {
  connection_timeout : Time.System.Span.t;
      (** Maximum time allowed to the establishment of a connection. *)
  authentication_timeout : Time.System.Span.t;
      (** Delay granted to a peer to perform authentication. *)
  greylist_timeout : Time.System.Span.t;
      (** GC delay for the greylists tables. *)
  maintenance_idle_time : Time.System.Span.t;
      (** How long to wait at most before running a maintenance loop. *)
  min_connections : int;
      (** Strict minimum number of connections (triggers an urgent maintenance) *)
  expected_connections : int;
      (** Targeted number of connections to reach when bootstrapping / maintaining *)
  max_connections : int;
      (** Maximum number of connections (exceeding peers are disconnected) *)
  backlog : int;  (** Argument of [Lwt_unix.accept].*)
  max_incoming_connections : int;
      (** Maximum not-yet-authenticated incoming connections. *)
  max_download_speed : int option;
      (** Hard-limit in the number of bytes received per second. *)
  max_upload_speed : int option;
      (** Hard-limit in the number of bytes sent per second. *)
  read_buffer_size : int;
      (** Size in bytes of the buffer passed to [Lwt_unix.read]. *)
  read_queue_size : int option;
  write_queue_size : int option;
  incoming_app_message_queue_size : int option;
  incoming_message_queue_size : int option;
  outgoing_message_queue_size : int option;
      (** Various bounds for internal queues. *)
  max_known_peer_ids : (int * int) option;
  max_known_points : (int * int) option;
      (** Optional limitation of internal hashtables (max, target) *)
  peer_greylist_size : int;
      (** The number of peer_ids kept in the peer_id greylist. *)
  ip_greylist_size_in_kilobytes : int;
      (** The size of the IP address greylist in kilobytes. *)
  ip_greylist_cleanup_delay : Time.System.Span.t;
      (** The time an IP address is kept in the greylist. *)
  swap_linger : Time.System.Span.t;
      (** Peer swapping does not occur more than once during a timespan of
      [swap_linger]. *)
  binary_chunks_size : int option;
      (** Size (in bytes) of binary blocks that are sent to other
      peers. Default value is 64 kB. Max value is 64kB. *)
}
