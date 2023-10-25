(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
(*                                                                           *)
(*****************************************************************************)

type t = {
  number_of_slots : int;
  attestation_lag : int;
  slot_size : int;
  page_size : int;
}

let pp ppf {number_of_slots; attestation_lag; slot_size; page_size} =
  Format.fprintf
    ppf
    "number_of_slots: %d ; attestation_lag: %d ; slot_size: %d ; page_size: %d"
    number_of_slots
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
    (fun {number_of_slots; attestation_lag; slot_size; page_size} ->
      (number_of_slots, attestation_lag, slot_size, page_size))
    (fun (number_of_slots, attestation_lag, slot_size, page_size) ->
      {number_of_slots; attestation_lag; slot_size; page_size})
    (obj4
       (req "number_of_slots" int31)
       (req "attestation_lag" int31)
       (req "slot_size" int31)
       (req "page_size" int31))
