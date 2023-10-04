(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

type t = {
  config : Config_file.t;
  rpc_comm_socket_path : string;
  internal_events : Tezos_base.Internal_event_config.t;
  genesis : Genesis.t;
  history_mode : Tezos_shell_services.History_mode.t option;
  store_root : string;
  context_root : string;
  node_version : Tezos_version.Node_version.t;
}

let parameters_encoding =
  let open Data_encoding in
  conv
    (fun {
           config;
           rpc_comm_socket_path;
           internal_events;
           genesis;
           history_mode;
           store_root;
           context_root;
           node_version;
         } ->
      ( config,
        rpc_comm_socket_path,
        internal_events,
        genesis,
        history_mode,
        store_root,
        context_root,
        node_version ))
    (fun ( config,
           rpc_comm_socket_path,
           internal_events,
           genesis,
           history_mode,
           store_root,
           context_root,
           node_version ) ->
      {
        config;
        rpc_comm_socket_path;
        internal_events;
        genesis;
        history_mode;
        store_root;
        context_root;
        node_version;
      })
    (obj8
       (req "config" Config_file.encoding)
       (req "rpc_comm_socket_path" Data_encoding.string)
       (req "internal_events" Tezos_base.Internal_event_config.encoding)
       (req "genesis" Genesis.encoding)
       (opt "history_mode" Tezos_shell_services.History_mode.encoding)
       (req "store_root" Data_encoding.string)
       (req "context_root" Data_encoding.string)
       (req "node_version" Tezos_version.Node_version.encoding))
