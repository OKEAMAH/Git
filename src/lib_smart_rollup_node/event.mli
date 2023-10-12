(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

(** This module defines functions that emit the events used when the smart
    rollup node is running (see {!Daemon}). *)

val starting_node : unit -> unit Lwt.t

val node_is_ready : rpc_addr:string -> rpc_port:int -> unit Lwt.t

(** [rollup_exists addr kind] emits the event that the smart rollup
    node is interacting with the rollup at address [addr] and of the given
    [kind]. *)
val rollup_exists : addr:Address.t -> kind:Kind.t -> unit Lwt.t

(** [shutdown_node exit_status] emits the event that the smart rollup
    node is stopping with exit status [exit_status]. *)
val shutdown_node : int -> unit Lwt.t

(** [starting_metrics_server ~metrics_addr ~metrics_port] emits the event
    that the metrics server for the rollup node is starting. *)
val starting_metrics_server : host:string -> port:int -> unit Lwt.t

(** [metrics_ended error] emits the event that the metrics server
    has ended with a failure. *)
val metrics_ended : string -> unit Lwt.t

(** [metrics_ended error] emits the event that the metrics server
    has ended with a failure.
    (Doesn't wait for event to be emited. *)
val metrics_ended_dont_wait : string -> unit

(** [kernel_debug str] emits the event that the kernel has logged [str]. *)
val kernel_debug : string -> unit Lwt.t

(** [simulation_kernel_debug str] emits the event that the kernel has logged
    [str] during a simulation. *)
val simulation_kernel_debug : string -> unit Lwt.t

(** [kernel_debug str] emits the event that the kernel has logged [str].
    (Doesn't wait for event to be emitted) *)
val kernel_debug_dont_wait : string -> unit

(** [warn_dal_enabled_no_node ()] emits a warning for when DAL is enabled in the
    protocol but the rollup node has no DAL node. *)
val warn_dal_enabled_no_node : unit -> unit Lwt.t

(** Emit event that the node is waiting for the first block of its protocol. *)
val waiting_first_block : Protocol_hash.t -> unit Lwt.t

(** Emit event that the node received the first block of its protocol. *)
val received_first_block : Block_hash.t -> Protocol_hash.t -> unit Lwt.t

(** Emit event that the node will shutdown because of protocol migration. *)
val detected_protocol_migration : unit -> unit Lwt.t

(** [acquiring_lock ()] emits an event to indicate that the node is attempting
    to acquire a lock on the data directory. *)
val acquiring_lock : unit -> unit Lwt.t

(** [calling_gc level] emits and event which indicates that a call to GC was
    made at [level]. *)
val calling_gc : int32 -> unit Lwt.t

(** [starting_gc hash] emits and event which indicates that a GC run
    was launched for [hash]. *)
val starting_gc : Smart_rollup_context_hash.t -> unit Lwt.t

(** [gc_already_launched ()] emits an event which indicates that a GC launch
    was attempted but resulted in no action because a GC run is already
    in progress. *)
val gc_already_launched : unit -> unit Lwt.t

(** [ending_gc total_duration finalise_duration] emits an event which indicates
    that a GC run has ended, providing its total duration and its finalisation
    duration. *)
val ending_gc : Ptime.span * Ptime.span -> unit Lwt.t

(** [gc_failure err] emits an event which indicates a GC failure. *)
val gc_failure : string -> unit Lwt.t

(** [gc_launch_failure err] emits an event which indicates a GC launch error. *)
val gc_launch_failure : string -> unit Lwt.t
