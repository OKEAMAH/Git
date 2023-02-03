(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech  <contact@trili.tech>                        *)
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

(* This module represents comparison between two different types,
   which might be compared.
   Also it's useful for cases when
   two types can only be compared within Lwt.
   For now this module is used to compare Snapshotted and Current
   durable storages.
   Also it will be handy when we replace CBV with immutable CBV
   for Durable.load_bytes.
*)
module type S = sig
  type a

  type b

  val pp_a : Format.formatter -> a -> unit

  val pp_b : Format.formatter -> b -> unit

  (* This one might be improved to return `(bool, string) result`
     to return where exactly values diverged.
  *)
  val eq : a -> b -> bool Lwt.t
end

type ('a, 'b) t = (module S with type a = 'a and type b = 'b)

(* Make Hetero_equality.t for values of the same type  *)
let make (type x) ~pp ~(eq : x -> x -> bool) : (x, x) t =
  (module struct
    type a = x

    type b = x

    let pp_a = pp

    let pp_b = pp

    let eq a b = Lwt.return @@ eq a b
  end)

(* Make (t Option.t) Hetero_equality.t for option having t Hetero_equality.t *)
let make_option (type x y) ((module Eq) : (x, y) t) : (x Option.t, y Option.t) t
    =
  (module struct
    type a = x Option.t

    type b = y Option.t

    let pp_a fmt a = Format.fprintf fmt "%a" (Fmt.option Eq.pp_a) a

    let pp_b fmt b = Format.fprintf fmt "%a" (Fmt.option Eq.pp_b) b

    let eq x_opt y_opt =
      match (x_opt, y_opt) with
      | None, None -> Lwt.return_true
      | Some x, Some y -> Eq.eq x y
      | _, _ -> Lwt.return_false
  end)
