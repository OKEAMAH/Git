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

(** The purpose of this module is to provide the {!validate_operation}
    function, that decides quickly whether an operation may safely be
    included in a block. See the function's description for further
    information.

    Most elements in this module are either used or wrapped in the
    {!Main} module. *)

(** Static information needed in {!validate_operation}.

    It lives in memory, not in the storage. *)
type validate_operation_info

(** State used and modified by {!validate_operation}.

    It lives in memory, not in the storage. *)
type validate_operation_state

(** Circumstances of the call to {!validate_operation}:

    - [Block]: called during the validation or application of a block
      (received from a peer of freshly constructed). Corresponds to
      [Application], [Partial_application], and [Full_construction] modes
      of {!Main.validation_mode}.

    - [Mempool]: called by the mempool (either directly or through the
      plugin). Corresponds to [Partial_construction] of
      {!Main.validation_mode}. *)
type mode = Block | Mempool

(** Initialize the {!validate_operation_info} and
    {!validate_operation_state} that are needed in
    {!validate_operation}. *)
val init_info_and_state :
  Alpha_context.t ->
  mode ->
  Chain_id.t ->
  validate_operation_info * validate_operation_state

(** A receipt to guarantee that an operation is always validated
    before it is applied.

    Indeed, some functions in {!Apply} require a value of this type,
    which may only be created by calling {!validate_operation} (or a
    function in {!TMP_for_plugin}). *)
type stamp

(** Check the validity of the given operation; return an updated
    {!validate_operation_state}, and a {!stamp} attesting that the
    operation has been validated.

    An operation is valid if it may be included in a block without
    causing the block's application to fail. The purpose of this
    function is to decide validity quickly, that is, without trying to
    actually apply the operation (ie. compute modifications to the
    context: see {!Apply.apply_operation}) and see whether it causes an
    error.

    An operation's validity may be checked in different situations:
    when we receive a block from a peer or we are constructing a fresh
    block, we validate each operation in the block right before trying
    to apply it; when a mempool receives an operation, it validates it
    to decide whether the operation should be propagated (note that for
    now, this only holds for manager operations, since
    [validate_operation] is not impleted yet for other operations: see
    below). See {!type:mode}.

    The [validate_operation_info] contains every information we need
    about the status of the chain to validate an operation, notably the
    context (of type {!Alpha_context.t}) at the end of the previous
    block. This context is never updated by the validation of
    operations, since validation is separate from application. Yet
    sometimes, the presence of some previous operations in a block or a
    mempool may render the current operation invalid. E.g. the
    one-operation-per-manager-per-block restriction (1M) states that a
    block is invalid if it contains two separate operations from the
    same manager; therefore the validation of an operation will return
    [Error Manager_restriction] if another operation by the same
    manager has already been validated in the same block or mempool. In
    order to track this kind of operation incompatibilities, we use a
    [validate_operation_state] with minimal information that gets
    updated during validation.

    For a manager operation, validity is solvability, ie. it must be
    well-formed, and we need to be able to take its fees. Indeed, this
    is sufficient for the safe inclusion of the operation in a block:
    even if there is an error during the subsequent application of the
    manager operation, this will cause the operation to have no further
    effects, but won't impact the success of the block's
    application. The solvability of a manager operation notably
    includes it being correctly signed: indeed, we can't take anything
    from a manager without having checked their signature.

    @param should_check_signature indicates whether the signature
    check should happen. It defaults to [true] because the signature
    needs to be correct for the operation to be valid. This argument
    exists for special cases where it is acceptable to bypass this
    check, e.g.:

    - The mempool may keep track of operations whose signatures have
      already been checked: if such an operation needs to be validated
      again (typically when the head block changes), then the mempool may
      call [validate_operation] with [should_check_signature:false].

    - The [run_operation] RPC provided by the plugin explicitly
      excludes signature checks: see its documentation in
      [lib_plugin/RPC.Scripts.S.run_operation].

    TODO: https://gitlab.com/tezos/tezos/-/issues/2603

    This function currently does nothing for operations other than
    anonymous or manager operation. (instead, the validity of a
    consensus or voting operation is decided by calling
    {!Apply.apply_operation} to check whether it returns an error).
    We should specify and implement the validation of every kind of
    operation. *)
val validate_operation :
  validate_operation_info ->
  validate_operation_state ->
  ?should_check_signature:bool ->
  Operation_hash.t ->
  'kind Alpha_context.operation ->
  (validate_operation_state * stamp) tzresult Lwt.t

(** Functions for the plugin.

    These functions are temporary.

    TODO: https://gitlab.com/tezos/tezos/-/issues/3245
    Update the plugin to call directly {!validate_operation} then
    remove these functions. *)
module TMP_for_plugin : sig
  (** Indicate whether the signature should be checked in
      {!precheck_manager}; if so, provide the raw operation.

      We could have used an [option], but this makes calls to
      {!precheck_manager} more readable. *)
  type 'a should_check_signature =
    | Check_signature of 'a Alpha_context.operation
    | Skip_signature_check

  (** Similar to {!validate_operation}, but do not check the
      one-operation-per-manager-per-block restriction (1M).

      Indeed, 1M is already handled by the plugin. This function is
      purposefully close to the former
      [Apply.precheck_manager_contents_list], so that few changes are
      needed in the plugin.

      The signature is only checked if the [should_check_signature]
      argument is [Check_signature _].

      The {!validate_operation_state} does not need to be updated
      because:

      + 1M is not handled here anyway.

      + In mempool mode, the block gas limit is not tracked.

      This function is called by {!Main.precheck_manager}, which is
      called in [lib_plugin/mempool.ml]. *)
  val precheck_manager :
    validate_operation_info ->
    validate_operation_state ->
    'a Alpha_context.Kind.manager Alpha_context.contents_list ->
    'a Alpha_context.Kind.manager should_check_signature ->
    stamp tzresult Lwt.t
end
