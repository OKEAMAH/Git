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

type error += (* `Permanent *) Wrong_rejection

type error += (* `Permanent *) Rejection_without_prerejection

type error += (* `Permanent *) Duplicate_prerejection

let () =
  let open Data_encoding in
  (* Wrong_rejection *)
  register_error_kind
    `Temporary
    ~id:"Wrong_rejection"
    ~title:"This rejection wrongly attempts to reject a correct comitment"
    ~description:"This rejection wrongly attempts to reject a correct comitment"
    unit
    (function Wrong_rejection -> Some () | _ -> None)
    (fun () -> Wrong_rejection) ;
  (* Rejection_without_prerejection *)
  register_error_kind
    `Temporary
    ~id:"Rejection_without_prerejection"
    ~title:"This rejection is missing a prerejection"
    ~description:"This rejection is missing a prerejection"
    unit
    (function Rejection_without_prerejection -> Some () | _ -> None)
    (fun () -> Rejection_without_prerejection) ;
  (* Duplicate_prerejection *)
  register_error_kind
    `Temporary
    ~id:"Duplicate_prerejection"
    ~title:"This prerejection has already been filed"
    ~description:"This prerejection has already been filed"
    unit
    (function Duplicate_prerejection -> Some () | _ -> None)
    (fun () -> Duplicate_prerejection)

type t = {
  rollup : Tx_rollup_repr.t;
  level : Raw_level_repr.t;
  hash : Tx_rollup_commitments_repr.Commitment_hash.t;
  batch_index : int;
  batch : Tx_rollup_message_repr.t;
}

let encoding =
  let open Data_encoding in
  conv
    (fun {rollup; level; hash; batch_index; batch} ->
      (rollup, level, hash, batch_index, batch))
    (fun (rollup, level, hash, batch_index, batch) ->
      {rollup; level; hash; batch_index; batch})
    (obj5
       (req "rollup" Tx_rollup_repr.encoding)
       (req "level" Raw_level_repr.encoding)
       (req "hash" Tx_rollup_commitments_repr.Commitment_hash.encoding)
       (req "batch_index" int31)
       (req "batch" Tx_rollup_message_repr.encoding))

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
    nonce:int64 ->
    source:Contract_repr.t ->
    rollup:Tx_rollup_repr.t ->
    level:Raw_level_repr.t ->
    commitment_hash:Tx_rollup_commitments_repr.Commitment_hash.t ->
    batch_index:int ->
    Rejection_hash.t =
 fun ~nonce ~source ~rollup ~level ~commitment_hash ~batch_index ->
  let to_bytes = Data_encoding.Binary.to_bytes_exn in
  let rollup_bytes = to_bytes Tx_rollup_repr.encoding rollup in
  let level_bytes = to_bytes Raw_level_repr.encoding level in
  let hash_bytes =
    Tx_rollup_commitments_repr.Commitment_hash.to_bytes commitment_hash
  in
  let batch_index_bytes = to_bytes Data_encoding.int31 batch_index in
  let nonce_bytes = Bytes.of_string @@ Int64.to_string nonce in
  let contract_bytes = to_bytes Contract_repr.encoding source in
  Rejection_hash.hash_bytes
    [
      rollup_bytes;
      level_bytes;
      nonce_bytes;
      hash_bytes;
      batch_index_bytes;
      contract_bytes;
    ]
