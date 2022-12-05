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

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/3207
   use another storage solution that irmin as we don't need backtracking *)

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/4097
   Add an interface to this module *)

(* Relative path to store directory from base-dir *)
let path = "store"

let slot_header_store = "slot_header_store"

module StoreMaker = Irmin_pack_unix.KV (Tezos_context_encoding.Context.Conf)
include StoreMaker.Make (Irmin.Contents.String)

let shard_store_path = "shard_store"

let info message =
  let date = Unix.gettimeofday () |> int_of_float |> Int64.of_int in
  Irmin.Info.Default.v ~author:"DAL Node" ~message date

let set ~msg store path v = set_exn store path v ~info:(fun () -> info msg)

(** Store context *)
type node_store = {
  slots_store : t;
  shard_store : Shard_store.t;
  slot_headers_store : Slot_headers_store.t;
  slots_watcher : Cryptobox.Commitment.t Lwt_watcher.input;
}

(** [open_slots_watcher node_store] opens a stream that should be notified when
    the storage is updated with a new slot. *)
let open_slots_stream {slots_watcher; _} =
  Lwt_watcher.create_stream slots_watcher

(** [init config] inits the store on the filesystem using the given [config]. *)
let init config =
  let open Lwt_syntax in
  let dir = Configuration.data_dir_path config path in
  let* slot_headers_store = Slot_headers_store.load dir in
  let slots_watcher = Lwt_watcher.create_input () in
  let* repo = Repo.v (Irmin_pack.config dir) in
  let* slots_store = main repo in
  let* shard_store = Shard_store.init shard_store_path in
  let* () = Event.(emit store_is_ready ()) in
  Lwt.return {shard_store; slots_store; slots_watcher; slot_headers_store}

module Legacy_paths : sig
  type path = string list

  val slot_by_commitment : string -> path

  val slot_id_by_commitment : string -> Services.Types.slot_id -> path

  val slot_shards_by_commitment : string -> path

  val slot_shard_by_commitment : string -> int -> path

  val successfully_included_slot_header_in_l1 :
    published_level:Services.Types.level ->
    slot_index:Services.Types.slot_index ->
    path * path

  val other_slot_header_in_l1 :
    published_level:Services.Types.level ->
    slot_index:Services.Types.slot_index ->
    commitment:string ->
    path

  val commitment_by_id : Services.Types.slot_id -> path

end = struct
  module Path_internals = struct
    type internal = [`Internal]

    type any = [internal | `Any]

    type _ path =
      | Root : string -> internal path
      | Internal : {prefix : internal path; ext : string} -> internal path
      | Leaf : {
          prefix : internal path;
          ext : string list;
          is_collection : bool;
        }
          -> any path

    let root = Root "slots"

    let mk_internal prefix ext = Internal {prefix; ext}

    let mk_leaf ?(is_collection = true) prefix ext =
      Leaf {prefix; ext; is_collection}

    let slot_by_commitment commitment = mk_internal root commitment

    let slot_ids_by_commitment commitment =
      mk_internal (slot_by_commitment commitment) "slot_ids"

    let slot_id_by_commitment commitment slot_id =
      let {Services.Types.slot_level; slot_index} = slot_id in
      mk_leaf
        ~is_collection:false
        (slot_ids_by_commitment commitment)
        [Int32.to_string slot_level; Int.to_string slot_index]

    let slot_shards_by_commitment commitment =
      mk_internal (slot_by_commitment commitment) "shards"

    let slot_shard_by_commitment commitment index =
      mk_leaf (slot_shards_by_commitment commitment) [string_of_int index]

    let included_slot_header_in_l1 level slot_index =
      let mk a b = mk_internal b a in
      mk "levels" root
      |> mk (Int32.to_string level)
      |> mk "slot_index"
      |> mk (string_of_int slot_index)

    let successfully_included_slot_header_in_l1 published_level slot_index =
      let shared =
        mk_internal
          (included_slot_header_in_l1 published_level slot_index)
          "accepted"
      in
      ( mk_leaf ~is_collection:false shared ["commitment"],
        mk_leaf ~is_collection:false shared ["status"] )

    let other_slot_header_in_l1 published_level slot_index commitment =
      mk_leaf
        ~is_collection:false
        (mk_internal
           (included_slot_header_in_l1 published_level slot_index)
           "others")
        [commitment]

    let by_level level =
      mk_internal (mk_internal root "levels") (Int32.to_string level)

    let by_index internal slot_index =
      mk_internal (mk_internal internal "slot_index") (Int.to_string slot_index)

    let by_id id =
      let {Services.Types.slot_level; slot_index} = id in
      let path = by_level slot_level in
      by_index path slot_index

    let commitment_by_id id =
      mk_leaf ~is_collection:false (by_id id) ["accepted"; "commitment"]


    let data_path (type a) (p : a path) =
      let rec path (p : internal path) acc =
        match p with
        | Root s -> s :: acc
        | Internal {prefix; ext} -> path prefix (ext :: acc)
      in
      let prefix, is_collection, ext =
        match p with
        | (Root _ | Internal _) as p -> ((p : internal path), false, None)
        | Leaf {prefix; ext; is_collection} -> (prefix, is_collection, Some ext)
      in
      let acc =
        match (ext, is_collection) with
        | None, _ -> ["data"]
        | Some ext, true -> "data" :: ext
        | Some ext, false -> ext @ ["data"]
      in
      path prefix acc
  end

  type path = string list

  let slot_by_commitment c = Path_internals.(data_path @@ slot_by_commitment c)

  let slot_id_by_commitment c slot_id =
    Path_internals.(data_path @@ slot_id_by_commitment c slot_id)

  let slot_shard_by_commitment c index =
    Path_internals.(data_path @@ slot_shard_by_commitment c index)

  let slot_shards_by_commitment c =
    Path_internals.(data_path @@ slot_shards_by_commitment c)

  let successfully_included_slot_header_in_l1 ~published_level ~slot_index =
    let commitment, status =
      Path_internals.successfully_included_slot_header_in_l1
        published_level
        slot_index
    in
    Path_internals.(data_path @@ commitment, data_path @@ status)

  let other_slot_header_in_l1 ~published_level ~slot_index ~commitment =
    Path_internals.(
      data_path @@ other_slot_header_in_l1 published_level slot_index commitment)

  let commitment_by_id id = Path_internals.(data_path @@ commitment_by_id id)
end

module Legacy = struct
  let encode enc v =
    Data_encoding.Binary.to_string enc v
    |> Result.map_error (fun e ->
           [Tezos_base.Data_encoding_wrapper.Encoding_error e])

  let add_slot_by_commitment node_store slot commitment =
    let open Lwt_syntax in
    let commitment_b58 = Cryptobox.Commitment.to_b58check commitment in
    let path = Legacy_paths.slot_by_commitment commitment_b58 in
    let encoded_slot = Bytes.to_string slot in
    let* () = set ~msg:"Slot stored" node_store.slots_store path encoded_slot in
    let* () = Event.(emit stored_slot_content commitment_b58) in
    Lwt_watcher.notify node_store.slots_watcher commitment ;
    return_unit

  let associate_slot_id_with_commitment node_store commitment slot_id =
    let open Lwt_syntax in
    let commitment_b58 = Cryptobox.Commitment.to_b58check commitment in
    let path = Legacy_paths.slot_id_by_commitment commitment_b58 slot_id in
    let* () = set ~msg:"Slot id stored" node_store.slots_store path "" in
    return_unit

  let exists_slot_by_commitment node_store commitment =
    let commitment_b58 = Cryptobox.Commitment.to_b58check commitment in
    let path = Legacy_paths.slot_by_commitment commitment_b58 in
    mem node_store.slots_store path

  let find_slot_by_commitment node_store commitment =
    let open Lwt_syntax in
    let commitment_b58 = Cryptobox.Commitment.to_b58check commitment in
    let path = Legacy_paths.slot_by_commitment commitment_b58 in
    let* res_opt = find node_store.slots_store path in
    Option.map Bytes.of_string res_opt |> Lwt.return

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4383
     Remove legacy code once migration to new API is done. *)
  let legacy_add_slot_headers ~block_hash slot_headers node_store =
    let slot_headers_store = node_store.slot_headers_store in
    List.iter_s
      (fun (slot_header, status) ->
        match status with
        | Dal_plugin.Succeeded ->
            let Dal_plugin.{slot_index; commitment; _} = slot_header in
            Slot_headers_store.add
              slot_headers_store
              ~primary_key:block_hash
              ~secondary_key:slot_index
              commitment
        | Dal_plugin.Failed ->
            (* This function is only supposed to add successfully applied slot
               headers. Anyway, this piece of code will be removed once fully
               implementing the new DAL API. *)
            Lwt.return_unit)
      slot_headers

  let add_slot_headers ~block_level:_ ~block_hash slot_headers node_store =
    let open Lwt_syntax in
    let* () = legacy_add_slot_headers ~block_hash slot_headers node_store in
    let slots_store = node_store.slots_store in
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/4388
       Handle reorgs. *)
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/4389
       Handle statuses evolution. *)
    List.iter_s
      (fun (slot_header, status) ->
        let Dal_plugin.{slot_index; commitment; published_level} =
          slot_header
        in
        let commitment_b58 = Cryptobox.Commitment.to_b58check commitment in
        match status with
        | Dal_plugin.Succeeded ->
            let commitment_path, status_path =
              Legacy_paths.successfully_included_slot_header_in_l1
                ~published_level
                ~slot_index
            in
            let* () =
              set
                ~msg:"add_slot_headers:success:commitment"
                slots_store
                commitment_path
                commitment_b58
            in
            set
              ~msg:"add_slot_headers:success:status"
              slots_store
              status_path
              (Services.Types.header_attestation_status_to_string
                 `Waiting_for_attestations)
        | Dal_plugin.Failed ->
            let path =
              Legacy_paths.other_slot_header_in_l1
                ~published_level
                ~slot_index
                ~commitment:commitment_b58
            in
            set
              ~msg:"add_slot_headers:others:status"
              slots_store
              path
              (Services.Types.header_status_to_string `Not_selected))
      slot_headers

  let find_commitment_by_id node_store slot_id =
    let open Lwt_syntax in
    let path = Legacy_paths.commitment_by_id slot_id in
    let* raw_commitment_opt = find node_store.slots_store path in
    Option.bind raw_commitment_opt (fun raw_commitment ->
        Data_encoding.Binary.of_string_opt
          Cryptobox.Commitment.encoding
          raw_commitment)
    |> return
end
