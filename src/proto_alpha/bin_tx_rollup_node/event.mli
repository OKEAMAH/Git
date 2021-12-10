(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2021 Marigold, <team@marigold.dev>                          *)
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

(** Event emitted when the configuration has been written. *)
val configuration_written :
  into:string -> config:Configuration.t -> unit tzresult Lwt.t

(** Event emitted when the node is starting. *)
val starting_node : unit -> unit tzresult Lwt.t

(** Event emitted when the node is ready. *)
val node_is_ready : rpc_addr:string -> rpc_port:int -> unit tzresult Lwt.t

(** Event emitted when the node is shutting down. *)
val node_is_shutting_down : exit_status:int -> unit Lwt.t

(** Event emitted when the node is not reachable. *)
val cannot_connect : delay:float -> unit Lwt.t

(** Event emitted when the connection to the node is lost. *)
val connection_lost : unit -> unit Lwt.t

val ping : unit -> unit Lwt.t
