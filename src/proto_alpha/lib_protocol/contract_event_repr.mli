(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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

module Hash : sig
  val prefix : string

  include S.HASH
end

type address = Hash.t

(** Canonical contract event log entry

  [tag]: the canonical tag of this event

  [data]: the data attachment to this event whose type [event] is declared by emitting contract
*)
type t = {addr : address; data : Script_repr.expr}

(** Serialization scheme for an event log entry in Micheline format *)
val encoding : t Data_encoding.t

(** [in_memory_size event_addr] returns the number of bytes [event_addr]
    uses in RAM. *)
val in_memory_size : address -> Cache_memory_helpers.sint

val to_b58check : address -> string

val pp : Format.formatter -> address -> unit

val of_b58data : Base58.data -> address option

val of_b58check : string -> (address, error trace) result

val of_b58check_opt : string -> address option

val entrypoint : Entrypoint_repr.t

val ty_encoding :
  Michelson_v1_primitives.prim Micheline.canonical Data_encoding.t

val default_event_type_node :
  (Micheline.canonical_location, Michelson_v1_primitives.prim) Micheline.node
