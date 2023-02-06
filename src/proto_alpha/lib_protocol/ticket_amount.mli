(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
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

open Script_int

(* A type for ticket amount values to ensure positivity of non-legacy
   ticket amounts. *)
type t = private n num

val encoding : t Data_encoding.t

(* Converts a natural number to a ticket amount value. Retuns [None]
   when the argument is [0] and the [legacy] flag is [false]. *)
val of_n : legacy:bool -> n num -> t option

(* Converts a integral number to a ticket amount value.  If the
   [legacy] flag is [true] then this returns [None] on negative (< 0)
   arguments.  If the [legacy] flag is [false] then this returns
   [None] on non-positive (<= 0) arguments. *)
val of_z : legacy:bool -> z num -> t option

val of_zint : legacy:bool -> Z.t -> t option

val add : t -> t -> t

(* Subtract among ticket amount values unless the resultant amount is not positive (when [legacy] is t *)
val sub : legacy:bool -> t -> t -> t option

val one : t
