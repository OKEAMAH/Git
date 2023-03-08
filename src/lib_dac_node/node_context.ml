(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 Trili Tech, <contact@trili.tech>                  *)
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

exception Status_already_ready

let store_path_prefix = "store"

type dac_plugin_module = (module Dac_plugin.T)

module Coordinator = struct
  type t = {
    committee_members : Wallet.Coordinator.t list;
    hash_streamer : Dac_plugin.hash Data_streamer.t;
        (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4895
           This could be problematic in case coordinator and member/observer
           use two different plugins that bind different underlying hashes. *)
  }

  let init coordinator_config cctxt =
    let open Lwt_result_syntax in
    let Configuration.Coordinator.{committee_members_addresses; _} =
      coordinator_config
    in
    let+ committee_members =
      Wallet.Coordinator.get_all_committee_members_public_keys
        committee_members_addresses
        cctxt
    in
    let hash_streamer = Data_streamer.init () in
    {committee_members; hash_streamer}

  let hash_streamer t = t.hash_streamer

  let pks_opt t =
    List.map (fun Wallet.Coordinator.{pk_opt; _} -> pk_opt) t.committee_members
end

module Committee_member = struct
  type t = {
    committee_member : Wallet.Committee_member.t;
    coordinator_cctxt : Dac_node_client.cctxt;
  }

  let init committee_member_config cctxt =
    let open Lwt_result_syntax in
    let Configuration.Committee_member.
          {address; coordinator_rpc_address; coordinator_rpc_port} =
      committee_member_config
    in
    let+ committee_member =
      Wallet.Committee_member.get_committee_member_signing_key address cctxt
    in
    let coordinator_cctxt =
      Dac_node_client.make_unix_cctxt
        ~scheme:"http"
        ~host:coordinator_rpc_address
        ~port:coordinator_rpc_port
    in
    {committee_member; coordinator_cctxt}

  let coordinator_cctxt t = t.coordinator_cctxt

  let sk_uri t =
    let Wallet.Committee_member.{sk_uri; _} = t.committee_member in
    sk_uri
end

module Observer = struct
  type t = {coordinator_cctxt : Dac_node_client.cctxt}

  let init observer_config =
    let open Lwt_result_syntax in
    let Configuration.Observer.{coordinator_rpc_address; coordinator_rpc_port} =
      observer_config
    in
    let coordinator_cctxt =
      Dac_node_client.make_unix_cctxt
        ~scheme:"http"
        ~host:coordinator_rpc_address
        ~port:coordinator_rpc_port
    in
    return {coordinator_cctxt}

  let coordinator_cctxt t = t.coordinator_cctxt
end

module Legacy = struct
  type t = {
    committee_members : Wallet.Legacy.t list;
    coordinator_cctxt : Dac_node_client.cctxt option;
    hash_streamer : Dac_plugin.hash Data_streamer.t;
  }

  let init legacy_config cctxt =
    let open Lwt_result_syntax in
    let Configuration.Legacy.
          {threshold; committee_members_addresses; dac_cctxt_config} =
      legacy_config
    in
    let+ committee_members =
      Wallet.Legacy.get_all_committee_members_keys
        committee_members_addresses
        ~threshold
        cctxt
    in
    let coordinator_cctxt =
      Option.map
        (fun Configuration.{host; port} ->
          Dac_node_client.make_unix_cctxt ~scheme:"http" ~host ~port)
        dac_cctxt_config
    in
    let hash_streamer = Data_streamer.init () in
    {committee_members; coordinator_cctxt; hash_streamer}

  let hash_streamer t = t.hash_streamer

  let coordinator_cctxt t = t.coordinator_cctxt

  let pks_opt t =
    List.map (fun Wallet.Legacy.{pk_opt; _} -> pk_opt) t.committee_members

  let sk_uris_opt t =
    List.map
      (fun Wallet.Legacy.{sk_uri_opt; _} -> sk_uri_opt)
      t.committee_members
end

module Modal = Operating_modes.Make_modal_type (struct
  type coordinator_t = Coordinator.t

  type committee_member_t = Committee_member.t

  type observer_t = Observer.t

  type legacy_t = Legacy.t
end)

type ready_ctxt = {dac_plugin : dac_plugin_module}

type status = Ready of ready_ctxt | Starting

type 'a node_ctxt = {
  mutable status : status;
  reveal_data_dir : string;
  tezos_node_cctxt : Client_context.full;
  page_store : Page_store.Filesystem.t;
  node_store : Store_sigs.rw Store.Irmin_store.t;
  (* TODO: Should this be only in coordinator and legacy mode?*)
  mode : 'a Modal.mode;
}

type t = Ex : 'a node_ctxt -> t

let init config cctxt =
  let open Lwt_result_syntax in
  let* node_store =
    Store.Irmin_store.load
      Store_sigs.Read_write
      (Configuration.data_dir_path config store_path_prefix)
  in
  let make_node_ctxt mode =
    Ex
      {
        status = Starting;
        reveal_data_dir = Configuration.reveal_data_dir config;
        tezos_node_cctxt = cctxt;
        page_store =
          Page_store.Filesystem.init (Configuration.reveal_data_dir config);
        node_store;
        mode;
      }
  in
  let (Ex {mode; _}) = config in
  match mode with
  | Coordinator config ->
      let+ mode_node_ctxt = Coordinator.init config cctxt in
      make_node_ctxt (Modal.Coordinator mode_node_ctxt)
  | Committee_member config ->
      let+ mode_node_ctxt = Committee_member.init config cctxt in
      make_node_ctxt (Modal.Committee_member mode_node_ctxt)
  | Observer config ->
      let+ mode_node_ctxt = Observer.init config in
      make_node_ctxt (Modal.Observer mode_node_ctxt)
  | Legacy config ->
      let+ mode_node_ctxt = Legacy.init config cctxt in
      make_node_ctxt (Modal.Legacy mode_node_ctxt)

let mode (type a) (node_ctxt : a node_ctxt) = node_ctxt.mode

let set_ready (Ex ctxt) dac_plugin =
  match ctxt.status with
  | Starting ->
      (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4681
         Currently, Dac only supports coordinator functionalities but we might
         want to filter this capability out depending on the profile.
      *)
      ctxt.status <- Ready {dac_plugin}
  | Ready _ -> raise Status_already_ready

type error +=
  | Node_not_ready
  | Invalid_operation_for_mode of {mode : string; operation : string}

let () =
  register_error_kind
    `Permanent
    ~id:"dac.node.not.ready"
    ~title:"DAC Node not ready"
    ~description:"DAC node is starting. It's not ready to respond to RPCs."
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "DAC node is starting. It's not ready to respond to RPCs.")
    Data_encoding.(unit)
    (function Node_not_ready -> Some () | _ -> None)
    (fun () -> Node_not_ready) ;
  register_error_kind
    `Permanent
    ~id:"dac_unexpected_mode"
    ~title:"Invalid operation for the current mode of Dac node."
    ~description:
      "An operation was called that it not supported by the current Dac node."
    ~pp:(fun ppf (mode, operation) ->
      Format.fprintf
        ppf
        "An operation was called that it not supported by the current Dac \
         node. Mode: %s; Unsupported_operation: %s"
        mode
        operation)
    Data_encoding.(
      obj2 (req "mode" (string' Plain)) (req "operation" (string' Plain)))
    (function
      | Invalid_operation_for_mode {mode; operation} -> Some (mode, operation)
      | _ -> None)
    (fun (mode, operation) -> Invalid_operation_for_mode {mode; operation})

let get_ready (Ex ctxt) =
  let open Result_syntax in
  match ctxt.status with
  | Ready ctxt -> Ok ctxt
  | Starting -> fail [Node_not_ready]

let get_status (Ex ctxt) = ctxt.status

let get_tezos_node_cctxt (Ex ctxt) = ctxt.tezos_node_cctxt

let get_dac_plugin (Ex ctxt) =
  let open Result_syntax in
  match ctxt.status with
  | Ready {dac_plugin} -> Ok dac_plugin
  | Starting -> tzfail Node_not_ready

let get_page_store (Ex ctxt) = ctxt.page_store

let get_node_store (type a) (Ex ctxt) (access_mode : a Store_sigs.mode) :
    a Store.Irmin_store.t =
  match access_mode with
  | Store_sigs.Read_only -> Store.Irmin_store.readonly ctxt.node_store
  | Store_sigs.Read_write -> ctxt.node_store

let get_committee_members (Ex ctxt) =
  let open Result_syntax in
  match ctxt.mode with
  | Legacy legacy ->
      Ok (List.map (fun Wallet.Legacy.{pkh; _} -> pkh) legacy.committee_members)
  | Coordinator coordinator ->
      Ok
        ((List.map (fun Wallet.Coordinator.{pkh; _} -> pkh))
           coordinator.committee_members)
  | Observer _ ->
      tzfail
      @@ Invalid_operation_for_mode
           {mode = "observer"; operation = "get_committee_members"}
  | Committee_member _ ->
      tzfail
      @@ Invalid_operation_for_mode
           {mode = "dac_member"; operation = "get_committee_members"}
