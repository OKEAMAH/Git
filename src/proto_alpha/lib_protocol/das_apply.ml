(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Alpha_context

(* DAS/FIXME Register error *)
type error += Data_availibility_size_exceeded

let validate_data_availibility ctxt data_availibility =
  let open Constants in
  let Parametric.{das = {number_of_slots; _}; _} = parametric ctxt in
  let expected_size =
    Das.Endorsement.expected_size ~max_index:(number_of_slots - 1)
  in
  let size = Das.Endorsement.size data_availibility in
  error_unless
    Compare.Int.(size = expected_size)
    Data_availibility_size_exceeded

let apply_data_availibility ctxt data_availibility ~endorser =
  let shards = Das.Endorsement.shards ctxt ~endorser in
  Das.Endorsement.record_available_shards ctxt data_availibility shards ;
  return_unit

type error +=
  | Validate_publish_slot_header_invalid_index of {
      given : int;
      upper_bound : int;
    }

let validate_publish_slot_header ctxt slot =
  let open Constants in
  let slot_index = Das.Slot.index slot in
  let Parametric.{das = {number_of_slots; _}; _} = parametric ctxt in
  error_unless
    Compare.Int.(0 <= slot_index && slot_index < number_of_slots)
    (Validate_publish_slot_header_invalid_index
       {given = slot_index; upper_bound = number_of_slots})

(* DAS/FIXME Register error *)
type error +=
  | Slot_header_candidate_with_low_fees of {
      recorded_fees : Tez.t;
      proposed_fees : Tez.t;
    }

let apply_publish_slot_header ctxt slot proposed_fees =
  match Das.Slot.current_slot_fees ctxt slot with
  | Some recorded_fees ->
      if Tez.(recorded_fees < proposed_fees) then (
        Das.Slot.update_slot ctxt slot proposed_fees ;
        ok ())
      else
        error
          (Slot_header_candidate_with_low_fees {recorded_fees; proposed_fees})
  | None ->
      Das.Slot.update_slot ctxt slot proposed_fees ;
      ok ()

let das_finalisation ctxt =
  Das.Slot.finalize_pending_slots ctxt >>= fun ctxt ->
  Das.Slot.finalize_confirmed_slots ctxt >>= fun ctxt ->
  Das.Slot.finalize_unavailable_slots ctxt
