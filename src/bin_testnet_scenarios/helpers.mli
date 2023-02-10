(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

open Tezt
open Tezt_tezos

(** [download ?runner url filename] downloads the file at [url],
    stores it in a temporary file named [filename], and returns the
    complete path to the downloaded file. *)
val download : ?runner:Runner.t -> string -> string -> string Lwt.t

(** [wait_for_funded_key node client amount key] will not return
    before [key] has been funded with [amount] tez. *)
val wait_for_funded_key :
  Node.t -> Client.t -> Tez.t -> Account.key -> unit Lwt.t

(** [setup_octez_node ?runner snapshot_path] setups a new Octez node
    from the snapshot stored at [snapshot_path], and waits for it to be
    bootstrapped. *)
val setup_octez_node : ?runner:Runner.t -> string -> (Client.t * Node.t) Lwt.t

val deploy : runner:Runner.t -> ?r:bool -> string -> string -> unit Lwt.t
