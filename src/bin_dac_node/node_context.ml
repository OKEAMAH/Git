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

type dac_plugin = (module Dac_plugin.T)

type node_plugin = (module Node_plugin.S)

type ready_ctxt = {node_plugin : node_plugin}

type status = Ready of ready_ctxt | Starting

type t = {
  mutable status : status;
  config : Configuration.t;
  tezos_node_cctxt : Client_context.full;
}

let init config cctxt = {status = Starting; config; tezos_node_cctxt = cctxt}

let set_ready ctxt ~(dac_plugin : dac_plugin) =
  match ctxt.status with
  | Starting ->
      let module Dac_plugin = (val dac_plugin) in
      let module Reveal_hash_mapper =
        Dac_hash.Make (Dac_plugin.Protocol_reveal_hash) in
      let module Node_plugin = struct
        type reveal_hash = Dac_plugin.Protocol_reveal_hash.t

        include Dac_plugin
        module Reveal_hash_mapper = Reveal_hash_mapper
      end in
      let (node_plugin : node_plugin) = (module Node_plugin) in
      (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4681
         Currently, Dac only supports coordinator functionalities but we might
         want to filter this capability out depending on the profile.
      *)
      ctxt.status <- Ready {node_plugin}
  | Ready _ -> raise Status_already_ready

type error += Node_not_ready

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
    (fun () -> Node_not_ready)

let get_ready ctxt =
  let open Result_syntax in
  match ctxt.status with
  | Ready ctxt -> Ok ctxt
  | Starting -> fail [Node_not_ready]

let get_config ctxt = ctxt.config

let get_status ctxt = ctxt.status

let get_tezos_node_cctxt ctxt = ctxt.tezos_node_cctxt

let get_dac_hash_encoding ctxt =
  let open Result_syntax in
  match ctxt.status with
  | Ready {node_plugin = (module Node_plugin); _} ->
      Ok Node_plugin.Reveal_hash_mapper.encoding
  | _ -> fail [Node_not_ready]
