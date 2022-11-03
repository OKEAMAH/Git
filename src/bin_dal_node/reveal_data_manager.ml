(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili tech, <contact@trili.tech>                       *)
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

type error += Load_reveal_failed of string

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.load_reveal_page_failed"
    ~title:"Load reveal page failed"
    ~description:"Loading reveal page failed"
    ~pp:(fun ppf msg -> Format.fprintf ppf "%s" msg)
    Data_encoding.(obj1 (req "msg" string))
    (function Load_reveal_failed parameter -> Some parameter | _ -> None)
    (fun parameter -> Load_reveal_failed parameter)

let path data_dir b58_hash = Filename.(concat data_dir b58_hash)

let save_bytes data_dir b58_hash page_contents =
  let open Lwt_result_syntax in
  let+ page_contents = return page_contents in
  let path = path data_dir b58_hash in
  let cout = open_out path in
  output_bytes cout page_contents ;
  close_out cout

let load_file data_dir b58_hash =
  let open Lwt_result_syntax in
  Lwt.catch
    (fun () ->
      let+ path = return @@ path data_dir b58_hash in
      let cin = open_in path in
      let s = really_input_string cin (in_channel_length cin) in
      let b = Bytes.of_string s in
      close_in cin ;
      b)
    (fun _ -> tzfail @@ Load_reveal_failed b58_hash)

let ensure_dir_exists data_dir =
  if Sys.(file_exists data_dir) then (
    if not (Sys.is_directory data_dir) then
      Stdlib.failwith (data_dir ^ " should be a directory."))
  else Sys.mkdir data_dir 0o700
