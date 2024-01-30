(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
(*                                                                           *)
(*****************************************************************************)

(** Compression strategy for snapshot archives. *)
type compression =
  | No  (** Produce uncompressed archive. Takes more space. *)
  | On_the_fly
      (** Compress archive on the fly. The rollup node will use less disk space
          to produce the snapshot but will lock the rollup node (if running) for
          a longer time. *)
  | After
      (** Compress archive after snapshot creation. Uses more disk space
          temporarily than {!On_the_fly} but does not lock the rollup node for
          very long. *)

(** [export ~no_checks ~compression ~data_dir ~dest ~filename] creates a tar
    gzipped archive with name [filename] (or a generated name) in [dest] (or the
    current directory) containing a snapshot of the data of the rollup node with
    data directory [data_dir]. The path of the snapshot archive is returned. If
    [no_checks] is [true], the integrity of the snapshot is not checked at the
    end. *)
val export :
  no_checks:bool ->
  compression:compression ->
  data_dir:string ->
  dest:string option ->
  filename:string option ->
  string tzresult Lwt.t

(** [export_compact ~compression ~data_dir ~dest ~filename] creates a tar
    gzipped archive with name [filename] (or a generated name) in [dest] (or the
    current directory) containing a snapshot of the data of the rollup node with
    data directory [data_dir]. The difference with {!export} is that the
    snapshot contains a single commit for the context (which must be
    reconstructed on import) but is significantly smaller. *)
val export_compact :
  compression:compression ->
  data_dir:string ->
  dest:string option ->
  filename:string option ->
  string tzresult Lwt.t

(** [import ~no_checks ~force cctxt ~data_dir ~snapshot_file] imports the
    snapshot at path [snapshot_file] into the data directory [data_dir]. If
    [no_checks] is [true], the integrity of the imported data is not checked at
    the end. Import will fail if [data_dir] is already populated unless [force]
    is set to [true]. *)
val import :
  no_checks:bool ->
  force:bool ->
  #Client_context.full ->
  data_dir:string ->
  snapshot_file:string ->
  unit tzresult Lwt.t

(** [info ~snapshot_file] returns information that can be used to inspect the
    snapshot file. *)
val info :
  snapshot_file:string ->
  Snapshot_utils.snapshot_metadata * [`Compressed | `Uncompressed]
