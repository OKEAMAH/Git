(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

type staker =
  | Single of Contract_repr.t * Signature.public_key_hash
  | Shared of Signature.public_key_hash

let staker_encoding =
  let open Data_encoding in
  let single_tag = 0 in
  let single_encoding =
    obj2
      (req "contract" Contract_repr.encoding)
      (req "delegate" Signature.Public_key_hash.encoding)
  in
  let shared_tag = 1 in
  let shared_encoding =
    obj1 (req "delegate" Signature.Public_key_hash.encoding)
  in
  def
    ~title:"staker"
    ~description:
      "Abstract notion of staker used in operation receipts, either a single \
       staker or all the stakers delegating to some delegate."
    "staker"
  @@ matching
       (function
         | Single (contract, delegate) ->
             matched single_tag single_encoding (contract, delegate)
         | Shared delegate -> matched shared_tag shared_encoding delegate)
       [
         case
           ~title:"Single"
           (Tag single_tag)
           single_encoding
           (function
             | Single (contract, delegate) -> Some (contract, delegate)
             | _ -> None)
           (fun (contract, delegate) -> Single (contract, delegate));
         case
           ~title:"Shared"
           (Tag shared_tag)
           shared_encoding
           (function Shared delegate -> Some delegate | _ -> None)
           (fun delegate -> Shared delegate);
       ]

let compare_staker sa sb =
  match (sa, sb) with
  | Single (ca, da), Single (cb, db) ->
      Compare.or_else (Contract_repr.compare ca cb) (fun () ->
          Signature.Public_key_hash.compare da db)
  | Shared da, Shared db -> Signature.Public_key_hash.compare da db
  | Single _, Shared _ -> -1
  | Shared _, Single _ -> 1

let staker_delegate = function
  | Single (_contract, delegate) -> delegate
  | Shared delegate -> delegate