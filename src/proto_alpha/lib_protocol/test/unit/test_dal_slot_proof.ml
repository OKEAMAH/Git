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

open Tezos_crypto_dal
open Protocol
module S = Dal_slot_repr
module Hist = S.Slots_history

(* Helper functions *)
let mk_dal_env dal_params =
  let open Result_syntax in
  match Cryptobox.make dal_params with
  | Ok dal -> return dal
  | Error (`Fail s) -> fail s

let mk_polynomial_from_slot dal slot_data =
  let open Result_syntax in
  match Cryptobox.polynomial_from_slot dal slot_data with
  | Ok p -> return p
  | Error (`Slot_wrong_size s) ->
      fail (Format.sprintf "compute_proof_segment: Slot_wrong_size (%s)" s)

let compute_proof_segment dal_params ~slot_data page_id =
  let open Result_syntax in
  let* dal = mk_dal_env dal_params in
  let* poly = mk_polynomial_from_slot dal slot_data in
  match Cryptobox.prove_segment dal poly page_id.S.Page.page_index with
  | Ok p -> return p
  | Error `Segment_index_out_of_range ->
      fail "compute_proof_segment: Segment_index_out_of_range"

(* FIXME/DAL-REFUTATION: L1 parameters for test network?? *)
let dal_parameters =
  {
    Hist.redundancy_factor = 16;
    segment_size = 4096;
    slot_size = 1 lsl 20;
    number_of_shards = 2048;
  }

let _hits_genesis_dummy_cell () =
  let open Lwt_result_syntax in
  let slots_history = Hist.genesis in
  let history_cache = Hist.History_cache.empty ~capacity:3000L in
  let page_content_of _ =
    (*failwith "I don't expect to be called"*)
    assert false
  in
  let genesis_cell = Hist.Internal_for_tests.content slots_history in
  let* proof, input_opt =
    Hist.produce_proof
      dal_parameters
      ~page_content_of
      S.Page.
        {
          published_level = genesis_cell.published_level;
          slot_index = genesis_cell.index;
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

let _test_proof_unconfirmed_slot_genesis () =
  let open Lwt_result_syntax in
  let slots_history = Hist.genesis in
  let history_cache = Hist.History_cache.empty ~capacity:3000L in
  let page_content_of _ =
    (*failwith "I don't expect to be called"*)
    assert false
  in
  let genesis_cell = Hist.Internal_for_tests.content slots_history in
  let page_id =
    S.Page.
      {
        published_level = genesis_cell.published_level;
        slot_index =
          Option.value_f
            S.Index.(of_int (to_int genesis_cell.index + 1))
            ~default:(fun () -> assert false);
        page_index = S.Page.Index.zero;
      }
  in
  let* proof, input_opt =
    Hist.produce_proof
      dal_parameters
      ~page_content_of
      page_id
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
  let* input_opt_opt =
    Hist.verify_proof dal_parameters page_id slots_history proof
    >|= Environment.wrap_tzresult
  in
  match input_opt_opt with
  | None ->
      Format.eprintf "Proof verification failed@." ;
      assert false
  | Some input_opt' ->
      let ( == ) a b = Option.equal String.equal a b in
      assert (input_opt' == input_opt) ;
      return_unit

let test_proof_confirmed_slot_genesis () =
  let open Lwt_result_syntax in
  let slots_history = Hist.genesis in
  let history_cache = Hist.History_cache.empty ~capacity:3000L in
  let page_content_of _ =
    (*failwith "I don't expect to be called"*)
    assert false
  in
  let slot_data = Bytes.make dal_parameters.slot_size '0' in
  let*? dal = mk_dal_env dal_parameters in
  let*? _poly = mk_polynomial_from_slot dal slot_data in
  assert false
(*
  (* xxxxxxxxx *)
  let page_id =
    S.Page.
      {
        published_level = genesis_cell.published_level;
        slot_index =
          Option.value_f
            S.Index.(of_int (to_int genesis_cell.index + 1))
            ~default:(fun () -> assert false);
        page_index = S.Page.Index.zero;
      }
  in
  let* proof, input_opt =
    Hist.produce_proof
      dal_parameters
      ~page_content_of
      page_id
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
  let* input_opt_opt =
    Hist.verify_proof dal_parameters page_id slots_history proof
    >|= Environment.wrap_tzresult
  in
  match input_opt_opt with
  | None ->
      Format.eprintf "Proof verification failed@." ;
      assert false
  | Some input_opt' ->
      let ( == ) a b = Option.equal String.equal a b in
      assert (input_opt' == input_opt) ;
      return_unit
*)

let tests =
  [
    (*
       Tztest.tztest
         "test_proof_unconfirmed_slot_genesis"
         `Quick
         _test_proof_unconfirmed_slot_genesis;*)
    Tztest.tztest
      "test_proof_confirmed_slot_genesis"
      `Quick
      test_proof_confirmed_slot_genesis;
  ]
