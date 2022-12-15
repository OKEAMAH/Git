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

open Sc_rollup_staker_index_repr

(** [init ctxt rollup] initialize a staker index counter for [rollup]. *)
val init : Raw_context.t -> Sc_rollup_repr.t -> Raw_context.t tzresult Lwt.t

(** [fresh_staker_index ctxt rollup staker] creates a new index for [staker] and
    store it in {!Storage.Sc_rollup.Staker_index}. *)
val fresh_staker_index :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  Signature.public_key_hash ->
  (Raw_context.t * t) tzresult Lwt.t

(** [find_staker_index_unsafe ctxt rollup staker] returns the index for the
    [rollup]'s [staker]. This function *must* be called only after they have
    checked for the existence of the rollup, and therefore it is not necessary
    for it to check for the existence of the rollup again. Otherwise, use the
    safe function {!find_staker_index}.

    May fail with [Sc_rollup_not_staked] if [staker] is not staked. *)
val find_staker_index_unsafe :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  Signature.public_key_hash ->
  (Raw_context.t * t) tzresult Lwt.t

(** Same as {!find_staker_index_unsafe} but checks for the existence of the
[rollup] before. *)
val find_staker_index :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  Signature.public_key_hash ->
  (Raw_context.t * t) tzresult Lwt.t

val remove_staker :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  Signature.public_key_hash ->
  (Raw_context.t * int) tzresult Lwt.t
