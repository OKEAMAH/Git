(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023, Marigold <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)

(** Parse the [PROFILING] envrionment variable. *)
val parse_profiling_env_var : unit -> string option * string option

(** Retrieve the [max_lod], [output_dir] and [file_format]
    which are necessary to setup the profiler(s). *)
val get_profiler_options :
  string option * string option ->
  Config_file.t ->
  (Profiler.lod * string * Profiler.file_format) option
