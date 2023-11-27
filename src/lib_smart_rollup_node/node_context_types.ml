(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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
(* type lcc = Store.Lcc.lcc = {commitment : Commitment.Hash.t; level : int32} *)

(* type genesis_info = Metadata.genesis_info = { *)
(*   level : int32; *)
(*   commitment_hash : Commitment.Hash.t; *)
(* } *)

(* type 'a store = 'a Store.t *)

(* type debug_logger = string -> unit Lwt.t *)

(* type current_protocol = { *)
(*   hash : Protocol_hash.t; *)
(*   proto_level : int; *)
(*   constants : Rollup_constants.protocol_constants; *)
(* } *)

(* type last_whitelist_update = {message_index : int; outbox_level : Int32.t} *)

(* type private_info = { *)
(*   last_whitelist_update : last_whitelist_update; *)
(*   last_outbox_level_searched : int32; *)
(* } *)

(* type ('a, 'repo) t = { *)
(*   config : Configuration.t; *)
(*   cctxt : Client_context.full; *)
(*   dal_cctxt : Dal_node_client.cctxt option; *)
(*   dac_client : Dac_observer_client.t option; *)
(*   data_dir : string; *)
(*   l1_ctxt : Layer1.t; *)
(*   genesis_info : genesis_info; *)
(*   injector_retention_period : int; *)
(*   block_finality_time : int; *)
(*   kind : Kind.t; *)
(*   lockfile : Lwt_unix.file_descr; *)
(*   store : 'a store; *)
(*   context : ('a, 'repo) Context.index; *)
(*   lcc : ('a, lcc) Reference.t; *)
(*   lpc : ('a, Commitment.t option) Reference.t; *)
(*   private_info : ('a, private_info option) Reference.t; *)
(*   kernel_debug_logger : debug_logger; *)
(*   finaliser : unit -> unit Lwt.t; *)
(*   mutable current_protocol : current_protocol; *)
(*   global_block_watcher : Sc_rollup_block.t Lwt_watcher.input; *)
(* } *)

(* type 'repo rw = ([`Read | `Write], 'repo) t *)

(* type 'repo ro = ([`Read], 'repo) t *)

type lcc = Store.Lcc.lcc = {commitment : Commitment.Hash.t; level : int32}
(* type lcc = {commitment : Commitment.Hash.t; level : int32} *)

type genesis_info = Metadata.genesis_info = {
  level : int32;
  commitment_hash : Commitment.Hash.t;
}

(* type genesis_info = {level : int32; commitment_hash : Commitment.Hash.t} *)

(** Abstract type for store to force access through this module. *)
type 'a store = 'a Store.t constraint 'a = [< `Read | `Write > `Read]

type debug_logger = string -> unit Lwt.t

type current_protocol = {
  hash : Protocol_hash.t;  (** Hash of the current protocol. *)
  proto_level : int;
      (** Protocol supported by this rollup node (represented as a protocol
          level). *)
  constants : Rollup_constants.protocol_constants;
      (** Protocol constants retrieved from the Tezos node. *)
}

type last_whitelist_update = {message_index : int; outbox_level : Int32.t}

type private_info = {
  last_whitelist_update : last_whitelist_update;
  last_outbox_level_searched : int32;
      (** If the rollup is private then the last search outbox level
          when looking at whitelist update to execute. This is to
          reduce the folding call at each cementation. If the rollup
          is public then it's None. *)
}

type ('a, 'repo) t = {
  config : Configuration.t;  (** Inlined configuration for the rollup node. *)
  cctxt : Client_context.full;  (** Client context used by the rollup node. *)
  dal_cctxt : Dal_node_client.cctxt option;
      (** DAL client context to query the dal node, if the rollup node supports
          the DAL. *)
  dac_client : Dac_observer_client.t option;
      (** DAC observer client to optionally pull in preimages *)
  data_dir : string;  (** Node data dir. *)
  l1_ctxt : Layer1.t;
      (** Layer 1 context to fetch blocks and monitor heads, etc.*)
  genesis_info : genesis_info;
      (** Origination information of the smart rollup. *)
  injector_retention_period : int;
      (** Number of blocks the injector will keep information about included
          operations. *)
  block_finality_time : int;
      (** Deterministic block finality time for the layer 1 protocol. *)
  kind : Kind.t;  (** Kind of the smart rollup. *)
  lockfile : Lwt_unix.file_descr;
      (** A lock file acquired when the node starts. *)
  store : 'a store;  (** The store for the persistent storage. *)
  context : ('a, 'repo) Context.index;
      (** The persistent context for the rollup node. *)
  lcc : ('a, lcc) Reference.t;
      (** Last cemented commitment on L1 (independently of synchronized status
          of rollup node) and its level. *)
  lpc : ('a, Commitment.t option) Reference.t;
      (** The last published commitment on L1, i.e. commitment that the operator
          is staked on (even if the rollup node is not synchronized). *)
  private_info : ('a, private_info option) Reference.t;
      (** contains information for the rollup when it's private.*)
  kernel_debug_logger : debug_logger;
      (** Logger used for writing [kernel_debug] messages *)
  finaliser : unit -> unit Lwt.t;
      (** Aggregation of finalisers to run when the node context closes *)
  mutable current_protocol : current_protocol;
      (** Information about the current protocol. This value is changed in place
          on protocol upgrades. *)
  global_block_watcher : Sc_rollup_block.t Lwt_watcher.input;
      (** Watcher for the L2 chain, which enables RPC services to access
          a stream of L2 blocks. *)
}

(** Read/write node context {!t}. *)
type 'repo rw = ([`Read | `Write], 'repo) t

(** Read only node context {!t}. *)
type 'repo ro = ([`Read], 'repo) t

(** Monad for values with delayed write effects in the node context. *)
type ('a, 'repo) delayed_write = ('a, 'repo rw) Delayed_write_monad.t

(* (\** [protocol_of_level t level] returns the protocol of block level [level]. *\) *)
(* val protocol_of_level : _ t -> int32 -> proto_info tzresult Lwt.t *)

let level_of_hash {l1_ctxt; store; _} hash =
  let open Lwt_result_syntax in
  let* l2_header = Store.L2_blocks.header store.l2_blocks hash in
  match l2_header with
  | Some {level; _} -> return level
  | None ->
      let+ {level; _} = Layer1.fetch_tezos_shell_header l1_ctxt hash in
      level

let last_seen_protocol node_ctxt =
  let open Lwt_result_syntax in
  let+ protocols = Store.Protocols.read node_ctxt.store.protocols in
  match protocols with
  | None | Some [] -> None
  | Some (p :: _) -> Some p.protocol

let protocol_activation_level node_ctxt protocol_hash =
  let open Lwt_result_syntax in
  let* protocols = Store.Protocols.read node_ctxt.store.protocols in
  match
    Option.bind
      protocols
      (List.find_map (function Store.Protocols.{protocol; level; _} ->
           if Protocol_hash.(protocol_hash = protocol) then Some level else None))
  with
  | None ->
      failwith
        "Could not determine the activation level of a previously unseen \
         protocol %a"
        Protocol_hash.pp
        protocol_hash
  | Some l -> return l

type proto_info = {
  proto_level : int;
  first_level_of_protocol : bool;
  protocol : Protocol_hash.t;
}

let protocol_of_level_with_store (store : _ Store.t) level =
  let open Lwt_result_syntax in
  let* protocols = Store.Protocols.read store.protocols in
  let*? protocols =
    match protocols with
    | None | Some [] ->
        error_with "Cannot infer protocol for level %ld: no protocol info" level
    | Some protos -> Ok protos
  in
  let rec find = function
    | [] ->
        error_with "Cannot infer protocol for level %ld: no information" level
    | {Store.Protocols.level = p_level; proto_level; protocol} :: protos -> (
        (* Latest protocols appear first in the list *)
        match p_level with
        | First_known l when level >= l ->
            Ok {protocol; proto_level; first_level_of_protocol = false}
        | Activation_level l when level > l ->
            (* The block at the activation level is of the previous protocol, so
               we are in the protocol that was activated at [l] only when the
               level we query is after [l]. *)
            Ok
              {
                protocol;
                proto_level;
                first_level_of_protocol = level = Int32.succ l;
              }
        | _ -> (find [@tailcall]) protos)
  in
  Lwt.return (find protocols)

let protocol_of_level (node_ctxt : _ t) level =
  assert (level >= node_ctxt.genesis_info.level) ;
  protocol_of_level_with_store node_ctxt.store level
