(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(** Module that implements Dac related functionalities. *)

type error +=
  | Reveal_data_path_not_a_directory of string
  | Cannot_create_reveal_data_dir of string

module Storage : sig
  (** [ensure_reveal_data_dir_exists reveal_data_dir] checks that the
      path at [reveal_data_dir] exists and is a directory. If
      the path does not exist, it is created as a directory.
      Parent directories are recursively created when they do not
      exist.

      This function may fail with
      {ul
        {li [Reveal_data_path_not_a_directory reveal_data_dir] if the
          path exists and is not a directory,

        {li [Cannot_create_reveal_data_dir reveal_data_dir] If the
            creation of the directory fails.}}
      }
  *)
  val ensure_reveal_data_dir_exists : string -> unit tzresult Lwt.t
end

val resolve_plugin :
  Tezos_shell_services.Chain_services.Blocks.protocols ->
  (module Dac_plugin.T) option Lwt.t
