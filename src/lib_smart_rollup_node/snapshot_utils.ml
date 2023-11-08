(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
(*                                                                           *)
(*****************************************************************************)

module type READER = sig
  type in_channel

  val open_in : string -> in_channel

  val really_input : in_channel -> bytes -> int -> int -> unit

  val input : in_channel -> bytes -> int -> int -> int

  val close_in : in_channel -> unit
end

module type WRITER = sig
  type out_channel

  val open_out : string -> out_channel

  val output : out_channel -> bytes -> int -> int -> unit

  val flush_continue : out_channel -> unit

  val close_out : out_channel -> unit
end

module Stdlib_reader : READER with type in_channel = Stdlib.in_channel = Stdlib

module Stdlib_writer : WRITER with type out_channel = Stdlib.out_channel =
struct
  include Stdlib

  let flush_continue = flush
end

module Gzip_reader : READER with type in_channel = Gzip.in_channel = Gzip

module Gzip_writer : WRITER with type out_channel = Gzip.out_channel = struct
  include Gzip

  let open_out f = open_out f
end

type reader = (module READER)

type writer = (module WRITER)

let stdlib_reader : reader = (module Stdlib_reader)

let stdlib_writer : writer = (module Stdlib_writer)

let gzip_reader : reader = (module Gzip_reader)

let gzip_writer : writer = (module Gzip_writer)

let list_files dir ~include_file f =
  let rec list stream dir prefix =
    let dh = Unix.opendir dir in
    let rec list_dir stream =
      match Unix.readdir dh with
      | "." | ".." -> list_dir stream
      | basename ->
          let file = Filename.concat dir basename in
          let file_base = Filename.concat prefix basename in
          let stream =
            if Sys.is_directory file then list stream file file_base
            else if include_file ~file_base then
              Stream.icons (f ~file ~file_base) stream
            else stream
          in
          list_dir stream
      | exception End_of_file ->
          Unix.closedir dh ;
          stream
    in
    list_dir stream
  in
  list Stream.sempty dir ""

let create (module Reader : READER) (module Writer : WRITER) ~dir ~include_file
    ~dest =
  let module Archive_writer = Tar.Make (struct
    include Reader
    include Writer
  end) in
  let write_file file (out_chan : Writer.out_channel) =
    let in_chan = Reader.open_in file in
    try
      let buffer_size = 64 * 1024 in
      let buf = Bytes.create buffer_size in
      let rec copy () =
        let read_bytes = Reader.input in_chan buf 0 buffer_size in
        Writer.output out_chan buf 0 read_bytes ;
        if read_bytes > 0 then copy ()
      in
      copy () ;
      Writer.flush_continue out_chan ;
      Reader.close_in in_chan
    with e ->
      Reader.close_in in_chan ;
      raise e
  in
  let file_stream =
    list_files dir ~include_file @@ fun ~file ~file_base ->
    let {Unix.st_perm; st_size; st_mtime; _} = Unix.lstat file in
    let header =
      Tar.Header.make
        ~file_mode:st_perm
        ~mod_time:(Int64.of_float st_mtime)
        file_base
        (Int64.of_int st_size)
    in
    let writer = write_file file in
    (header, writer)
  in
  let out_chan = Writer.open_out dest in
  try
    Archive_writer.Archive.create_gen file_stream out_chan ;
    Writer.close_out out_chan
  with e ->
    Writer.close_out out_chan ;
    raise e

let rec create_dir ?(perm = 0o755) dir =
  let stat =
    try Some (Unix.stat dir) with Unix.Unix_error (ENOENT, _, _) -> None
  in
  match stat with
  | Some {st_kind = S_DIR; _} -> ()
  | Some _ -> Stdlib.failwith "Not a directory"
  | None -> (
      create_dir ~perm (Filename.dirname dir) ;
      try Unix.mkdir dir perm
      with Unix.Unix_error (EEXIST, _, _) ->
        (* This is the case where the directory has been created at the same
           time. *)
        ())

let extract (module Reader : READER) (module Writer : WRITER) ~snapshot_file
    ~dest =
  let module Archive_reader = Tar.Make (struct
    include Reader
    include Writer
  end) in
  let out_channel_of_header (header : Tar.Header.t) =
    let path = Filename.concat dest header.file_name in
    create_dir (Filename.dirname path) ;
    Writer.open_out path
  in
  let in_chan = Reader.open_in snapshot_file in
  try
    Archive_reader.Archive.extract_gen out_channel_of_header in_chan ;
    Reader.close_in in_chan
  with e ->
    Reader.close_in in_chan ;
    raise e

let compress ~snapshot_file =
  let snapshot_file_gz = Filename.chop_suffix snapshot_file ".uncompressed" in
  let in_chan = open_in snapshot_file in
  let out_chan = Gzip.open_out snapshot_file_gz in
  try
    let buffer_size = 64 * 1024 in
    let buf = Bytes.create buffer_size in
    let rec copy () =
      let read_bytes = input in_chan buf 0 buffer_size in
      Gzip.output out_chan buf 0 read_bytes ;
      if read_bytes > 0 then copy ()
    in
    copy () ;
    Gzip.close_out out_chan ;
    close_in in_chan ;
    Unix.unlink snapshot_file ;
    snapshot_file_gz
  with e ->
    Gzip.close_out out_chan ;
    close_in in_chan ;
    raise e
