(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

let rec repeat n f =
  if n < 0 then ()
  else (
    f ();
    repeat (n - 1) f)

let must_fail f =
  let exception Local in
  try
    (try f () with _ -> raise Local);
    assert false
  with
  | Local -> ()
  | _ -> assert false

let file_mapping =
  let t = Hashtbl.create 17 in
  let rec loop path =
    List.iter
      (fun name ->
        let full = Filename.concat path name in
        if Sys.is_directory full then loop full else Hashtbl.add t name full)
      (Array.to_list (Sys.readdir path))
  in
  let test_vectors = [ "test_vectors"; "test/test_vectors" ] in
  List.iter (fun f -> if Sys.file_exists f then loop f) test_vectors;
  t

let open_file filename =
  let name =
    if Sys.file_exists filename then filename
    else
      match Hashtbl.find file_mapping filename with
      | exception _ ->
          failwith
            (Printf.sprintf
               "Cannot open %S, the file doesn't exists in test_vectors"
               filename)
      | f -> f
  in
  open_in_bin name
