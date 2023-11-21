(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

type error += Unsupported_protocol of Protocol_hash.t

type error += Unregistered_protocol of Protocol_hash.t

type 'a tid = 'a Context.tid

let () =
  register_error_kind
    ~id:"smart_rollup.node.unsupported_protocol"
    ~title:"Protocol not supported by rollup node"
    ~description:"Protocol not supported by rollup node."
    ~pp:(fun ppf proto ->
      Format.fprintf
        ppf
        "Protocol %a is not supported by the rollup node."
        Protocol_hash.pp
        proto)
    `Permanent
    Data_encoding.(obj1 (req "protocol" Protocol_hash.encoding))
    (function Unsupported_protocol p -> Some p | _ -> None)
    (fun p -> Unsupported_protocol p)

let () =
  register_error_kind
    ~id:"smart_rollup.node.unregistered_protocol"
    ~title:"Protocol not registered by rollup node"
    ~description:"Protocol not registered by rollup node."
    ~pp:(fun ppf proto ->
      Format.fprintf
        ppf
        "Protocol %a is not registered by the rollup node."
        Protocol_hash.pp
        proto)
    `Permanent
    Data_encoding.(obj1 (req "protocol" Protocol_hash.encoding))
    (function Unsupported_protocol p -> Some p | _ -> None)
    (fun p -> Unsupported_protocol p)

type ('repo, 'tree) proto_plugin = ('repo, 'tree) Protocol_plugin_sig.typed_full

open Context

type obj =
  | Object : {
      plugin :
        (module Protocol_plugin_sig.S
           with type Pvm.Store.Context.Store.repo = 'repo
            and type Pvm.Store.Context.Store.tree = 'tree);
      tid : ('repo * 'tree) tid;
    }
      -> obj

let cast_plugin (type repo tree) (t : (repo * tree) tid)
    (Object {tid; plugin; _}) : (repo, tree) proto_plugin option =
  match try_cast t tid with Some Equal -> Some plugin | None -> None

let keys : obj Protocol_hash.Table.t = Protocol_hash.Table.create 7

let register (type tree repo) (plugin : (repo, tree) proto_plugin) =
  let module Plugin = (val plugin) in
  if Protocol_hash.Table.mem keys Plugin.protocol then
    Format.kasprintf
      invalid_arg
      "The rollup node protocol plugin for protocol %a is already registered. \
       Did you register it manually multiple times?"
      Protocol_hash.pp
      Plugin.protocol ;
  let tid = tid () in
  Protocol_hash.Table.add keys Plugin.protocol (Object {plugin; tid}) ;
  tid

let registered_protocols () =
  Protocol_hash.Table.to_seq_keys keys |> List.of_seq

let proto_plugin_for_protocol :
    type tree repo.
    (repo * tree) tid ->
    Protocol_hash.t ->
    (repo, tree) Protocol_plugin_sig.typed_full tzresult =
 fun tid protocol ->
  let open Result_syntax in
  let* key =
    Protocol_hash.Table.find keys protocol
    |> Option.to_result ~none:[Unsupported_protocol protocol]
  in
  cast_plugin tid key |> Option.to_result ~none:[Unregistered_protocol protocol]

let proto_plugin_for_level tid node_ctxt level =
  let open Lwt_result_syntax in
  let* {protocol; _} = Node_context.protocol_of_level node_ctxt level in
  let*? plugin = proto_plugin_for_protocol tid protocol in
  return plugin

let proto_plugin_for_level_with_store tid node_store level =
  let open Lwt_result_syntax in
  let* {protocol; _} =
    Node_context.protocol_of_level_with_store node_store level
  in
  let*? plugin = proto_plugin_for_protocol tid protocol in
  return plugin

let proto_plugin_for_block tid node_ctxt block_hash =
  let open Lwt_result_syntax in
  let* level = Node_context.level_of_hash node_ctxt block_hash in
  proto_plugin_for_level tid node_ctxt level

let last_proto_plugin tid node_ctxt =
  let open Lwt_result_syntax in
  let* protocol = Node_context.last_seen_protocol node_ctxt in
  match protocol with
  | None -> failwith "No known last protocol, cannot get plugin"
  | Some protocol ->
      let*? plugin = proto_plugin_for_protocol tid protocol in
      return plugin

module Constants_cache =
  Aches_lwt.Lache.Make_result
    (Aches.Rache.Transfer (Aches.Rache.LRU) (Protocol_hash))

let constants_cache =
  let cache_size = 3 in
  Constants_cache.create cache_size

let get_constants_of_protocol :
    type tree repo.
    (repo * tree) tid ->
    (_, repo) Node_context.t ->
    Protocol_hash.t ->
    Rollup_constants.protocol_constants tzresult Lwt.t =
 fun tid node_ctxt protocol_hash ->
  let open Lwt_result_syntax in
  if Protocol_hash.(protocol_hash = node_ctxt.current_protocol.hash) then
    return node_ctxt.current_protocol.constants
  else
    let retrieve protocol_hash =
      let*? (plugin : (repo, tree) proto_plugin) =
        proto_plugin_for_protocol tid protocol_hash
      in
      let (module Plugin) = plugin in
      let* (First_known l | Activation_level l) =
        Node_context.protocol_activation_level node_ctxt protocol_hash
      in
      Plugin.Layer1_helpers.retrieve_constants ~block:(`Level l) node_ctxt.cctxt
    in
    Constants_cache.bind_or_put
      constants_cache
      protocol_hash
      retrieve
      Lwt.return

let get_constants_of_level proto_plugins node_ctxt level =
  let open Lwt_result_syntax in
  let* {protocol; _} = Node_context.protocol_of_level node_ctxt level in
  get_constants_of_protocol proto_plugins node_ctxt protocol

let get_constants_of_block_hash proto_plugins node_ctxt block_hash =
  let open Lwt_result_syntax in
  let* level = Node_context.level_of_hash node_ctxt block_hash in
  get_constants_of_level proto_plugins node_ctxt level

(* type context_t = *)
(*   | Irmin of *)
(*       (Context.IStore.Context.Store.repo * Context.IStore.Context.Store.tree) *)
(*       tid *)

(* let proto_tid : context_t Protocol_hash.Table.t = Protocol_hash.Table.create 7 *)

(* let get_tid : Protocol_hash.t -> 'a tid option = *)
(*  fun protocol_hash -> *)
(*   match Protocol_hash.Table.find proto_tid protocol_hash with *)
(*   | Some (Irmin t) -> Some t *)
(*   | None -> None *)
