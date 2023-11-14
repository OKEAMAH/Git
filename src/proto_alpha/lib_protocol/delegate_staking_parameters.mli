(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs                                           *)
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

val of_delegate :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Staking_parameters_repr.t tzresult Lwt.t

val pending_updates :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  (Cycle_repr.t * Staking_parameters_repr.t) list tzresult Lwt.t

val register_update :
  Raw_context.t ->
  Signature.Public_key_hash.t ->
  Staking_parameters_repr.t ->
  Raw_context.t tzresult Lwt.t

(** Changes autostaking status.

    It can fail if [delegate] is not a delegate or if it allows staking from
    delegators
*)
val set_autostaking :
  Raw_context.t ->
  delegate:Signature.Public_key_hash.t ->
  autostake:bool ->
  Raw_context.t tzresult Lwt.t

(** Return a boolean that tells if the delegate is set for autostaking.

    It returns false if no value was set.
*)
val is_autostaking :
  Raw_context.t -> delegate:Signature.Public_key_hash.t -> bool tzresult Lwt.t

(** Maintenance of staking parameters at the beginning of cycle [new_cycle].
    This function iterates on all registered delegates. *)
val activate : Raw_context.t -> new_cycle:Cycle_repr.t -> Raw_context.t Lwt.t
