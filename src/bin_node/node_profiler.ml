(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023, Marigold <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)

let parse_profiling_env_var () =
  match Sys.getenv_opt "PROFILING" with
  | None -> (None, None)
  | Some var -> (
      match String.split_on_char ':' var with
      | [] -> (None, None)
      | [x] -> (Some (String.lowercase_ascii x), None)
      | x :: l ->
          let output_dir = String.concat "" l in
          if not (Sys.file_exists output_dir && Sys.is_directory output_dir)
          then
            Stdlib.failwith
              "Profiling output is not a directory or does not exist."
          else (Some (String.lowercase_ascii x), Some output_dir))

let get_profiler_options profiling_env_car (config : Config_file.t) =
  match profiling_env_car with
  | None, _ -> None
  | ( Some (("true" | "on" | "yes" | "terse" | "detailed" | "verbose") as mode),
      output_dir ) ->
      let max_lod =
        match mode with
        | "detailed" -> Profiler.Detailed
        | "verbose" -> Profiler.Verbose
        | _ -> Profiler.Terse
      in
      let output_dir =
        match output_dir with
        | None -> config.data_dir
        | Some output_dir -> output_dir
      in
      let file_format =
        match Sys.getenv_opt "PROFILING_FORMAT" with
        | None -> Tezos_base.Profiler.Plain_text
        | Some var -> (
            match var with
            | "txt" -> Tezos_base.Profiler.Plain_text
            | "json" -> Tezos_base.Profiler.Json
            | _ -> Tezos_base.Profiler.Plain_text)
      in
      Some (max_lod, output_dir, file_format)
  | _ -> None
