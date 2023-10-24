(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
(*                                                                           *)
(*****************************************************************************)

(** DAL related parameters for the PVMs.  *)

(** DAL related parameters that would be useful to the kernel. *)
type t = {attestation_lag : int; slot_size : int; page_size : int}

(** Pretty-printer for the parameters. *)
val pp : Format.formatter -> t -> unit

(** Equality of the parameters. *)
val equal : t -> t -> bool

(** Encoding of the parameters. *)
val encoding : t Data_encoding.t
