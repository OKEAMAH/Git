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

val pp_hex : Format.formatter -> t -> unit

(** {2 Copy of {!String}} *)

val length : t -> int

val get : t -> int -> char

val init : int -> (int -> char) -> t

val sub : t -> int -> int -> t

val blit : t -> int -> bytes -> int -> int -> unit

val concat : t -> t list -> t

val iter : (char -> unit) -> t -> unit

val iteri : (int -> char -> unit) -> t -> unit

val map : (char -> char) -> t -> t

val mapi : (int -> char -> char) -> t -> t

val trim : t -> t

val escaped : t -> t

val index_opt : t -> char -> int option

val rindex_opt : t -> char -> int option

val index_from_opt : t -> int -> char -> int option

val rindex_from_opt : t -> int -> char -> int option

val contains : t -> char -> bool

val contains_from : t -> int -> char -> bool

val rcontains_from : t -> int -> char -> bool

val uppercase_ascii : t -> t

val lowercase_ascii : t -> t

val capitalize_ascii : t -> t

val uncapitalize_ascii : t -> t

val compare : t -> t -> int

val equal : t -> t -> bool

val split_on_char : char -> t -> t list

val of_bytes : bytes -> t

val to_bytes : t -> bytes
