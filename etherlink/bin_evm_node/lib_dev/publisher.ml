(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

open Ethereum_types

module type TxEncoder = sig
  type encoded

  val encode_transaction :
    smart_rollup_address:string ->
    transaction:string ->
    (hash * encoded) tzresult
end

module type Publisher = sig
  type message

  val publish_messages :
    smart_rollup_address:string -> messages:message list -> unit tzresult Lwt.t
end

module Make
    (TxEncoder : TxEncoder)
    (Publisher : Publisher with type message = TxEncoder.encoded) =
struct
  let inject_raw_transactions ~smart_rollup_address ~transactions =
    let open Lwt_result_syntax in
    let* rev_tx_hashes, to_publish =
      List.fold_left_es
        (fun (tx_hashes, to_publish) tx_raw ->
          let*? tx_hash, encoded =
            TxEncoder.encode_transaction
              ~smart_rollup_address
              ~transaction:tx_raw
          in
          return (tx_hash :: tx_hashes, to_publish @ [encoded]))
        ([], [])
        transactions
    in
    let* () =
      Publisher.publish_messages ~smart_rollup_address ~messages:to_publish
    in
    return (List.rev rev_tx_hashes)
end
