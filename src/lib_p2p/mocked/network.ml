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

(* We {e could} simulate bandwith-limited connections using the
   throttled pipe wrappers of tezos-p2p *)
type ('msg, 'peer_meta, 'conn_meta) single_conn = {
  data : 'msg Lwt_pipe.Unbounded.t;  (** Messages outbound to [peer] *)
  peer : P2p_peer.Id.t;
  meta : 'peer_meta;
  conn : 'conn_meta;
}

type ('msg, 'peer_meta, 'conn_meta) connections =
  ('msg, 'peer_meta, 'conn_meta) single_conn list

type ('msg, 'peer_meta, 'conn_meta) peer_state = {
  conns : ('msg, 'peer_meta, 'conn_meta) single_conn list;
  self_meta : 'peer_meta;
  mutable on_new_conn : (P2p_peer.Id.t -> unit) list;
}

module Peer_table = P2p_peer.Id.Table

type ('msg, 'peer_meta, 'conn_meta) network = {
  network : ('msg, 'peer_meta, 'conn_meta) peer_state Peer_table.t;
}

let create () = {network = Peer_table.create 11}

module type Parameters = sig
  type message

  type peer_metadata

  type conn_metadata

  val create_peer_metadata : unit -> peer_metadata

  val create_conn_metadata : unit -> conn_metadata
end

let peer_state self_meta = {conns = []; self_meta; on_new_conn = []}

let conn peer peer_meta conn_meta =
  {
    data = Lwt_pipe.Unbounded.create ();
    peer;
    meta = peer_meta;
    conn = conn_meta;
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

let activate_peer net id meta =
  match Peer_table.find_opt net.network id with
  | None ->
      Peer_table.add net.network id (peer_state meta) ;
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

let connect_peers net ~a ~b =
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
      Peer_table.replace
        net.network
        a
        {
          a_state with
          conns = conn b (assert false) (assert false) :: a_state.conns;
        } ;
      Peer_table.replace
        net.network
        b
        {
          b_state with
          conns = conn a (assert false) (assert false) :: b_state.conns;
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
      Peer_table.replace net.network a {a_state with conns = a_conns} ;
      Peer_table.replace net.network b {b_state with conns = b_conns} ;
      return_unit

let kill_peer net id =
  let* state = get_peer ~s:"kill_peer" net id in
  List.iter_e
    (fun {peer; _} -> remove_peer_from_neighbours net ~id:peer ~removed_peer:id)
    state.conns

let send net ~src ~dst msg =
  let* src_state = get_peer ~s:"send (src)" net src in
  let dst_opt =
    List.find (fun {peer; _} -> P2p_peer.Id.equal peer dst) src_state.conns
  in
  match dst_opt with
  | None ->
      Format.kasprintf
        fail
        "send: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        dst
        P2p_peer.Id.pp
        src
  | Some {data; _} ->
      Lwt_pipe.Unbounded.push data msg ;
      return_unit

let recv net ~dst ~src =
  let open Lwt_result_syntax in
  let*? src_state = get_peer ~s:"recv (src)" net src in
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
      let*! data = Lwt_pipe.Unbounded.pop data in
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
        "get_peer: %a is not in the neighbourhood of %a"
        P2p_peer.Id.pp
        n
        P2p_peer.Id.pp
        self
  | Some conn -> conn

let get_self_meta net ~self =
  (get_peer_exn ~s:"get_self_meta" net self).self_meta

let get_peer_meta net ~self n = (get_peer_conn net ~self n).meta

let get_conn_meta net ~self n = (get_peer_conn net ~self n).conn

let on_new_connection net id f =
  let state = get_peer_exn ~s:"on_new_connection" net id in
  state.on_new_conn <- f :: state.on_new_conn
