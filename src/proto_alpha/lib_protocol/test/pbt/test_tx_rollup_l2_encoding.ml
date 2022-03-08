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
open Protocol.Tx_rollup_l2_apply

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

let signer_index_gen : Signer_indexable.index QCheck2.Gen.t =
  let open QCheck2.Gen in
  (fun x -> Protocol.Indexable.index_exn x) <$> ui32

let l2_address_gen =
  let open QCheck2.Gen in
  Protocol.Tx_rollup_l2_address.of_bls_pk <$> bls_pk_gen

let public_key_hash =
  Signature.Public_key_hash.of_b58check_exn
    "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU"

let destination_gen =
  let open QCheck2.Gen in
  let* choice = bool in
  if choice then return (Layer1 public_key_hash)
  else
    let* choice = bool in
    if choice then (fun x -> Layer2 (from_index_exn x)) <$> ui32
    else (fun x -> Layer2 (from_value x)) <$> l2_address_gen

let ticket_hash_gen : Protocol.Alpha_context.Ticket_hash.t QCheck2.Gen.t =
  let open QCheck2.Gen in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/2592
     we could introduce a bit more randomness here *)
  let ticketer_b58 = "tz1Ke2h7sDdakHJQh8WX4Z372du1KChsksyU" in
  let ticketer_pkh = Signature.Public_key_hash.of_b58check_exn ticketer_b58 in
  let ticketer =
    Protocol.Alpha_context.Contract.implicit_contract ticketer_pkh
  in
  let+ tx_rollup = l2_address_gen in
  Tx_rollup_l2_helpers.make_unit_ticket_key ticketer tx_rollup

let idx_ticket_hash_idx_gen : Ticket_indexes.key either QCheck2.Gen.t =
  let open QCheck2.Gen in
  from_index_exn <$> ui32

let idx_ticket_hash_value_gen : Ticket_indexes.key either QCheck2.Gen.t =
  let open QCheck2.Gen in
  from_value <$> ticket_hash_gen

let idx_ticket_hash_gen : Ticket_indexes.key either QCheck2.Gen.t =
  let open QCheck2.Gen in
  oneof [idx_ticket_hash_idx_gen; idx_ticket_hash_value_gen]

let qty_gen =
  let open QCheck2.Gen in
  Protocol.Tx_rollup_l2_qty.of_int64_exn
  <$> graft_corners ui64 [0L; 1L; 2L; Int64.max_int] ()

let v1_operation_content_gen =
  let open QCheck2.Gen in
  let* destination = destination_gen and+ qty = qty_gen in
  (* in valid [operation_content]s, the ticket_hash is a value when the
     destination is layer1 *)
  let+ ticket_hash =
    match destination with
    | Layer1 _ -> idx_ticket_hash_value_gen
    | Layer2 _ -> idx_ticket_hash_gen
  in
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

let indexes_gen =
  let open QCheck2.Gen in
  let ticket_hash_gen =
    match Tx_rollup_l2_helpers.gen_n_ticket_hash 1 with
    | [ticket] -> pure ticket
    | _ -> assert false
  in
  let* addresses =
    small_list (pair l2_address_gen (map Protocol.Indexable.index_exn ui32))
  in
  let+ tickets =
    small_list (pair ticket_hash_gen (map Protocol.Indexable.index_exn ui32))
  in
  let address_indexes : address_indexes =
    Protocol.Tx_rollup_l2_apply.Internal_for_tests.address_indexes_of_list
      addresses
  in
  let ticket_indexes : ticket_indexes =
    Protocol.Tx_rollup_l2_apply.Internal_for_tests.ticket_indexes_of_list
      tickets
  in
  {address_indexes; ticket_indexes}

let deposit_result_gen =
  let open QCheck2.Gen in
  let open Message_result in
  let success =
    let+ indexes = indexes_gen in
    Deposit_success indexes
  in
  (* We do no test here the encodings for every errors *)
  let failure =
    let error = Protocol.Tx_rollup_l2_apply.Incorrect_aggregated_signature in
    pure (Deposit_failure error)
  in
  let+ result = oneof [success; failure] in
  Deposit_result result

(** This is a particular transaction generator, the signers are provided
    with indexes only. *)
let v1_transaction_index_signer_gen :
    (index_only, unknown) V1.transaction QCheck2.Gen.t =
  let open QCheck2.Gen in
  let operation_signer_index_gen =
    let+ signer = signer_index_gen
    and+ counter = Int64.of_int <$> int
    and+ contents = small_list v1_operation_content_gen in
    V1.{signer; counter; contents}
  in
  small_list operation_signer_index_gen

let transaction_result_gen =
  let open QCheck2.Gen in
  let open Message_result in
  let success = pure Transaction_success in
  let failure =
    let reason = Protocol.Tx_rollup_l2_apply.Incorrect_aggregated_signature in
    let+ index = small_nat in
    Transaction_failure {index; reason}
  in
  oneof [success; failure]

let batch_v1_result_gen : Message_result.Batch_V1.t QCheck2.Gen.t =
  let open QCheck2.Gen in
  let* results =
    small_list (pair v1_transaction_index_signer_gen transaction_result_gen)
  in
  let+ indexes = indexes_gen in
  Message_result.Batch_V1.Batch_result {results; indexes}

let message_result : Message_result.message_result QCheck2.Gen.t =
  let open QCheck2.Gen in
  let open Message_result in
  let batch_v1_result_gen =
    let+ result = batch_v1_result_gen in
    Batch_V1_result result
  in
  frequency [(2, deposit_result_gen); (8, batch_v1_result_gen)]

let withdrawal : Protocol.Alpha_context.Tx_rollup_withdraw.t QCheck2.Gen.t =
  let open QCheck2.Gen in
  let open Protocol.Alpha_context.Tx_rollup_withdraw in
  let destination = public_key_hash in
  let* ticket_hash = ticket_hash_gen in
  let* amount = qty_gen in
  return {destination; ticket_hash; amount}

let message_result_withdrawal : Message_result.t QCheck2.Gen.t =
  let open QCheck2.Gen in
  let+ mres = message_result and+ withdrawals = list withdrawal in
  (mres, withdrawals)

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

let test_roundtrip ~count title arb equ encoding =
  let pp fmt x =
    Data_encoding.Json.construct encoding x
    |> Data_encoding.Json.to_string |> Format.pp_print_string fmt
  in
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
              Protocol.Tx_rollup_l2_batch.encoding;
            test_roundtrip
              ~count:1_000
              "message_result"
              message_result_withdrawal
              ( = )
              Protocol.Tx_rollup_l2_apply.Message_result.encoding;
          ] );
    ]
