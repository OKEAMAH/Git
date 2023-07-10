(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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
   Component:    Baker
   Invocation:   dune exec tezt/tests/main.exe -- --file baker_test.ml
   Subject:      Test the baker
*)

let baker_test ?force_apply protocol ~keys =
  let* parameter_file =
    Protocol.write_parameter_file
      ~bootstrap_accounts:(List.map (fun k -> (k, None)) keys)
      ~base:(Right (protocol, None))
      []
  in
  let* node, client =
    Client.init_with_protocol
      ~keys:(Constant.activator :: keys)
      `Client
      ~protocol
      ~timestamp:Now
      ~parameter_file
      ()
  in
  let level_2_promise = Node.wait_for_level node 2 in
  let level_3_promise = Node.wait_for_level node 3 in
  let* baker = Baker.init ?force_apply ~protocol node client in
  Log.info "Wait for new head." ;
  Baker.log_events baker ;
  let* _ = level_2_promise in
  Log.info "New head arrive level 2" ;
  let* _ = level_3_promise in
  Log.info "New head arrive level 3" ;
  Lwt.return client

let baker_simple_test =
  Protocol.register_test ~__FILE__ ~title:"baker test" ~tags:["node"; "baker"]
  @@ fun protocol ->
  let* _ =
    baker_test protocol ~keys:(Account.Bootstrap.keys |> Array.to_list)
  in
  unit

(* Run the baker while performing a lot of transfers *)
let baker_stresstest =
  Protocol.register_test
    ~__FILE__
    ~title:"baker stresstest"
    ~tags:["node"; "baker"; "stresstest"]
  @@ fun protocol ->
  let* node, client =
    Client.init_with_protocol `Client ~protocol () ~timestamp:Now
  in
  let* _ = Baker.init ~protocol node client in
  let* _ = Node.wait_for_level node 3 in
  (* Use a large tps, to have failing operations too *)
  let* () = Client.stresstest ~tps:25 ~transfers:100 client in
  Lwt.return_unit

(* Force the baker to apply operations after validating them *)
let baker_stresstest_apply =
  Protocol.register_test
    ~__FILE__
    ~supports:Protocol.(From_protocol (number Mumbai))
    ~title:"baker stresstest with forced application"
    ~tags:["node"; "baker"; "stresstest"; "apply"]
  @@ fun protocol ->
  let* node, client =
    Client.init_with_protocol `Client ~protocol () ~timestamp:Now
  in
  let* _ = Baker.init ~force_apply:true ~protocol node client in
  let* _ = Node.wait_for_level node 3 in
  (* Use a large tps, to have failing operations too *)
  let* () = Client.stresstest ~tps:25 ~transfers:100 client in
  unit

let baker_bls_test =
  Protocol.register_test
    ~__FILE__
    ~title:"No BLS baker test"
    ~tags:["node"; "baker"; "bls"]
  @@ fun protocol ->
  let* client0 = Client.init_mockup ~protocol () in
  Log.info "Generate BLS keys for client" ;
  let* keys =
    Lwt_list.map_s
      (fun i ->
        Client.gen_and_show_keys
          ~alias:(sf "bootstrap_bls_%d" i)
          ~sig_alg:"bls"
          client0)
      (Base.range 1 5)
  in
  let* parameter_file =
    Protocol.write_parameter_file
      ~bootstrap_accounts:(List.map (fun k -> (k, None)) keys)
      ~base:(Right (protocol, None))
      []
  in
  let* _node, client =
    Client.init_with_node ~keys:(Constant.activator :: keys) `Client ()
  in
  let activate_process =
    Client.spawn_activate_protocol
      ~protocol
      ~timestamp:Now
      ~parameter_file
      client
  in
  let msg =
    rex "The delegate tz4.*\\w is forbidden as it is a BLS public key hash"
  in
  Process.check_error activate_process ~exit_code:1 ~msg

let baker_remote_test =
  Protocol.register_test
    ~__FILE__
    ~title:"Baker in RPC-only mode"
    ~tags:["baker"; "remote"]
  @@ fun protocol ->
  let* node, client =
    Client.init_with_protocol `Client ~protocol () ~timestamp:Now
  in
  let* _ = Baker.init ~remote_mode:true ~protocol node client in
  let* _ = Node.wait_for_level node 3 in
  unit

(* An event watcher checks that the event doesn't occur in the test
   until it is explicitely allowed by calling [allow]. Then, the event
   can be waited on using [waiter]. *)
module Baker_event_watcher = struct
  type 'a t = {waiter : 'a Lwt.t; allowed : bool ref}

  (* The arguments are the same as in {!Baker.wait_for}. *)
  let init ?where baker name filter =
    let allowed = ref false in
    let filter json =
      match filter json with
      | None -> None
      | Some output ->
          if !allowed then Some output
          else
            Test.fail
              "Event occurred too early in %s: %s%s"
              (Baker.name baker)
              name
              (match where with None -> "" | Some where -> " where " ^ where)
    in
    let waiter = Baker.wait_for ?where baker name filter in
    {waiter; allowed}

  let allow {waiter = _; allowed} = allowed := true

  let waiter {waiter; allowed = _} = waiter
end

(* Test that the baker doesn't count non-first-slot (pre)attestations
   toward the (pre)quorum. *)
let test_baker_ignores_non_first_slot_consensus_operations =
  Protocol.register_test
    ~__FILE__
    ~title:"Baker ignores non-first-slot consensus operations"
    ~tags:
      [
        "baker";
        "consensus";
        "preattestation";
        "attestation";
        "slot";
        "prequorum";
        "quorum";
      ]
    ~supports:(Protocol.From_protocol 017)
  (* This test relies on the relaxation of the constraint on the
     branch of a (pre)attestation that was added in Nairobi (017). *)
  @@
  fun protocol ->
  let level = 2 in
  let round_zero_duration = 10 in
  Log.info
    "Start a node and client, and activate the protocol with a consensus \
     threshold equal to the committee size. This means that every possible \
     (pre)attestation will be needed to reach the (pre)quorum. Also bump the \
     round zero duration (minimal_block_delay) to %ds so that there is enough \
     time to inject operations and observe events on the level %d round 0 \
     proposed block."
    round_zero_duration
    level ;
  let* parameter_file =
    let parameters = JSON.parse_file (Protocol.parameter_file protocol) in
    let consensus_committee_size =
      JSON.(parameters |-> "consensus_committee_size" |> as_int)
    in
    Protocol.write_parameter_file
      ~base:(Right (protocol, None))
      [
        (["consensus_threshold"], `Int consensus_committee_size);
        (["minimal_block_delay"], `String_of_int round_zero_duration);
      ]
  in
  let* node, client =
    Client.init_with_protocol
      `Client
      ~protocol
      ~parameter_file
      ~timestamp:Now
      ()
  in
  Log.info
    "Find a delegate that owns neither round 0 nor round 1 baking slots at \
     level %d, nor round 0 at level %d."
    level
    (level + 1) ;
  let* attestation_rights =
    RPC.call node @@ RPC.get_chain_block_helper_validators ~level ()
  and* next_level_rights =
    RPC.call node @@ RPC.get_chain_block_helper_validators ~level:(level + 1) ()
  (* Simultaneously, retrieve constants that will be useful to craft operations. *)
  and* branch = Operation.get_branch ~offset:0 client
  and* chain_id = RPC.call node @@ RPC.get_chain_chain_id () in
  let next_level_round_0_baker =
    let open JSON in
    next_level_rights |> as_list
    |> List.find_map (fun rights ->
           let first_slot = rights |-> "slots" |=> 0 |> as_int in
           if Int.equal first_slot 0 then
             Some (rights |-> "delegate" |> as_string)
           else None)
    |> Option.get
  in
  let delegate_pkh, slots =
    let open JSON in
    attestation_rights |> as_list
    |> List.find_map (fun rights ->
           let pkh = rights |-> "delegate" |> as_string in
           let slots = rights |-> "slots" |> as_list |> List.map as_int in
           if pkh <> next_level_round_0_baker && List.hd slots >= 2 then
             Some (pkh, slots)
           else None)
    |> Option.get
  in
  let delegate =
    Option.get
      (Array.find_opt
         (fun {Account.public_key_hash; _} ->
           String.equal public_key_hash delegate_pkh)
         Account.Bootstrap.keys)
  in
  let not_own_slot = 0
  and first_slot = List.hd slots
  and not_first_slot = List.nth slots 1 in
  Log.info "Start a baker for all delegates except %s." delegate.alias ;
  let other_delegates =
    List.filter_map
      (fun {Account.public_key_hash; _} ->
        if String.equal public_key_hash delegate_pkh then None
        else Some public_key_hash)
      (Array.to_list Account.Bootstrap.keys)
  in
  let event_sections_levels =
    [(String.concat "." [Protocol.encoding_prefix protocol; "baker"], `Debug)]
  in
  let* baker =
    Baker.init
      ~protocol
      ~delegates:other_delegates
      ~event_sections_levels
      node
      client
  in
  Baker.log_block_injection ~color:Log.Color.FG.yellow baker ;
  Log.info
    "Set up watchers to check that the following events don't happen until we \
     manually inject a fully correct (pre)attestation for %s later on: \
     prequorum, quorum, injection of a level 3 block."
    delegate.alias ;
  let preattestations_field_name, attestations_field_name =
    if Protocol.number protocol > 017 then ("preattestations", "attestations")
    else ("preendorsements", "endorsements")
  in
  let pqc_watcher =
    Baker_event_watcher.init baker "pqc_reached.v0" (fun value ->
        Check.(
          (JSON.(value |-> preattestations_field_name |> as_int) = 5)
            int
            ~error_msg:"Expected PQC with %R preattestations but got %L") ;
        Some ())
  in
  let qc_watcher =
    Baker_event_watcher.init baker "qc_reached.v0" (fun value ->
        Check.(
          (JSON.(value |-> attestations_field_name |> as_int) = 5)
            int
            ~error_msg:"Expected QC with %R attestations but got %L") ;
        Some ())
  in
  let next_level_block_watcher =
    Baker_event_watcher.init baker "block_injected.v0" (fun value ->
        if Int.equal JSON.(value |-> "level" |> as_int) (level + 1) then Some ()
        else None)
  in
  Log.info
    "Wait for for the baker to attest at level %d round 0, then retrieve the \
     attested block_payload_hash."
    level ;
  let preattestation_event_name, preattestation_kind =
    if Protocol.number protocol > 017 then
      ("preattestation_injected.v0", "preattestation")
    else ("preendorsement_injected.v0", "preendorsement")
  in
  let wait_for_preattestation ~round =
    let where = sf "level = %d && round = %d" level round in
    Baker.wait_for baker preattestation_event_name ~where (fun json ->
        if
          JSON.(
            Int.equal (json |-> "level" |> as_int) level
            && Int.equal (json |-> "round" |> as_int) round)
        then Some ()
        else None)
  in
  let get_block_payload_hash ~round =
    let* mempool =
      RPC.call node @@ RPC.get_chain_mempool_pending_operations ~version:"2" ()
    in
    let open JSON in
    mempool |-> "validated" |> as_list
    |> List.find_map (fun op ->
           let contents = op |-> "contents" |=> 0 in
           if
             String.equal (contents |-> "kind" |> as_string) preattestation_kind
             && Int.equal (contents |-> "level" |> as_int) level
             && Int.equal (contents |-> "round" |> as_int) round
           then Some (contents |-> "block_payload_hash" |> as_string)
           else None)
    |> Option.get |> return
  in
  let* () = wait_for_preattestation ~round:0 in
  let* round0_payload_hash = get_block_payload_hash ~round:0 in
  Log.info
    "Check that a preattestation or attestation on a slot that doesn't belong \
     to the delegate is rejected by the mempool." ;
  let inject_consensus ?error ~kind ~slot ~round ~block_payload_hash () =
    Operation.Consensus.(
      inject
        ?error
        (consensus
           ~kind
           ~use_legacy_name:true (* need the legacy name for Nairobi *)
           ~slot
           ~level
           ~round
           ~block_payload_hash)
        ~signer:delegate
        ~branch
        ~chain_id
          (* We provide the branch and chain_id to avoid two
             additional RPC calls for each injection (then we would
             need to set a longer round duration for the test to
             succeed). *)
        client)
  in
  let* (`OpHash _) =
    inject_consensus
      ~error:Operation.invalid_signature
      ~kind:Preattestation
      ~slot:not_own_slot
      ~round:0
      ~block_payload_hash:round0_payload_hash
      ()
  and* (`OpHash _) =
    inject_consensus
      ~error:Operation.invalid_signature
      ~kind:Attestation
      ~slot:not_own_slot
      ~round:0
      ~block_payload_hash:round0_payload_hash
      ()
  in
  Log.info
    "Inject a preattestation and an attestation on a slot that belongs to %s \
     but is not its first slot."
    delegate.alias ;
  let* (`OpHash oph1) =
    inject_consensus
      ~kind:Preattestation
      ~slot:not_first_slot
      ~round:0
      ~block_payload_hash:round0_payload_hash
      ()
  and* (`OpHash oph2) =
    inject_consensus
      ~kind:Attestation
      ~slot:not_first_slot
      ~round:0
      ~block_payload_hash:round0_payload_hash
      ()
  in
  Log.info
    "Check that the non-first-slot preattestation and attestation are \
     validated in the mempool." ;
  let* mempool = Mempool.get_mempool client in
  Mempool.check_mempool_contains ~validated:[oph1; oph2] mempool ;
  Log.info
    "Check that the baker reaches the end of the round without having seen an \
     attestable payload. Moreover, the event watchers that we have previously \
     set up ensure that there is no prequorum or quorum." ;
  let no_attestable_payload_event_name =
    if Protocol.number protocol > 017 then
      "no_attestable_payload_fresh_block.v0"
    else "no_endorsable_payload_fresh_block.v0"
  in
  let* () =
    Baker.wait_for baker no_attestable_payload_event_name (fun _ -> Some ())
  in
  Log.info
    "Wait for for the baker to attest at level %d round 1, then retrieve the \
     attested block_payload_hash."
    level ;
  let* () = wait_for_preattestation ~round:1 in
  let* round1_payload_hash = get_block_payload_hash ~round:1 in
  Log.info
    "Inject a fully correct preattestation on %s's first slot and check that \
     the baker sees the prequorum."
    delegate.alias ;
  Baker_event_watcher.allow pqc_watcher ;
  let* (`OpHash _) =
    inject_consensus
      ~kind:Preattestation
      ~slot:first_slot
      ~round:1
      ~block_payload_hash:round1_payload_hash
      ()
  in
  let* () = Baker_event_watcher.waiter pqc_watcher in
  Log.info
    "Inject an attestation but not on the first slot. Then sleep 1s, during \
     which the baker should still not see any quorum." ;
  let* (`OpHash _) =
    inject_consensus
      ~kind:Attestation
      ~slot:not_first_slot
      ~round:1
      ~block_payload_hash:round1_payload_hash
      ()
  in
  let* () = Lwt_unix.sleep 1. in
  Log.info
    "Inject a fully correct attestation on %s's first slot. Check that the \
     baker sees the quorum then proposes a block for level %d."
    delegate.alias
    (level + 1) ;
  Baker_event_watcher.allow qc_watcher ;
  Baker_event_watcher.allow next_level_block_watcher ;
  let* (`OpHash _) =
    inject_consensus
      ~kind:Attestation
      ~slot:first_slot
      ~round:1
      ~block_payload_hash:round1_payload_hash
      ()
  in
  Lwt.join
    [
      Baker_event_watcher.waiter qc_watcher;
      Baker_event_watcher.waiter next_level_block_watcher;
    ]

let register ~protocols =
  baker_simple_test protocols ;
  baker_stresstest protocols ;
  baker_stresstest_apply protocols ;
  baker_bls_test protocols ;
  baker_remote_test protocols ;
  test_baker_ignores_non_first_slot_consensus_operations protocols
