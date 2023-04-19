(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Lang_core
open Lang_stdlib

module type PARAMETERS = sig
  val modulus : Z.t

  val base : Z.t

  val nb_limbs : int

  (* Assert that base^nb_limbs >= modulus *)

  val setM : Z.t list
end

module type MOD_ARITH = functor (L : LIB) -> sig
  open L

  type mod_int

  val modulus : Z.t

  val input_mod_int : ?kind:input_kind -> S.t list -> mod_int repr t

  val add : mod_int repr -> mod_int repr -> mod_int repr t

  val mul : mod_int repr -> mod_int repr -> mod_int repr t

  val neg : mod_int repr -> mod_int repr t

  (* val of_z : Z.t -> mod_int *)

  (* val to_z : mod_int -> Z.t *)
end

module Make (Params : PARAMETERS) : MOD_ARITH =
functor
  (L : LIB)
  ->
  struct
    open L

    type mod_int = scalar list

    let modulus = Params.modulus

    let input_mod_int ?(kind = `Private) n =
      assert (List.length n = Params.nb_limbs) ;
      (* TODO: add range check assertions on the limbs *)
      Input.(list @@ List.map scalar n) |> input ~kind

    let add = Mod_arith.add

    let mul = failwith "TODO"

    let neg = failwith "TODO"

    (* let _ = Utils.z_to_base ~base:Params.base n |> List.map S.of_z *)
  end
