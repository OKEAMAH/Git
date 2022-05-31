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

(* data
   x size in bytes
   x arrival time in seconds since epoch *)
type 'msg in_flight = 'msg * int * float

(* We {e could} simulate bandwith-limited connections using the
   throttled pipe wrappers of tezos-p2p *)
type ('msg, 'peer_meta, 'conn_meta) single_conn = {
  data : 'msg in_flight Lwt_pipe.Unbounded.t;
      (** Messages outbound to [peer] *)
  peer : P2p_peer.Id.t;
  conn : 'conn_meta;
  propagation_delay : float;
}

type ('msg, 'peer_meta, 'conn_meta) connections =
  ('msg, 'peer_meta, 'conn_meta) single_conn list

module Peer_table = P2p_peer.Id.Table

type ('msg, 'peer_meta, 'conn_meta) peer_state = {
  conns : ('msg, 'peer_meta, 'conn_meta) single_conn list;
      (** Outgoing connections from this peer *)
  pool : 'peer_meta Peer_table.t;  (** Metadata on peers *)
  bandwidth : float;  (** Bandwidth (in bytes/second) *)
  encoding_speed : float;
      (** In bytes/second.
          Delay incurred by encoding the message to bytes. *)
  decoding_speed : float;
      (** In bytes/second.
          Delay incurred by encoding the message to bytes. *)
  mutable deferred_delay : float;  (** Delay accumulated in calls to [send] *)
  mutable on_new_conn : (P2p_peer.Id.t -> unit) list;
      (** Callbacks called when a new connection is added. *)
  mutable on_disconnect : (P2p_peer.Id.t -> unit) list;
      (** Callbacks called when a connection is removed. *)
}

type ('msg, 'peer_meta, 'conn_meta) network = {
  network : ('msg, 'peer_meta, 'conn_meta) peer_state Peer_table.t;
  msg_encoding : 'msg Data_encoding.t;
}

let encoding_from_msg_encoding msg_encoding =
  Data_encoding.union
  @@ ListLabels.map msg_encoding ~f:(function
         | P2p_params.Encoding
             {tag; title; encoding; wrap; unwrap; max_length = _ (* ?? *)}
         -> Data_encoding.case (Tag tag) ~title encoding unwrap wrap)

let create msg_encoding =
  {
    network = Peer_table.create 11;
    msg_encoding = encoding_from_msg_encoding msg_encoding;
  }

module type Parameters = sig
  type message

  type peer_metadata

  type conn_metadata

  val create_peer_metadata : unit -> peer_metadata

  val create_conn_metadata : unit -> conn_metadata
end

let peer_state ~encoding_speed ~decoding_speed ~bandwidth =
  {
    conns = [];
    pool = Peer_table.create 11;
    encoding_speed;
    decoding_speed;
    bandwidth;
    deferred_delay = 0.0;
    on_new_conn = [];
    on_disconnect = [];
  }

let make_conn_with ~peer ~conn_meta ~propagation_delay =
  {
    data = Lwt_pipe.Unbounded.create ();
    peer;
    conn = conn_meta;
    propagation_delay;
  }

open Result_syntax

let get_peer_exn ?(s = "get_peer") net id =
  match Peer_table.find_opt net.network id with
  | None ->
      Format.kasprintf invalid_arg "%s: %a does not exist" s P2p_peer.Id.pp id
  | Some peer -> peer

let get_peer ?(s = "get_peer") net id =
  match Peer_table.find_opt net.network id with
  | None -> Format.kasprintf fail "%s: %a does not exist" s P2p_peer.Id.pp id
  | Some peer -> return peer

let activate_peer net id =
  match Peer_table.find_opt net.network id with
  | None ->
      Peer_table.add
        net.network
        id
        (peer_state ~encoding_speed:1e6 ~decoding_speed:1e6 ~bandwidth:1e9) ;
      return_unit
  | Some _ ->
      Format.kasprintf fail "activate_peer: %a already exists" P2p_peer.Id.pp id

let remove_peer_from_neighbours net ~id ~removed_peer =
  let* state = get_peer ~s:"remove_peer_from_neighbours" net id in
  let conns =
    List.filter
      (fun {peer; _} -> not (P2p_peer.Id.equal peer removed_peer))
      state.conns
  in
  Peer_table.replace net.network id {state with conns} ;
  return_unit

let add_empty_metadata_if_nonexistent peer_state peer peer_meta_initial =
  if Peer_table.mem peer_state.pool peer then ()
  else Peer_table.add peer_state.pool peer (peer_meta_initial ())

let connect_peers net ~a ~b ~peer_meta_initial ~ab_conn_meta ~ba_conn_meta
    ~propagation_delay =
  if P2p_peer.Id.equal a b then
    Format.kasprintf fail "connect_peers: equal peers"
  else
    let* a_state = get_peer ~s:"connect_peers (a)" net a in
    let* b_state = get_peer ~s:"connect_peers (b)" net b in
    let err a b =
      Format.kasprintf
        fail
        "connect_peers: %a already a neighbour to %a"
        P2p_peer.Id.pp
        a
        P2p_peer.Id.pp
        b
    in
    if
      List.exists
        (fun {peer = existing; _} -> P2p_peer.Id.equal existing b)
        a_state.conns
    then err b a
    else if
      List.exists
        (fun {peer = existing; _} -> P2p_peer.Id.equal existing a)
        b_state.conns
    then err a b
    else (
      add_empty_metadata_if_nonexistent a_state b peer_meta_initial ;
      add_empty_metadata_if_nonexistent b_state a peer_meta_initial ;
      Peer_table.replace
        net.network
        a
        {
          a_state with
          conns =
            make_conn_with ~peer:b ~conn_meta:ab_conn_meta ~propagation_delay
            :: a_state.conns;
        } ;
      Peer_table.replace
        net.network
        b
        {
          b_state with
          conns =
            make_conn_with ~peer:a ~conn_meta:ba_conn_meta ~propagation_delay
            :: b_state.conns;
        } ;
      List.iter (fun callback -> callback b) a_state.on_new_conn ;
      List.iter (fun callback -> callback a) b_state.on_new_conn ;
      return_unit)

let disconnect_peers net ~a ~b =
  if P2p_peer.Id.equal a b then
    Format.kasprintf fail "diconnect_peers: equal peers"
  else
    let* a_state = get_peer ~s:"disconnect_peers (a)" net a in
    let* b_state = get_peer ~s:"disconnect_peers (b)" net b in
    let err a b =
      Format.kasprintf
        fail
        "disconnect_peers: %a not a neighbour to %a"
        P2p_peer.Id.pp
        a
        P2p_peer.Id.pp
        b
    in
    if
      not
        (List.exists
           (fun {peer = existing; _} -> P2p_peer.Id.equal existing b)
           a_state.conns)
    then err b a
    else if
      not
        (List.exists
           (fun {peer = existing; _} -> P2p_peer.Id.equal existing a)
           b_state.conns)
    then err a b
    else
      let a_conns =
        List.filter
          (fun {peer; _} -> not (P2p_peer.Id.equal peer b))
          a_state.conns
      in
      let b_conns =
        List.filter
          (fun {peer; _} -> not (P2p_peer.Id.equal peer a))
          b_state.conns
      in
      List.iter (fun callback -> callback b) a_state.on_disconnect ;
      List.iter (fun callback -> callback a) b_state.on_disconnect ;
      Peer_table.replace net.network a {a_state with conns = a_conns} ;
      Peer_table.replace net.network b {b_state with conns = b_conns} ;
      return_unit

let kill_peer net id =
  let* state = get_peer ~s:"kill_peer" net id in
  List.iter_e
    (fun {peer; _} -> remove_peer_from_neighbours net ~id:peer ~removed_peer:id)
    state.conns

let send net ~src ~dst msg =
  let open Result_syntax in
  let* src_state = get_peer ~s:"send (src)" net src in
  let dst_opt =
    List.find (fun {peer; _} -> P2p_peer.Id.equal peer dst) src_state.conns
  in
  let size = Data_encoding.Binary.length net.msg_encoding msg in
  let time_to_encode = float size /. src_state.encoding_speed in
  let time_to_send = float size /. src_state.bandwidth in
  src_state.deferred_delay <-
    src_state.deferred_delay +. (time_to_encode +. time_to_send) ;
  match dst_opt with
  | None ->
      Format.kasprintf
        fail
        "send: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        dst
        P2p_peer.Id.pp
        src
  | Some {data; propagation_delay; _} ->
      let now = Ptime.to_float_s (Ptime_clock.now ()) in
      let arrives_at =
        now +. time_to_encode +. time_to_send +. propagation_delay
      in
      Lwt_pipe.Unbounded.push data (msg, size, arrives_at) ;
      return_unit

let recv net ~dst ~src =
  let open Lwt_result_syntax in
  let*? src_state = get_peer ~s:"recv (src)" net src in
  let*? dst_state = get_peer ~s:"recv (dst)" net dst in
  let dst_opt =
    List.find (fun {peer; _} -> P2p_peer.Id.equal peer dst) src_state.conns
  in
  match dst_opt with
  | None ->
      Format.kasprintf
        fail
        "recv: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        dst
        P2p_peer.Id.pp
        src
  | Some {data; _} ->
      let*! data, size, arrives_at = Lwt_pipe.Unbounded.pop data in
      let now = Ptime.to_float_s (Ptime_clock.now ()) in
      let time_to_decode = float size /. dst_state.decoding_speed in
      let*! () =
        if arrives_at <= now then Lwt_unix.sleep time_to_decode
        else Lwt_unix.sleep (time_to_decode +. arrives_at -. now)
      in
      return data

let get_peer_conn net ~self n =
  let self_state = get_peer_exn ~s:"get_peer_conn (self)" net self in
  let dst_opt =
    List.find (fun {peer; _} -> P2p_peer.Id.equal peer n) self_state.conns
  in
  match dst_opt with
  | None ->
      Format.kasprintf
        invalid_arg
        "get_peer_conn: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        n
        P2p_peer.Id.pp
        self
  | Some conn -> conn

let get_peer_meta net ~self n =
  let state = get_peer_exn ~s:"get_peer_meta" net self in
  match Peer_table.find state.pool n with
  | None ->
      Format.kasprintf
        invalid_arg
        "get_peer_meta: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        n
        P2p_peer.Id.pp
        self
  | Some meta -> meta

let get_conn_meta net ~self n = (get_peer_conn net ~self n).conn

let on_new_connection net id f =
  let state = get_peer_exn ~s:"on_new_connection" net id in
  state.on_new_conn <- f :: state.on_new_conn

let on_disconnection net id f =
  let state = get_peer_exn ~s:"on_disconnection" net id in
  state.on_disconnect <- f :: state.on_new_conn

let sleep_on_deferred_delays net peer_id =
  let open Lwt_result_syntax in
  let*? state = get_peer ~s:"sleep_on_deferred_delays" net peer_id in
  let*! () = Lwt_unix.sleep state.deferred_delay in
  state.deferred_delay <- 0.0 ;
  return_unit
