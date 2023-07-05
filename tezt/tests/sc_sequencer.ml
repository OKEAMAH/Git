(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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
   Component:    Smart Optimistic Rollups: Sequencer
   Invocation:   dune exec tezt/tests/main.exe -- --file sc_sequencer.ml
*)
open Sc_rollup_helpers
open Tezos_protocol_alpha.Protocol

let pvm_kind = "wasm_2_0_0"

type full_sequencer_setup = {
  node : Node.t;
  client : Client.t;
  sc_sequencer_node : Sc_rollup_node.t;
  sc_rollup_client : Sc_rollup_client.t;
  sc_rollup_address : string;
  originator_key : string;
  sequencer_key : string;
}

let next_rollup_level {node; client; sc_sequencer_node; _} =
  let* () = Client.bake_for_and_wait client in
  Sc_rollup_node.wait_for_level
    ~timeout:30.
    sc_sequencer_node
    (Node.get_level node)

let setup_sequencer_kernel
    ?(originator_key = Constant.bootstrap1.public_key_hash)
    ?(sequencer_key = Constant.bootstrap1.public_key_hash) sequenced_kernel
    protocol =
  let* node, client = setup_l1 protocol in
  let sc_sequencer_node =
    Sc_rollup_node.create
      ~protocol
      Custom
      node
      ~path:"./octez-smart-rollup-sequencer-node"
      ~base_dir:(Client.base_dir client)
      ~default_operator:sequencer_key
  in
  (* Prepare sequencer kernel & originate it *)
  let* boot_sector =
    prepare_installer_kernel
      ~base_installee:"./"
      ~config:
        [
          Installer_kernel_config.Set
            {
              value =
                (* encodings of State::Sequenced(edpkuBknW28nW72KG6RoHtYW7p12T6GKc7nAbwYX5m8Wd9sDVC9yav) *)
                "00004798d2cc98473d7e250c898885718afd2e4efbcb1a1595ab9730761ed830de0f";
              to_ = "/__sequencer/state";
            };
        ]
      ~preimages_dir:
        (Filename.concat
           (Sc_rollup_node.data_dir sc_sequencer_node)
           "wasm_2_0_0")
      sequenced_kernel
  in
  let* sc_rollup_address =
    originate_sc_rollup
      ~kind:pvm_kind
      ~boot_sector
      ~parameters_ty:"unit"
      ~src:originator_key
      client
  in
  (* Start a sequencer node *)
  let* () =
    Sc_rollup_node.run_sequencer
      sc_sequencer_node
      sc_rollup_address
      ["--log-kernel-debug"]
  in
  let sc_rollup_client = Sc_rollup_client.create ~protocol sc_sequencer_node in
  let setup =
    {
      node;
      client;
      sc_sequencer_node;
      sc_rollup_client;
      sc_rollup_address;
      originator_key;
      sequencer_key;
    }
  in
  Lwt.return setup

let wrap_with_framed rollup_address msg =
  (* Byte from framing protocol, then smart rollup address, then message bytes *)
  String.concat
    ""
    [
      "\000";
      Data_encoding.Binary.to_string_exn
        Sc_rollup_repr.Address.encoding
        rollup_address;
      msg;
    ]

let send_message ~src client raw_msg =
  Client.Sc_rollup.send_message
    ~hooks
    ~src
    ~msg:(sf "hex:[%S]" @@ hex_encode raw_msg)
    client

let wait_for_sequence_debug_message sc_node =
  Sc_rollup_node.wait_for sc_node "kernel_debug.v0" @@ fun json ->
  let message = JSON.as_string json in
  if String.starts_with ~prefix:"Received a sequence message" message then
    Some message
  else None

let pp_sequencer_msg_body ppf (seq, signature) =
  let open Octez_smart_rollup_sequencer.Kernel_message in
  match seq with
  | Sequence seq ->
      Format.fprintf
        ppf
        "Sequence { nonce: %ld, delayed_messages_prefix: %ld, \
         delayed_messages_suffix: %ld, messages: [], signature: \
         Signature(\"%s\") }"
        seq.nonce
        seq.delayed_messages_prefix
        seq.delayed_messages_suffix
        signature

let test_delayed_inbox_consumed =
  Protocol.register_test
    ~__FILE__
    ~tags:["sequencer"]
    ~title:"Originate sequencer kernel & consume delayed inbox messages"
  @@ fun protocol ->
  let* ({client; sc_rollup_address; sc_sequencer_node; _} as setup) =
    setup_sequencer_kernel "sequenced_empty_kernel" protocol
  in
  let sc_rollup_address =
    Sc_rollup_repr.Address.of_b58check_exn sc_rollup_address
  in
  let* () =
    send_message ~src:Constant.bootstrap2.alias client
    @@ wrap_with_framed sc_rollup_address "\000\000\000"
  in
  let* () =
    send_message ~src:Constant.bootstrap3.alias client
    @@ wrap_with_framed sc_rollup_address "\000\000\001"
  in

  (* Start async collection of sequence debug messages from the kernel *)
  let collected_sequences = ref [] in
  let _ =
    let rec collect_sequences () =
      let* c = wait_for_sequence_debug_message sc_sequencer_node in
      collected_sequences := c :: !collected_sequences ;
      collect_sequences ()
    in
    collect_sequences ()
  in

  (* Bake block with those user messages, which has level 3, origination level is 2.

     This block will incorporate "\000\000\000" and "\000\000\001" *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 3 ------------------------ *)

  (* At this moment delayed inbox corresponding to the previous block is empty,
     hence, a Sequence with 0 delayed inbox messages and 0 user messages has been batched,
     which denoted as S0. *)

  (* Bake a block with level 4 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 4 ------------------------ *)

  (* At this moment delayed inbox corresponding to the previous block have 5 messages:
     [SoL3, IpL3, "\000\000\000", "\000\000\001", EoL3].
     Seq_batcher has batched a Sequence with
     5 delayed inbox messages and 0 L2 messages, which denoted S1.
  *)

  (* Bake a block with level 5, incorporating S0 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 5 ------------------------ *)

  (* At this moment delayed inbox corresponding to the previous block have 3 messages:
     [SoL4, IpL4, EoL4].
     5 delayed inbox messages have been consumed by the previous block.
     Seq_batcher has batched a Sequence with the 3 delayed inbox messages
     and 0 L2 messages, which denoted S2.
  *)

  (* Inject S1 into an upcoming block with level 6 *)

  (* Bake a block with level 6, incorporating S1 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 6 ------------------------ *)

  (* Feed to the sequencer kernel S1 sequence *)

  (* Inject S2 into an upcoming block with level 7 *)
  (* Following S3 is not going to be injected within this test, so we ingore consideration of it *)

  (* Bake a block with level 7, incorporating S2 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 7 ------------------------ *)

  (* Feed to the sequencer kernel S2 sequence *)
  let open Octez_smart_rollup_sequencer.Kernel_message in
  let expected_sequences =
    List.map
      (Format.asprintf
         "Received a sequence message %a targeting our rollup"
         pp_sequencer_msg_body)
    @@ [
         ( Sequence
             {
               nonce = 1l;
               delayed_messages_prefix = 0l;
               delayed_messages_suffix = 0l;
               l2_messages = [];
             },
           "sigULSkLUnitzmA1DXXGXFi1UDRv421GtasjcXXgZDcTLcDFXGRBvr83s6yqTrXc3epKDPq34Qjjczcqw5jVMhtXLJoW2psA"
         );
         ( Sequence
             {
               nonce = 2l;
               delayed_messages_prefix = 4l;
               delayed_messages_suffix = 1l;
               l2_messages = [];
             },
           "sigWsYLRJVST2iwumN66jNFuiJqu9wUbiZKMa9fj4V66Jkpm1s38kFsxUb5qKcvF9G1waA8GG9qHxKsHCi9nduUbPCAwntU6"
         );
         ( Sequence
             {
               nonce = 3l;
               delayed_messages_prefix = 2l;
               delayed_messages_suffix = 1l;
               l2_messages = [];
             },
           "siggmUHffviSZZaLCTmZ3yLq5Y6vmqbr9HGMYa9fKsTT5U6JBWphjdba7uwTDeKUZRGPdr72867R9752HA5P5SbxEaB31Yzb"
         );
       ]
  in
  Check.(
    ( = )
      expected_sequences
      (List.rev !collected_sequences)
      ~__LOC__
      (list string)
      ~error_msg:"Unexpected debug messages emitted") ;
  Lwt.return_unit

let rpc_inject_messages = Sc_rollup_client.inject ~hooks

let rpc_get_optimistic_storage_value sc_client key =
  Sc_rollup_client.rpc_get_rich
    ~hooks
    sc_client
    ["local"; "durable"; "wasm_2_0_0"; "value"]
    [("key", key)]

let test_optimistic_state_computed_correctly =
  Protocol.register_test
    ~__FILE__
    ~tags:["sequencer"]
    ~title:
      "Supply messages via RPC and through L1 directly, making sure optimistic \
       durable state equals to the expected one"
  @@ fun protocol ->
  let* ({client; sc_rollup_address; sc_rollup_client; _} as setup) =
    setup_sequencer_kernel "sequenced_concat_kernel" protocol
  in
  let sc_rollup_address =
    Sc_rollup_repr.Address.of_b58check_exn sc_rollup_address
  in
  let* () =
    send_message ~src:Constant.bootstrap2.alias client
    @@ wrap_with_framed sc_rollup_address "L1_message1"
  in
  let* () =
    send_message ~src:Constant.bootstrap3.alias client
    @@ wrap_with_framed sc_rollup_address "L1_message2"
  in

  (* Bake block with the L1 user messages, which has level 3, origination level is 2.

     This block will incorporate "L1_message1" and "L1_message2" *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 3 ------------------------ *)

  (* At this moment we just initialized simulation context *)

  (* Inject messages through RPC *)
  let*! _messages_hashes =
    rpc_inject_messages sc_rollup_client
    @@ List.map
         (wrap_with_framed sc_rollup_address)
         ["RPC_message1"; "RPC_message2"]
  in

  (* Inject more messages directly in L1 *)
  let* () =
    send_message ~src:Constant.bootstrap2.alias client
    @@ wrap_with_framed sc_rollup_address "L1_message3"
  in

  (* Bake a block with level 4, that will incorporate "L1_message3" *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 4 ------------------------ *)

  (* At this moment delayed inbox corresponding to the previous block have 5 messages:
     [SoL, IpL, "L1_message1", "L1_message2", EoL].
     Seq_batcher has batched a Sequence with those 5 delayed inbox messages
     and ["RPC_message1"; "RPC_message2"] which denoted S1.
  *)

  (* Inject more messages through RPC *)
  let*! _messages_hashes =
    rpc_inject_messages sc_rollup_client
    @@ List.map
         (wrap_with_framed sc_rollup_address)
         ["RPC_message3"; "RPC_message4"]
  in

  (* Bake a block with level 5, incorporating S0 and "L1_message3" *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 5 ------------------------ *)

  (* At this moment delayed inbox corresponding to the previous block have 4 messages:
     [SoL4, IpL4, "L1_message3", EoL4].
     5 delayed inbox messages have been consumed by the previous block.
     Seq_batcher has batched a Sequence with the 4 delayed inbox messages
     and ["RPC_message3"; "RPC_message4"] user messages, which denoted S2.
  *)

  (* TODO: INSPECT STATE HERE *)

  (* Inject S1 into an upcoming block with level 6 *)

  (* Bake a block with level 6, containing S1 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 6 ------------------------ *)

  (* Feed to the sequencer kernel S1 sequence *)

  (* Inject S2 into an upcoming block with level 7 *)
  (* Following S3 is not going to be injected within this test, so we ingore consideration of it *)

  (* Bake a block with level 7, containing S2 *)
  let* _ = next_rollup_level setup in

  (* ------------------------ NEW BLOCK level = 7 ------------------------ *)
  let*! concated_string =
    rpc_get_optimistic_storage_value sc_rollup_client "/concat"
  in
  let concated_string_hex = `Hex (JSON.as_string concated_string) in
  let expected_concat =
    "SoL IpL L1_message1 L1_message2 RPC_message1 RPC_message2 EoL SoL IpL \
     L1_message3 RPC_message3 RPC_message4 EoL"
  in
  (* let expected_concat = Hex.show @@ Hex.of_string expected_concat in *)
  Format.printf "RECEIVED %s\n" (Hex.to_string concated_string_hex) ;
  Check.(
    ( = )
      expected_concat
      (Hex.to_string concated_string_hex)
      ~__LOC__
      string
      ~error_msg:"Unexpected optimistic state ") ;
  Lwt.return_unit

let register ~protocols =
  let _p = protocols in
  ()
(* test_delayed_inbox_consumed protocols ; *)
(* test_optimistic_state_computed_correctly protocols *)
