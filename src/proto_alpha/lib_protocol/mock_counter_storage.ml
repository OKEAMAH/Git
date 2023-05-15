(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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

(* Chose the key of the "mock_counter" in the map storage to be Int64.zero,
   as it is not important. Chose the Z.of_int 0 return value as the default for
   when the mock_counter is not initialised. *)

let mock_counter_key = Int64.zero

let update_value ctxt value =
  let open Lwt_result_syntax in
  let* ctxt, stored_value = Storage.Mock_counter.find ctxt mock_counter_key in
  match stored_value with
  | Some prev_value ->
      let new_value = Z.add prev_value value in
      let* new_ctxt, size_diff =
        Storage.Mock_counter.update ctxt mock_counter_key new_value
      in
      return (new_ctxt, size_diff)
  | None ->
      let* new_ctxt, size_diff =
        Storage.Mock_counter.init ctxt mock_counter_key value
      in
      return (new_ctxt, size_diff)

let get_value ctxt =
  let open Lwt_result_syntax in
  let* ctxt, stored_value = Storage.Mock_counter.find ctxt mock_counter_key in
  match stored_value with
  | Some value -> return (ctxt, value)
  | None -> return (ctxt, Z.of_int 0)
