(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Error_monad

type error +=
  | Missing_stored_kvs_data of {filepath : string; index : int}
  | Wrong_encoded_value_size of {
      file : string;
      index : int;
      expected : int;
      got : int;
    }
  | Closed of {action : string}
  | Corrupted_data of {action : string; filepath : string; index : int}

let () =
  register_error_kind
    `Permanent
    ~id:"stdlib_unix.missing_kvs_data"
    ~title:"Missing stored data from KVS"
    ~description:"Failed to load stored data from KVS"
    ~pp:(fun ppf (path, index) ->
      Format.fprintf
        ppf
        "Failed to load on-disk data: no corresponding data found in file %s \
         at index %d."
        path
        index)
    Data_encoding.(obj2 (req "filepath" string) (req "index" int31))
    (function
      | Missing_stored_kvs_data {filepath; index} -> Some (filepath, index)
      | _ -> None)
    (fun (filepath, index) -> Missing_stored_kvs_data {filepath; index}) ;
  register_error_kind
    `Permanent
    ~id:"stdlib_unix.wrong_encoded_value_size"
    ~title:"Wrong encoded value size"
    ~description:"Try to write a value that does not match the expected size"
    ~pp:(fun ppf (file, index, expected, got) ->
      Format.fprintf
        ppf
        "While encoding a value with index '%d' on file '%s', the value size \
         was expected to be '%d'. Got '%d'."
        index
        file
        expected
        got)
    Data_encoding.(
      obj4
        (req "file" string)
        (req "index" int31)
        (req "expected_size " int31)
        (req "got_size" int31))
    (function
      | Wrong_encoded_value_size {file; index; expected; got} ->
          Some (file, index, expected, got)
      | _ -> None)
    (fun (file, index, expected, got) ->
      Wrong_encoded_value_size {file; index; expected; got}) ;
  register_error_kind
    `Permanent
    ~id:"stdlib_unix.closed"
    ~title:"Key value stored was closed"
    ~description:"Action performed while the store is closed"
    ~pp:(fun ppf action ->
      Format.fprintf
        ppf
        "Failed to performa action '%s' because the store was closed"
        action)
    Data_encoding.(obj1 (req "action" string))
    (function Closed {action} -> Some action | _ -> None)
    (fun action -> Closed {action}) ;
  register_error_kind
    `Permanent
    ~id:"stdlib_unix.corrupted_data"
    ~title:"key value store data is corrupted"
    ~description:"A data of the key value store was corrupted"
    ~pp:(fun ppf (action, file, index) ->
      Format.fprintf
        ppf
        "Could not complete action '%s' because the data associated to file \
         '%s' and key index '%d' because the data is corrupted. Likely the \
         store was shutdown abnormally. If you see this message, please report \
         it."
        action
        file
        index)
    Data_encoding.(
      obj3 (req "action" string) (req "filepath" string) (req "index" int31))
    (function
      | Corrupted_data {action; filepath; index} ->
          Some (action, filepath, index)
      | _ -> None)
    (fun (action, filepath, index) -> Corrupted_data {action; filepath; index})

type ('key, 'value) layout = {
  encoding : 'value Data_encoding.t;
  eq : 'value -> 'value -> bool;
  index_of : 'key -> int;
  filepath : string;
  value_size : int;
}

(** The module [Files] handles writing and reading into memory-mapped
    files. A virtual file is backed by a physical file and a key is
    an offset in this file.

    Besides implementing a key-value store, this module must properly
    handle resource utilization, especially file descriptors.

    The structure {!Files.t} guarantees that no more than the specified
    [lru_size] file descriptors can be open at the same time.

    This modules also enables each file to come with its own layout.
*)
module Files : sig
  type 'value t

  val init : lru_size:int -> 'value t

  val close : 'value t -> unit Lwt.t

  val write :
    ?override:bool ->
    'value t ->
    ('key, 'value) layout ->
    'key ->
    'value ->
    unit tzresult Lwt.t

  val read : 'value t -> ('key, 'value) layout -> 'key -> 'value tzresult Lwt.t

  val value_exists :
    'value t -> ('key, 'value) layout -> 'key -> bool tzresult Lwt.t

  val remove : 'value t -> ('key, 'value) layout -> unit tzresult Lwt.t
end = struct
  module LRU = Ringo.LRU_Collection

  module Table = Hashtbl.Make (struct
    include String

    let hash = Hashtbl.hash
  end)

  (* This magic constant could be changed in the future. *)
  let max_number_of_keys = 4096

  (* TODO: https://gitlab.com/tezos/tezos/-/issues/6033
     For now the bitset is a byte set...
     With a true bitset, we'd have [max_number_of_keys/8].
     Should be ok in practice since an atomic read/write on Linux is 4KiB.
  *)
  let bitset_size = max_number_of_keys

  (* The following cache allows to cache in memory values that were
     accessed recently. There is one cache per file opened. *)
  module Cache = Hashtbl.Make (struct
    type t = int

    let equal = Int.equal

    let hash = Hashtbl.hash
  end)

  type 'value opened_file = {
    fd : Lwt_unix.file_descr;
        (* The file descriptor of the file containing those
           values. The file is always prefixed by the bitset indicated
           the values stored in this file. *)
    bitset : Lwt_bytes.t;
    (* This bitset encodes the values that are present. *)
    cache : 'value Cache.t;
        (* This cache keeps in memory values accessed recently. It is
           bounded by the maximum number of values the file can
           contain. It is cleaned up only once the file is removed from the LRU. *)
    lru_node : string LRU.node; (* LRU node associated with the current file. *)
  }

  (* This type contains info related to a physical file loaded into
     memory. *)
  type 'value file =
    | Opening of 'value opened_file Lwt.t
    (* The promise is fulfilled only once the file descriptor is
       opened. *)
    | Closing of unit Lwt.t
  (* The promise is fulfilled only once the file descriptor is
     closed. *)

  (* This datatype encodes the current action performed by the store. *)
  type 'value actions =
    | Close :
        unit Lwt.t
        -> 'value actions (* The promise returns by [close] contains no data. *)
    | Read :
        ('value opened_file option * 'value tzresult) Lwt.t
        -> 'value actions
      (* The promise returned by [Read] contains the file read if it
         exists as well as the value read if it exists or an error. *)
    | Write : ('value opened_file * unit tzresult) Lwt.t -> 'value actions
      (* The promise returned by [Write] contains the file loaded or
         created, and return nothing (except if an error occured
         during the write. *)
    | Value_exists :
        ('value opened_file option * bool tzresult) Lwt.t
        -> 'value actions
      (* The promise returned by [Value_exists] returned the file read
         if it exists as well as the existence of the key. *)
    | Remove : unit Lwt.t -> 'value actions
  (* The promise returned by [Remove] contains nothing. *)

  (* The state of the store. *)
  type 'value t = {
    closed : bool ref;
        (* [true] if the store was closed. Current actions will
           end, and any other actions will fail. *)
    state : 'value actions Table.t;
    (* [state] contains per file the last action performed. It must be
       updated atomically when a new action is performed. *)
    files : 'value file Table.t;
    (* [files] contains per file data related to this file. It must be
       updated atomically before opening or closing the associated
       file descriptor. *)
    lru : string LRU.t;
        (* [lru] contains a set of [filename] that are opened. It
           ensures there is a limited number of file descriptors opened. *)
  }

  (* The invariant behind this type ensures that

     (A) filename \in lru -> filename \in files /\ filename \in state

     (B) The number of file descriptors opened is bounded by the
     capcity of the LRU

     As a consequence, a read or write in the store can remove another
     file from the LRU. If an action was already performing on such a
     file, the store waits for this action to be terminated and close
     the file before opening a new one.

     Such an eviction explains why the invariant:

     (C) filename \in files -> filename \in lru

     does not hold.

     This store can be shutdown only once. Any other actions performed
     after the store has been closed will fail. The promise returned
     by the close function will be fulfilled only once all the current
     actions will be completed.

     The store ensures that any action performed on a given file are
     done sequentially.
  *)

  let init ~lru_size =
    let state = Table.create lru_size in
    let files = Table.create lru_size in
    let lru = LRU.create lru_size in
    let closed = ref false in
    {closed; state; files; lru}

  (* The promise returned by this function is fulfilled when the
     current action is completed. The promise returned the opened file
     associated to the action if it exists once the action is
     completed. *)
  let wait =
    let open Lwt_syntax in
    function
    | Read p ->
        let* file, _ = p in
        return file
    | Close p ->
        let* () = p in
        return_none
    | Write p ->
        let* file, _ = p in
        return_some file
    | Value_exists p ->
        let* file, _ = p in
        return file
    | Remove p ->
        let* () = p in
        return_none

  (* This function is the only one that calls [Lwt_unix.close]. *)
  let close_opened_file opened_file = Lwt_unix.close opened_file.fd

  (* The 'n'th byte of the bitset indicates whether a value is stored or not. *)
  let key_exists handle index =
    if handle.bitset.{index} = '\000' then `Not_found
    else if handle.bitset.{index} = '\001' then `Found
    else `Corrupted

  (* This computation relies on the fact that the size of all the
     values are fixed, and the values are stored after the bitset. *)
  let position_of layout index =
    bitset_size + (index * layout.value_size) |> Int64.of_int

  let read_with_opened_file layout opened_file key =
    let open Lwt_syntax in
    let index = layout.index_of key in
    let filepath = layout.filepath in
    match key_exists opened_file index with
    | `Not_found ->
        return
          ( Some opened_file,
            Error
              (Error_monad.TzTrace.make
                 (Missing_stored_kvs_data {filepath = layout.filepath; index}))
          )
    | `Corrupted ->
        return
          ( Some opened_file,
            Error
              (Error_monad.TzTrace.make
                 (Corrupted_data {action = "read"; filepath; index})) )
    | `Found -> (
        match Cache.find opened_file.cache index with
        | None ->
            (* If the value is not in the cache, we do an "I/O" via mmap. *)
            (* Note that the following code executes atomically Lwt-wise. *)
            let pos = position_of layout index in
            let mmap =
              Lwt_bytes.map_file
                ~fd:(Lwt_unix.unix_file_descr opened_file.fd)
                ~pos
                ~size:layout.value_size
                ~shared:true
                ()
            in
            let bytes = Bytes.make layout.value_size '\000' in
            Lwt_bytes.blit_to_bytes mmap 0 bytes 0 layout.value_size ;
            let data =
              Data_encoding.Binary.of_bytes_exn layout.encoding bytes
            in
            Cache.add opened_file.cache index data ;
            return (Some opened_file, Ok data)
        | Some v -> return (Some opened_file, Ok v))

  let write_with_opened_file ~override layout opened_file key data =
    let open Lwt_syntax in
    let index = layout.index_of key in
    let filepath = layout.filepath in
    match (key_exists opened_file index, override) with
    | `Corrupted, _ ->
        Lwt.return
          ( opened_file,
            Error
              (Error_monad.TzTrace.make
                 (Corrupted_data {action = "read"; filepath; index})) )
    | `Found, false -> Lwt.return (opened_file, Ok ())
    | `Found, true | `Not_found, _ ->
        let pos = position_of layout index in
        let mmap =
          Lwt_bytes.map_file
            ~fd:(Lwt_unix.unix_file_descr opened_file.fd)
            ~pos
            ~size:layout.value_size
            ~shared:true
            ()
        in
        let bytes = Data_encoding.Binary.to_bytes_exn layout.encoding data in
        let encoded_size = Bytes.length bytes in
        (* If the [value_size] has been provided by the user, we
           ensure the encoded size is the expected one. *)
        if encoded_size <> layout.value_size then
          Lwt.return
            ( opened_file,
              Error
                (Error_monad.TzTrace.make
                   (Wrong_encoded_value_size
                      {
                        file = layout.filepath;
                        index;
                        expected = layout.value_size;
                        got = encoded_size;
                      })) )
        else (
          (* This is necessary only when overriding values. *)
          opened_file.bitset.{index} <- '\002' ;
          Lwt_bytes.blit_from_bytes bytes 0 mmap 0 layout.value_size ;
          Cache.replace opened_file.cache index data ;
          opened_file.bitset.{index} <- '\001' ;
          return (opened_file, Ok ()))

  let remove_with_opened_file files lru filepath opened_file =
    let open Lwt_syntax in
    let* () = close_opened_file opened_file in
    (* It may happen that the node was already evicted by a concurrent
       action. Hence the LRU.remove can fail. *)
    (try LRU.remove lru opened_file.lru_node with _ -> ()) ;
    Table.remove files filepath ;
    Lwt_unix.unlink filepath

  module Action = struct
    let get_file_from_last_action files state filepath =
      let open Lwt_syntax in
      let last_or_concurrent_action = Table.find_opt state filepath in
      (* If an action is happening concurrently on the file, we wait
         for it to end.
         The action returns the opened file if any. *)
      match last_or_concurrent_action with
      | None -> (
          let file_cached = Table.find_opt files filepath in
          match file_cached with
          | None -> Lwt.return_none
          | Some (Closing p) ->
              let* () = p in
              Lwt.return_none
          | Some (Opening p) ->
              let* opened_file = p in
              Lwt.return_some opened_file)
      | Some action -> (
          let* file_opt = wait action in
          match file_opt with
          | None -> Lwt.return_none
          | Some opened_file -> Lwt.return_some opened_file)

    (* Any action on the key value store can be implemented that way. *)
    let generic_action files state filepath ~on_file_closed ~on_file_opened =
      let open Lwt_syntax in
      let* opened_file_opt = get_file_from_last_action files state filepath in
      match opened_file_opt with
      | None -> on_file_closed ~on_file_opened
      | Some opened_file -> on_file_opened opened_file

    let close_file files state filepath =
      let on_file_closed ~on_file_opened:_ = Lwt.return_unit in
      let on_file_opened opened_file = close_opened_file opened_file in
      generic_action files state filepath ~on_file_closed ~on_file_opened

    let read ~on_file_closed files state layout key =
      let on_file_opened opened_file =
        read_with_opened_file layout opened_file key
      in
      generic_action files state layout.filepath ~on_file_closed ~on_file_opened

    let value_exists ~on_file_closed files state layout key =
      let on_file_opened opened_file =
        let index = layout.index_of key in
        let filepath = layout.filepath in
        match key_exists opened_file index with
        | `Corrupted ->
            Lwt.return
              ( Some opened_file,
                Error
                  (Error_monad.TzTrace.make
                     (Corrupted_data {action = "value_exists"; filepath; index}))
              )
        | `Found -> Lwt.return (Some opened_file, Ok true)
        | `Not_found -> Lwt.return (Some opened_file, Ok false)
      in
      generic_action files state layout.filepath ~on_file_closed ~on_file_opened

    let write ~on_file_closed ~override files state layout key data =
      let on_file_opened opened_file =
        write_with_opened_file ~override layout opened_file key data
      in
      generic_action files state layout.filepath ~on_file_closed ~on_file_opened

    let remove_file ~on_file_closed files state lru filepath =
      let on_file_opened opened_file =
        remove_with_opened_file files lru filepath opened_file
      in
      generic_action files state filepath ~on_file_closed ~on_file_opened
  end

  let close_file files state filepath =
    (* Since this function does not aim to be exposed, we do not check
       whether the store is closed. This would actually be a mistake
       since it is used while the store is closing.

       Moreover, we do not remove the file from the LRU. The reason is
       this function si called twice:

       - when the file is evicted from the LRU (so it was already removed)

       - when closing the store. In that case, after closing the store
       we clean up the LRU.
    *)
    let open Lwt_syntax in
    (* [p] is a promise that triggers the action of closing the
       file. It is important to not wait on it so that we can update
       the store's state atomically to ensure invariant (A). *)
    let p = Action.close_file files state filepath in

    Table.replace files filepath (Closing p) ;
    Table.replace state filepath (Close p) ;
    let* () = p in
    Table.remove files filepath ;
    (* To avoid any memory leaks, we woud like to remove the
       corresponding entry from the [state] table. However, while
       closing the file, another action could have been performed. In
       that case, we don't want to remove the corresponding entry in
       the [state] table.

       Hence, we remove only entries if no other concurrent actions
       happened while closing the file (except closing the very same
       file). *)
    (match Table.find_opt state filepath with
    | Some (Close p) -> (
        match Lwt.state p with
        | Lwt.Return _ -> Table.remove state filepath
        | _ -> ())
    | _ -> ()) ;
    Lwt.return_unit

  (* The promise returned by this function is fullfiled once all the
     current actions are completed and all the opened files are
     closed. This function should be idempotent. *)
  let close {state; files; lru; closed} =
    let open Lwt_syntax in
    if !closed then return_unit
    else (
      closed := true ;
      let* () =
        Table.iter_s (fun filename _ -> close_file files state filename) files
      in
      LRU.clear lru ;
      return_unit)

  (* This function returns the lru node added and a promise for
     closing the file evicted by the LRU. *)
  let add_lru files state lru filename =
    let open Lwt_syntax in
    let lru_node, remove = LRU.add_and_return_erased lru filename in
    match remove with
    | None -> return lru_node
    | Some filepath ->
        (* We want to ensure that the number of file descriptors opened
           is bounded by the size of the LRU. This is why we wait first
           for the eviction promise to be fulfilled that will close the
           file evicted *)
        let* () = close_file files state filepath in
        return lru_node

  (* This function aims to be used when the file already exists on the
     file system. *)
  let load_file files state lru filename =
    let open Lwt_syntax in
    let* lru_node = add_lru files state lru filename in
    let* fd = Lwt_unix.openfile filename [O_RDWR; O_CLOEXEC] 0o660 in
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6033
       Should we check that the file is at least as big as the bitset? *)
    let bitset =
      Lwt_bytes.map_file
        ~fd:(Lwt_unix.unix_file_descr fd)
        ~shared:true
        ~size:bitset_size
        ()
    in
    return {fd; bitset; cache = Cache.create 101; lru_node}

  (* This function aims to be used when a write action is performed on
     a file that does not exist yet. *)
  let initialize_file files state lru filename value_size =
    let open Lwt_syntax in
    let* lru_node = add_lru files state lru filename in
    let* fd =
      Lwt_unix.openfile filename [O_RDWR; O_CREAT; O_EXCL; O_CLOEXEC] 0o660
    in
    let total_size = bitset_size + (max_number_of_keys * value_size) in
    let* () = Lwt_unix.ftruncate fd total_size in
    let unix_fd = Lwt_unix.unix_file_descr fd in
    let bitset =
      Lwt_bytes.map_file ~fd:unix_fd ~shared:true ~size:bitset_size ()
    in
    return {fd; bitset; cache = Cache.create 101; lru_node}

  (* This function is associated with the [Read] action. *)
  let may_load_file files state lru filepath =
    let open Lwt_syntax in
    let* b = Lwt_unix.file_exists filepath in
    if b then Lwt.return_some (load_file files state lru filepath)
    else Lwt.return_none

  (* This function is associated with the [Remove_file] action. *)
  let may_remove_file filepath =
    let open Lwt_syntax in
    let* b = Lwt_unix.file_exists filepath in
    if b then Lwt_unix.unlink filepath else Lwt.return_unit

  (* This function is associated with the [Write] action. *)
  let load_or_initialize_file files state lru layout =
    let open Lwt_syntax in
    let* b = Lwt_unix.file_exists layout.filepath in
    if b then load_file files state lru layout.filepath
    else initialize_file files state lru layout.filepath layout.value_size

  let read {files; state; lru; closed} layout key =
    let open Lwt_syntax in
    if !closed then
      Lwt.return (Error (Error_monad.TzTrace.make (Closed {action = "read"})))
    else
      let on_file_closed ~on_file_opened =
        let* r = may_load_file files state lru layout.filepath in
        match r with
        | None ->
            let index = layout.index_of key in
            Lwt.return
              ( None,
                Error
                  (Error_monad.TzTrace.make
                     (Missing_stored_kvs_data
                        {filepath = layout.filepath; index})) )
        | Some opened_file_promise ->
            Table.replace files layout.filepath (Opening opened_file_promise) ;
            let* opened_file = opened_file_promise in
            on_file_opened opened_file
      in
      let p = Action.read ~on_file_closed files state layout key in
      Table.replace state layout.filepath (Read p) ;
      let+ _file, value = p in
      value

  (* Very similar to [read] action except we only look at the bitset
     value avoiding one I/O. *)
  let value_exists {files; state; lru; closed} layout key =
    let open Lwt_syntax in
    if !closed then
      Lwt.return
        (Error (Error_monad.TzTrace.make (Closed {action = "value_exists"})))
    else
      let on_file_closed ~on_file_opened =
        let* r = may_load_file files state lru layout.filepath in
        match r with
        | None -> return (None, Ok false)
        | Some opened_file_promise ->
            Table.replace files layout.filepath (Opening opened_file_promise) ;
            let* opened_file = opened_file_promise in
            on_file_opened opened_file
      in
      let p = Action.value_exists ~on_file_closed files state layout key in
      Table.replace state layout.filepath (Value_exists p) ;
      let+ _, exists = p in
      exists

  let write ?(override = false) {files; state; lru; closed} layout key data =
    let open Lwt_syntax in
    if !closed then
      Lwt.return (Error (Error_monad.TzTrace.make (Closed {action = "write"})))
    else
      let on_file_closed ~on_file_opened =
        let opened_file_promise =
          load_or_initialize_file files state lru layout
        in
        Table.replace files layout.filepath (Opening opened_file_promise) ;
        let* opened_file = opened_file_promise in
        on_file_opened opened_file
      in
      let p =
        Action.write ~on_file_closed ~override files state layout key data
      in
      Table.replace state layout.filepath (Write p) ;
      let+ _file, result = p in
      result

  let remove {files; state; lru; closed} layout =
    let open Lwt_syntax in
    if !closed then
      Lwt.return (Error (Error_monad.TzTrace.make (Closed {action = "remove"})))
    else
      let on_file_closed ~on_file_opened:_ = may_remove_file layout.filepath in
      let p =
        Action.remove_file ~on_file_closed files state lru layout.filepath
      in
      Table.replace state layout.filepath (Remove p) ;
      Table.replace files layout.filepath (Closing p) ;
      let* () = p in
      (* See [close_file] for an explanation of the lines below. *)
      (match Table.find_opt state layout.filepath with
      | Some (Close p) -> (
          match Lwt.state p with
          | Lwt.Return _ -> Table.remove state layout.filepath
          | _ -> ())
      | _ -> ()) ;
      return_ok ()
end

(* Main data-structure of the store.

   Each phisycal file may have a different layout.
*)
type ('file, 'key, 'value) t = {
  layout_of : 'file -> ('key, 'value) layout;
  files : 'value Files.t;
}

let layout ?encoded_value_size ~encoding ~filepath ~eq ~index_of () =
  match encoded_value_size with
  | Some value_size -> {filepath; eq; encoding; index_of; value_size}
  | None -> (
      match Data_encoding.classify encoding with
      | `Fixed value_size -> {filepath; eq; encoding; index_of; value_size}
      | `Dynamic | `Variable ->
          invalid_arg
            "Key_value_store.layout: encoding does not have fixed size")

let init ~lru_size layout_of =
  let files = Files.init ~lru_size in
  {layout_of; files}

let close {files; _} = Files.close files

let write_value :
    type file key value.
    ?override:bool ->
    (file, key, value) t ->
    file ->
    key ->
    value ->
    unit tzresult Lwt.t =
 fun ?override {files; layout_of} file key value ->
  let layout = layout_of file in
  Files.write ?override files layout key value

let read_value :
    type file key value.
    (file, key, value) t -> file -> key -> value tzresult Lwt.t =
 fun {files; layout_of} file key ->
  let layout = layout_of file in
  Files.read files layout key

let value_exists :
    type file key value.
    (file, key, value) t -> file -> key -> bool tzresult Lwt.t =
 fun {files; layout_of} file key ->
  let layout = layout_of file in
  Files.value_exists files layout key

let write_values ?override t seq =
  Seq.ES.iter
    (fun (file, key, value) -> write_value ?override t file key value)
    seq

let read_values t seq =
  let open Lwt_syntax in
  Seq_s.of_seq seq
  |> Seq_s.S.map (fun (file, key) ->
         let* maybe_value = read_value t file key in
         return (file, key, maybe_value))

let values_exist t seq =
  let open Lwt_syntax in
  Seq_s.of_seq seq
  |> Seq_s.S.map (fun (file, key) ->
         let* maybe_value = value_exists t file key in
         return (file, key, maybe_value))

let remove_file {files; layout_of} file =
  let layout = layout_of file in
  Files.remove files layout
