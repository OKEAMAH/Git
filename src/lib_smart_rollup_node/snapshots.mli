(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
(*                                                                           *)
(*****************************************************************************)

(** [export cctxt ~data_dir ~dest] creates a tar gzipped archive in [dest]
    containing a snapshot of the data of the rollup node with data directory
    [data_dir]. The path of the snapshot archive is returned. *)
val export :
  #Client_context.full ->
  data_dir:string ->
  dest:string ->
  string tzresult Lwt.t
