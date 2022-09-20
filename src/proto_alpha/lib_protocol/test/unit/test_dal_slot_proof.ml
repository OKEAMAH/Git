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

(** Testing
    -------
    Component:  Protocol (dal slot proof)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "^\[Unit\] dal slot proof$"
    Subject:    These unit tests check proof-related functions of Dal slots
*)

open Protocol
module S = Dal_slot_repr
module Hist = S.Slots_history

(* FIXME/DAL-REFUTATION: L1 parameters for test network?? *)
let dal_parameters =
  {
    Hist.redundancy_factor = 16;
    segment_size = 4096;
    slot_size = 1 lsl 20;
    number_of_shards = 2048;
  }

let test_proof_unconfirmed_slot_genesis () =
  let open Lwt_result_syntax in
  let slots_history = Hist.genesis in
  let history_cache = Hist.History_cache.empty ~capacity:3000L in
  let page_content_of _ =
    (*failwith "I don't expect to be called"*)
    assert false
  in
  let* proof, input_opt =
    Hist.produce_proof
      dal_parameters
      ~page_content_of
      S.Page.
        {
          published_level = Raw_level_repr.(root);
          slot_index = S.Index.zero;
          page_index = S.Page.Index.zero;
        }
      slots_history
      history_cache
    >|= Environment.wrap_tzresult
  in
  Format.eprintf
    "## Input is:@.%a@.@."
    (fun fmt i ->
      match i with
      | None -> Format.fprintf fmt "<None>"
      | Some s -> Format.fprintf fmt "<Some %s>" s)
    input_opt ;

  Format.eprintf "## Proof is:@.%a@.@." Hist.pp_proof proof ;
  assert false

let tests =
  [
    Tztest.tztest
      "test_proof_unconfirmed_slot_genesis"
      `Quick
      test_proof_unconfirmed_slot_genesis;
  ]
