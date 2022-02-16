(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

(** This module introduces the semantics of Proof-generating Virtual Machines.

   A PVM defines an operational semantics for some computational
   model. The specificity of PVMs, in comparison with standard virtual
   machines, is their ability to generate and to validate a *compact*
   proof that a given atomic execution step turned a given state into
   another one.

   In the smart-contract rollups, PVMs are used for two purposes:

    - They allow for the externalization of rollup execution by
   completely specifying the operational semantics of a given
   rollup. This standardization of the semantics gives a unique and
   executable source of truth about the interpretation of
   smart-contract rollup inboxes, seen as a transformation of a rollup
   state.

    - They allow for the validation or refutation of a claim that the
   processing of some messages led to a given new rollup state (given
   an actual source of truth about the nature of these messages).

*)

module type S = sig
  (**

       The state of the PVM denotes a state of the rollup.

  *)
  type state

  (**

       In particular, a state can be a lossy compression of the
     concrete machine state, typically a hash of this state. This is
     useful to transmit a short fingerprint of this state to the layer
     1 as a claim about its contents.

  *)

  (** [compress state] turns a PVM state into a compressed state. *)
  val compress : state -> state

  (**

       A state must finally be *serializable* as it must be
       transmitted from rollup participants to the layer 1.

  *)
  val encoding : state Data_encoding.encoding

  (** [equal_states s1 s2] returns true iff [s1] and of [s2] are
     equal. *)
  val equal_states : state -> state -> bool

  (** [eval inbox s0] returns a state [s1] resulting from the
     execution of an atomic step of the rollup at state [s0], assuming
     this execution happens when the economic protocol exposes the
     given [inbox].

     This function not only provides a reference implementation for
     the semantics of the rollup but it also serves as a validation
     for the assumptions made by rollup participants about the rollup
     inbox exposed by the protocol and about the input rollup
     state.

     If these assumptions are ill-formed, [None] is returned. *)
  val eval : state -> state option
end
