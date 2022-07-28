(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** Shard representation for the data-availability layer. *)

module Index : sig
  type t

  val encoding : t Data_encoding.t

  val pp : Format.formatter -> t -> unit

  val zero : t

  val max_value : t

  (** [of_int n] constructs a`Dal_shard_repr.Index.t`
      May fail with:
     {ul
       {li [Dal_invalid_slot_header n] if [n] is either negative or greater than [max_slot_value].}
     }
    *)
  val of_int : int -> t option

  val to_int : t -> int

  val compare : t -> t -> int

  val ( >= ) : t -> t -> bool

  val ( <= ) : t -> t -> bool

  val ( > ) : t -> t -> bool

  val ( < ) : t -> t -> bool

  val add_int : t -> int -> t Option.t

  val max : t -> t -> t

  val min : t -> t -> t

  val ( --> ) : t -> t -> t list
end
