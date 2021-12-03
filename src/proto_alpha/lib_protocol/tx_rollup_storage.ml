(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

let fresh_tx_rollup_from_current_nonce ctxt =
  Raw_context.increment_origination_nonce ctxt >|? fun (ctxt, nonce) ->
  (ctxt, Tx_rollup_repr.originated_tx_rollup nonce)

let originate ctxt =
  fresh_tx_rollup_from_current_nonce ctxt >>?= fun (ctxt, tx_rollup) ->
  Storage.Tx_rollup.State.add ctxt tx_rollup Tx_rollup_state_repr.empty
  >|= fun ctxt -> ok (ctxt, tx_rollup)

let state c tx_rollup = Storage.Tx_rollup.State.find c tx_rollup

let exists c tx_rollup =
  state c tx_rollup >>=? fun rollup -> return @@ Option.is_some rollup

let get_or_empty_inboxes ctxt key =
  Storage.Tx_rollup.Pending_inbox.find ctxt key >>=? function
  | None -> return Pending_inbox_repr.empty
  | Some l -> return l

let pending_inbox ctxt tx_rollup level =
  state ctxt tx_rollup >>=? function
  | None -> return None
  | Some _ -> (
      get_or_empty_inboxes ctxt (level, tx_rollup) >>=? function
      | inbox -> return @@ Some (Pending_inbox_repr.get_operations inbox))

let add_message ctxt tx_rollup level transactions =
  let key = (level, tx_rollup) in
  get_or_empty_inboxes ctxt key >>=? fun inboxes ->
  let inboxes = Pending_inbox_repr.append inboxes transactions in
  Storage.Tx_rollup.Pending_inbox.add ctxt key inboxes >|= ok

let retire_rollup_level ctxt tx_rollup level =
  let key = (level, tx_rollup) in
  Storage.Tx_rollup.Pending_inbox.remove ctxt key >|= ok
