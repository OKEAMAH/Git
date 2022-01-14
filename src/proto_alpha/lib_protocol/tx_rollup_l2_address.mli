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

(** This module introduces the types used to identify ticket holders
    within a transaction rollup. *)

(** The hash of a BLS public key is used as the primary identifier
    of ticket holders within a transaction rollup. *)
type address

val address_encoding : address Data_encoding.t

val pp_address : Format.formatter -> address -> unit

val address_to_b58check : address -> string

val address_of_b58check_opt : string -> address option

val address_of_b58check_exn : string -> address

val address_of_bytes_exn : bytes -> address

val address_of_bytes_opt : bytes -> address option

val compare_address : address -> address -> int

(** [of_bls_pk pk] computes the address of the L2 tickets holder
    authentified by [pk]. *)
val of_bls_pk : Bls_signature.pk -> address

(** Within a transaction rollup, tickets holders are primilarly
    identified by addresses made of the hash of their BLS public
    key. They are also indexed by an integer, that can act as shorter
    identifier.

    {b Note:} Because addresses are indexed using 32bit integers, the
    maximum number of valid addresses is bounded inside a transaction
    rollup. *)
type t = Full of address | Indexed of int32

val encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

(** [in_memory_size address] returns the size (in bytes) a L2 address
    is taking in memory. *)
val in_memory_size : t -> Cache_memory_helpers.sint

val compare : t -> t -> int

(** [size a] returns the number of bytes allocated in an inbox to store [a]. *)
val size : t -> int
