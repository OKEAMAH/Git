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
   two types can be only compared within Lwt.
   For now this module is used to compare reference and current implementations
   of durable storages.
   Also it will be handy when we replace CBV with immutable CBV
   for Durable.load_bytes.
*)
module type S = sig
  type a

  type b

  val to_string_a : a -> string Lwt.t

  val to_string_b : b -> string Lwt.t

  (* This one might be improved to return `(bool, string) result`
     to return where exactly values diverged.
  *)
  val eq : a -> b -> bool Lwt.t
end

type ('a, 'b) t = (module S with type a = 'a and type b = 'b)

(* Make {!Hetero_equality} for values of the same type  *)
module Make (X : sig
  type t

  val pp : t Fmt.t

  val eq : t -> t -> bool
end) : S with type a = X.t and type b = X.t = struct
  type a = X.t

  type b = X.t

  let to_string_a a = Lwt.return @@ Format.asprintf "%a" X.pp a

  let to_string_b = to_string_a

  let eq a b = Lwt.return @@ X.eq a b
end

(* Make {!Hetero_equality} from provided {!Hetero_equality} for ['t option] *)
module Make_option (Eq : S) :
  S with type a = Eq.a option and type b = Eq.b option = struct
  type a = Eq.a option

  type b = Eq.b option

  let to_string_option ~to_string x =
    let open Lwt_syntax in
    let opt_formatter = Fmt.option Fmt.string in
    match x with
    | None -> Lwt.return @@ Format.asprintf "%a" opt_formatter None
    | Some x ->
        let+ s = to_string x in
        Format.asprintf "%a" opt_formatter (Some s)

  let to_string_a = to_string_option ~to_string:Eq.to_string_a

  let to_string_b = to_string_option ~to_string:Eq.to_string_b

  let eq x_opt y_opt =
    match (x_opt, y_opt) with
    | None, None -> Lwt.return_true
    | Some x, Some y -> Eq.eq x y
    | _, _ -> Lwt.return_false
end

module Context_hash = Make (struct
  type t = Context_hash.t

  let pp = Context_hash.pp

  let eq = Context_hash.equal
end)

module Context_hash_option = Make_option (Context_hash)

module Int = Make (struct
  type t = int

  let pp = Fmt.int

  let eq = ( = )
end)

module String_list = Make (struct
  type t = string list

  let pp = Fmt.list ~sep:Fmt.semi Fmt.string

  let eq = List.equal String.equal
end)

module String = Make (struct
  type t = string

  let pp = Fmt.string

  let eq = String.equal
end)

module Unit = Make (struct
  type t = unit

  let pp fmt () = Format.fprintf fmt "unit"

  let eq _ _ = true
end)
