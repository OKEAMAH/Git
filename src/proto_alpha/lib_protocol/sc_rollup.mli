(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(** High-level operations over smart contract rollups. *)

type origination_result = {address : Sc_rollup_repr.Address.t; size : Z.t}

(** [originate context ~pvm ~boot_sector] adds a new rollup running in a
   given [pvm] initialized with a [boot_sector]. *)
val originate :
  Raw_context.t ->
  pvm:Sc_rollup_repr.PVM.t ->
  boot_sector:Sc_rollup_repr.PVM.boot_sector ->
  (Raw_context.t * origination_result) tzresult Lwt.t

val add_messages :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  bytes list ->
  (Raw_context.t * Sc_rollup_inbox.t * Z.t) tzresult Lwt.t

val inbox :
  Raw_context.t ->
  Sc_rollup_repr.t ->
  (Raw_context.t * Sc_rollup_inbox.t) tzresult Lwt.t

val inbox_uncarbonated :
  Raw_context.t -> Sc_rollup_repr.t -> Sc_rollup_inbox.t tzresult Lwt.t
