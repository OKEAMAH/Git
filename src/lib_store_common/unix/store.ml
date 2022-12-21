(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

type error += Missing_stored_data of string

let () =
  Error_monad.register_error_kind
    `Permanent
    ~id:"store-common-unix.missing_stored_data"
    ~title:"Missing stored data"
    ~description:"Failed to load stored data"
    ~pp:(fun ppf path ->
      Format.fprintf
        ppf
        "Failed to load on-disk data: no corresponding data found in file %s."
        path)
    Data_encoding.(obj1 (req "path" string))
    (function Missing_stored_data path -> Some path | _ -> None)
    (fun path -> Missing_stored_data path)

type _ t =
  | Stored_data : {
      mutable cache : 'a;
      file : (_, 'a) File.t;
      scheduler : Lwt_idle_waiter.t;
    }
      -> 'a t

let read_json_file file =
  let open Lwt_syntax in
  let open File in
  Option.catch_os (fun () ->
      let* r = Lwt_utils_unix.Json.read_file file.path in
      match r with
      | Ok json ->
          Lwt.return_some (Data_encoding.Json.destruct file.encoding json)
      | _ -> Lwt.return_none)

let read_file file =
  let open File in
  Lwt.try_bind
    (fun () -> Lwt_utils_unix.read_file file.path)
    (fun str ->
      Lwt.return (Data_encoding.Binary.of_string_opt file.encoding str))
    (fun _ -> Lwt.return_none)

let get (Stored_data v) =
  Lwt_idle_waiter.task v.scheduler (fun () -> Lwt.return v.cache)

let write_file file data =
  let open Lwt_syntax in
  let open File in
  protect (fun () ->
      let encoder data =
        if file.json then
          Data_encoding.Json.construct file.encoding data
          |> Data_encoding.Json.to_string
        else Data_encoding.Binary.to_string_exn file.encoding data
      in
      let str = encoder data in
      let+ result =
        Lwt_utils_unix.with_atomic_open_out file.path (fun fd ->
            Lwt_utils_unix.write_string fd str)
      in
      Result.bind_error result Lwt_utils_unix.tzfail_of_io_error)

let write (Stored_data v) data =
  Lwt_idle_waiter.force_idle v.scheduler (fun () ->
      if v.cache = data then Lwt_result_syntax.return_unit
      else (
        v.cache <- data ;
        write_file v.file data))

let create file data =
  let open Lwt_result_syntax in
  let file = file in
  let scheduler = Lwt_idle_waiter.create () in
  let* () = write_file file data in
  return (Stored_data {cache = data; file; scheduler})

let update_with (Stored_data v) f =
  let open Lwt_syntax in
  Lwt_idle_waiter.force_idle v.scheduler (fun () ->
      let* new_data = f v.cache in
      if v.cache = new_data then return_ok_unit
      else (
        v.cache <- new_data ;
        write_file v.file new_data))

let load file =
  let open Lwt_result_syntax in
  let open File in
  let*! o = if file.json then read_json_file file else read_file file in
  match o with
  | Some cache ->
      let scheduler = Lwt_idle_waiter.create () in
      return (Stored_data {cache; file; scheduler})
  | None -> tzfail (Missing_stored_data file.path)

let init file ~initial_data =
  let open Lwt_syntax in
  let open File in
  let* b = Lwt_unix.file_exists file.path in
  match b with true -> load file | false -> create file initial_data
