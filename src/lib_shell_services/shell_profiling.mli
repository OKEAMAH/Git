(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
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

(** This file contains all helper functions to
    activate or deactivate a dedicated profiler.
    So far, only the RPC profiler is declared and enabled,
    but one can simply add a new profiler with corresponding
    helper functions. *)

(** All profilers available. *)
type profiler_name =
  | Rpc_server
  | Mempool
  | Store
  | Chain_validator
  | Block_validator
  | Merge
  | P2p_reader
  | Requester

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
  Profiler.file_format * (string * 'a) Profiler.driver ->
  Profiler.instance
