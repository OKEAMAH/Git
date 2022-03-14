(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

module Message_result_hash = struct
  let message_result_hash =
    Tx_rollup_prefixes.message_result_hash.b58check_prefix

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "Message_result_hash"

        let title = "A message result"

        let b58check_prefix = message_result_hash

        let size = Some Tx_rollup_prefixes.message_result_hash.hash_size
      end)

  include H
  include Path_encoding.Make_hex (H)

  let () =
    Tx_rollup_prefixes.(check_encoding message_result_hash b58check_encoding)
end

type message_result = {
  context_hash : Context_hash.t;
  withdrawals_merkle_root : Tx_rollup_withdraw_repr.withdrawals_merkle_root;
}

let message_result_encoding =
  let open Data_encoding in
  conv
    (fun {context_hash; withdrawals_merkle_root} ->
      (context_hash, withdrawals_merkle_root))
    (fun (context_hash, withdrawals_merkle_root) ->
      {context_hash; withdrawals_merkle_root})
    (obj2
       (req "context_hash" Context_hash.encoding)
       (req
          "withdrawals_merkle_root"
          Tx_rollup_withdraw_repr.withdrawals_merkle_root_encoding))

let hash_message_result result =
  let bytes =
    Data_encoding.Binary.to_bytes_exn message_result_encoding result
  in
  Message_result_hash.hash_bytes [bytes]

let pp_message_result_hash = Message_result_hash.pp

module Commitment_hash = struct
  let commitment_hash = Tx_rollup_prefixes.commitment_hash.b58check_prefix

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "Commitment_hash"

        let title = "A commitment ID"

        let b58check_prefix = commitment_hash

        let size = Some Tx_rollup_prefixes.commitment_hash.hash_size
      end)

  include H

  let () = Tx_rollup_prefixes.(check_encoding commitment_hash b58check_encoding)

  include Path_encoding.Make_hex (H)

  let rpc_arg =
    let construct = Data_encoding.Binary.to_string_exn encoding in
    let destruct str =
      Option.value_e ~error:"Failed to decode commitment"
      @@ Data_encoding.Binary.of_string_opt encoding str
    in
    RPC_arg.make
      ~descr:"A tx_rollup commitment."
      ~name:"tx_rollup_commitment"
      ~construct
      ~destruct
      ()
end

type t = {
  level : Tx_rollup_level_repr.t;
  messages : Message_result_hash.t list;
  predecessor : Commitment_hash.t option;
  inbox_hash : Tx_rollup_inbox_repr.hash;
}

let compare_or cmp c1 c2 f = match cmp c1 c2 with 0 -> f () | diff -> diff

include Compare.Make (struct
  type nonrec t = t

  module Compare_root_list = Compare.List (Message_result_hash)

  let compare r1 r2 =
    compare_or Tx_rollup_level_repr.compare r1.level r2.level (fun () ->
        compare_or Compare_root_list.compare r1.messages r2.messages (fun () ->
            compare_or
              (Option.compare Commitment_hash.compare)
              r1.predecessor
              r2.predecessor
              (fun () ->
                Tx_rollup_inbox_repr.compare_hash r1.inbox_hash r2.inbox_hash)))
end)

let pp : Format.formatter -> t -> unit =
 fun fmt t ->
  Format.fprintf
    fmt
    "commitment %a : messages = %a predecessor %a for inbox %a"
    Tx_rollup_level_repr.pp
    t.level
    (Format.pp_print_list Message_result_hash.pp)
    t.messages
    (Format.pp_print_option Commitment_hash.pp)
    t.predecessor
    Tx_rollup_inbox_repr.pp_hash
    t.inbox_hash

(* FIXME/TORU: We need a test that checks that. *)
let empty_l2_context_hash =
  Context_hash.of_b58check_exn
    "CoVu7Pqp1Gh3z33mink5T5Q2kAQKtnn3GHxVhyehdKZpQMBxFBGF"

let initial_message_result_hash =
  hash_message_result
    {
      context_hash = empty_l2_context_hash;
      withdrawals_merkle_root =
        Tx_rollup_withdraw_repr.empty_withdrawals_merkle_root;
    }

(* FIXME/TORU: https://gitlab.com/tezos/tezos/-/issues/2470

   This encoding is not bounded, and maybe it is an issue. *)
let encoding =
  let open Data_encoding in
  conv
    (fun {level; messages; predecessor; inbox_hash} ->
      (level, messages, predecessor, inbox_hash))
    (fun (level, messages, predecessor, inbox_hash) ->
      {level; messages; predecessor; inbox_hash})
    (obj4
       (req "level" Tx_rollup_level_repr.encoding)
       (req "batches" (list Message_result_hash.encoding))
       (req "predecessor" (option Commitment_hash.encoding))
       (req "inbox_hash" Tx_rollup_inbox_repr.hash_encoding))

let hash c =
  let bytes = Data_encoding.Binary.to_bytes_exn encoding c in
  Commitment_hash.hash_bytes [bytes]

let check_message_result : t -> message_result -> message_index:int -> bool =
 fun {messages; _} result ~message_index ->
  let computed = hash_message_result result in
  match List.nth messages message_index with
  | Some expected -> Message_result_hash.(computed = expected)
  | None -> false

module Index = struct
  type t = Commitment_hash.t

  let path_length = 1

  let to_path c l =
    let raw_key =
      Data_encoding.Binary.to_bytes_exn Commitment_hash.encoding c
    in
    let (`Hex key) = Hex.of_bytes raw_key in
    key :: l

  let of_path = function
    | [key] ->
        Option.bind
          (Hex.to_bytes (`Hex key))
          (Data_encoding.Binary.of_bytes_opt Commitment_hash.encoding)
    | _ -> None

  let rpc_arg = Commitment_hash.rpc_arg

  let encoding = Commitment_hash.encoding

  let compare = Commitment_hash.compare
end

module Submitted_commitment = struct
  type nonrec t = {
    commitment : t;
    commitment_hash : Commitment_hash.t;
    committer : Signature.Public_key_hash.t;
    submitted_at : Raw_level_repr.t;
    finalized_at : Raw_level_repr.t option;
  }

  let encoding =
    let open Data_encoding in
    conv
      (fun {commitment; commitment_hash; committer; submitted_at; finalized_at} ->
        (commitment, commitment_hash, committer, submitted_at, finalized_at))
      (fun (commitment, commitment_hash, committer, submitted_at, finalized_at) ->
        {commitment; commitment_hash; committer; submitted_at; finalized_at})
      (obj5
         (req "commitment" encoding)
         (req "commitment_hash" Commitment_hash.encoding)
         (req "committer" Signature.Public_key_hash.encoding)
         (req "submitted_at" Raw_level_repr.encoding)
         (opt "finalized_at" Raw_level_repr.encoding))
end
