(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(** An integer value between 0 and 100, inclusive. *)
type t = private int

val encoding : t Data_encoding.t

val of_ratio_bounded : Ratio_repr.t -> t

(** Constants *)

val p7 : t

val p50 : t
