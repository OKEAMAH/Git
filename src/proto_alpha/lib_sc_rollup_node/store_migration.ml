(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

open Store_version

let messages_store_location ~storage_dir =
  let open Filename.Infix in
  storage_dir // "messages"

let version_of_unversionned_store ~storage_dir =
  let open Lwt_syntax in
  let path = messages_store_location ~storage_dir in
  let* messages_store_v0 = Store_v0.Messages.load ~path ~cache_size:1 Read_only
  and* messages_store_v1 =
    Store_v1.Messages.load ~path ~cache_size:1 Read_only
  in
  let cleanup () =
    let open Lwt_syntax in
    let* (_ : unit tzresult) =
      match messages_store_v0 with
      | Error _ -> Lwt.return_ok ()
      | Ok s -> Store_v0.Messages.close s
    and* (_ : unit tzresult) =
      match messages_store_v1 with
      | Error _ -> Lwt.return_ok ()
      | Ok s -> Store_v1.Messages.close s
    in
    return_unit
  in
  let guess_version () =
    let open Lwt_result_syntax in
    match (messages_store_v0, messages_store_v1) with
    | Ok _, Error _ -> return_some V0
    | Error _, Ok _ -> return_some V1
    | Ok _, Ok _ ->
        (* Empty store, both loads succeed *)
        return_none
    | Error _, Error _ ->
        failwith
          "Cannot determine unversionned store version (no messages decodable)"
  in
  Lwt.finalize guess_version cleanup

let version_of_store ~storage_dir =
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/5554
     Use store version information when available. *)
  version_of_unversionned_store ~storage_dir

module V0_to_V1 = struct
  let tmp_dir ~storage_dir =
    Filename.concat
      (Configuration.default_storage_dir storage_dir)
      "migration_v0_v1"

  let migrate ~storage_dir =
    let open Lwt_result_syntax in
    let tmp_dir = tmp_dir ~storage_dir in
    let*! tmp_dir_exists = Lwt_utils_unix.dir_exists tmp_dir in
    let*? () =
      if tmp_dir_exists then
        error_with
          "Store migration (from v0 to v1) is already ongoing. Wait for it to \
           finish or remove %S and restart."
          tmp_dir
      else Ok ()
    in
    let*! () = Lwt_utils_unix.create_dir tmp_dir in
    let cleanup () =
      let open Lwt_syntax in
      (* Don't remove migration dir to allow for later resume. *)
      return_unit
    in
    let run_migration () =
      let*! () = Lwt_utils_unix.remove_dir tmp_dir in
      return_unit
    in
    Lwt.finalize run_migration cleanup
end

let maybe_run_migration ~storage_dir =
  let open Lwt_result_syntax in
  let* current_version = version_of_store ~storage_dir in
  let last_version = Store.version in
  match (current_version, last_version) with
  | None, _ ->
      (* Store not initialized, nothing to do *)
      return_unit
  | Some current, last when last = current ->
      (* Up to date, nothing to do *)
      return_unit
  | Some V0, V1 ->
      Format.printf "Migrating store from v0 to v1@." ;
      let+ () = V0_to_V1.migrate ~storage_dir in
      Format.printf "Migrating completed@."
  | Some current, last ->
      failwith
        "Store version %a is not supported by this rollup node. Last supported \
         version is %a@."
        Store_version.pp
        current
        Store_version.pp
        last
