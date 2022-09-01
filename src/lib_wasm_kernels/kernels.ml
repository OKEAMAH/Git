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

type t = string

module Test = struct
  let computation = "computation"

  let unreachable = "unreachable"
end

module Stable = struct end

(* Extracted from Tezt.Base, to avoid linking it directly. *)
let project_root =
  match Sys.getenv_opt "DUNE_SOURCEROOT" with
  | Some x -> x
  | None -> (
      match Sys.getenv_opt "PWD" with
      | Some x -> x
      | None ->
          (* For some reason, under [dune runtest], [PWD] and
             [getcwd] have different values. [getcwd] is in
             [_build/default], and [PWD] is where [dune runtest] was
             executed, which is closer to what we want. *)
          Sys.getcwd ())

let kernel_path (kernel : t) : string =
  Filename.(
    concat project_root (concat (Filename.dirname __FILE__) (kernel ^ ".wasm")))

let read_kernel kernel =
  let ic = open_in (kernel_path kernel) in
  let buffer = Buffer.create 512 in
  let bytes = Bytes.create 512 in
  let rec loop () =
    let len = input ic bytes 0 512 in
    if len > 0 then (
      Buffer.add_subbytes buffer bytes 0 len ;
      loop ())
  in
  loop () ;
  close_in ic ;
  Buffer.contents buffer
