(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
(*                                                                           *)
(*****************************************************************************)

type t = {attestation_lag : int; slot_size : int; page_size : int}

let pp ppf {attestation_lag; slot_size; page_size} =
  Format.fprintf
    ppf
    "attestation_lag: %d ; slot_size: %d ; page_size: %d"
    attestation_lag
    slot_size
    page_size

let equal t1 t2 =
  Compare.Int.(
    t1.attestation_lag = t2.attestation_lag
    && t1.slot_size = t2.slot_size
    && t1.page_size = t2.page_size)

let encoding =
  let open Data_encoding in
  conv
    (fun {attestation_lag; slot_size; page_size} ->
      (attestation_lag, slot_size, page_size))
    (fun (attestation_lag, slot_size, page_size) ->
      {attestation_lag; slot_size; page_size})
    (obj3
       (req "attestation_lag" int31)
       (req "slot_size" int31)
       (req "page_size" int31))
