(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trili Tech, <contact@trili.tech>                       *)
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

let remove_zero_ticket_entry ctxt m vty =
  let open Lwt_result_syntax in
  let*? ht, ctxt = Ticket_scanner.type_has_tickets ctxt vty in
  let* ctxt, kvs = Big_map.list_key_values ctxt m in
  let filter ctxt (k, v) =
    let*! res =
      Ticket_scanner.tickets_of_node
        ~include_lazy:false
        ctxt
        ht
        (Micheline.root v)
    in
    if Result.is_error res then return (Some k) else return None
  in
  let* ks = List.filter_map_es (filter ctxt) kvs in
  let* ctxt = Migration_util.evict_big_map_key ctxt m ks in
  return ctxt

let init ctxt =
  let open Lwt_result_syntax in
  let open Script_typed_ir in
  let loc = Micheline.dummy_location in
  let*? ticket_ty = ticket_t loc string_t in
  let*? (Ty_ex_c vty) = pair_t loc timestamp_t ticket_ty in
  let m = Big_map.Id.parse_z (Z.of_int 5696) in
  remove_zero_ticket_entry ctxt m vty
