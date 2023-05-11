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
  let convert_store_messages
      (messages, (block_hash, timestamp, number_of_messages)) =
    ( messages,
      (false (* is migration block *), block_hash, timestamp, number_of_messages)
    )

  let migrate_messages (v0_store : _ Store_v0.t) (v1_store : _ Store_v1.t)
      (l2_block : Sc_rollup_block.t) =
    let open Lwt_result_syntax in
    let* v0_messages =
      Store_v0.Messages.read v0_store.messages l2_block.header.inbox_witness
    in
    match v0_messages with
    | None -> return_unit
    | Some v0_messages ->
        let value, header = convert_store_messages v0_messages in
        Store_v1.Messages.append
          v1_store.messages
          ~key:l2_block.header.inbox_witness
          ~header
          ~value

  (* In place migration of processed slots under new key name by hand *)
  let migrate_dal_processed_slots_irmin (v1_store : _ Store_v1.t) =
    let open Lwt_syntax in
    let open Store_v1 in
    let info () =
      let date =
        Tezos_base.Time.(
          System.now () |> System.to_protocol |> Protocol.to_seconds)
      in
      let author =
        Format.asprintf
          "Rollup node %a"
          Tezos_version_parser.pp
          Tezos_version.Current_git_info.version
      in
      let message = "Migration store from v0 to v1" in
      Irmin_store.Raw_irmin.Info.v ~author ~message date
    in
    let store = Irmin_store.Raw_irmin.unsafe v1_store.irmin_store in
    let old_root = Store_v0.Dal_processed_slots.path in
    let new_root = Dal_slots_statuses.path in
    let* old_tree = Irmin_store.Raw_irmin.find_tree store old_root in
    match old_tree with
    | None -> return_unit
    | Some _ ->
        (* Move the tree in the new key *)
        Irmin_store.Raw_irmin.with_tree_exn
          ~info
          store
          new_root
          (fun _new_tree -> return old_tree)

  let tmp_dir ~storage_dir =
    Filename.concat
      (Configuration.default_storage_dir storage_dir)
      "migration_v0_v1"

  let migrate ~storage_dir =
    let open Lwt_result_syntax in
    let* v0_store =
      Store_v0.load Read_only ~l2_blocks_cache_size:1 storage_dir
    in
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
    let* v1_store = Store_v1.load Read_write ~l2_blocks_cache_size:1 tmp_dir in
    let cleanup () =
      let open Lwt_syntax in
      let* (_ : unit tzresult) = Store_v0.close v0_store
      and* (_ : unit tzresult) = Store_v1.close v1_store in
      (* Don't remove migration dir to allow for later resume. *)
      return_unit
    in
    let run_migration () =
      let* () =
        Store_v0.iter_l2_blocks v0_store (migrate_messages v0_store v1_store)
      in
      let*! () =
        Lwt_utils_unix.remove_dir (messages_store_location ~storage_dir)
      in
      let*! () =
        Lwt_unix.rename
          (messages_store_location ~storage_dir:tmp_dir)
          (messages_store_location ~storage_dir)
      in
      let*! () = migrate_dal_processed_slots_irmin v1_store in
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
