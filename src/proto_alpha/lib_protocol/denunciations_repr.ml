(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

type misbehaviour_cycle = Current | Previous

let misbehaviour_cycle_encoding =
  let open Data_encoding in
  conv_with_guard
    (function Current -> 0 | Previous -> 1)
    (function
      | 0 -> Ok Current
      | 1 -> Ok Previous
      | _ -> Error "Invalid misbehaviour cycle")
    int8

type item = {
  operation_hash : Operation_hash.t;
  rewarded : Signature.public_key_hash;
  misbehaviour : Misbehaviour_repr.t;
  misbehaviour_cycle : misbehaviour_cycle;
}

let item_encoding =
  let open Data_encoding in
  conv
    (fun {operation_hash; rewarded; misbehaviour; misbehaviour_cycle} ->
      (operation_hash, rewarded, misbehaviour, misbehaviour_cycle))
    (fun (operation_hash, rewarded, misbehaviour, misbehaviour_cycle) ->
      {operation_hash; rewarded; misbehaviour; misbehaviour_cycle})
    (obj4
       (req "operation_hash" Operation_hash.encoding)
       (req "rewarded" Signature.Public_key_hash.encoding)
       (req "misbehaviour" Misbehaviour_repr.encoding)
       (req "misbehaviour_cycle" misbehaviour_cycle_encoding))

type t = item list

let encoding = Data_encoding.list item_encoding

let add operation_hash rewarded misbehaviour misbehaviour_cycle list =
  list @ [{operation_hash; rewarded; misbehaviour; misbehaviour_cycle}]

module Internal_for_tests = struct
  let pp_item fmt
      {operation_hash = _; rewarded; misbehaviour; misbehaviour_cycle} =
    Format.fprintf
      fmt
      "%a; rewarded: %a; cycle: %s@."
      Misbehaviour_repr.Internal_for_tests.pp
      misbehaviour
      Signature.Public_key_hash.pp
      rewarded
      (match misbehaviour_cycle with
      | Current -> "current"
      | Previous -> "previous")

  let compare_cycle c1 c2 =
    match (c1, c2) with
    | Previous, Current -> -1
    | Previous, Previous | Current, Current -> 0
    | Current, Previous -> 1

  let compare_item_except_hash
      {
        operation_hash = _;
        rewarded = r1;
        misbehaviour = m1;
        misbehaviour_cycle = c1;
      }
      {
        operation_hash = _;
        rewarded = r2;
        misbehaviour = m2;
        misbehaviour_cycle = c2;
      } =
    Compare.or_else (Misbehaviour_repr.Internal_for_tests.compare m1 m2)
    @@ fun () ->
    (* Equal misbehaviours should imply equal cycles. However, we
       still compare the cycles explicitly so that equality assertions
       fail in tests if somehow only the cycles differ. *)
    Compare.or_else (compare_cycle c1 c2) @@ fun () ->
    Signature.Public_key_hash.compare r1 r2
end
