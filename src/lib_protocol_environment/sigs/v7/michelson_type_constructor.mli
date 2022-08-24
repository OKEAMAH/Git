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

(** This module is used in the script_typed_ir file. It's useful to look at 
    this file for a better understanding of how Michelson_type_constructor 
    works. The structure of the Michelson_type_constructor module is written 
    in environment_V7.ml . *)

type (_, _) eq = Refl : ('a, 'a) eq

(** [HashConsingInupt] will serve as input for the HashConsing functor. It's 
    types t and s will serve as value in [HashConsing]. In Michelson types and 
    stacks hash consing, t and s will represent types and stacks values. *)
module type HashConsingInput = sig
  type 'a t

  type 'a s
end

(** All the Constr_Base modules will serve as base for the Constr module format 
    in [HashConsing]. *)

(** [Constr1_Type_Base] is the base module for what is needed when creating an
    instance of a Michelson type that takes an argument of type t to make a
    v res type.
    For example, we use it for the Sapling_transaction Michelson type : type
    t would be Sapling.Memo_size.t (equivalent to int), type v would be 
    Sapling.transaction * no and type 'a res would be 'a Ty_value.t . *)
module type Constr1_Type_Base = sig
  type t

  type v

  type 'a res

  val mk : t -> v res
end

(** [Constr1_Base] is the base module for what is needed when creating an
    instance of a Michelson type that takes as argument a Michelson type 
    represented by the type 'a t to make a 'b res type.
    For example, we use it for the option Michelson type : type
    'a t would be 'a Ty.t and type 'a res would be 'a Ty_value.t . 
    So where do we write that we want an option Michelson type in output ?

    For that, we use the witness type that will be used in the next Constr_Base 
    modules. The witness type will here serve as a witness to ensure that we have 
    the correct syntax for our input and output types. It enables us to make a 
    safe link between 'a and 'b in the mk function. 
    
    Back to our option example, we would write 
          type (_, _) witness =
            | W : 'a option ty_metadata -> ('a * 'ac, 'a option * 'ac) witness
    In this example, type witness has a tripple role :
      - to make sure we give a ('a * 'ac) Ty.t input, 'ac representing whether 
            the input is comparable or not, which is needed in Michelson types;
      - to make sure that the output type will indeed be an option Michelson type
            and that it will have the correct comparability;
      - to store the information of the output type metadata that will be needed
            for its creation. *)
module type Constr1_Base = sig
  type 'a t

  type ('a, 'b) witness

  type 'a res

  val mk : 'a t -> ('a, 'b) witness -> 'b res
end

(** [Constr2_Base] is the base module for what is needed when creating an
    instance of a Michelson type that takes as argument two Michelson types
    represented by the type 'a t to make a 'c res type.
    For example, we use it for the pair Michelson type : type
    'a t would be 'a Ty.t, type 'a res would be 'a Ty_value.t and for the witness :
          type (_, _, _) witness =
            | W : ('a, 'b) pair ty_metadata * ('ac, 'bc, 'rc) dand
              -> ('a * 'ac, 'b * 'bc, ('a, 'b) pair * 'rc) witness
    ( The dand type being needed for the output pair comparability. ). *)
module type Constr2_Base = sig
  type 'a t

  type ('a, 'b, 'c) witness

  type 'a res

  val mk : 'a t -> 'b t -> ('a, 'b, 'c) witness -> 'c res
end

(** [Constr_Stack_Base] is the base module for what is needed when creating an
    instance of a Michelson stack that takes as argument a Michelson type 
    represented by the type 'a t and a Michelson stack represented by the type 'a s.
    To create a stack : type 'a t would be 'a Ty.t, type 'a s would be 'a Ty.s, type 
    'a res would be 'a Ty_value.s and for the witness : 
          type (_, _, _) witness =
            | W : ('a * _, 'top * 'rest, 'a * ('top * 'rest)) witness    *)
module type Constr_Stack_Base = sig
  type 'a t

  type 'a s

  type ('a, 'b, 'c) witness

  type 'a res

  val mk : 'a t -> 'b s -> ('a, 'b, 'c) witness -> 'c res
end

(** [HashConsing] is the core of the Michelson types and stacks hash consing. The types
    will be represented as type 'a t and the stacks as type 'a s. Those two types have 
    both two fields :
      - the id field : it will give an unique identification for each Michelson type and
            stack instance to test the types and stacks equality in constant time;
      - the value field : store the value of the Michelson type or stack. 
    Here we will use 'a Equality_witness.t as 'a id. *)
module type HashConsing = sig
  type 'a id

  module Value : HashConsingInput

  type 'a t = private {id : 'a id; value : 'a Value.t}

  type 'a s = private {id : 'a id; value : 'a Value.s}

  (** The constant functions will be used to create Michelson types and stacks instances
      that don't need any Michelson type or stack arguments and that can be created only 
      with a value.
      For example, we use it for the unit Michelson type or for the bot Michelson stack. *)
  val constant_t : 'a Value.t -> 'a t

  val constant_s : 'a Value.s -> 'a s

  (** The Parametric modules will be used to create Michelson types and stacks instances
      that need Michelson type or stack arguments. 
      Each module corresponds to a case that we describe above. 
      
      We also have to add a witness_is_a_function function in Parametric modules input 
      to ensure the output type equality if we have the same input type. *)
  module Parametric1_Type : functor
    (C : Constr1_Type_Base with type 'a res := 'a Value.t)
    ->
    Constr1_Type_Base
      with type t := C.t
       and type v := C.v
       and type 'a res := 'a t

  module type Constr1 = Constr1_Base with type 'a t := 'a t

  module type Constr1_Input = sig
    include Constr1

    val witness_is_a_function :
      ('a, 'b1) witness -> ('a, 'b2) witness -> ('b1, 'b2) eq
  end

  module Parametric1 : functor
    (C : Constr1_Input with type 'a res := 'a Value.t)
    ->
    Constr1
      with type ('a, 'b) witness := ('a, 'b) C.witness
       and type 'a res := 'a t

  module type Constr2 = Constr2_Base with type 'a t := 'a t

  module type Constr2_Input = sig
    include Constr2

    val witness_is_a_function :
      ('a, 'b, 'c1) witness -> ('a, 'b, 'c2) witness -> ('c1, 'c2) eq
  end

  module Parametric2 : functor
    (C : Constr2_Input with type 'a res := 'a Value.t)
    ->
    Constr2
      with type ('a, 'b, 'c) witness := ('a, 'b, 'c) C.witness
       and type 'a res := 'a t

  module type Constr_Stack =
    Constr_Stack_Base with type 'a t := 'a t and type 'a s := 'a s

  module type Constr_Stack_Input = sig
    include Constr_Stack

    val witness_is_a_function :
      ('a, 'b, 'c1) witness -> ('a, 'b, 'c2) witness -> ('c1, 'c2) eq
  end

  module Parametric_Stack : functor
    (C : Constr_Stack_Input with type 'a res := 'a Value.s)
    ->
    Constr_Stack
      with type ('a, 'b, 'c) witness := ('a, 'b, 'c) C.witness
       and type 'a res := 'a s
end

module HashConsing (V : HashConsingInput) : HashConsing with module Value := V
