(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(* A set of definitions borrowed from Tezt's [lib_core/base.ml] *)

let sf = Format.asprintf

let ( // ) = Filename.concat

module String_set = Set.Make (String)
module String_map = Map.Make (String)

let with_open_out file write_f =
  let chan = open_out file in
  try
    write_f chan ;
    close_out chan
  with x ->
    close_out chan ;
    raise x

let with_open_in file read_f =
  let chan = open_in file in
  try
    let value = read_f chan in
    close_in chan ;
    value
  with x ->
    close_in chan ;
    raise x

let read_lines_from_file path =
  with_open_in path @@ fun ch ->
  let rec loop acc =
    match input_line ch with
    | exception End_of_file -> List.rev acc
    | line -> loop (line :: acc)
  in
  loop []

let write_file filename ~contents =
  with_open_out filename @@ fun ch -> output_string ch contents

let project_root =
  match Sys.getenv_opt "DUNE_SOURCEROOT" with
  | Some x -> x
  | None -> (
      match Sys.getenv_opt "PWD" with
      | Some x -> x
      | None ->
          (* For some reason, under [dune runtest], [PWD] and
             [getcwd] have different values. [getcwd] is in
             [_build/default], and [PWD] is where [dune runtest] was
             executed, which is closer to what we want. *)
          Sys.getcwd ())

let write_yaml ?(header = "") filename yaml =
  let contents =
    header
    ^
    match Yaml.(to_string ~encoding:`Utf8 ~scalar_style:`Plain yaml) with
    | Ok s -> s
    | Error (`Msg error_msg) ->
        failwith
          ("Could not convert JSON configuration to YAML string: " ^ error_msg)
  in
  write_file filename ~contents
