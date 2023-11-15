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

module IntMap = Map.Make (Int)
(** Reads [len] bytes from descriptor [file_descr], storing them in
    byte sequence [buffer], starting at position [offset] in [file_descr].*)
let read_file file_descr buffer ~offset ~len =
  (* Printf.printf "\nroffset : %d\nrlen : %d\n" offset len ; *)
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.read file_descr buffer 0 len in
  (* Printf.printf "\ni = %d\n" i ; *)
  assert (i = len)

(** Writes [len] bytes to descriptor [file_descr], taking them from
        byte sequence [buffer], starting at position [offset] in [file_descr].*)
let write_file file_descr buffer ~offset ~len =
  (* Printf.printf "\nwoffset : %d\nwlen : %d\n" offset len ; *)
  assert (Bytes.length buffer = len) ;
  let i = Unix.lseek file_descr offset Unix.SEEK_SET in
  assert (i = offset) ;
  let i = Unix.write file_descr buffer 0 len in
  assert (i = len)

module type Vector_commitment = sig

  type leaves
  type tree
  (* diff or new values depending on the tree *)
  type update

  module Parameters : sig
    val log_nb_cells : int
  end

  (* very bad name *)
  val commit_storage : string -> leaves -> unit

  val read_storage : string -> tree

  val print_storage : string -> unit

  val create_update : int -> update

  val update_commit : string -> update -> unit

  val generate_leaves : unit -> leaves
  val update_leaves : leaves -> update -> unit

end