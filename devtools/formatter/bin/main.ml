(******************************************************************************)
(*                                                                            *)
(* Open Source License                                                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                 *)
(*                                                                            *)
(* Permission is hereby granted, free of charge, to any person obtaining a    *)
(* copy of this software and associated documentation files (the "Software"), *)
(* to deal in the Software without restriction, including without limitation  *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,   *)
(* and/or sell copies of the Software, and to permit persons to whom the      *)
(* Software is furnished to do so, subject to the following conditions:       *)
(*                                                                            *)
(* The above copyright notice and this permission notice shall be included    *)
(* in all copies or substantial portions of the Software.                     *)
(*                                                                            *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR *)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER *)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        *)
(* DEALINGS IN THE SOFTWARE.                                                  *)
(*                                                                            *)
(******************************************************************************)

open Xtdlib
open Fmt
open Config

let format_file_with_format ~get_och ~format ~cc ich =
  let lines = Seq.of_in_channel_with_ln_and_offset ich in
  let parsed, rem_lines = Parser.parse ~cc ~format lines in
  assert (Seq.uncons rem_lines = None) ;
  let och, close_all = get_och () in
  let pf = Printer.default_printer och in
  Printer.print ~cc ~pf format parsed ;
  close_all ich

let format_file file ~get_och =
  match format file with
  | Ignore -> Format.eprintf "Ignoring %s\n" file
  | Format_header format ->
      Format.eprintf "Formatting header of %s...\n" file ;
      let format =
        let start_line = start_line file in
        F.(Copy (start_line - 1) :: format :: CopyAll :: EndOfFile)
      in
      let cc =
        let start, end_ = comment_start_end file in
        let comment_line_length = comment_line_length file in
        let fill = start.[String.length start - 1] in
        Parser.{comment_line_length; start; end_; fill}
      in
      let ich = open_in file in
      format_file_with_format ~get_och ~format ~cc ich

let format_file file =
  let get_och () =
    let prefix = "octez" in
    let suffix = "fmt" in
    let temp, och = Filename.open_temp_file prefix suffix in
    let close_all ich =
      flush och ;
      close_out och ;
      close_in ich ;
      Sys.rename temp file
    in
    (och, close_all)
  in
  format_file file ~get_och

let readdir_recursive_git_ignore =
  let mk_rec_ignore ~ignore path files =
    if Array.mem ".gitignore" files then
      let git_ignore_path = Filename.concat path ".gitignore" in
      let more_ignore = Config_helpers.mk_git_ignore git_ignore_path in
      fun path -> ignore path || more_ignore path
    else ignore
  in
  Seq.readdir_recursive ~mk_rec_ignore

let format_path path =
  if not (Sys.file_exists path) then (
    Format.eprintf "File %s does not exist." path ;
    exit 1) ;
  let files = readdir_recursive_git_ignore ~ignore path in
  Seq.iter format_file files

let () =
  match Sys.argv with
  | [||] -> failwith "Unexpected empty argv!"
  | [|_|] -> failwith "Expected a path"
  | paths -> paths |> Array.to_seq |> Seq.drop 1 |> Seq.iter format_path
