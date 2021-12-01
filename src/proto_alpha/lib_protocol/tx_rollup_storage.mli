(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

(** This module introduces various functions to manipulate the storage related
    to transaction rollups. *)

(** {1 Errors} *)

(** This error is raised when someone tries to interact with a transaction rollup
    which does not exists. *)
type error += Tx_rollup_does_not_exist of Tx_rollup_repr.t

(** This error is raised when someone tries to interact with an inbox
    of a transaction rollup which does not exists. *)
type error += Tx_rollup_inbox_does_not_exist of Tx_rollup_repr.t

(** This error is raised when the inbox is already using too much
    storage space for a message to be appended. *)
type error += Tx_rollup_hard_size_limit_reached of Tx_rollup_repr.t

(** {1 Origination} *)

(** [originate ctxt] derives an address from [ctxt] from [ctxt], and
    initializes the new transaction rollup. *)
val originate :
  Raw_context.t -> (Raw_context.t * Tx_rollup_repr.t) tzresult Lwt.t

(** {2 State} *)

(** [get_state ctxt tx_rollup] returns the current state of [tx_rollup].

    Raises [Tx_rollup_does_not_exist] if [tx_rollup] is not a valid
    transaction rollup. *)
val get_state :
  Raw_context.t -> Tx_rollup_repr.t -> Tx_rollup_state_repr.t tzresult Lwt.t

(** [get_opt ctxt tx_rollup] returns the current state of [tx_rollup],
    or [None] if [tx_rollup] is not a valid transaction rollup. *)
val get_state_opt :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_state_repr.t option tzresult Lwt.t

(** {1 Inboxes} *)

(** [inbox_status] is a description of the effect of the
    [append_message] function on the inbox state, in term of storage
    size. *)
type inbox_status = {cumulated_size : int; last_message_size : int}

(** [append_message ctxt tx_rollup message] tries to append message to
    the inbox of [tx_rollup] at the level. Returns the size of the
    appended message and the cumulated size of the inbox in addition
    to the new context.

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val append_message :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.message ->
  (inbox_status * Raw_context.t) tzresult Lwt.t

(** [get_inbox ctxt ?level tx_rollup] returns the compact form of
    the inbox (without the messages) of [tx_rollup] at level [level].

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val get_inbox :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.t tzresult Lwt.t

(** [get_full_inbox ctxt ?offset tx_rollup] returns the complete form
    of the inbox (with the messages) of [tx_rollup] at level [level].

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val get_full_inbox :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.full tzresult Lwt.t

(** [get_inbox_opt ctxt ?level tx_rollup] returns the compact form of
    the inbox (without the messages) of [tx_rollup] at level [level],
    or [None] if it does not exist.

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises [Tx_rollup_does_not_exist] if [tx_rollup] does not exist. *)
val get_inbox_opt :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.t option tzresult Lwt.t

(** [get_full_inbox_opt ctxt ?level tx_rollup] returns the complete
    form of the inbox (with the messages) of [tx_rollup] at level
    [level], or [None] if said inbox does not exists.

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises [Tx_rollup_does_not_exist] if [tx_rollup] does not exist. *)
val get_full_inbox_opt :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.full option tzresult Lwt.t

(** [hash_ticket ctxt tx_rollup ~contents ~ticketer ~ty] computes the
    hash to be used both with the table of ticket and within the
    layer-2 to identify a layer-1 ticket. *)
val hash_ticket :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  contents:Script_repr.node ->
  ticketer:Script_repr.node ->
  ty:Script_repr.node ->
  (Ticket_repr.key_hash * Raw_context.t) tzresult

(** {1 Block Finalization Routine} *)

(** [finalize_block ctxt] updates the [cost_per_byte] variable of each
    transaction rollup which has had an inbox created during the
    current block. *)
val finalize_block : Raw_context.t -> Raw_context.t tzresult Lwt.t
