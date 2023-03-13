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

let originate_new_rollup ?(boot_sector = Constant.wasm_echo_kernel_boot_sector)
    ?(parameters_ty = "bytes") ~src client =
  let* rollup =
    Client.Sc_rollup.originate
      client
      ~wait:"0"
      ~src
      ~kind:"wasm_2_0_0"
      ~parameters_ty
      ~boot_sector
      ~burn_cap:(Tez.of_int 2)
  in
  Log.info "Rollup %s originated" rollup ;
  return rollup

let setup_l2_node ~(testnet : Testnet.t) ?runner ?name ?loser_mode ~operator
    client node rollup =
  let rollup_node =
    Sc_rollup_node.create
      ?runner
      ?name
      ~base_dir:(Client.base_dir client)
      ~default_operator:operator
      ~protocol:testnet.protocol
      Operator
      node
  in

  let* _ = Sc_rollup_node.config_init ?loser_mode rollup_node rollup in
  Log.info "Starting a smart rollup node to track %s" rollup ;
  let* () = Sc_rollup_node.run rollup_node [] in
  let* () = Sc_rollup_node.wait_for_ready rollup_node in
  Log.info "Smart rollup node started." ;
  return rollup_node

let game_in_progress ~staker rollup_address client =
  let* game =
    RPC.Client.call client
    @@ RPC.get_chain_block_context_smart_rollups_smart_rollup_staker_games
         ~staker
         rollup_address
         ()
  in
  return (not ([] = JSON.as_list game))

let rec wait_for_game ~staker rollup_address client node =
  let* in_progress = game_in_progress ~staker rollup_address client in
  if not in_progress then (
    Log.info "Still no game at level %d" (Node.get_level node) ;
    let* _ = Node.wait_for_level node (Node.get_level node + 1) in
    wait_for_game ~staker rollup_address client node)
  else unit

let rec wait_for_end_of_game ~staker rollup_address client node =
  let* in_progress = game_in_progress ~staker rollup_address client in
  if in_progress then (
    Log.info "Game still in progress at level %d" (Node.get_level node) ;
    let* _ = Node.wait_for_level node (Node.get_level node + 1) in
    wait_for_end_of_game ~staker rollup_address client node)
  else unit

let rejection_with_proof ~(testnet : Testnet.t) () =
  (* We expect each player to have at least 11,000 xtz. This is enough
     to originate a rollup (1.68 xtz for one of the player), commit
     (10,000 xtz for both player), and play the game (each
     [Smart_rollup_refute] operation should be relatively cheap). *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot = Helpers.download testnet.snapshot "snapshot" in
  let* client, node = Helpers.setup_octez_node ~testnet snapshot in
  let* honest_operator = Client.gen_and_show_keys client in
  let* dishonest_operator = Client.gen_and_show_keys client in
  let* () =
    Lwt.join
      [
        Helpers.wait_for_funded_key node client min_balance honest_operator;
        Helpers.wait_for_funded_key node client min_balance dishonest_operator;
      ]
  in
  let* rollup_address =
    originate_new_rollup ~src:honest_operator.alias client
  in
  let level = Node.get_level node in
  let fault_level = level + 5 in
  Log.info
    "Dishonest operator expected to inject an error at level %d"
    fault_level ;
  let* _rollup_nodes =
    Lwt.all
      [
        setup_l2_node
          ~testnet
          ~name:"honest-node"
          ~operator:honest_operator.alias
          client
          node
          rollup_address;
        setup_l2_node
          ~testnet
          ~name:"dishonest-node"
          ~loser_mode:Format.(sprintf "%d 0 0" fault_level)
          ~operator:dishonest_operator.alias
          client
          node
          rollup_address;
      ]
  in
  let* () =
    wait_for_game
      ~staker:honest_operator.public_key_hash
      rollup_address
      client
      node
  in
  let* () =
    wait_for_end_of_game
      ~staker:honest_operator.public_key_hash
      rollup_address
      client
      node
  in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4929
     Should the scenario checks if the game ended with the expected
     result? *)
  unit

let get_staked_on_commitment rollup_address staker client =
  let* json =
    RPC.Client.call client
    @@ RPC
       .get_chain_block_context_smart_rollups_smart_rollup_staker_staked_on_commitment
         ~sc_rollup:rollup_address
         staker
  in
  return JSON.(json |-> "hash" |> as_string_opt)

let rec wait_for_staker rollup_address staker client node =
  Lwt.catch
    (fun () ->
      let* staked = get_staked_on_commitment rollup_address staker client in
      match staked with
      | Some _hash -> unit
      | None ->
          let* _ = Node.wait_for_level node (Node.get_level node + 1) in
          wait_for_staker rollup_address staker client node)
    (fun _ ->
      let* _ = Node.wait_for_level node (Node.get_level node + 1) in
      wait_for_staker rollup_address staker client node)

let rec wait_for_recoverable rollup_address staker client node =
  Lwt.catch
    (fun () ->
      let* staked = get_staked_on_commitment rollup_address staker client in
      match staked with
      | None -> unit
      | Some _hash ->
          let* _ = Node.wait_for_level node (Node.get_level node + 1) in
          wait_for_recoverable rollup_address staker client node)
    (fun _ -> unit)

let recover_bond ~(testnet : Testnet.t) () =
  (* We expect the operator to have at least 11,000 xtz. This is
     enough to originate a rollup (1.68 xtz), and commit (10,000 xtz
     for both player). *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot = Helpers.download testnet.snapshot "snapshot" in
  let* client, node = Helpers.setup_octez_node ~testnet snapshot in
  let* operator1 = Client.gen_and_show_keys client in
  let* operator2 = Client.gen_and_show_keys client in
  let* () =
    Lwt.join
      [
        Helpers.wait_for_funded_key node client min_balance operator1;
        Helpers.wait_for_funded_key node client min_balance operator2;
      ]
  in
  let* rollup_address = originate_new_rollup ~src:operator1.alias client in
  let* rollup_node1, _rollup_node2 =
    Lwt.both
      (setup_l2_node
         ~testnet
         ~operator:operator1.alias
         client
         node
         rollup_address)
      (setup_l2_node
         ~testnet
         ~operator:operator2.alias
         client
         node
         rollup_address)
  in
  let* () =
    wait_for_staker rollup_address operator1.public_key_hash client node
  in
  let* () = Sc_rollup_node.kill rollup_node1 in
  let* () =
    wait_for_recoverable rollup_address operator1.public_key_hash client node
  in
  let*! _ =
    Client.Sc_rollup.submit_recover_bond
      ~rollup:rollup_address
      ~src:operator1.public_key_hash
      ~fee:Tez.one
      ~staker:operator1.public_key_hash
      ~wait:"1"
      client
  in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4929
     Should the scenario checks if the game ended with the expected
     result? *)
  unit

let originate_echo_sink rollup_address source client =
  let prg =
    Printf.sprintf
      {|
          {
            parameter (or (int %%default) (int %%aux));
            storage (int :s);
            code
              {
                # Check that SENDER is the rollup address
                SENDER;
                PUSH address %S;
                ASSERT_CMPEQ;
                # Check that SOURCE is the implicit account used for executing
                # the outbox message.
                SOURCE;
                PUSH address %S;
                ASSERT_CMPEQ;
                UNPAIR;
                IF_LEFT
                  { SWAP ; DROP; NIL operation }
                  { SWAP ; DROP; NIL operation };
                PAIR;
              }
          }
        |}
      rollup_address
      source
  in
  let* address =
    Client.originate_contract
      ~alias:"target"
      ~amount:(Tez.of_int 100)
      ~burn_cap:(Tez.of_int 100)
      ~src:source
      ~prg
      ~init:"0"
      ~wait:"0"
      client
  in
  return address

let echo_input_message client sink_address parameters =
  let transaction =
    Sc_rollup_client.{destination = sink_address; entrypoint = None; parameters}
  in
  let* answer = Sc_rollup_client.encode_batch client [transaction] in
  match answer with
  | None -> failwith "Encoding of batch should not fail."
  | Some answer -> return answer

let add_echo_message ~src rollup_client client sink_address parameters =
  let* payload = echo_input_message rollup_client sink_address parameters in
  let json = Ezjsonm.list Ezjsonm.string [payload] in
  let msg = "hex:" ^ Ezjsonm.to_string ~minify:true json in
  Client.Sc_rollup.send_message ~wait:"1" ~src ~msg client

let wait_for_outbox_message_execution ~src ~rollup_address rollup_client
    outbox_level ~parameters ~sink_address node client =
  let rec wait_for () =
    Lwt.catch
      (fun () ->
        let* answer =
          Sc_rollup_client.outbox_proof_single
            rollup_client
            ~message_index:0
            ~outbox_level
            ~destination:sink_address
            ~parameters
        in
        match answer with
        | None -> failwith "Unexpected error during proof generation"
        | Some proof -> return proof)
      (fun _ ->
        let* _ = Node.wait_for_level node (Node.get_level node + 1) in
        wait_for ())
  in
  let* Sc_rollup_client.{commitment_hash; proof} = wait_for () in
  let*! () =
    Client.Sc_rollup.execute_outbox_message
      ~burn_cap:(Tez.of_int 10)
      ~rollup:rollup_address
      ~src
      ~commitment_hash
      ~proof
      ~wait:"1"
      client
  in
  unit

let execute_outbox_message ~(testnet : Testnet.t) () =
  (* We expect each player to have at least 11,000 xtz. This is enough
     to originate a rollup (1.68 xtz for one of the player), commit
     (10,000 xtz for both player), and play the game (each
     [Smart_rollup_refute] operation should be relatively cheap). *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot = Helpers.download testnet.snapshot "snapshot" in
  let* client, node = Helpers.setup_octez_node ~testnet snapshot in
  let* operator = Client.gen_and_show_keys client in
  let* () = Helpers.wait_for_funded_key node client min_balance operator in
  let* rollup_address = originate_new_rollup ~src:operator.alias client in
  let* rollup_node =
    setup_l2_node
      ~testnet
      ~name:"rollup-node"
      ~operator:operator.alias
      client
      node
      rollup_address
  in
  let rollup_client =
    Sc_rollup_client.create ~protocol:testnet.protocol rollup_node
  in
  let* sink_address =
    originate_echo_sink rollup_address operator.public_key_hash client
  in
  let payload = "37" in
  let* () =
    add_echo_message
      ~src:operator.public_key_hash
      rollup_client
      client
      sink_address
      payload
  in
  let* () =
    wait_for_outbox_message_execution
      ~src:operator.alias
      ~rollup_address
      rollup_client
      (Node.get_level node - 1)
      ~parameters:payload
      ~sink_address
      node
      client
  in
  unit

let register ~testnet =
  Test.register
    ~__FILE__
    ~title:"Rejection with proof"
    ~tags:["rejection"]
    (rejection_with_proof ~testnet) ;
  Test.register
    ~__FILE__
    ~title:"Recover bond"
    ~tags:["recover"]
    (recover_bond ~testnet) ;
  Test.register
    ~__FILE__
    ~title:"Execute outbox message"
    ~tags:["outbox"]
    (execute_outbox_message ~testnet)
