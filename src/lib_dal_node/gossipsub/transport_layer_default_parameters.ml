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

(* TODO: https://gitlab.com/tezos/tezos/-/issues/5565

   Document these values (taken from octez-node), and chage them if needed.
*)
module P2p_limits = struct
  let connection_timeout = Time.System.Span.of_seconds_exn 10.

  let authentication_timeout = Time.System.Span.of_seconds_exn 5.

  let greylist_timeout = Time.System.Span.of_seconds_exn 86400. (* one day *)

  (* Some of the default values below taken from L1 node instantiation of
     Octez-p2p library. We amplify the value by this constant. *)
  (* FIXME: https://gitlab.com/tezos/tezos/-/issues/6391

     Decide which default value we should choose for P2P parameters and wheter we
     specialize them per profile kind. *)
  let dal_amplification_factor = 8

  (* [maintenance_idle_time] is set to [None] to disable the internal maintenance
     mechanism of Octez-p2p. *)
  let maintenance_idle_time = None

  let min_connections = 10

  let expected_connections = 50 * dal_amplification_factor

  let max_connections = 100 * dal_amplification_factor

  let backlog = 20

  let max_incoming_connections = 20 * dal_amplification_factor

  let max_download_speed = None

  let max_upload_speed = None

  let read_buffer_size = 1 lsl 14

  let read_queue_size = None

  let write_queue_size = None

  let incoming_app_message_queue_size = None

  let incoming_message_queue_size = None

  let outgoing_message_queue_size = None

  let max_known_points =
    Some (400 * dal_amplification_factor, 300 * dal_amplification_factor)

  let max_known_peer_ids =
    Some (400 * dal_amplification_factor, 300 * dal_amplification_factor)

  let peer_greylist_size = 1023 (* historical value *)

  let ip_greylist_size_in_kilobytes =
    2 * 1024 (* two megabytes has shown good properties in simulation *)

  let ip_greylist_cleanup_delay =
    Time.System.Span.of_seconds_exn 86400. (* one day *)

  let binary_chunks_size = None

  (** Contraty to octez-node, [swap_linger] is disabled for Gossipsub. *)
  let swap_linger = None
end

module P2p_reconnection_config = struct
  let factor = 1.05

  let initial_delay = Ptime.Span.of_int_s 1

  let disconnection_delay = Ptime.Span.of_int_s 5

  let increase_cap = Ptime.Span.of_int_s 60
end

module P2p_config = struct
  let expected_pow = 26.

  let listening_port = 11732

  let listening_addr = P2p_addr.of_string_exn "0.0.0.0"

  let discovery_port = None

  let discovery_addr = None

  let advertised_port = Some listening_port

  let trusted_points = []

  let private_mode = false

  let proof_of_work_target = Crypto_box.make_pow_target expected_pow

  let trust_discovered_peers = false

  let disable_peer_discovery = true
end
