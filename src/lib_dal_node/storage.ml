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

type error += Resource_not_found of string

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.resource_not_found"
    ~title:"Resource not found"
    ~description:"Resource not found at the given path"
    ~pp:(fun ppf s ->
      Format.fprintf ppf "Resource not found at the given path: %s" s)
    Data_encoding.(obj1 (req "path" string))
    (function Resource_not_found s -> Some s | _ -> None)
    (fun s -> Resource_not_found s)

module Make (Stored_data : Storage_intf.STORED_DATA) = struct
  module Mutexes = struct
    type mutex = Lwt_idle_waiter.t

    include
      Aches.Vache.Map (Aches.Vache.FIFO_Precise) (Aches.Vache.Strong)
        (struct
          type t = string

          let equal = String.equal

          let hash = Hashtbl.hash
        end)

    let mem t k = Option.is_some @@ find_opt t k

    let add t k =
      let mutex = Lwt_idle_waiter.create () in
      replace t k mutex ;
      mutex
  end

  type t = {data_dir : string; mutexes : Mutexes.mutex Mutexes.t}

  let get_data_dir t = t.data_dir

  type subpath = string

  type key = Stored_data.key

  type value = Stored_data.value

  type key_value = {key : key; value : value}

  let key_of_string s =
    Data_encoding.(Binary.of_string Stored_data.key_encoding s)
    |> Result.map_error (fun e ->
           [Tezos_base.Data_encoding_wrapper.Decoding_error e])

  let string_of_key s =
    Data_encoding.(Binary.to_string Stored_data.key_encoding s)
    |> Result.map_error (fun e ->
           [Tezos_base.Data_encoding_wrapper.Encoding_error e])

  let bytes_of_value s =
    Data_encoding.(Binary.to_bytes Stored_data.value_encoding s)
    |> Result.map_error (fun e ->
           [Tezos_base.Data_encoding_wrapper.Encoding_error e])

  let value_of_bytes b =
    Data_encoding.(Binary.of_bytes Stored_data.value_encoding b)
    |> Result.map_error (fun e ->
           [Tezos_base.Data_encoding_wrapper.Decoding_error e])

  let mkdir_if_not_exists dirpath =
    Lwt.catch
      (fun () -> Lwt_unix.mkdir dirpath 0o755)
      (function
        | Unix.Unix_error (Unix.EEXIST, "mkdir", _) -> Lwt.return_unit
        | e -> raise e)

  let init ~max_mutexes data_dir =
    let open Lwt_result_syntax in
    let*! () = mkdir_if_not_exists data_dir in
    let mutexes = Mutexes.create max_mutexes in
    return {data_dir; mutexes}

  let subpath_dir store subpath = Filename.concat store.data_dir subpath

  let with_mutex store filepath f =
    let open Lwt_result_syntax in
    let mutex =
      match Mutexes.find_opt store.mutexes filepath with
      | None -> Mutexes.add store.mutexes filepath
      | Some mutex -> mutex
    in
    let*! v = f mutex in
    let () =
      match v with
      | Ok _ -> ()
      | Error _ -> Mutexes.remove store.mutexes filepath
    in
    Lwt.return v

  let write_values store ~subpath values =
    let open Lwt_result_syntax in
    let subpath_dir = subpath_dir store subpath in
    let*! () = mkdir_if_not_exists subpath_dir in
    values
    |> Seq.iter_es (fun (key, value) ->
           let*? filename = string_of_key key in
           let filepath = Filename.concat subpath_dir filename in
           if Mutexes.mem store.mutexes filepath then return_unit
           else
             with_mutex store filepath @@ fun mutex ->
             Lwt_idle_waiter.force_idle mutex @@ fun () ->
             let*? content = bytes_of_value value in
             (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4289
                check if path and values already exists *)
             let*! r =
               Lwt_utils_unix.with_atomic_open_out filepath (fun fd ->
                   Lwt_utils_unix.write_bytes fd content)
             in
             Lwt.return @@ Result.bind_error r Lwt_utils_unix.tzfail_of_io_error)

  let read_value_from_disk ~partial_path_on_error store ~value_size filepath =
    let open Lwt_result_syntax in
    let*! value =
      with_mutex store filepath @@ fun mutex ->
      catch_es @@ fun () ->
      let*! value =
        Lwt_idle_waiter.task mutex @@ fun () ->
        Lwt_utils_unix.with_open_in filepath @@ fun fd ->
        let value = Bytes.create value_size in
        let*! () = Lwt_utils_unix.read_bytes fd value in
        Lwt.return value
      in
      Lwt.return @@ Result.bind_error value Lwt_utils_unix.tzfail_of_io_error
    in
    match value with
    | Ok value -> Lwt.return @@ value_of_bytes value
    | Error [Lwt_utils_unix.Io_error e] when e.action = `Open ->
        fail [Resource_not_found partial_path_on_error]
    | Error e -> fail e

  let read_values ~value_size store subpath =
    let open Lwt_result_syntax in
    let dir = subpath_dir store subpath in
    let file_stream = Lwt_unix.files_of_directory dir in
    let rec read acc =
      let*! elt = catch_s @@ fun () -> Lwt_stream.get file_stream in
      let* elt =
        match elt with
        | Ok r -> return r
        | Error [Exn (Unix.Unix_error (_, "opendir", _))] ->
            fail [Resource_not_found subpath]
        | Error e -> fail e
      in
      match elt with
      | None -> return acc
      | Some "." | Some ".." -> read acc
      | Some filename ->
          (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4289
             handle error cases for [int_of_string] *)
          let*? key = key_of_string filename in
          let filepath = Filename.concat dir filename in
          let partial_path_on_error = Filename.concat subpath filename in
          let* value =
            read_value_from_disk
              ~partial_path_on_error
              store
              ~value_size
              filepath
          in
          read ({key; value} :: acc)
    in
    read []

  let read_values_subset ~value_size store ~subpath values =
    let open Lwt_result_syntax in
    let dir = subpath_dir store subpath in
    List.map_es
      (fun key ->
        let*? filename = string_of_key key in
        let filepath = Filename.concat dir filename in
        let partial_path_on_error = Filename.concat subpath filename in
        let* value =
          read_value_from_disk ~partial_path_on_error store ~value_size filepath
        in
        return {key; value})
      values

  let read_value ~value_size store ~subpath key =
    let open Lwt_result_syntax in
    let dir = subpath_dir store subpath in
    let*? filename = string_of_key key in
    let filepath = Filename.concat dir filename in
    let partial_path_on_error = Filename.concat subpath filename in
    let* value =
      read_value_from_disk ~partial_path_on_error store ~value_size filepath
    in
    return {key; value}
end
