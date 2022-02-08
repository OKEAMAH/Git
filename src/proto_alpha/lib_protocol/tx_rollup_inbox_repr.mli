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

(** The metadata for an inbox stores the [cumulated_size] in
   bytes for the inbox, so that we do not need to retrieve the entries
   for the inbox just to get the size.  It also stores the
   [predecessor] and [successor] levels.  For the first inbox of a
   rollup, the [predecessor] will be None.  For all inboxes, the
   [successor] will be None until a subsequent inbox is created. *)
type metadata = {
  cumulated_size : int;
  predecessor : Raw_level_repr.t option;
  successor : Raw_level_repr.t option;
}

(** An inbox gathers, for a given Tezos level, messages crafted by the
    layer-1 for the layer-2 to interpret.

    The structure comprises two fields: (1) [contents] is the list of
    message hashes, and (2) [cumulated_size] is the quantity of bytes
    allocated by the related messages.

    We recall that a transaction rollup can have up to one inbox per
    Tezos level, starting from its origination. See
    {!Storage.Tx_rollup} for more information. *)
type content = Tx_rollup_message_repr.hash list

type t = {content : content; metadata : metadata}

val pp : Format.formatter -> t -> unit

val encoding : t Data_encoding.t

val metadata_encoding : metadata Data_encoding.t
