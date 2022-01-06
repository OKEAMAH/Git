(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2021 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

(** A [message] is a piece of data submitted though the layer-1 to be
    interpreted by the layer-2.

    {ul {li A raw array of bytes that supposedly contains a sequence
            of L2 operations.}} *)
type message = Batch of string

(** [message_size msg] returns the number of bytes allocated in an
    inbox by [msg]. *)
val message_size : message -> int

val message_encoding : message Data_encoding.t

type message_hash

val message_hash_encoding : message_hash Data_encoding.t

val message_hash_pp : Format.formatter -> message_hash -> unit

val hash_message : message -> message_hash

(** An inbox gathers, for a given Tezos level, messages crafted by the
    layer-1 for the layer-2 to interpret.

    The structure comprises two fields: (1) [contents] is the list of
    message hashes, and (2) [cumulated_size] is the quantity of bytes
    allocated by the related messages.

    We recall that a transaction rollup can have up to one inbox per
    Tezos level, starting from its origination. See
    {!Storage.Tx_rollup} for more information. *)
type t = {contents : message_hash list; cumulated_size : int}

val pp : Format.formatter -> t -> unit

val encoding : t Data_encoding.t
