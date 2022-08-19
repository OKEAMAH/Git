(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

type (_, _) eq = Refl : ('a, 'a) eq

module type HashConsingInput = sig
  type 'a t
end

module type Constr1_Type = sig
  type t

  type v

  type 'a res

  val mk : t -> v res
end

module type Constr1 = sig
  type 'a t

  type ('a, 'b) witness

  type 'a res

  val mk : 'a t -> ('a, 'b) witness -> 'b res
end

module type Constr2 = sig
  type 'a t

  type ('a, 'b, 'c) witness

  type 'a res

  val mk : 'a t -> 'b t -> ('a, 'b, 'c) witness -> 'c res
end

module type HashConsing = sig
  type 'a id

  type 'a value

  type 'a t = private {id : 'a id; value : 'a value}

  val constant : 'a value -> 'a t

  module Parametric1_Type : functor
    (C : Constr1_Type with type 'a res := 'a value)
    ->
    Constr1_Type with type t := C.t and type v := C.v and type 'a res := 'a t

  module type Constr1 := Constr1 with type 'a t := 'a t

  module type Constr1_Input := sig
    include Constr1

    val witness_is_a_function :
      ('a, 'b1) witness -> ('a, 'b2) witness -> ('b1, 'b2) eq
  end

  module Parametric1 : functor
    (C : Constr1_Input with type 'a res := 'a value)
    ->
    Constr1
      with type ('a, 'b) witness := ('a, 'b) C.witness
       and type 'a res := 'a t

  module type Constr2 := Constr2 with type 'a t := 'a t

  module type Constr2_Input := sig
    include Constr2

    val witness_is_a_function :
      ('a, 'b, 'c1) witness -> ('a, 'b, 'c2) witness -> ('c1, 'c2) eq
  end

  module Parametric2 : functor
    (C : Constr2_Input with type 'a res := 'a value)
    ->
    Constr2
      with type ('a, 'b, 'c) witness := ('a, 'b, 'c) C.witness
       and type 'a res := 'a t
end

module HashConsing (V : HashConsingInput) :
  HashConsing with type 'a value := 'a V.t
