(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* Testing
   -------
   Component:    RPCs
   Invocation:   dune exec tezt/tests/main.exe -- --file rpc_versioning.ml
   Subject:      rpc versioning
*)

let register_test ~title ?(additionnal_tags = []) f =
  Protocol.register_test
    ~__FILE__
    ~title
    ~supports:(Protocol.From_protocol 18)
    ~tags:(["rpc"; "versioning"] @ additionnal_tags)
    f

type consensus_kind = Attestation | Preattestation

let mk_consensus (kind, use_legacy_name) =
  (match kind with
  | Attestation -> Operation.Consensus.attestation
  | Preattestation -> Operation.Consensus.preattestation)
    ~use_legacy_name
    ~slot:1
    ~level:1
    ~round:0
    ~block_payload_hash:"vh1g87ZG6scSYxKhspAUzprQVuLAyoa5qMBKcUfjgnQGnFb3dJcG"

let get_name_consensus (kind, use_legacy_name) =
  match kind with
  | Attestation -> if use_legacy_name then "endorsement" else "attestation"
  | Preattestation ->
      if use_legacy_name then "preendorsement" else "preattestation"

let check_kind json kind =
  let json_kind =
    JSON.(json |-> "contents" |> as_list |> List.hd |-> "kind" |> as_string)
  in
  if not (String.equal json_kind kind) then
    Test.fail ~__LOC__ "Operation should have %s kind, got: %s" kind json_kind

let check_hex_from_ops op1 op2 client =
  Log.info
    "Ensures that Bytes returned from calling the forge RPC on both operations \
     are identical" ;
  let* (`Hex op1_raw) = Operation.hex op1 client in
  let* (`Hex op2_raw) = Operation.hex op2 client in
  if not (String.equal op1_raw op2_raw) then
    Test.fail ~__LOC__ "Bytes are not equal, got: %s and: %s" op1_raw op2_raw
  else unit

let test_consensus kind protocol =
  let* _node, client = Client.init_with_protocol ~protocol `Client () in
  let signer = Constant.bootstrap1 in

  let create_consensus_op ~use_legacy_name =
    let consensus = (kind, use_legacy_name) in
    let consensus_name = get_name_consensus consensus in
    Log.info "Create an %s operation" consensus_name ;
    let consensus = mk_consensus consensus in
    let* consensus_op =
      Operation.Consensus.operation ~signer consensus client
    in

    Log.info
      "Ensures that the generated JSON contains the %s kind"
      consensus_name ;
    let consensus_json =
      JSON.annotate ~origin:"" @@ Operation.json consensus_op
    in
    check_kind consensus_json consensus_name ;
    Lwt.return consensus_op
  in

  let* legacy_consensus_op = create_consensus_op ~use_legacy_name:true in
  let* consensus_op = create_consensus_op ~use_legacy_name:false in
  check_hex_from_ops legacy_consensus_op consensus_op client

let test_forge_consensus =
  register_test
    ~title:"Forge consensus operations"
    ~additionnal_tags:["forge"; "operations"; "consensus"]
  @@ fun protocol -> test_consensus Attestation protocol

let test_forge_preconsensus =
  register_test
    ~title:"Forge pre-consensus operations"
    ~additionnal_tags:["forge"; "operations"; "consensus"; "pre"]
  @@ fun protocol -> test_consensus Preattestation protocol

let register ~protocols =
  test_forge_consensus protocols ;
  test_forge_preconsensus protocols
