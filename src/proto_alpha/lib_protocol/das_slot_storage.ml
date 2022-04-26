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

let find ctxt level =
  Storage.Das.Slot_headers.find ctxt level >|=? function
  | None -> None
  | Some headers ->
      Some
        (List.mapi
           (fun slot -> function
             | None -> None
             | Some header -> Some Das_slot_repr.{level; slot; header})
           headers)

let finalize_pending_slots ctxt =
  let current_level = Raw_context.current_level ctxt in
  let headers = Raw_context.Das.get_pending_slot_headers ctxt in
  Storage.Das.Slot_headers.add ctxt current_level.level headers

let finalize_confirmed_slots ctxt =
  let current_level = Raw_context.current_level ctxt in
  let Constants_parametric_repr.{das; _} = Raw_context.constants ctxt in
  let delay = das.endorsement_lag in
  match Raw_level_repr.(sub current_level.level delay) with
  | None -> Lwt.return ctxt
  | Some level ->
      (* DAS/FIXME Integration with SCORU should be probably done here. *)
      Storage.Das.Slot_headers.remove ctxt level

let finalize_unavailable_slots ctxt =
  let current_level = Raw_context.current_level ctxt in
  let shards_by_slot = Raw_context.Das.get_shards_availibility ctxt in
  let Constants_parametric_repr.{das; _} = Raw_context.constants ctxt in
  match Raw_level_repr.(sub current_level.level das.endorsement_lag) with
  | None -> return ctxt
  | Some level_endorsed -> (
      Storage.Das.Slot_headers.find ctxt level_endorsed >>=? function
      | None -> return ctxt
      | Some slots ->
          let available_slots =
            List.mapi
              (fun slot_index slot_header ->
                match slot_header with
                | None ->
                    (* DAS/FIXME Should we do something? If an endorser said this slot was available? *)
                    None
                | Some slot ->
                    let shards_available =
                      FallbackArray.fold
                        (fun acc x -> if x then acc + 1 else acc)
                        (FallbackArray.get shards_by_slot slot_index)
                        0
                    in
                    if
                      Compare.Int.(
                        shards_available >= das.availibility_threshold)
                    then None
                    else Some slot)
              slots
          in
          Storage.Das.Slot_headers.add ctxt level_endorsed available_slots
          >|= ok)
