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

module Foo = struct
  module Key : Index.Key.S with type t = int32 * int = struct
    type t = int32 * int

    let t =
      let open Repr in
      pair int32 int

    let equal = ( = )

    let hash = Hashtbl.hash

    let hash_size = 31

    let encoding =
      let open Data_encoding in
      tup2 int32 int31

    let encode v = Data_encoding.Binary.to_string_exn encoding v

    let encoded_size =
      match Data_encoding.Binary.fixed_length encoding with
      | None -> assert false
      | Some size -> size

    let decode v _i = Data_encoding.Binary.of_string_exn encoding v
  end

  module Value : Index.Value.S with type t = Cryptobox.commitment = struct
    type t = Cryptobox.commitment

    let encoding = Cryptobox.Commitment.encoding

    let encode v = Data_encoding.Binary.to_string_exn encoding v

    let encoded_size =
      match Data_encoding.Binary.fixed_length encoding with
      | None -> assert false
      | Some size -> size

    let decode v _i = Data_encoding.Binary.of_string_exn encoding v

    let t =
      let open Repr in
      map string (fun str -> decode str 0) (fun commitment -> encode commitment)
  end

  include Index_unix.Make (Key) (Value) (Index.Cache.Unbounded)
end

module StoreMaker = Irmin_pack_unix.KV (Tezos_context_encoding.Context.Conf)
include StoreMaker.Make (Irmin.Contents.String)

let info message =
  let date = Unix.gettimeofday () |> int_of_float |> Int64.of_int in
  Irmin.Info.Default.v ~author:"DAL Node" ~message date

let set ~msg store path v = set_exn store path v ~info:(fun () -> info msg)

(** Store context *)
type node_store = {
  slots_store : t;
  commitment_index : Foo.t;
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
  let* () = Event.(emit store_is_ready ()) in
  let commitment_index = Foo.v ~log_size:10_000 "coucou" in
  Lwt.return {slots_store; slots_watcher; slot_headers_store; commitment_index}
