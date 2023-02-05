(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
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

(* TODO move this module to some common lib *)

module Seq = struct
  include Seq

  (** [min_by lt seq] is the minimum element in [seq] based on the partial order [lt]
      "lt a b" means "a is less than b"
    *)
  let min_by (lt : 'a -> 'a -> bool) (seq : 'a Seq.t) : 'a option =
    Seq.fold_left
      (fun acc x ->
        match acc with
        | None -> Some x
        | Some min -> if lt x min then Some x else acc)
      None
      seq
end

module Lwt_mvar = struct
  include Lwt_mvar

  let use (mvar : 'a t) (f : 'a -> ('a * 'r) Lwt.t) : 'r Lwt.t =
    let open Lwt.Syntax in
    let* content = Lwt_mvar.take mvar in
    let* content, result = f content in
    let* () = Lwt_mvar.put mvar content in
    Lwt.return result
end

module Option = struct
  include Option

  let or_else opt2 opt1 = match opt1 with None -> opt2 | _ -> opt1
end
