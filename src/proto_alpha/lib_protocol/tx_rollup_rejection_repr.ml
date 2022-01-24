(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

module Rejection_hash = struct
  let rejection_hash = "\001\111\092\025" (* rej1(37) *)

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "Rejection_hash"

        let title = "A rejection ID"

        let b58check_prefix = rejection_hash

        let size = Some 20
      end)

  include H

  let () = Base58.check_encoded_prefix b58check_encoding "rej1" 37

  include Path_encoding.Make_hex (H)

  let rpc_arg =
    let construct = Data_encoding.Binary.to_string_exn encoding in
    let destruct str =
      Option.value_e ~error:"Failed to decode rejection"
      @@ Data_encoding.Binary.of_string_opt encoding str
    in
    RPC_arg.make
      ~descr:"A tx_rollup rejection."
      ~name:"tx_rollup_rejection"
      ~construct
      ~destruct
      ()

  module Index = struct
    type nonrec t = t

    let path_length = 1

    let to_path c l =
      let raw_key = Data_encoding.Binary.to_bytes_exn encoding c in
      let (`Hex key) = Hex.of_bytes raw_key in
      key :: l

    let of_path = function
      | [key] ->
          Option.bind
            (Hex.to_bytes (`Hex key))
            (Data_encoding.Binary.of_bytes_opt encoding)
      | _ -> None

    let rpc_arg = rpc_arg

    let encoding = encoding

    let compare = compare
  end
end

let generate_prerejection :
    source:Signature.Public_key_hash.t ->
    tx_rollup:Tx_rollup_repr.t ->
    level:Tx_rollup_level_repr.t ->
    message_position:int ->
    proof:Tx_rollup_l2_proof.t ->
    Rejection_hash.t =
 fun ~source ~tx_rollup ~level ~message_position ~proof ->
  let to_bytes = Data_encoding.Binary.to_bytes_exn in
  let rollup_bytes = to_bytes Tx_rollup_repr.encoding tx_rollup in
  let level_bytes = to_bytes Tx_rollup_level_repr.encoding level in
  let proof_bytes =
    Data_encoding.Binary.to_bytes_exn Tx_rollup_l2_proof.encoding proof
  in
  let message_position_bytes = to_bytes Data_encoding.int31 message_position in
  let contract_bytes = to_bytes Signature.Public_key_hash.encoding source in
  Rejection_hash.hash_bytes
    [
      rollup_bytes;
      level_bytes;
      proof_bytes;
      message_position_bytes;
      contract_bytes;
    ]

type prerejection = {
  hash : Tx_rollup_commitment_repr.Hash.t;
  proof : Tx_rollup_l2_proof.t;
  contract : Signature.Public_key_hash.t;
  priority : int32;
}

let prerejection_encoding =
  Data_encoding.(
    conv
      (fun {hash; contract; priority; proof} ->
        (hash, contract, priority, proof))
      (fun (hash, contract, priority, proof) ->
        {hash; contract; priority; proof})
      (obj4
         (req "hash" Tx_rollup_commitment_repr.Hash.encoding)
         (req "contract" Signature.Public_key_hash.encoding)
         (req "priority" int32)
         (req "proof" Tx_rollup_l2_proof.encoding)))
