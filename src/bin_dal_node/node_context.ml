(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type ready_ctxt = {
  cryptobox : Cryptobox.t;
  proto_parameters : Dal_plugin.proto_parameters;
  dal_plugin : (module Dal_plugin.T);
  dac_plugin : (module Dac_plugin.T);
}

type status = Ready of ready_ctxt | Starting

type t = {
  mutable status : status;
  config : Configuration.t;
  store : Store.node_store;
  neighbors_cctxts : Dal_node_client.cctxt list;
}

let init config store =
  let neighbors_cctxts =
    List.map
      (fun Configuration.{addr; port} ->
        Dal_node_client.make_unix_cctxt ~addr ~port)
      config.Configuration.neighbors
  in
  {status = Starting; config; store; neighbors_cctxts}

let set_ready ctxt ~dal_plugin ~dac_plugin cryptobox proto_parameters =
  match ctxt.status with
  | Starting ->
      ctxt.status <- Ready {dac_plugin; dal_plugin; cryptobox; proto_parameters}
  | Ready _ -> raise Status_already_ready

type error += Node_not_ready

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.not.ready"
    ~title:"DAL Node not ready"
    ~description:"DAL node is starting. It's not ready to respond to RPCs."
    ~pp:(fun ppf () ->
      Format.fprintf
        ppf
        "DAL node is starting. It's not ready to respond to RPCs.")
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

let get_store ctxt = ctxt.store

let get_neighbors_cctxts ctxt = ctxt.neighbors_cctxts
