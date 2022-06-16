(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

module Make (T : Sigs.TreeS) : sig
  type nonrec 'a result = ('a, string) result

  type tree = T.tree

  type 'a decoder = tree -> 'a option result Lwt.t

  type 'a encoder = tree -> string list -> 'a -> tree Lwt.t

  module Schema : sig
    type !'a t

    val encoding : 'a Data_encoding.t -> 'a t

    val lift : 'a encoder -> 'a decoder -> 'a t

    type !'a field

    val folders : string list -> 'a t -> 'a t

    val req : string -> 'a t -> 'a field

    val obj2 : 'a field -> 'b field -> ('a * 'b) t

    val obj3 : 'a field -> 'b field -> 'c field -> ('a * 'b * 'c) t

    val map : ('a -> string) -> 'b t -> ('a -> 'b) t
  end

  type 'a schema = 'a Schema.t

  type !'a t

  type 'a thunk = 'a t

  val decode : 'a schema -> tree -> 'a thunk

  val encode : tree -> 'a thunk -> tree Lwt.t

  val find : 'a thunk -> 'a option result Lwt.t

  val get : 'a thunk -> 'a result Lwt.t

  val set : 'a thunk -> 'a -> unit result Lwt.t

  val cut : 'a thunk -> unit result Lwt.t

  type ('a, 'b) lens = 'a thunk -> 'b thunk result Lwt.t

  val ( ^. ) : ('a, 'b) lens -> ('b, 'c) lens -> ('a, 'c) lens

  val tup2_0 : ('a * 'b, 'a) lens

  val tup2_1 : ('a * 'b, 'b) lens

  val tup3_0 : ('a * 'b * 'c, 'a) lens

  val tup3_1 : ('a * 'b * 'c, 'b) lens

  val tup3_2 : ('a * 'b * 'c, 'c) lens

  val entry : 'a -> ('a -> 'b, 'b) lens

  module Lazy_list : sig
    type !'a t

    val schema : 'a schema -> 'a t schema

    val length : 'a t thunk -> int32 result Lwt.t

    val nth : check:bool -> int32 -> ('a t, 'a) lens

    val alloc_cons : 'a t thunk -> (int32 * 'a thunk) result Lwt.t

    val cons : 'a t thunk -> 'a -> int32 result Lwt.t
  end
end
