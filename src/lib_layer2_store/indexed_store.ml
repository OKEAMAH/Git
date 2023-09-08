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

open Store_sigs
open Store_errors

(* Helper functions to copy byte sequences or integers in [src] to another byte
   sequence [dst] at offset [offset], with named arguments to avoid
   confusion. These functions return the offset in the destination at which to
   copy the more data. *)

let blit ~src ~dst offset =
  let len = Bytes.length src in
  Bytes.blit src 0 dst offset len ;
  offset + len

let bytes_set_int64 ~src ~dst offset =
  Bytes.set_int64_be dst offset src ;
  offset + 8

let bytes_set_int8 ~src ~dst offset =
  Bytes.set_int8 dst offset src ;
  offset + 1

(* Helper functions to read data (strings with a decoding function, or integers)
   from a binary string. These functions return, as the second component, the
   offset in the string at which to read more data. *)

let read_int64 str offset =
  let i = TzEndian.get_int64_string str offset in
  (i, offset + 8)

let read_int8 str offset =
  let i = TzEndian.get_int8_string str offset in
  (i, offset + 1)

(* Functors to build stores on indexes *)

module type NAME = sig
  val name : string
end

module type SINGLETON_STORE = sig
  type +'a t

  type value

  val load : path:string -> 'a mode -> 'a t tzresult Lwt.t

  val read : [> `Read] t -> value option tzresult Lwt.t

  val write : [> `Write] t -> value -> unit tzresult Lwt.t

  val delete : [> `Write] t -> unit tzresult Lwt.t

  val readonly : [> `Read] t -> [`Read] t
end

module type INDEXABLE_STORE = sig
  type +'a t

  type key

  type value

  val load :
    path:string -> index_buffer_size:int -> 'a mode -> 'a t tzresult Lwt.t

  val mem : [> `Read] t -> key -> bool tzresult Lwt.t

  val find : [> `Read] t -> key -> value option tzresult Lwt.t

  val add : ?flush:bool -> [> `Write] t -> key -> value -> unit tzresult Lwt.t

  val close : _ t -> unit tzresult Lwt.t

  val readonly : [> `Read] t -> [`Read] t

  val gc : ?async:bool -> _ t -> retain:key list -> unit Lwt.t
end

module type INDEXABLE_REMOVABLE_STORE = sig
  include INDEXABLE_STORE

  val remove : ?flush:bool -> [> `Write] t -> key -> unit tzresult Lwt.t
end

module type INDEXED_FILE = sig
  type +'a t

  type key

  type header

  type value

  val mem : [> `Read] t -> key -> bool tzresult Lwt.t

  val header : [> `Read] t -> key -> header option tzresult Lwt.t

  val read : [> `Read] t -> key -> (value * header) option tzresult Lwt.t

  val append :
    ?flush:bool ->
    [> `Write] t ->
    key:key ->
    header:header ->
    value:value ->
    unit tzresult Lwt.t

  val load :
    path:string ->
    index_buffer_size:int ->
    cache_size:int ->
    'a mode ->
    'a t tzresult Lwt.t

  val close : _ t -> unit tzresult Lwt.t

  val readonly : [> `Read] t -> [`Read] t
end

module type SIMPLE_INDEXED_FILE = sig
  include INDEXED_FILE

  val append :
    ?flush:bool -> [> `Write] t -> key:key -> value:value -> unit tzresult Lwt.t
end

module type ENCODABLE_VALUE = sig
  type t

  val name : string

  val encoding : t Data_encoding.t
end

module type FIXED_ENCODABLE_VALUE = sig
  include ENCODABLE_VALUE

  val fixed_size : int
end

module type ENCODABLE_VALUE_HEADER = sig
  include ENCODABLE_VALUE

  module Header : FIXED_ENCODABLE_VALUE
end

module Make_fixed_encodable (V : ENCODABLE_VALUE) :
  FIXED_ENCODABLE_VALUE with type t = V.t = struct
  include V

  let fixed_size =
    match Data_encoding.Binary.fixed_length encoding with
    | None -> Stdlib.invalid_arg (name ^ " encoding is not fixed size")
    | Some size -> size
end

module Make_index_value (E : FIXED_ENCODABLE_VALUE) :
  Index.Value.S with type t = E.t = struct
  type t = E.t

  let encoded_size = E.fixed_size

  let encode v =
    Data_encoding.Binary.to_string_exn ~buffer_size:encoded_size E.encoding v

  let decode buf offset =
    let _read_bytes, v =
      Data_encoding.Binary.read_exn E.encoding buf offset encoded_size
    in
    v

  (* The {!Repr.t} value is only used for pretty printing in {!Index} so this is
     fine. *)
  let t = Repr.map Repr.string (fun s -> decode s 0) encode
end

module Make_index_key (E : sig
  include FIXED_ENCODABLE_VALUE

  val equal : t -> t -> bool
end) : Index.Key.S with type t = E.t = struct
  include Make_index_value (E)

  let equal = E.equal

  let hash v = Stdlib.Hashtbl.hash (encode v)

  (* {!Stdlib.Hashtbl.hash} is 30 bits *)
  let hash_size = 30 (* in bits *)
end

module Make_indexable (N : NAME) (K : Index.Key.S) (V : Index.Value.S) = struct
  module I = Index_unix.Make (K) (V) (Index.Cache.Unbounded)

  type internal_index = {index : I.t; index_path : string}

  type gc_status =
    | No_gc
    | Ongoing of {tmp_index : internal_index; promise : unit Lwt.t}
    | Failed of tztrace

  type pending_gc = {retain : K.t list; filter : V.t -> bool}

  type _ t = {
    mutable fresh : internal_index;
    mutable stales : internal_index list;
    scheduler : Lwt_idle_waiter.t;
    readonly : bool;
    index_buffer_size : int;
    path : string;
    mutable gc_status : gc_status;
    pending_gcs : pending_gc Queue.t;
  }

  let internal_indexes store = store.fresh :: store.stales

  let unsafe_mem store k =
    List.exists (fun i -> I.mem i.index k) (internal_indexes store)

  let mem store k =
    let open Lwt_result_syntax in
    trace (Cannot_read_from_store N.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.task store.scheduler @@ fun () ->
    return (unsafe_mem store k)

  let find_index i k = try Some (I.find i k) with Not_found -> None

  let unsafe_find store k =
    List.find_map
      (fun i ->
        try find_index i.index k
        with e ->
          Format.kasprintf
            Stdlib.failwith
            "cannot access index %s : %s"
            i.index_path
            (Printexc.to_string e))
      (internal_indexes store)

  let find store k =
    let open Lwt_result_syntax in
    trace (Cannot_read_from_store N.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.task store.scheduler @@ fun () ->
    return (unsafe_find store k)

  let add ?(flush = true) store k v =
    let open Lwt_result_syntax in
    trace (Cannot_write_to_store N.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    I.replace store.fresh.index k v ;
    if flush then I.flush store.fresh.index ;
    return_unit

  let stale_path path n = String.concat "." [path; string_of_int n]

  let tmp_path path = String.concat "." [path; "tmp"]

  let load_internal_index ~index_buffer_size ~readonly index_path =
    let index = I.v ~log_size:index_buffer_size ~readonly index_path in
    {index; index_path}

  let load (type a) ~path ~index_buffer_size (mode : a mode) :
      a t tzresult Lwt.t =
    let open Lwt_result_syntax in
    trace (Cannot_load_store {name = N.name; path})
    @@ protect
    @@ fun () ->
    let*! () = Lwt_utils_unix.create_dir (Filename.dirname path) in
    let readonly = match mode with Read_only -> true | Read_write -> false in
    let fresh = load_internal_index ~index_buffer_size ~readonly path in
    let rec load_stales acc n =
      let open Lwt_syntax in
      if n = 1 then
        let stale =
          load_internal_index
            ~index_buffer_size
            ~readonly:true
            (stale_path path 1)
        in
        load_stales (stale :: acc) (n + 1)
      else
        let stale_path = stale_path path n in
        let*! exists = Lwt_unix.file_exists stale_path in
        if exists then
          let stale =
            load_internal_index ~index_buffer_size ~readonly:true stale_path
          in
          load_stales (stale :: acc) (n + 1)
        else return acc
    in
    let*! stales = load_stales [] 1 in
    let scheduler = Lwt_idle_waiter.create () in
    return
      {
        fresh;
        stales;
        scheduler;
        readonly;
        index_buffer_size;
        path;
        gc_status = No_gc;
        pending_gcs = Queue.create ();
      }

  let close_internal_index i = try I.close i.index with Index.Closed -> ()

  let mv_internal_index index dest =
    close_internal_index index ;
    Lwt_unix.rename index.index_path dest

  let rm_internal_index index =
    close_internal_index index ;
    Lwt_utils_unix.remove_dir index.index_path

  let close store =
    protect @@ fun () ->
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    let open Lwt_result_syntax in
    (match store.gc_status with
    | Ongoing {promise; _} -> Lwt.cancel promise
    | _ -> ()) ;
    close_internal_index store.fresh ;
    List.iter close_internal_index store.stales ;
    let*! () =
      match store.gc_status with
      | No_gc | Failed _ -> Lwt.return_unit
      | Ongoing {tmp_index; _} -> rm_internal_index tmp_index
    in
    return_unit

  let readonly x = (x :> [`Read] t)

  let initiate_gc store =
    let open Lwt_syntax in
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    let tmp_index_path = tmp_path store.path in
    let new_stale_path = stale_path store.path (List.length store.stales + 1) in
    let* () = mv_internal_index store.fresh new_stale_path in
    let new_index_fresh =
      load_internal_index
        ~index_buffer_size:store.index_buffer_size
        ~readonly:store.readonly
        store.path
    in
    let new_index_stale =
      load_internal_index
        ~index_buffer_size:store.index_buffer_size
        ~readonly:store.readonly
        new_stale_path
    in
    let tmp_index =
      load_internal_index
        ~index_buffer_size:store.index_buffer_size
        ~readonly:false
        tmp_index_path
    in
    I.clear tmp_index.index ;
    store.fresh <- new_index_fresh ;
    store.stales <- new_index_stale :: store.stales ;
    return tmp_index

  let revert_failed_gc store error =
    let open Lwt_syntax in
    match store.gc_status with
    | No_gc | Failed _ -> return_unit
    | Ongoing {tmp_index; promise} ->
        Lwt.cancel promise ;
        store.gc_status <- Failed error ;
        rm_internal_index tmp_index

  let unsafe_retain_one_item store tmp_index filter k =
    match unsafe_find store k with
    | None -> Lwt.return_unit
    | Some v ->
        if filter v then I.replace tmp_index.index k v ;
        Lwt.return_unit

  let unsafe_finalize_gc store tmp_index =
    let open Lwt_syntax in
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    let* () = List.iter_s rm_internal_index store.stales in
    let stale_path = stale_path store.path 1 in
    let* () = mv_internal_index tmp_index stale_path in
    let index_stale =
      load_internal_index
        ~index_buffer_size:store.index_buffer_size
        ~readonly:store.readonly
        stale_path
    in
    store.stales <- [index_stale] ;
    store.gc_status <- No_gc ;
    return_unit

  let rec finalize_gc store tmp =
    let open Lwt_result_syntax in
    protect @@ fun () ->
    let*! () = unsafe_finalize_gc store tmp in
    let*! () =
      try
        let {retain; filter} = Queue.pop store.pending_gcs in
        gc_internal false store retain filter
      with Queue.Empty -> Lwt.return_unit
    in
    return_unit

  and gc_background_task store tmp_index retain filter =
    let open Lwt_syntax in
    let* res =
      let open Lwt_result_syntax in
      protect @@ fun () ->
      let*! () =
        List.iter_s (unsafe_retain_one_item store tmp_index filter) retain
      in
      finalize_gc store tmp_index
    in
    match res with
    | Ok () -> return_unit
    | Error error -> revert_failed_gc store error

  and gc_internal async store retain filter =
    let open Lwt_syntax in
    let* tmp_index = initiate_gc store in
    let promise = gc_background_task store tmp_index retain filter in
    store.gc_status <- Ongoing {tmp_index; promise} ;
    if async then return_unit else promise

  let gc_internal async store retain filter =
    match store.gc_status with
    | No_gc | Failed _ -> gc_internal async store retain filter
    | Ongoing _ ->
        Queue.push {retain; filter} store.pending_gcs ;
        Lwt.return_unit

  let gc ?(async = true) store ~retain =
    gc_internal async store retain (fun _ -> true)
end

module Make_indexable_removable (N : NAME) (K : Index.Key.S) (V : Index.Value.S) =
struct
  module V_opt = struct
    (* The values stored in the index are optional values.  When we "remove" a
       key from the store, we're not really removing it from the index, but
       simply setting its association to [None] (encoded with zero bytes here).
    *)

    type t = V.t option

    let t = Repr.option V.t

    let encoded_size = 1 + V.encoded_size

    let encode v =
      let dst = Bytes.create encoded_size in
      let tag, value_bytes =
        match v with
        | None -> (0, Bytes.make V.encoded_size '\000')
        | Some v -> (1, V.encode v |> Bytes.unsafe_of_string)
      in
      let offset = bytes_set_int8 ~dst ~src:tag 0 in
      let _ = blit ~src:value_bytes ~dst offset in
      Bytes.unsafe_to_string dst

    let decode str offset =
      let tag, offset = read_int8 str offset in
      match tag with
      | 0 -> None
      | 1 ->
          let value = V.decode str offset in
          Some value
      | _ -> assert false
  end

  include Make_indexable (N) (K) (V_opt)

  let find store k =
    let open Lwt_result_syntax in
    let+ v = find store k in
    match v with None | Some None -> None | Some (Some v) -> Some v

  let mem store hash =
    let open Lwt_result_syntax in
    let+ b = find store hash in
    Option.is_some b

  let add ?flush store k v = add ?flush store k (Some v)

  let remove ?(flush = true) store k =
    let open Lwt_result_syntax in
    trace (Cannot_write_to_store N.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    let exists = unsafe_mem store k in
    if not exists then return_unit
    else (
      I.replace store.fresh.index k None ;
      if flush then I.flush store.fresh.index ;
      return_unit)

  let gc ?(async = true) store ~retain =
    gc_internal async store retain Option.is_some
end

module Make_singleton (S : sig
  type t

  val name : string

  val encoding : t Data_encoding.t
end) : SINGLETON_STORE with type value := S.t = struct
  type +'a t = {file : string; mutable cache : S.t option option}

  let read_disk store =
    let open Lwt_result_syntax in
    trace (Cannot_read_from_store S.name)
    @@ protect
    @@ fun () ->
    let*! exists = Lwt_unix.file_exists store.file in
    match exists with
    | false -> return_none
    | true -> (
        Lwt_io.with_file
          ~flags:[Unix.O_RDONLY; O_CLOEXEC]
          ~mode:Input
          store.file
        @@ fun channel ->
        let*! raw_data = Lwt_io.read channel in
        let data = Data_encoding.Binary.of_string S.encoding raw_data in
        match data with
        | Ok data -> return_some data
        | Error err -> tzfail (Decoding_error err))

  let read store =
    let open Lwt_result_syntax in
    match store.cache with Some v -> return v | None -> read_disk store

  let write_disk store x =
    let open Lwt_result_syntax in
    trace (Cannot_write_to_store S.name)
    @@ let*! res =
         Lwt_utils_unix.with_atomic_open_out ~overwrite:true store.file
         @@ fun fd ->
         let block_bytes = Data_encoding.Binary.to_bytes_exn S.encoding x in
         Lwt_utils_unix.write_bytes fd block_bytes
       in
       Result.bind_error res Lwt_utils_unix.tzfail_of_io_error |> Lwt.return

  let write store x =
    let open Lwt_result_syntax in
    let+ () = write_disk store x in
    store.cache <- Some (Some x)

  let delete_disk store =
    let open Lwt_result_syntax in
    trace (Cannot_write_to_store S.name)
    @@ protect
    @@ fun () ->
    let*! exists = Lwt_unix.file_exists store.file in
    match exists with
    | false -> return_unit
    | true ->
        let*! () = Lwt_unix.unlink store.file in
        return_unit

  let delete store =
    let open Lwt_result_syntax in
    let+ () = delete_disk store in
    store.cache <- Some None

  let load ~path _mode =
    let open Lwt_result_syntax in
    trace (Cannot_load_store {name = S.name; path})
    @@ protect
    @@ fun () ->
    let*! () = Lwt_utils_unix.create_dir (Filename.dirname path) in
    return {file = path; cache = None}

  let readonly x = (x :> [`Read] t)
end

module Make_indexed_file
    (N : NAME)
    (K : Index.Key.S)
    (V : ENCODABLE_VALUE_HEADER) =
struct
  module Cache =
    Aches_lwt.Lache.Make_result (Aches.Rache.Transfer (Aches.Rache.LRU) (K))
  module Raw_header = Make_index_value (V.Header)

  module IHeader = struct
    let name = N.name ^ ".header"

    type t = {offset : int; header : V.Header.t}

    let encoded_size = 8 (* offset *) + Raw_header.encoded_size

    let t =
      let open Repr in
      map
        (pair int Raw_header.t)
        (fun (offset, header) -> {offset; header})
        (fun {offset; header} -> (offset, header))

    let encode v =
      let dst = Bytes.create encoded_size in
      let offset = bytes_set_int64 ~src:(Int64.of_int v.offset) ~dst 0 in
      let _offset =
        blit ~src:(Raw_header.encode v.header |> String.to_bytes) ~dst offset
      in
      Bytes.unsafe_to_string dst

    let decode str offset =
      let file_offset, offset = read_int64 str offset in
      let header = Raw_header.decode str offset in
      {offset = Int64.to_int file_offset; header}
  end

  module Header_index = Index_unix.Make (K) (IHeader) (Index.Cache.Unbounded)

  module Values_file = struct
    let encoding = Data_encoding.dynamic_size ~kind:`Uint30 V.encoding

    let pread_value fd ~file_offset =
      let open Lwt_result_syntax in
      trace (Cannot_read_from_store N.name)
      @@ protect
      @@ fun () ->
      (* Read length *)
      let length_bytes = Bytes.create 4 in
      let*! () =
        Lwt_utils_unix.read_bytes ~file_offset ~pos:0 ~len:4 fd length_bytes
      in
      let value_length_int32 = Bytes.get_int32_be length_bytes 0 in
      let value_length = Int32.to_int value_length_int32 in
      let value_bytes = Bytes.extend length_bytes 0 value_length in
      let*! () =
        Lwt_utils_unix.read_bytes
          ~file_offset:(file_offset + 4)
          ~pos:4
          ~len:value_length
          fd
          value_bytes
      in
      match Data_encoding.Binary.of_bytes encoding value_bytes with
      | Ok value -> return (value, 4 + value_length)
      | Error err -> tzfail (Decoding_error err)
  end

  type _ t = {
    index : Header_index.t;
    fd : Lwt_unix.file_descr;
    scheduler : Lwt_idle_waiter.t;
    readonly : bool;
    cache : (V.t * V.Header.t, tztrace) Cache.t;
    index_path : string;
    data_path : string;
  }

  let mem store key =
    let open Lwt_result_syntax in
    trace (Cannot_read_from_store IHeader.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.task store.scheduler @@ fun () ->
    let cached =
      Cache.bind store.cache key (fun v -> Lwt.return (Result.is_ok v))
    in
    let*! cached = Option.value cached ~default:Lwt.return_false in
    return (cached || Header_index.mem store.index key)

  let header store key =
    let open Lwt_result_syntax in
    trace (Cannot_read_from_store IHeader.name)
    @@ protect
    @@ fun () ->
    Lwt_idle_waiter.task store.scheduler @@ fun () ->
    let cached =
      Cache.bind store.cache key @@ function
      | Ok (_value, header) -> return header
      | Error _ as e -> Lwt.return e
    in
    match cached with
    | Some header -> Lwt_result.map Option.some header
    | None -> (
        match Header_index.find store.index key with
        | exception Not_found -> return_none
        | {header; _} -> return_some header)

  let read store key =
    Lwt_idle_waiter.task store.scheduler @@ fun () ->
    let read_from_disk key =
      let open Lwt_result_syntax in
      match Header_index.find store.index key with
      | exception Not_found -> tzfail (Exn Not_found)
      | {IHeader.offset; header} ->
          let+ value, _ofs =
            Values_file.pread_value store.fd ~file_offset:offset
          in
          (value, header)
    in
    let open Lwt_result_syntax in
    Cache.bind_or_put store.cache key read_from_disk @@ function
    | Ok value -> return_some value
    | Error _ -> return_none

  let locked_write_value store ~offset ~value ~key ~header =
    trace_eval (fun () -> Cannot_write_to_store N.name)
    @@ protect
    @@ fun () ->
    let open Lwt_result_syntax in
    let value_bytes =
      Data_encoding.Binary.to_bytes_exn Values_file.encoding value
    in
    let value_length = Bytes.length value_bytes in
    let*! () =
      Lwt_utils_unix.write_bytes ~pos:0 ~len:value_length store.fd value_bytes
    in
    Header_index.replace store.index key {offset; header} ;
    return value_length

  let append ?(flush = true) store ~key ~header ~(value : V.t) =
    trace (Cannot_write_to_store N.name)
    @@ protect
    @@ fun () ->
    let open Lwt_result_syntax in
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    Cache.put store.cache key (return (value, header)) ;
    let*! offset = Lwt_unix.lseek store.fd 0 Unix.SEEK_END in
    let*! _written_len = locked_write_value store ~offset ~value ~key ~header in
    if flush then Header_index.flush store.index ;
    return_unit

  let load (type a) ~path ~index_buffer_size ~cache_size (mode : a mode) :
      a t tzresult Lwt.t =
    let open Lwt_result_syntax in
    trace (Cannot_load_store {name = N.name; path})
    @@ protect
    @@ fun () ->
    let*! () = Lwt_utils_unix.create_dir path in
    let readonly = match mode with Read_only -> true | Read_write -> false in
    let flag = if readonly then Unix.O_RDONLY else Unix.O_RDWR in
    let data_path = Filename.concat path "data" in
    let*! fd =
      Lwt_unix.openfile data_path [Unix.O_CREAT; O_CLOEXEC; flag] 0o644
    in
    let index_path = Filename.concat path "index" in
    let index =
      Header_index.v ~log_size:index_buffer_size ~readonly index_path
    in
    let scheduler = Lwt_idle_waiter.create () in
    let cache = Cache.create cache_size in
    return {index; fd; scheduler; readonly; cache; index_path; data_path}

  let close store =
    protect @@ fun () ->
    Lwt_idle_waiter.force_idle store.scheduler @@ fun () ->
    (try Header_index.close store.index with Index.Closed -> ()) ;
    Lwt_utils_unix.safe_close store.fd

  let readonly x = (x :> [`Read] t)
end

module Make_simple_indexed_file
    (N : NAME)
    (K : Index.Key.S) (V : sig
      include ENCODABLE_VALUE_HEADER

      val header : t -> Header.t
    end) =
struct
  include Make_indexed_file (N) (K) (V)

  let append ?flush store ~key ~value =
    append ?flush store ~key ~value ~header:(V.header value)
end
