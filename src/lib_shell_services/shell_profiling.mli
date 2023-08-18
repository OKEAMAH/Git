(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)
(** This file contains all helper functions to
    activate or deactivate a dedicated profiler.
    So far, only the RPC profiler is declared and enabled,
    but one can simply add a new profiler with corresponding
    helper functions. *)

(** All profilers available. *)
type profiler_name

(** Unplug the RPC profiler. *)
val rpc_server_profiler : Profiler.profiler

(** Unplug the requester profiler. *)
val requester_profiler : Profiler.profiler

(** Unplug the merge profiler. *)
val merge_profiler : Profiler.profiler

(** Unplug the block validator profiler. *)
val block_validator_profiler : Profiler.profiler

(** Unplug the store profiler. *)
val store_profiler : Profiler.profiler

(** Unplug the P2P reader profiler. *)
val p2p_reader_profiler : Profiler.profiler

(** Unplug the mempool profiler. *)
val mempool_profiler : Profiler.profiler

(** Unplug the chain validator profiler. *)
val chain_validator_profiler : Profiler.profiler

(** Return all the profilers name. *)
val all_profilers : (profiler_name * Profiler.profiler) trace

(** Get [string] representation of provided [profiler_name]. *)
val profiler_name_to_string : profiler_name -> string

(** Get [profiler_name] from provided [string], fails if unknwon. *)
val profiler_name_of_string : string -> profiler_name

(** [plug] all profilers of the previous list. *)
val activate_all :
  profiler_maker:(name:profiler_name -> Profiler.instance) -> unit

(** [close_and_unplug_all] all profilers of the previous list. *)
val deactivate_all : unit -> unit

(** [plug] Profiler based on provided name. *)
val activate :
  profiler_maker:(name:profiler_name -> Profiler.instance) ->
  profiler_name ->
  unit

(** [close_and_unplug_all] Profiler based on provided name. *)
val deactivate : profiler_name -> unit

val may_start_block : Block_hash.t -> unit

(** Start to log the for the provided [Profiler.driver] file format,
    inside the specified [data_dir],
    with the specified [profiler_name],
    and the provided [max_lod]. *)
val profiler_maker :
  string ->
  name:profiler_name ->
  'a ->
  (string * 'a) Profiler.driver ->
  Profiler.file_format ->
  Profiler.instance
