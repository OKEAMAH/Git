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

(** [originate context] originates a new tx rollup and returns its hash
    generated from the [origination_nonce] in context. It also increment the
    [origination_nonce]. *)
val originate :
  Raw_context.t -> (Raw_context.t * Tx_rollup_repr.t) tzresult Lwt.t

(** [state context tx_rollup] is the current state of [tx_rollup] in the
    context. *)
val state :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_state_repr.t option tzresult Lwt.t

(* [exists context tx_rollup] returns true if the given rollup has been
   originated. *)
val exists :
  Raw_context.t -> Tx_rollup_repr.t -> (bool, error trace) result Lwt.t

(** [pending_inbox context tx_rollup level] is the current pending inboxes of
    [tx_rollup] at [level] in the context. *)
val pending_inbox :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Raw_level_repr.t ->
  Pending_inbox_repr.stored_operation list option tzresult Lwt.t

(** [add_message context tx_rollup level message] adds a message to a rollup's
    inbox *)
val add_message :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Raw_level_repr.t ->
  Pending_inbox_repr.stored_operation ->
  Raw_context.t tzresult Lwt.t

(** [retire_rollup_level contxt tx_rollup level] removes all data
   associated with a level. *)
val retire_rollup_level :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Raw_level_repr.t ->
  Raw_context.t tzresult Lwt.t
