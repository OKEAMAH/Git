(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

module Conf = struct
  let entries = 32

  let stable_hash = 256

  let inode_child_order = `Seeded_hash
end

let make_info message =
  let date = Unix.gettimeofday () |> Int64.of_float in
  Irmin.Info.v ~author:"tx-rollup-node" ~date message

module Kv = Irmin_pack.KV (Irmin_pack.Version.V2) (Conf) (Irmin.Contents.String)

type t = Kv.t

let load data_dir =
  let open Lwt_syntax in
  let* repository = Kv.Repo.v (Irmin_pack.config data_dir) in
  let* branch = Kv.master repository in
  let* () = Event.(emit irmin_store_loaded) data_dir in
  return_ok branch

let close data_dir =
  let open Lwt_syntax in
  let* repository = Kv.Repo.v (Irmin_pack.config data_dir) in
  let* () = Kv.Repo.close repository in
  return_unit

module type REF_CONF = sig
  val location : string list

  type value

  val value_encoding : value Data_encoding.t
end

module type MAP_CONF = sig
  include REF_CONF

  type key

  val key_to_string : key -> string
end

module type REF = sig
  type t

  type value

  val find : t -> value option Lwt.t

  val get : t -> value tzresult Lwt.t

  val set : t -> value -> unit tzresult Lwt.t
end

module type MAP = sig
  type t

  type key

  type value

  val mem : t -> key -> bool Lwt.t

  val find : t -> key -> value option Lwt.t

  val get : t -> key -> value tzresult Lwt.t

  val add : t -> key -> value -> unit tzresult Lwt.t
end

module Make_map (M : MAP_CONF) = struct
  type t = Kv.t

  type key = M.key

  type value = M.value

  let mk key =
    let loc = Kv.Key.v M.location in
    Kv.Key.rcons loc @@ M.key_to_string key

  let render_key key =
    Format.sprintf "%s/%s" (String.concat "/" M.location) (M.key_to_string key)

  let mem store key =
    let key = mk key in
    Kv.mem store key

  let encode key value =
    value
    |> Data_encoding.Binary.to_string M.value_encoding
    |> Result.fold ~ok:return ~error:(fun _ ->
           let json = Data_encoding.Json.construct M.value_encoding value in
           fail @@ Error.Tx_rollup_unable_to_encode_storable_value (key, json))

  let decode key value =
    value
    |> Data_encoding.Binary.of_string M.value_encoding
    |> Result.fold ~ok:return ~error:(fun _ ->
           fail @@ Error.Tx_rollup_unable_to_decode_stored_value (key, value))

  let find store raw_key =
    let open Lwt_syntax in
    let key = mk raw_key in
    let* binaries = Kv.find store key in
    let+ value =
      match binaries with
      | None -> Lwt.return None
      | Some x -> (
          let+ k = decode (render_key raw_key) x in
          match k with Ok x -> Some x | _ -> None)
    in
    value

  let get store raw_key =
    let open Lwt_syntax in
    let key = mk raw_key in
    let* binaries = Kv.get store key in
    decode (render_key raw_key) binaries

  let set rendered_key store key value =
    let open Lwt_tzresult_syntax in
    let info () = make_info rendered_key in
    let*! r = Kv.set ~info store key value in
    match r with
    | Error _ -> fail @@ Error.Tx_rollup_irmin_error "cannot store value"
    | Ok () -> return_unit

  let add store raw_key value =
    let open Lwt_result_syntax in
    let key = mk raw_key in
    let rendered_key = render_key raw_key in
    let* value = encode rendered_key value in
    set rendered_key store key value
end

module Make_ref (R : REF_CONF) = struct
  type t = Kv.t

  type value = R.value

  let key = Kv.Key.v R.location

  let rendered_key = String.concat "/" R.location

  let decode value =
    value
    |> Data_encoding.Binary.of_string R.value_encoding
    |> Result.fold ~ok:return ~error:(fun _ ->
           fail
           @@ Error.Tx_rollup_unable_to_decode_stored_value (rendered_key, value))

  let encode value =
    value
    |> Data_encoding.Binary.to_string R.value_encoding
    |> Result.fold ~ok:return ~error:(fun _ ->
           let json = Data_encoding.Json.construct R.value_encoding value in
           fail
           @@ Error.Tx_rollup_unable_to_encode_storable_value
                (rendered_key, json))

  let get store =
    let open Lwt_syntax in
    let* binaries = Kv.get store key in
    decode binaries

  let find store =
    let open Lwt_syntax in
    let* binaries = Kv.find store key in
    let+ value =
      match binaries with
      | None -> Lwt.return None
      | Some x -> (
          let+ k = decode x in
          match k with Ok x -> Some x | _ -> None)
    in
    value

  let set_aux store value =
    let open Lwt_tzresult_syntax in
    let info () = make_info rendered_key in
    let*! r = Kv.set ~info store key value in
    match r with
    | Error _ -> fail @@ Error.Tx_rollup_irmin_error "cannot store value"
    | Ok () -> return_unit

  let set store value =
    let open Lwt_result_syntax in
    let* value = encode value in
    set_aux store value
end

module Inboxes = Make_map (struct
  let location = ["tx_rollup"; "inboxes"]

  type key = Block_hash.t

  type value = Inbox.t

  (* TODO/TORU: use more compact Block_hash.to_string? *)
  let key_to_string = Block_hash.to_b58check

  let value_encoding = Inbox.encoding
end)

module Tezos_head = Make_ref (struct
  let location = ["tezos"; "head"]

  type value = Block_hash.t

  let value_encoding = Block_hash.encoding
end)

module Context_hashes = Make_map (struct
  let location = ["tx_rollup"; "context_hashes"]

  type key = Block_hash.t

  type value = Protocol.Tx_rollup_l2_context_hash.t

  (* TODO/TORU: use more compact Block_hash.to_string? *)
  let key_to_string = Block_hash.to_b58check

  let value_encoding = Protocol.Tx_rollup_l2_context_hash.encoding
end)
