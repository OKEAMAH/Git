(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

module Table = Hashtbl.Make (Namespace)
include Namespace

let of_namespace s = Namespace.of_string (Namespace.basename s)

let to_namespace t = t

let update t model_name =
  let ns =
    match List.rev @@ Namespace.to_list model_name with
    | [] | ["."] | _ :: [] ->
        Format.eprintf "Error: %a %a\n" Namespace.pp model_name pp t ;
        exit 1
    | x :: "intercept" :: xs when String.ends_with ~suffix:"__model" x ->
        x :: xs
    | "intercept" :: xs -> xs
    | x :: xs when String.ends_with ~suffix:"__model" x -> xs
    | xs -> xs
  in
  let name = String.concat "/" (List.rev ns) |> Namespace.of_string in
  Namespace.cons
    (Namespace.of_string @@ Namespace.basename name)
    (Namespace.basename t)

module Set = struct
  include Set

  let pp_sep s ppf () = Format.fprintf ppf "%s@;" s

  let pp fmtr set =
    let open Format in
    let elts = elements set in
    fprintf fmtr "{ @[<hv>%a@] }" (pp_print_list ~pp_sep:(pp_sep ";") pp) elts
end

module Sparse_vec = Sparse_vec.Make (Map)

module For_open = struct
  let fv s = Namespace.of_string s
end
