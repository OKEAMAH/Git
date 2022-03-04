(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

(** [prereject ctxt tx_rollup hash] stores a prerejection *)
val prereject :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_rejection_repr.Rejection_hash.t ->
  Raw_context.t tzresult Lwt.t

val check_prerejection :
  Raw_context.t ->
  source:Signature.Public_key_hash.t ->
  tx_rollup:Tx_rollup_repr.t ->
  level:Tx_rollup_level_repr.t ->
  message_position:int ->
  proof:Tx_rollup_l2_proof.t ->
  (Raw_context.t * int32) tzresult Lwt.t

val update_accepted_prerejection :
  Raw_context.t ->
  source:Signature.Public_key_hash.t ->
  tx_rollup:Tx_rollup_repr.t ->
  level:Tx_rollup_level_repr.t ->
  commitment:Tx_rollup_commitment_repr.Hash.t ->
  commitment_exists:bool ->
  proof:Tx_rollup_l2_proof.t ->
  priority:int32 ->
  Raw_context.t tzresult Lwt.t

val finalize_prerejections :
  Raw_context.t ->
  Tx_rollup_repr.t ->
  Tx_rollup_level_repr.t ->
  (Raw_context.t * Signature.public_key_hash list) tzresult Lwt.t
