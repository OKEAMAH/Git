(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 Trili Tech <contact@trili.tech>                   *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 Marigold  <contact@tmarigold.dev>                      *)
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

open Tezos_rpc_http
open Tezos_rpc_http_server

type error +=
  | Cannot_construct_external_message
  | Cannot_deserialize_external_message

let () =
  register_error_kind
    `Permanent
    ~id:"dac_cannot_construct_external_message"
    ~title:"External rollup message could not be constructed"
    ~description:"External rollup message could not be constructed"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "External rollup message could not be constructed")
    Data_encoding.unit
    (function Cannot_construct_external_message -> Some () | _ -> None)
    (fun () -> Cannot_construct_external_message) ;
  register_error_kind
    `Permanent
    ~id:"dac_cannot_deserialize_rollup_external_message"
    ~title:"External rollup message could not be deserialized"
    ~description:"External rollup message could not be deserialized"
    ~pp:(fun ppf () ->
      Format.fprintf ppf "External rollup message could not be deserialized")
    Data_encoding.unit
    (function Cannot_deserialize_external_message -> Some () | _ -> None)
    (fun () -> Cannot_deserialize_external_message)

let add_service registerer service handler directory =
  registerer directory service handler

let handle_post_store_preimage dac_plugin cctxt dac_sk_uris page_store
    hash_streamer (data, pagination_scheme) =
  let open Lwt_result_syntax in
  let open Pages_encoding in
  let* root_hash =
    match pagination_scheme with
    | Pagination_scheme.Merkle_tree_V0 ->
        (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4897
           Once new "PUT /preimage" endpoint is implemented, pushing
           a new root hash to the data streamer should be moved there.
           Tezt for testing streaming of root hashes should also use
           the new endpoint. *)
        let* root_hash =
          Merkle_tree.V0.Filesystem.serialize_payload
            dac_plugin
            ~page_store
            data
        in
        let () = Data_streamer.publish hash_streamer root_hash in
        let*! () =
          Event.emit_root_hash_pushed_to_data_streamer dac_plugin root_hash
        in
        return root_hash
    | Pagination_scheme.Hash_chain_V0 ->
        Hash_chain.V0.serialize_payload
          dac_plugin
          ~for_each_page:(fun (hash, content) ->
            Page_store.Filesystem.save dac_plugin page_store ~hash ~content)
          data
  in
  let* signature, witnesses =
    Signature_manager.sign_root_hash dac_plugin cctxt dac_sk_uris root_hash
  in
  let*! external_message =
    External_message.Default.make dac_plugin root_hash signature witnesses
  in
  match external_message with
  | Ok external_message -> return @@ (root_hash, external_message)
  | Error _ -> tzfail @@ Cannot_construct_external_message

let handle_get_verify_signature dac_plugin public_keys_opt encoded_l1_message =
  let open Lwt_result_syntax in
  let external_message =
    let open Option_syntax in
    let* encoded_l1_message in
    let* as_bytes = Hex.to_bytes @@ `Hex encoded_l1_message in
    let ((module P) : Dac_plugin.t) = dac_plugin in
    External_message.Default.of_bytes P.encoding as_bytes
  in
  match external_message with
  | None -> tzfail @@ Cannot_deserialize_external_message
  | Some {root_hash; signature; witnesses} ->
      Signature_manager.verify
        dac_plugin
        ~public_keys_opt
        root_hash
        signature
        witnesses

let handle_get_preimage dac_plugin page_store hash =
  Page_store.Filesystem.load dac_plugin page_store hash

(* Handler for subscribing to the streaming of root hashes via
   GET monitor/root_hashes RPC call. *)
let handle_monitor_root_hashes hash_streamer =
  let open Lwt_syntax in
  let stream, stopper = Data_streamer.handle_subscribe hash_streamer in
  let shutdown () = Lwt_watcher.shutdown stopper in
  let next () = Lwt_stream.get stream in
  let* () = Event.(emit handle_new_subscription_to_hash_streamer ()) in
  Tezos_rpc.Answer.return_stream {next; shutdown}

(* Handler for subscribing to the streaming of root hashes via
   GET monitor/root_hashes RPC call. *)
let handle_monitor_saved_pages hash_streamer =
  let stream, stopper = Data_streamer.handle_subscribe hash_streamer in
  let shutdown () = Lwt_watcher.shutdown stopper in
  let next () = Lwt_stream.get stream in
  Tezos_rpc.Answer.return_stream {next; shutdown}

let handle_get_certificate ctx root_hash =
  let open Lwt_result_syntax in
  let node_store = Node_context.get_node_store ctx Store_sigs.Read_only in
  let+ value_opt = Store.Certificate_store.find node_store root_hash in
  Option.map
    (fun Store.{aggregate_signature; witnesses} ->
      Certificate_repr.{aggregate_signature; witnesses; root_hash})
    value_opt

let handle_get_missing_page cctxt page_store dac_plugin root_hash =
  let open Lwt_result_syntax in
  let remote_store = Page_store.Remote.(init {cctxt; page_store}) in
  let* preimage =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/5142
        Retrieve missing page from dac committee via "flooding". *)
    Page_store.Remote.load dac_plugin remote_store root_hash
  in
  let*! () = Event.(emit (fetched_missing_page dac_plugin) root_hash) in
  return preimage

let register_post_store_preimage ctx cctxt dac_sk_uris page_store hash_streamer
    directory =
  directory
  |> add_service
       Tezos_rpc.Directory.register0
       (RPC_services.post_store_preimage ctx)
       (fun () input ->
         handle_post_store_preimage
           ctx
           cctxt
           dac_sk_uris
           page_store
           hash_streamer
           input)

let register_get_verify_signature dac_plugin public_keys_opt directory =
  directory
  |> add_service
       Tezos_rpc.Directory.register0
       RPC_services.get_verify_signature
       (fun external_message () ->
         handle_get_verify_signature dac_plugin public_keys_opt external_message)

let register_get_preimage dac_plugin page_store =
  add_service
    Tezos_rpc.Directory.register1
    (RPC_services.get_preimage dac_plugin)
    (fun hash () () -> handle_get_preimage dac_plugin page_store hash)

let register_monitor_root_hashes dac_plugin hash_streamer dir =
  Tezos_rpc.Directory.gen_register
    dir
    (Monitor_services.S.root_hashes dac_plugin)
    (fun () () () -> handle_monitor_root_hashes hash_streamer)

let register_monitor_saved_pages dac_plugin hash_streamer dir =
  Tezos_rpc.Directory.gen_register
    dir
    (Monitor_services.S.saved_pages dac_plugin)
    (fun () () () -> handle_monitor_saved_pages hash_streamer)

let register_put_dac_member_signature ctx dac_plugin cctxt =
  add_service
    Tezos_rpc.Directory.register0
    (RPC_services.put_dac_member_signature dac_plugin)
    (fun () dac_member_signature ->
      Signature_manager.Coordinator.handle_put_dac_member_signature
        ctx
        cctxt
        dac_member_signature)

let register_get_certificate ctx dac_plugin =
  add_service
    Tezos_rpc.Directory.register1
    (RPC_services.get_certificate dac_plugin)
    (fun root_hash () () -> handle_get_certificate ctx root_hash)

let register_get_missing_page ctx dac_plugin =
  match Node_context.mode ctx with
  | Legacy _ | Observer _ ->
      add_service
        Tezos_rpc.Directory.register1
        (RPC_services.get_missing_page dac_plugin)
        (fun root_hash () () ->
          let open Lwt_result_syntax in
          let page_store = Node_context.get_page_store ctx in
          let*? cctxt = Node_context.get_coordinator_client ctx in
          handle_get_missing_page cctxt page_store dac_plugin root_hash)
  | Coordinator _ | Committee_member _ -> Fun.id

module Coordinator = struct
  let handle_post_preimage dac_plugin page_store hash_streamer payload =
    let open Lwt_result_syntax in
    let* root_hash =
      Pages_encoding.Merkle_tree.V0.Filesystem.serialize_payload
        dac_plugin
        ~page_store
        payload
    in
    let () = Data_streamer.publish hash_streamer root_hash in
    let*! () =
      Event.emit_root_hash_pushed_to_data_streamer dac_plugin root_hash
    in
    return root_hash

  let register_coordinator_post_preimage dac_plugin hash_streamer page_store =
    add_service
      Tezos_rpc.Directory.register0
      (RPC_services.Coordinator.post_preimage dac_plugin)
      (fun () payload ->
        handle_post_preimage dac_plugin page_store hash_streamer payload)

  let dynamic_rpc_dir dac_plugin (node_ctxt : Node_context.t) =
    let modal_node_ctxt =
      match Node_context.mode node_ctxt with
      | Coordinator modal_node_ctxt -> modal_node_ctxt
      (* We only pass [Node_context.t] values whose mode is [Coordinator _] to
         this function. *)
      | _ -> assert false
    in

    let hash_streamer =
      modal_node_ctxt.Node_context.Coordinator.hash_streamer
    in
    let page_streamer =
      modal_node_ctxt.Node_context.Coordinator.page_streamer
    in
    let public_keys_opt =
      Node_context.Coordinator.public_keys_opt modal_node_ctxt
    in
    let page_store = Node_context.get_page_store node_ctxt in
    let cctxt = Node_context.get_tezos_node_cctxt node_ctxt in

    Tezos_rpc.Directory.empty
    |> register_coordinator_post_preimage dac_plugin hash_streamer page_store
    |> register_get_verify_signature dac_plugin public_keys_opt
    |> register_get_preimage dac_plugin page_store
    |> register_monitor_root_hashes dac_plugin hash_streamer
    |> register_put_dac_member_signature node_ctxt dac_plugin cctxt
    |> register_get_certificate node_ctxt dac_plugin
    |> register_monitor_saved_pages dac_plugin page_streamer
end

module Committee_member = struct
  let dynamic_rpc_dir dac_plugin (node_ctxt : Node_context.t) =
    let page_store = Node_context.get_page_store node_ctxt in
    Tezos_rpc.Directory.empty |> register_get_preimage dac_plugin page_store
end

module Observer = struct
  let dynamic_rpc_dir dac_plugin (node_ctxt : Node_context.t) =
    let page_store = Node_context.get_page_store node_ctxt in
    Tezos_rpc.Directory.empty
    |> register_get_preimage dac_plugin page_store
    |> register_get_missing_page node_ctxt dac_plugin
end

module Legacy = struct
  let dynamic_rpc_dir dac_plugin (node_ctxt : Node_context.t) =
    let modal_node_ctxt =
      match Node_context.mode node_ctxt with
      | Legacy modal_node_ctxt -> modal_node_ctxt
      (* We only pass [Node_context.t] values whose mode is [Coordinator _] to
         this function. *)
      | _ -> assert false
    in
    let hash_streamer = modal_node_ctxt.Node_context.Legacy.hash_streamer in
    let page_streamer = modal_node_ctxt.Node_context.Legacy.page_streamer in
    let public_keys_opt = Node_context.Legacy.public_keys_opt modal_node_ctxt in
    let secret_key_uris_opt =
      Node_context.Legacy.secret_key_uris_opt modal_node_ctxt
    in
    let page_store = Node_context.get_page_store node_ctxt in
    let cctxt = Node_context.get_tezos_node_cctxt node_ctxt in
    Tezos_rpc.Directory.empty
    |> register_post_store_preimage
         dac_plugin
         cctxt
         secret_key_uris_opt
         page_store
         hash_streamer
    |> register_get_verify_signature dac_plugin public_keys_opt
    |> register_get_preimage dac_plugin page_store
    |> register_monitor_root_hashes dac_plugin hash_streamer
    |> register_put_dac_member_signature node_ctxt dac_plugin cctxt
    |> register_get_certificate node_ctxt dac_plugin
    |> register_get_missing_page node_ctxt dac_plugin
    |> register_monitor_saved_pages dac_plugin page_streamer
end

let start ~rpc_address ~rpc_port node_ctxt =
  let open Lwt_syntax in
  let register_dynamic_rpc dac_plugin =
    match Node_context.mode node_ctxt with
    | Coordinator _ -> Coordinator.dynamic_rpc_dir dac_plugin node_ctxt
    | Committee_member _ ->
        Committee_member.dynamic_rpc_dir dac_plugin node_ctxt
    | Observer _ -> Observer.dynamic_rpc_dir dac_plugin node_ctxt
    | Legacy _ -> Legacy.dynamic_rpc_dir dac_plugin node_ctxt
  in
  let dir =
    Tezos_rpc.Directory.register_dynamic_directory
      Tezos_rpc.Directory.empty
      Tezos_rpc.Path.open_root
      (fun () ->
        match Node_context.get_status node_ctxt with
        | Ready {dac_plugin = (module Dac_plugin)} ->
            Lwt.return (register_dynamic_rpc (module Dac_plugin))
        | Starting -> Lwt.return Tezos_rpc.Directory.empty)
  in
  let rpc_address = P2p_addr.of_string_exn rpc_address in
  let host = Ipaddr.V6.to_string rpc_address in
  let node = `TCP (`Port rpc_port) in
  let acl = RPC_server.Acl.default rpc_address in
  let server =
    RPC_server.init_server dir ~acl ~media_types:Media_type.all_media_types
  in
  Lwt.catch
    (fun () ->
      let* () =
        RPC_server.launch
          ~host
          server
          ~callback:(RPC_server.resto_callback server)
          node
      in
      return_ok server)
    fail_with_exn

let shutdown = RPC_server.shutdown

let install_finalizer rpc_server =
  let open Lwt_syntax in
  Lwt_exit.register_clean_up_callback ~loc:__LOC__ @@ fun exit_status ->
  let* () = shutdown rpc_server in
  let* () = Event.(emit shutdown_node exit_status) in
  Tezos_base_unix.Internal_event_unix.close ()
