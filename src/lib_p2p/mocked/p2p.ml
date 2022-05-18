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

type ('msg, 'peer_meta, 'conn_meta) t = {
  self : P2p_peer.Id.t;
  version : Network_version.t;
  handle : ('msg, 'peer_meta, 'conn_meta) Network.network option;
}

type ('msg, 'peer_meta, 'conn_meta) net = ('msg, 'peer_meta, 'conn_meta) t

type ('msg, 'peer_meta, 'conn_meta) connection = {peer : P2p_peer.Id.t}

type config = P2p_config.config

type limits = P2p_config.limits

let default_version : Network_version.t =
  {
    chain_name = Distributed_db_version.Name.zero;
    distributed_db_version = Distributed_db_version.two;
    p2p_version = P2p_version.one;
  }

let gen_conn_id =
  let c = ref 0 in
  fun () ->
    let addr = Ipaddr.V4.of_int32 (Int32.of_int !c) in
    (P2p_addr.of_string_exn (Ipaddr.V4.to_string addr), Some 0)

let connection_info peer_id local_metadata remote_metadata =
  P2p_connection.Info.
    {
      incoming = false;
      peer_id;
      id_point = gen_conn_id ();
      remote_socket_port = 0;
      announced_version = default_version;
      private_node = false;
      local_metadata;
      remote_metadata;
    }

let faked_network :
    'message P2p_params.message_config ->
    'peer_metadata P2p_params.peer_meta_config ->
    'conn_metadata ->
    ('message, 'peer_metadata, 'conn_metadata) net =
 fun _msg_cfg _meta_cfg _meta ->
  let {P2p_identity.peer_id; _} = P2p_identity.generate_with_pow_target_0 () in
  {self = peer_id; version = default_version; handle = None}

(* /!\ HACK /!\

   The mocked p2p implementation relies on some shared state among all p2p intances.
   So when we perform a call to [P2p.create], we need to get a handle on that
   shared state. The issue is that the current p2p API allows to create many p2p
   intances with potentially different message types, and we can't have a single shared
   state with this constraint (we perhaps could if we encoded everything to bytes).

   We make the assumption that a [Network_version.t] determines everything about the
   network (ie there cannot be two distinct networks running concurrently with the
   same [Network_version.t]). In particular, this entails that [Network_version.t]
   determines the type of messages exchanged on the network.
*)

type p2p_network =
  | P2p_network : {
      id : Network_version.t;
      handle : ('a, 'b, 'c) Network.network;
    }
      -> p2p_network

let handles = ref []

let find_handle_opt :
    Network_version.t -> ('msg, 'peer, 'conn) Network.network option =
 fun version ->
  List.find_map
    (fun (P2p_network {id; handle}) ->
      if Network_version.equal id version then Some (Obj.magic handle) else None)
    !handles

let create :
    config:config ->
    limits:limits ->
    'peer_metadata P2p_params.peer_meta_config ->
    'conn_metadata P2p_params.conn_meta_config ->
    'message P2p_params.message_config ->
    ('message, 'peer_metadata, 'conn_metadata) net tzresult Lwt.t =
 fun ~config:_ ~limits:_ peer_cfg _conn_cfg msg_cfg ->
  let {P2p_identity.peer_id; _} = P2p_identity.generate_with_pow_target_0 () in
  let version =
    Network_version.announced
      ~chain_name:msg_cfg.chain_name
      ~distributed_db_versions:msg_cfg.distributed_db_versions
      ~p2p_versions:P2p_version.supported
  in
  let handle =
    match find_handle_opt version with
    | None ->
        let handle = Network.create () in
        handles := P2p_network {id = version; handle} :: !handles ;
        handle
    | Some handle -> handle
  in
  match
    Network.activate_peer handle peer_id (peer_cfg.peer_meta_initial ())
  with
  | Ok () ->
      Lwt_result_syntax.return {self = peer_id; version; handle = Some handle}
  | Error msg ->
      let err = error_of_fmt "%s" msg in
      Lwt_result_syntax.tzfail err

let activate {self; handle; _} =
  Option.iter
    (fun handle ->
      match Network.get_peer handle self with
      | Ok _ -> ()
      | Error msg -> Stdlib.failwith msg)
    handle

let shutdown {self; handle; _} =
  Option.iter_s
    (fun handle ->
      match Network.kill_peer handle self with
      | Ok () -> Lwt.return_unit
      | Error msg -> Lwt.fail_with msg)
    handle

let announced_version {version; _} = version

let negotiated_version {version; _} _conn = version

let peer_id {self; _} = self

let get_peer_metadata {self; handle; _} peer =
  match handle with
  | None ->
      Stdlib.failwith
        "mocked p2p: get_peer_metadata not implemented for faked p2p"
  | Some handle -> Network.get_peer_meta handle ~self peer

let connection_info {self; handle; _} {peer} =
  match handle with
  | None ->
      Stdlib.failwith
        "mocked p2p: connection_info not implemented for faked p2p"
  | Some handle ->
      let meta = Network.get_conn_meta handle ~self peer in
      connection_info self meta meta

let connection_local_metadata {self; handle; _} {peer} =
  match handle with
  | None ->
      Stdlib.failwith
        "mocked p2p: connection_local_metadata not implemented for faked p2p"
  | Some handle -> Network.get_conn_meta handle ~self peer

let connection_remote_metadata {self; handle; _} {peer} =
  match handle with
  | None ->
      Stdlib.failwith
        "mocked p2p: connection_remote_metadata not implemented for faked p2p"
  | Some handle -> Network.get_conn_meta handle ~self peer

let connections {self; handle; _} =
  match handle with
  | None -> []
  | Some handle ->
      List.map
        (fun {Network.peer; _} -> {peer})
        (Network.get_peer_exn ~s:"connections" handle self).conns

let find_connection_by_peer_id {self; handle; _} peer =
  Option.bind handle @@ fun handle ->
  match Network.get_peer_conn handle ~self peer with
  | exception Invalid_argument _ -> None
  | _ -> Some {peer}

let recv {self; handle; _} {peer} =
  let open Lwt_result_syntax in
  match handle with
  | None -> Stdlib.failwith "mocked p2p: recv not implemented for faked p2p"
  | Some handle ->
      let* msg =
        lwt_map_error
          (fun s -> TzTrace.make (error_of_fmt "%s" s))
          (Network.recv handle ~dst:self ~src:peer)
      in
      return msg

let send {self; handle; _} {peer} msg =
  let open Lwt_result_syntax in
  match handle with
  | None -> Stdlib.failwith "mocked p2p: send not implemented for faked p2p"
  | Some handle ->
      lwt_map_error
        (fun s -> TzTrace.make (error_of_fmt "%s" s))
        (let*? () = Network.send handle ~src:self ~dst:peer msg in
         return_unit)

let try_send {self; handle; _} {peer} msg =
  match handle with
  | None -> Stdlib.failwith "mocked p2p: try)send not implemented for faked p2p"
  | Some handle -> (
      match Network.send handle ~src:self ~dst:peer msg with
      | Ok () -> true
      | Error _ -> false)

let iter_connections {self; handle; _} f =
  match handle with
  | None -> ()
  | Some handle ->
      List.iter
        (fun {Network.peer; _} -> f peer {peer})
        (Network.get_peer_exn ~s:"iter_connections" handle self).conns

let fold_connections {self; handle; _} ~init ~f =
  match handle with
  | None -> init
  | Some handle ->
      List.fold_left
        (fun acc {Network.peer; _} -> f peer {peer} acc)
        init
        (Network.get_peer_exn ~s:"fold_connections" handle self).conns

let on_new_connection {self; handle; _} f =
  Option.iter
    (fun handle ->
      Network.on_new_connection handle self (fun peer -> f peer {peer}))
    handle

let disconnect {self; handle; _} ?wait {peer} =
  Option.iter_s
    (fun handle ->
      Option.iter (fun wait -> assert (not wait)) wait ;
      match Network.disconnect_peers handle ~a:self ~b:peer with
      | Ok () -> Lwt.return_unit
      | Error msg -> Lwt.fail_with msg)
    handle

let greylist_peer _net _id =
  Stdlib.failwith "greylist_peer: not implemented by fake_p2p"

let build_rpc_directory _ = RPC_directory.empty

(* module Internal_for_tests = struct
 *   let connect_peers a b = Network.connect_peers handle ~a ~b
 *
 *   let disconnect_peers a b = Network.disconnect_peers handle ~a ~b
 *
 *   let neighbourhood peer =
 *     let peer_state = Network.get_peer_exn ~s:"iter_neighbourhood" handle peer in
 *     List.map (fun {Network.data; peer; _} -> (peer, data)) peer_state.conns
 *
 *   let iter_neighbourhood peer f =
 *     let peer_state = Network.get_peer_exn ~s:"iter_neighbourhood" handle peer in
 *     List.iter
 *       (fun {Network.data = outbound; peer = neighbor; _} ->
 *         f ~outbound ~neighbor)
 *       peer_state.conns
 *
 *   let iter_neighbourhood_es peer f =
 *     let peer_state = Network.get_peer_exn ~s:"iter_neighbourhood" handle peer in
 *     List.iter_es
 *       (fun {Network.data = outbound; peer = neighbor; _} ->
 *         f ~outbound ~neighbor)
 *       peer_state.conns
 * end *)
