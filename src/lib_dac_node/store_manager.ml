(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type error +=
  | Reveal_data_path_not_a_directory of string
  | Cannot_create_reveal_data_dir of string

let () =
  register_error_kind
    `Permanent
    ~id:"dac.node.dac.reveal_data_path_not_a_dir"
    ~title:"Reveal data path is not a directory"
    ~description:"Reveal data path is not a directory"
    ~pp:(fun ppf reveal_data_path ->
      Format.fprintf
        ppf
        "Reveal data path %s is not a directory"
        reveal_data_path)
    Data_encoding.(obj1 (req "path" string))
    (function Reveal_data_path_not_a_directory path -> Some path | _ -> None)
    (fun path -> Reveal_data_path_not_a_directory path) ;
  register_error_kind
    `Permanent
    ~id:"dac.node.dac.cannot_create_directory"
    ~title:"Cannot create directory to store reveal data"
    ~description:"Cannot create directory to store reveal data"
    ~pp:(fun ppf reveal_data_path ->
      Format.fprintf
        ppf
        "Cannot create a directory \"%s\" to store reveal data"
        reveal_data_path)
    Data_encoding.(obj1 (req "path" string))
    (function Cannot_create_reveal_data_dir path -> Some path | _ -> None)
    (fun path -> Cannot_create_reveal_data_dir path)

let ensure_reveal_data_dir_exists reveal_data_dir =
  let open Lwt_result_syntax in
  Lwt.catch
    (fun () ->
      let*! () = Lwt_utils_unix.create_dir ~perm:0o744 reveal_data_dir in
      return ())
    (function
      | Failure s ->
          if String.equal s "Not a directory" then
            tzfail @@ Reveal_data_path_not_a_directory reveal_data_dir
          else tzfail @@ Cannot_create_reveal_data_dir reveal_data_dir
      | _ -> tzfail @@ Cannot_create_reveal_data_dir reveal_data_dir)
