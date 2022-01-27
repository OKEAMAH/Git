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

(** The basic components of an optimistic rollup for smart-contracts. *)

(**

   An optimistic rollup for smart-contracts is made of two main
   components:

   - a proof generating virtual machine (PVM), which provides the
   essential semantics for the rollup operations to be validated by
   the layer 1 in case of dispute about a commitment ;

   - a database which maintains the finalized operations of the rollup
   as well as the potentially-disputed operations.

*)

exception TickNotFound of Tick_repr.t
module  PVM : sig
  type _ state

  (**

     The state of the PVM represents a concrete execution state of the
     underlying machine. Let us write [concrete_of state] to denote
     the underlying concrete state of some PVM [state].

     This state is probably not implemented exactly as in the
     underlying machine because it must be useful for proof generation
     and proof validation.

     In particular, a state can be a lossy compression of the concrete
     machine state, typically a hash of this state. This is useful to
     transmit a short fingerprint of this state to the layer 1.

     A state can also be *verifiable* which means that it exposes
     enough structure to validate an execution step of the machine.

     A state must finally be *serializable* as it must be transmitted
     from rollup participants to the layer 1.

  *)

  (** The following three functions are for testing purposes. *)
  val initial_state : [`Verifiable | `Full] state

  (** [equal_state s1 s2] is [true] iff [concrete_of_state s1]
      is equal to [concrete_of_state s2]. *)
  val equal_state : _ state -> _ state -> bool

  (** The history of an execution. *)
  type history

  val empty_history : history

  (** We want to navigate into the history using a trace counter. *)
  type tick = Tick_repr.t

  val encoding : [`Full  |`Verifiable] state Data_encoding.t

  val remember : history -> tick -> [`Verifiable | `Full] state -> history

  val compress : _ state -> [`Compressed] state

  val verifiable_state_at : history -> tick -> [`Full  |`Verifiable] state

  (** [state_at p tick] returns a full representation of [concrete_of
     state] at the given trace counter [tick]. *)
  val state_at : history -> tick -> [`Verifiable | `Full] state

  val pp : Format.formatter -> _ state -> unit

  (** [eval failures tick state] executes the machine at [tick]
     assuming a given machine [state]. The function returns the state
     at the [next tick].

     [failures] is here for testing purpose: an error is intentionally
     inserted for ticks in [failures].
  *)
  val eval :
    failures:tick list -> tick -> ([> `Verifiable] as 'a) state -> 'a state

  (** [execute_until failures tick state pred] applies [eval]
       starting from a [tick] and a [state] and returns the first
       [tick] and [state] where [pred tick state] is [true], or
       diverges if such a configuration does not exist. *)
  val execute_until :
    failures:tick list ->
    tick ->
    ([> `Verifiable] as 'a) state ->
    (tick -> 'a state -> bool) ->
    tick * 'a state
end


(** A smart-contract rollup has an address starting with "scr1". *)
module Address : sig
  include S.HASH

  (** [from_nonce nonce] produces an address completely determined by
     an operation hash and an origination counter. *)
  val from_nonce : Origination_nonce.t -> t tzresult

  (** [encoded_size] is the number of bytes needed to represent an address. *)
  val encoded_size : int
end

(** A smart contract rollup is identified by its address. *)
type t = Address.t

val encoding : t Data_encoding.t

val rpc_arg : t RPC_arg.t

(** The data model uses an index of these addresses. *)
module Index : Storage_description.INDEX with type t = Address.t

(** A smart contract rollup has a kind, which assigns meaning to
   rollup operations. *)
module Kind : sig
  (**

     The list of available rollup kinds.

     This list must only be appended for backward compatibility.
  *)
  type t = Example_arith

  val encoding : t Data_encoding.t
end
