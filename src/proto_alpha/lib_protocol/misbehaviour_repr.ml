(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

type kind = Double_baking | Double_attesting

let kind_encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        (Tag 0)
        ~title:"Double baking"
        (constant "double baking")
        (function Double_baking -> Some () | _ -> None)
        (fun () -> Double_baking);
      case
        (Tag 1)
        ~title:"Double attesting"
        (constant "double attesting")
        (function Double_attesting -> Some () | _ -> None)
        (fun () -> Double_attesting);
    ]

type t = {
  kind : kind;
  level : Raw_level_repr.t;
  round : Round_repr.t;
  slot : Slot_repr.t;
}

let encoding =
  let open Data_encoding in
  conv
    (fun {kind; level; round; slot} -> (kind, level, round, slot))
    (fun (kind, level, round, slot) -> {kind; level; round; slot})
    (obj4
       (req "kind" kind_encoding)
       (req "level" Raw_level_repr.encoding)
       (req "round" Round_repr.encoding)
       (req "slot" Slot_repr.encoding))

module Internal_for_tests = struct
  let pp fmt {kind; level; round; slot} =
    Format.fprintf
      fmt
      "misbehaviour kind: %s; level: %a; round: %a; slot: %a@."
      (match kind with
      | Double_baking -> "double baking"
      | Double_attesting -> "double attesting")
      Raw_level_repr.pp
      level
      Round_repr.pp
      round
      Slot_repr.pp
      slot

  let compare_kind k1 k2 =
    match (k1, k2) with
    | Double_baking, Double_attesting -> -1
    | Double_baking, Double_baking | Double_attesting, Double_attesting -> 0
    | Double_attesting, Double_baking -> 1

  include Compare.Make (struct
    type nonrec t = t

    let compare {kind = k1; level = l1; round = r1; slot = s1}
        {kind = k2; level = l2; round = r2; slot = s2} =
      Compare.or_else (compare_kind k1 k2) @@ fun () ->
      Compare.or_else (Raw_level_repr.compare l1 l2) @@ fun () ->
      Compare.or_else (Round_repr.compare r1 r2) @@ fun () ->
      Slot_repr.compare s1 s2
  end)

  let of_first_duplicate_operation (type a)
      (duplicate_op : a Operation_repr.Kind.consensus Operation_repr.operation)
      =
    let ({slot; level; round; block_payload_hash = _}
          : Operation_repr.consensus_content) =
      match duplicate_op.protocol_data.contents with
      | Single (Preattestation consensus_content) -> consensus_content
      | Single (Attestation {consensus_content; _}) -> consensus_content
    in
    {kind = Double_attesting; level; round; slot}

  let of_duplicate_operations op1 op2 =
    let op1_is_first =
      Operation_hash.(Operation_repr.hash op1 < Operation_repr.hash op2)
    in
    of_first_duplicate_operation (if op1_is_first then op1 else op2)
end
