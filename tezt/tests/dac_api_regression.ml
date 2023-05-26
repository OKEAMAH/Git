(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(* Testing
   -------
   Component:    Data-availability-committee
   Invocation:   dune exec tezt/tests/main.exe -- --file dac_api_regression.ml
   Subject: Regression tests related to the DAC API versioning.
*)

open Dac_helper

let make ?data ?query_string =
  RPC.make
    ?data
    ?query_string
    ~get_host:Dac_node.rpc_host
    ~get_port:Dac_node.rpc_port
    ~get_scheme:(Fun.const "http")

(** [V0] module is used for regression testing [V0] API. *)
module V0 = struct
  let encode_bytes_to_hex_string raw =
    "\"" ^ match Hex.of_string raw with `Hex s -> s ^ "\""

  (** [post_preimage] asserts the binding contract of "POST v0/preimage"
      request. *)
  let post_preimage =
    (* [post_preimage_request] shape is binding. *)
    let post_preimage_request =
      JSON.parse
        ~origin:"Dac_api_regression.V0.coordinator_post_preimage"
        (encode_bytes_to_hex_string "test")
    in
    let data : RPC_core.data = Data (JSON.unannotate post_preimage_request) in
    make ~data POST [Dac_rpc.V0.api_prefix; "preimage"] Fun.id

  (** [assert_post_preimage_reponse] asserts the binding contract of
      "POST v0/preimage response". *)
  let assert_post_preimage_response reponse =
    let _root_hash = JSON.as_string reponse in
    Lwt.return_unit

  (** [test_coordinator_post_preimage] tests Cooordinator's
      "POST v0/preimage". *)
  let test_coordinator_post_preimage Scenarios.{coordinator_node; _} =
    (* 1. Test binding contract of RPC request.
       2. Test binding contract of RPC response. *)
    let* response = RPC.call coordinator_node post_preimage in
    assert_post_preimage_response response
end

let register ~protocols =
  scenario_with_full_dac_infrastructure
    ~__FILE__
    ~observers:0
    ~committee_size:0
    ~tags:["dac"; "dac_node"; "api_regression"]
    "test Coordinator's post preimage"
    V0.test_coordinator_post_preimage
    protocols