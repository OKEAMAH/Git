(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** Testing
    -------
    Component:    Protocol Library
    Invocation:   dune exec \
                  src/proto_alpha/lib_protocol/test/pbt/test_tx_rollup_l2_encoding.exe
    Subject:      Tx rollup l2 encoding
*)

open Lib_test
open Lib_test.Qcheck2_helpers
open Protocol.Indexable
open Protocol.Tx_rollup_l2_batch

(* ------ generators and compact encodings ---------------------------------- *)

let seed_gen =
  let open QCheck2.Gen in
  return @@ Bytes.init 32 (fun _ -> generate1 char)

let bls_pk_gen =
  let open QCheck2.Gen in
  let+ seed = seed_gen in
  let secret_key = Bls12_381.Signature.generate_sk seed in
  Bls12_381.Signature.MinPk.derive_pk secret_key

let signer_gen : Signer_indexable.either QCheck2.Gen.t =
  let open QCheck2.Gen in
  frequency
    [
      (1, (fun pk -> from_value pk) <$> bls_pk_gen);
      (9, (fun x -> from_index_exn x) <$> ui32);
    ]

let l2_address_gen =
  let open QCheck2.Gen in
  Protocol.Tx_rollup_l2_address.of_bls_pk <$> bls_pk_gen

let destination_gen =
  let open QCheck2.Gen in
  let* choice = bool in
  if choice then
    return
    @@ Layer1
         (Signature.Public_key_hash.of_b58check_exn
            "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU")
  else
    let* choice = bool in
    if choice then (fun x -> Layer2 (from_index_exn x)) <$> ui32
    else (fun x -> Layer2 (from_value x)) <$> l2_address_gen

(* Creating ticket hashes *)

let hash_ticket tx_rollup ~contents ~ticketer ~ty =
  let open Protocol in
  let hash_of_node node =
    let node = Micheline.strip_locations node in
    let bytes =
      Data_encoding.Binary.to_bytes_exn Script_repr.expr_encoding node
    in
    Alpha_context.Ticket_hash.of_script_expr_hash
    @@ Script_expr_hash.hash_bytes [bytes]
  in
  let make_ticket_hash ~ticketer ~ty ~contents ~owner =
    hash_of_node
    @@ Micheline.(Seq (dummy_location, [ticketer; ty; contents; owner]))
  in
  let owner =
    Micheline.(
      String (dummy_location, Tx_rollup_l2_address.to_b58check tx_rollup))
  in
  make_ticket_hash ~ticketer ~ty ~contents ~owner

(** [make_unit_ticket_key ctxt ticketer tx_rollup] computes the key hash of
    the unit ticket crafted by [ticketer] and owned by [tx_rollup]. *)
let make_unit_ticket_key ticketer tx_rollup =
  let open Protocol in
  let open Alpha_context in
  let open Tezos_micheline.Micheline in
  let open Michelson_v1_primitives in
  let ticketer =
    Bytes (0, Data_encoding.Binary.to_bytes_exn Contract.encoding ticketer)
  in
  let ty = Prim (0, T_unit, [], []) in
  let contents = Prim (0, D_Unit, [], []) in
  hash_ticket ~ticketer ~ty ~contents tx_rollup

let ticket_hash_idx_gen =
  let open QCheck2.Gen in
  from_index_exn <$> ui32

(* TODO: we introduce a bit more randomness here *)
let ticket_hash_value_gen =
  let open QCheck2.Gen in
  let ticketer_b58 = "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU" in
  let ticketer_pkh = Signature.Public_key_hash.of_b58check_exn ticketer_b58 in
  let ticketer =
    Protocol.Alpha_context.Contract.implicit_contract ticketer_pkh
  in
  let* tx_rollup = l2_address_gen in
  let ticket_hash = make_unit_ticket_key ticketer tx_rollup in
  return (from_value ticket_hash)

let ticket_hash_gen =
  let open QCheck2.Gen in
  oneof [ticket_hash_idx_gen; ticket_hash_value_gen]

let qty_gen =
  let open QCheck2.Gen in
  Protocol.Tx_rollup_l2_qty.of_int64_exn
  <$> graft_corners ui64 [0L; 1L; 2L; Int64.max_int] ()

let v1_operation_content_gen =
  let open QCheck2.Gen in
  (* in valid [operation_content]s, the ticket_hash is a value when the
     destination is layer1 *)
  let* destination = destination_gen in
  match destination with
  | Layer1 _ ->
      let+ ticket_hash = ticket_hash_value_gen and+ qty = qty_gen in
      V1.{destination; ticket_hash; qty}
  | Layer2 _ ->
      (* here ticket hash value *)
      let+ ticket_hash = ticket_hash_gen and+ qty = qty_gen in
      V1.{destination; ticket_hash; qty}

let v1_operation_gen =
  let open QCheck2.Gen in
  let+ signer = signer_gen
  and+ counter = Int64.of_int <$> int
  and+ contents = small_list v1_operation_content_gen in
  V1.{signer; counter; contents}

let v1_transaction_gen =
  let open QCheck2.Gen in
  small_list v1_operation_gen

let v1_batch =
  let open QCheck2.Gen in
  let+ contents = small_list v1_transaction_gen in
  (* This it not ideal as we do not use the QCheck2 seed. We need
     valid bytes since the signature encoding is "safe" and accept
     only valid signatures. However, it should not impact the
     tests here as the bytes length stays the same. *)
  let bytes = Bls12_381.G2.(to_compressed_bytes (random ())) in
  let aggregated_signature =
    Protocol.Environment.Bls_signature.unsafe_signature_of_bytes bytes
  in
  V1.{aggregated_signature; contents}

let batch =
  let open QCheck2.Gen in
  (fun batch -> V1 batch) <$> v1_batch

let pp fmt _ = Format.fprintf fmt "{}"

(* ------ test template ----------------------------------------------------- *)

let test_quantity ~count =
  let open Protocol in
  let open QCheck2.Gen in
  let op_gen = oneofl [`Sub; `Add] in
  let test_gen = triple op_gen qty_gen qty_gen in
  let print (op, q1, q2) =
    Format.asprintf
      "%a %s %a"
      Tx_rollup_l2_qty.pp
      q1
      (match op with `Add -> "+" | `Sub -> "-")
      Tx_rollup_l2_qty.pp
      q2
  in
  let test (op, q1, q2) =
    let f_op =
      match op with
      | `Sub -> Tx_rollup_l2_qty.sub
      | `Add -> Tx_rollup_l2_qty.add
    in
    match f_op q1 q2 with
    | Some q -> Tx_rollup_l2_qty.(q >= zero)
    | None -> (
        match op with
        | `Sub -> Tx_rollup_l2_qty.(q2 > q1)
        | `Add ->
            Int64.add
              (Tx_rollup_l2_qty.to_int64 q1)
              (Tx_rollup_l2_qty.to_int64 q2)
            < 0L)
  in
  QCheck2.Test.make ~count ~print ~name:"quantity operation" test_gen test

let test_roundtrip ~count title arb equ pp encoding =
  let test rdt input =
    let output = Roundtrip.make encoding rdt input in
    let success = equ input output in
    if not success then
      QCheck2.Test.fail_reportf
        "%s %s roundtrip error: %a became %a"
        title
        (Roundtrip.target rdt)
        pp
        input
        pp
        output
  in
  QCheck2.Test.make
    ~count
    ~name:(Format.asprintf "roundtrip %s" title)
    arb
    (fun input ->
      test Roundtrip.binary input ;
      test Roundtrip.json input ;
      true)

let () =
  let qcheck_wrap = qcheck_wrap ~rand:(Random.State.make_self_init ()) in
  Alcotest.run
    "Compact_encoding"
    [
      ("quantity", qcheck_wrap [test_quantity ~count:100_000]);
      ( "roundtrip",
        qcheck_wrap
          [
            test_roundtrip
              ~count:1_000
              "batch"
              batch
              ( = )
              pp
              Protocol.Tx_rollup_l2_batch.encoding;
          ] );
    ]
