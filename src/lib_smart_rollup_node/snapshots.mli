(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
(*                                                                           *)
(*****************************************************************************)

(** [export ~no_checks ~compress_on_the_fly ~data_dir ~dest] creates a tar
    gzipped archive in [dest] containing a snapshot of the data of the rollup
    node with data directory [data_dir]. The path of the snapshot archive is
    returned. If [no_checks] is [true], the integrity of the snapshot is not
    checked at the end. If [compress_on_the_fly] is [true] the snapshot will be
    produced as compressed on the fly and the rollup node will use less disk
    space to produce the snapshot but will lock the rollup node (if running) for
    a longer (~10x) time. *)
val export :
  no_checks:bool ->
  compress_on_the_fly:bool ->
  data_dir:string ->
  dest:string ->
  string tzresult Lwt.t

(** [import ?no_checks cctxt ~data_dir ~snapshot_file] imports the snapshot at
    path [snapshot_file] into the data directory [data_dir]. If [no_checks] is
    [true], the integrity of the imported data is not checked at the end. *)
val import :
  no_checks:bool ->
  #Client_context.full ->
  data_dir:string ->
  snapshot_file:string ->
  unit tzresult Lwt.t
