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

(** This error is raised when someone tries to interact with a
    transaction rollup that does not exist. *)
type error += Tx_rollup_does_not_exist of Tx_rollup_repr.t

(** This error is raised when someone tries to interact with an inbox
    of a transaction rollup that does not exist. *)
type error += Tx_rollup_inbox_does_not_exist of Tx_rollup_repr.t

(** This error is raised when the inbox is already using too much
    storage space for a message to be appended. *)
type error += Tx_rollup_hard_size_limit_reached of Tx_rollup_repr.t

(** {1 Origination} *)

(** [originate ctxt] derives an address from [ctxt], and initializes
    the new transaction rollup. *)
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

(** [append_message ctxt tx_rollup message] tries to append message to
    the inbox of [tx_rollup] at the current level. This function
    returns the size of the appended message (in bytes), in order for
    the appropriate fees to be taken from the message author.

    {b Note:} [tx_rollup] needs to be a valid transaction rollup, this
    function does not check it.

    Raises [Tx_rollup_hard_size_limit_reached] if appending [message]
    to the inbox would make it exceed the maximum size specified by
    the [tx_rollup_hard_size_limit_per_inbox] protocol parameter.  *)
val append_message :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_inbox_repr.message ->
  (int * Raw_context.t) tzresult Lwt.t

(** [inbox_messages ctxt ?level tx_rollup] returns the list of messages
    stored in the inbox of [tx_rollup] at level [level].

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val inbox_messages :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  (Raw_context.t * Tx_rollup_inbox_repr.message_hash list) tzresult Lwt.t

(** [inbox_cumulated_size ctxt ?level tx_rollup] returns the cumulated
    size (in bytes) of the messages stored in the inbox of [tx_rollup]
    at level [level].

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val inbox_cumulated_size :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  int tzresult Lwt.t

(** [inbox ctxt ?offset tx_rollup] returns the inbox of [tx_rollup] at
    level [level].

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises

    {ul {li [Tx_rollup_does_not_exist] if [tx_rollup] does not exist}
        {li [Tx_rollup_inbox_does_not_exist] if [tx_rollup] exists,
            but does not have an inbox at level [level]. }} *)
val inbox :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  (Raw_context.t * Tx_rollup_inbox_repr.t) tzresult Lwt.t

(** [inbox_opt ctxt ?level tx_rollup] returns the inbox of
    [tx_rollup] at level [level], or [None] if said inbox does not
    exists.

    If the [level] label is omitted, then it is inferred from [ctxt]
    (namely, from the current level of the chain).

    Raises [Tx_rollup_does_not_exist] if [tx_rollup] does not exist. *)
val inbox_opt :
  Raw_context.t ->
  ?level:Raw_level_repr.t ->
  Tx_rollup_repr.t ->
  (Raw_context.t * Tx_rollup_inbox_repr.t option) tzresult Lwt.t

(** {1 Block Finalization Routine} *)

(** [update_tx_rollup_at_block_finalization ctxt] updates the state of
    each transaction rollup which has had an inbox created during the
    current block.

    {b Note:} As the name suggests, this function must be called at
    block finalization time. *)
val update_tx_rollup_at_block_finalization :
  Raw_context.t -> Raw_context.t tzresult Lwt.t
