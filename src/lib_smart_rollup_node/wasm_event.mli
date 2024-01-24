(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

(** [fast_exec_panicked ()] emits the event that the WASM Fast Execution has
    panicked and is falling back to the PVM. *)
val fast_exec_panicked : unit -> unit Lwt.t
