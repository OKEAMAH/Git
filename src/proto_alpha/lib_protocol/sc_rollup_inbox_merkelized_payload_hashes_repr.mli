(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type error += Merkelized_payload_hashes_proof_error of string

module Hash : S.HASH

(** A type representing the head of a merkelized list of
    {!Sc_rollup_inbox_message_repr.serialized} message. It contains the hash of
    the payload and the index on the list. *)
type t

val encoding : t Data_encoding.t

type merkelized_and_payload = {
  merkelized : t;
  payload : Sc_rollup_inbox_message_repr.serialized;
}

val merkelized_and_payload_encoding : merkelized_and_payload Data_encoding.t

val pp_merkelized_and_payload :
  Format.formatter -> merkelized_and_payload -> unit

val equal_merkelized_and_payload :
  merkelized_and_payload -> merkelized_and_payload -> bool

(** [hash merkelized] is the hash of [merkelized]. It is used as key to remember
    a merkelized payload hash in an {!History.t}. *)
val hash : t -> Hash.t

(** [genesis payload] is the initial merkelized payload hashes with
    index 0. *)
val genesis : Sc_rollup_inbox_message_repr.serialized -> t

(** [add_payload merkelized payload] creates a new {!t} with [payload]
    and [merkelized] as ancestor (i.e. [index = succ (get_index
    merkelized)]) *)
val add_payload : t -> Sc_rollup_inbox_message_repr.serialized -> t

val equal : t -> t -> bool

val pp : Format.formatter -> t -> unit

(** [get_payload_hash merkelized] returns the
    {!Sc_rollup_inbox_message_repr.serialized} payload's hash of
    [merkelized]. *)
val get_payload_hash : t -> Sc_rollup_inbox_message_repr.Hash.t

(** [get_index merkelized] returns the index of [merkelized]. *)
val get_index : t -> Z.t

(** Given two t [(a, b)] and a {!Sc_rollup_inbox_message_repr.serialized}
    [payload], a [proof] guarantees that [payload] hash is equal to [a] and that
    [a] is an ancestor of [b]; i.e. [get_index a < get_index b]. *)
type proof = private t list

val pp_proof : Format.formatter -> proof -> unit

val proof_encoding : proof Data_encoding.t

(** [produce_proof history ~index into_] returns a {!merkelized_and_payload}
    with index [index] and a proof that it is an ancestor of [into_]. Returns
    [None] if no merkelized payload with [index] is found (either in the
    [history] or [index] is not inferior to [get_index into_]). *)
val produce_proof :
  (Hash.t -> merkelized_and_payload option Lwt.t) ->
  index:Z.t ->
  t ->
  (merkelized_and_payload * proof) option Lwt.t

(** [verify_proof proof] returns [(a, b)] where [proof] validates that [a] is an
    ancestor of [b]. Fails when [proof] is not a valid inclusion proof. *)
val verify_proof : proof -> (t * t) tzresult

module Internal_for_tests : sig
  val make_proof : t list -> proof
end
