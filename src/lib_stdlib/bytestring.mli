(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** Bytestring is an alias for {!string} *)
type t = private string

val of_string : string -> t

val to_hex : t -> Hex.t

val of_hex : Hex.t -> t

val pp_hex : Format.formatter -> t -> unit

(** {2 Copy of {!String}} *)

val make : int -> char -> t

val init : int -> (int -> char) -> t

val empty : t

val of_bytes : bytes -> t

val to_bytes : t -> bytes

val length : t -> int

val get : t -> int -> char

val concat : t -> t list -> t

val cat : t -> t -> t

val equal : t -> t -> bool

val compare : t -> t -> int

val starts_with : prefix:t -> t -> bool

val ends_with : suffix:t -> t -> bool

val contains_from : t -> int -> char -> bool

val rcontains_from : t -> int -> char -> bool

val contains : t -> char -> bool

val sub : t -> int -> int -> t

val split_on_char : char -> t -> t list

val map : (char -> char) -> t -> t

val mapi : (int -> char -> char) -> t -> t

val fold_left : ('a -> char -> 'a) -> 'a -> t -> 'a

val fold_right : (char -> 'a -> 'a) -> t -> 'a -> 'a

val for_all : (char -> bool) -> t -> bool

val exists : (char -> bool) -> t -> bool

val trim : t -> t

val escaped : t -> t

val blit : t -> int -> bytes -> int -> int -> unit

val uppercase_ascii : t -> t

val lowercase_ascii : t -> t

val capitalize_ascii : t -> t

val uncapitalize_ascii : t -> t

val iter : (char -> unit) -> t -> unit

val iteri : (int -> char -> unit) -> t -> unit

val index_from : t -> int -> char -> int

val index_from_opt : t -> int -> char -> int option

val rindex_from : t -> int -> char -> int

val rindex_from_opt : t -> int -> char -> int option

val index : t -> char -> int

val index_opt : t -> char -> int option

val rindex : t -> char -> int

val rindex_opt : t -> char -> int option

val to_seq : t -> char Seq.t

val to_seqi : t -> (int * char) Seq.t

val of_seq : char Seq.t -> t

val get_utf_8_uchar : t -> int -> Uchar.utf_decode

val is_valid_utf_8 : t -> bool

val get_utf_16be_uchar : t -> int -> Uchar.utf_decode

val is_valid_utf_16be : t -> bool

val get_utf_16le_uchar : t -> int -> Uchar.utf_decode

val is_valid_utf_16le : t -> bool

val get_uint8 : t -> int -> int

val get_int8 : t -> int -> int

val get_uint16_ne : t -> int -> int

val get_uint16_be : t -> int -> int

val get_uint16_le : t -> int -> int

val get_int16_ne : t -> int -> int

val get_int16_be : t -> int -> int

val get_int16_le : t -> int -> int

val get_int32_ne : t -> int -> int32

val get_int32_be : t -> int -> int32

val get_int32_le : t -> int -> int32

val get_int64_ne : t -> int -> int64

val get_int64_be : t -> int -> int64

val get_int64_le : t -> int -> int64
