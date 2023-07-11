(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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
   Component: Dal
   Invocation: dune exec tezt/long_tests/main.exe -- --file dal.ml
   Subject: Performance regression tests for the DAL.
*)

let measurement = "time-to-produce-and-propagate-shards"

let grafana_panels : Grafana.panel list =
  [
    Row "DAL: ";
    Grafana.simple_graph ~measurement ~test:measurement ~field:"duration" ();
  ]

(* Adapted from tezt/tests/dal.ml *)
let start_l1_node ~protocol ~account ?l1_bootstrap_peer ?dal_bootstrap_peer () =
  let* parameter_file =
    let base = Either.right (protocol, Some Protocol.Constants_mainnet) in
    let parameter_overrides =
      [(["dal_parametric"; "feature_enable"], `Bool true)]
    in
    Protocol.write_parameter_file
      ~base
      ~bootstrap_accounts:
        (* [bootstrap1] will act as the sole baker
           so we include it as [bootstrap_accounts]. *)
        [(Constant.bootstrap1, None)]
      ~additional_bootstrap_accounts:
        (* [bootstrap2] will act as the slot producer
           so we provide some tez for posting commitments. *)
        [(Constant.bootstrap2, Some 1000000, false)]
      parameter_overrides
  in
  (* Start node with the given protocol *)
  let nodes_args =
    Node.
      [
        Synchronisation_threshold 0; History_mode (Full None); No_bootstrap_peers;
      ]
  in
  let* node, client =
    Client.init_with_protocol
      ~nodes_args
      ~protocol
      ~parameter_file
      ~keys:[Constant.activator; account]
      `Client
      ()
  in
  (* Connect the node to the given L1 bootstrap peer (if any). *)
  let* () =
    match l1_bootstrap_peer with
    | None -> unit
    | Some peer -> Client.Admin.connect_address ~peer client
  in
  (* Update [dal_config] in the node config. *)
  let* dal_parameters = Rollup.Dal.Parameters.from_client client in
  let config : Rollup.Dal.Cryptobox.Config.t =
    {
      activated = true;
      use_mock_srs_for_testing = Some dal_parameters.cryptobox;
      bootstrap_peers =
        (match dal_bootstrap_peer with
        | None -> []
        | Some peer -> [Dal_node.listen_addr peer]);
    }
  in
  Node.Config_file.update
    node
    (Node.Config_file.set_sandbox_network_with_dal_config config) ;
  (* Restart the node to load the new config. *)
  let* () = Node.terminate node in
  let* () = Node.run node nodes_args in
  let* () = Node.wait_for_ready node in
  return (node, client)

let start_dal_node l1_node l1_client ?(producer_profiles = [])
    ?(attestor_profiles = []) () =
  let dal_node = Dal_node.create ~node:l1_node ~client:l1_client () in
  let* _dir =
    Dal_node.init_config dal_node ~producer_profiles ~attestor_profiles
  in
  let* () = Dal_node.run dal_node ~wait_ready:true in
  return dal_node

let store_slot_to_dal_node ~slot_size dal_node =
  let slot = Rollup.Dal.make_slot "someslot" ~slot_size in
  (* Post a commitment of the slot. *)
  let* commitment = RPC.call dal_node (Rollup.Dal.RPC.post_commitment slot) in
  (* Compute and save the shards of the slot. *)
  let* () =
    RPC.call dal_node
    @@ Rollup.Dal.RPC.put_commitment_shards ~with_proof:true commitment
  in
  let commitment_hash =
    match Rollup.Dal.Cryptobox.Commitment.of_b58check_opt commitment with
    | None -> Test.fail ~__LOC__ "Decoding commitment failed."
    | Some hash -> hash
  in
  (* Compute the proof for the commitment. *)
  let* proof =
    let* proof =
      RPC.call dal_node @@ Rollup.Dal.RPC.get_commitment_proof commitment
    in
    return
      (Data_encoding.Json.destruct
         Rollup.Dal.Cryptobox.Commitment_proof.encoding
         (`String proof))
  in
  return (commitment_hash, proof)

let publish_slot_header_to_l1_node ~slot_index ~source ~commitment_hash ~proof
    client =
  let* _op_hash =
    Operation.Manager.(
      inject
        [
          make ~source
          @@ dal_publish_slot_header
               ~index:slot_index
               ~commitment:commitment_hash
               ~proof;
        ]
        client)
  in
  unit

let measure f =
  let start = Unix.gettimeofday () in
  let* res = f () in
  return (res, Unix.gettimeofday () -. start)

let measure_and_add_data_point f ~tag =
  let* res, time = measure f in
  let data_point =
    InfluxDB.data_point ~tags:[("tag", tag)] measurement ("duration", Float time)
  in
  Long_test.add_data_point data_point ;
  return res

(** Test the time it takes for one node to publish a slot
    and another node to download it.
    - The sole baker of the network ([node1]) will:
        - Bake several blocks so the attestation lag passes.
        - Download all the shards from the slot to attest to the availability
          of the slot.
    - The slot producer ([node2]) will:
        - Store the shards for the slot.
        - Post a commitment to the slot to L1.
*)
let test_produce_and_propagate_shards ~executors ~protocol =
  let repeat = Cli.get_int ~default:10 "repeat" in
  let expected_running_time = 120 in
  let timeout = Long_test.Seconds (repeat * 10 * expected_running_time) in
  Long_test.register
    ~__FILE__
    ~title:"DAL node produce and propagate shards"
    ~tags:["dal"]
    ~executors
    ~timeout
  @@ fun () ->
  Long_test.measure_and_check_regression_lwt
    ~tags:[("tag", "total")]
    ~repeat
    measurement
  @@ fun () ->
  let slot_index = 0 in
  (* Set up [node1], the only baker in the network. *)
  let* node1, client1 =
    start_l1_node ~protocol ~account:Constant.bootstrap1 ()
  in
  let* dal_node1 =
    start_dal_node
      node1
      client1
      ~attestor_profiles:[Constant.bootstrap1.public_key_hash]
      ()
  in
  (* Set up [node2], the slot producer. *)
  let* node2, client2 =
    start_l1_node
      ~protocol
      ~account:Constant.bootstrap2
      ~l1_bootstrap_peer:node1
      ~dal_bootstrap_peer:dal_node1
      ()
  in
  let* dal_node2 =
    start_dal_node node2 client2 ~producer_profiles:[slot_index] ()
  in
  let*! () = Client.reveal ~src:Constant.bootstrap2.alias client2 in
  let* () = Client.bake_for_and_wait client1 in
  (* Now that the setup of the nodes are finished, we start measuring the time. *)
  let* (), time =
    measure @@ fun () ->
    (* Store slot in [dal_node2]. *)
    let* dal_parameters = Rollup.Dal.Parameters.from_client client2 in
    let* commitment_hash, proof =
      measure_and_add_data_point ~tag:"locally_store_slot" @@ fun () ->
      store_slot_to_dal_node
        ~slot_size:dal_parameters.cryptobox.slot_size
        dal_node2
    in
    (* Publish slot header from [node2]. *)
    let* () =
      publish_slot_header_to_l1_node
        ~slot_index
        ~source:Constant.bootstrap2
        ~commitment_hash
        ~proof
        client2
    in
    let dal_node_endpoint = Rollup.Dal.endpoint dal_node2 in
    let* () = Client.bake_for_and_wait client1 ~dal_node_endpoint in
    (* Wait until node1 downloads [dal_parameters.cryptobox.number_of_shards] shards.
       (i.e. the published slot is attestable by node1. *)
    let* () =
      measure_and_add_data_point ~tag:"wait_slot_propagated" @@ fun () ->
      let number_of_shards = dal_parameters.cryptobox.number_of_shards in
      let shard_count = ref 0 in
      Log.info "Waiting to download %d shards..." number_of_shards ;
      Dal_node.wait_for dal_node1 "stored_slot_shards.v0" @@ fun e ->
      let shards_stored = JSON.(e |-> "shards" |> as_int) in
      shard_count := !shard_count + shards_stored ;
      if !shard_count = number_of_shards then (
        Log.info "Downloaded %d shards. Ready to attest." number_of_shards ;
        Some ())
      else None
    in
    (* Bake several blocks to surpass the attestation lag. *)
    let* () =
      range 0 (dal_parameters.attestation_lag - 1)
      |> Tezos_base__TzPervasives.List.iter_s (fun _i ->
             Client.bake_for_and_wait client1 ~dal_node_endpoint)
    in
    (* Assert that the attestation was indeed posted. *)
    let* {dal_attestation; _} =
      RPC.(call node1 @@ get_chain_block_metadata ())
    in
    Check.((Some [|true|] = dal_attestation) (option (array bool)))
      ~error_msg:"Unexpected DAL attestations: expected %L, got %R" ;
    unit
  in
  return time

let register ~executors ~protocols =
  protocols
  |> List.iter @@ fun protocol ->
     test_produce_and_propagate_shards ~executors ~protocol
