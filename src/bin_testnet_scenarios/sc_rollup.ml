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
  let* snapshot =
    match testnet.snapshot with
    | Some snapshot ->
        let* snapshot = Helpers.download snapshot "snapshot" in
        return (Some snapshot)
    | None -> return None
  in
  let* client, node = Helpers.setup_octez_node ~testnet ?snapshot () in
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

let rejection_with_proof_loser_vs_loser ~(testnet : Testnet.t) () =
  (* We expect each player to have at least 11,000 xtz. This is enough
     to originate a rollup (1.68 xtz for one of the player), commit
     (10,000 xtz for both player), and play the game (each
     [Smart_rollup_refute] operation should be relatively cheap). *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot =
    match testnet.snapshot with
    | Some snapshot ->
        let* snapshot = Helpers.download snapshot "snapshot" in
        return (Some snapshot)
    | None -> return None
  in
  let* client, node = Helpers.setup_octez_node ~testnet ?snapshot () in
  let* dishonest_operator_1 = Client.gen_and_show_keys client in
  let* dishonest_operator_2 = Client.gen_and_show_keys client in
  let* () =
    Lwt.join
      [
        Helpers.wait_for_funded_key node client min_balance dishonest_operator_1;
        Helpers.wait_for_funded_key node client min_balance dishonest_operator_2;
      ]
  in
  let* rollup_address =
    originate_new_rollup ~src:dishonest_operator_1.alias client
  in
  let level = Node.get_level node in
  let fault_level = level + 20 in
  Log.info
    "Dishonest operator expected to inject an error at level %d"
    fault_level ;
  let* _rollup_nodes =
    Lwt.all
      [
        setup_l2_node
          ~testnet
          ~name:"dishonest-node1"
          ~loser_mode:Format.(sprintf "%d 0 0" fault_level)
          ~operator:dishonest_operator_1.alias
          client
          node
          rollup_address;
        setup_l2_node
          ~testnet
          ~name:"dishonest-node"
          ~loser_mode:Format.(sprintf "%d 0 0" fault_level)
          ~operator:dishonest_operator_2.alias
          client
          node
          rollup_address;
      ]
  in
  let* () =
    wait_for_game
      ~staker:dishonest_operator_1.public_key_hash
      rollup_address
      client
      node
  in
  let* () =
    wait_for_end_of_game
      ~staker:dishonest_operator_1.public_key_hash
      rollup_address
      client
      node
  in
  unit

type sc_rollup_constants = {
  origination_size : int;
  challenge_window_in_blocks : int;
  stake_amount : Tez.t;
  commitment_period_in_blocks : int;
  max_lookahead_in_blocks : int32;
  max_active_outbox_levels : int32;
  max_outbox_messages_per_level : int;
  number_of_sections_in_dissection : int;
  timeout_period_in_blocks : int;
}

let get_sc_rollup_constants client =
  let* json =
    RPC.Client.call client @@ RPC.get_chain_block_context_constants ()
  in
  let open JSON in
  let origination_size = json |-> "smart_rollup_origination_size" |> as_int in
  let challenge_window_in_blocks =
    json |-> "smart_rollup_challenge_window_in_blocks" |> as_int
  in
  let stake_amount =
    json |-> "smart_rollup_stake_amount" |> as_string |> Int64.of_string
    |> Tez.of_mutez_int64
  in
  let commitment_period_in_blocks =
    json |-> "smart_rollup_commitment_period_in_blocks" |> as_int
  in
  let max_lookahead_in_blocks =
    json |-> "smart_rollup_max_lookahead_in_blocks" |> as_int32
  in
  let max_active_outbox_levels =
    json |-> "smart_rollup_max_active_outbox_levels" |> as_int32
  in
  let max_outbox_messages_per_level =
    json |-> "smart_rollup_max_outbox_messages_per_level" |> as_int
  in
  let number_of_sections_in_dissection =
    json |-> "smart_rollup_number_of_sections_in_dissection" |> as_int
  in
  let timeout_period_in_blocks =
    json |-> "smart_rollup_timeout_period_in_blocks" |> as_int
  in
  return
    {
      origination_size;
      challenge_window_in_blocks;
      stake_amount;
      commitment_period_in_blocks;
      max_lookahead_in_blocks;
      max_active_outbox_levels;
      max_outbox_messages_per_level;
      number_of_sections_in_dissection;
      timeout_period_in_blocks;
    }

let cement_and_outbox_msg ~(testnet : Testnet.t) () =
  (* We expect each player to have at least 11,000 xtz. This is enough
     to originate a rollup (1.68 xtz for one of the player), commit
     (10,000 xtz for both player), and play the game (each
     [Smart_rollup_refute] operation should be relatively cheap). *)
  let min_balance = Tez.(of_mutez_int 11_000_000_000) in
  let* snapshot =
    match testnet.snapshot with
    | Some snapshot ->
        let* snapshot = Helpers.download snapshot "snapshot" in
        return (Some snapshot)
    | None -> return None
  in
  let* client, node = Helpers.setup_octez_node ~testnet ?snapshot () in
  let* operator = Client.gen_and_show_keys client in
  let* () =
    Lwt.join [Helpers.wait_for_funded_key node client min_balance operator]
  in
  let originate_target_contract rollup_address source =
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
        client
    in
    let* () = Client.bake_for_and_wait client in
    return address
  in
  let check_target_contract_execution target_address expected_storage =
    let* storage = Client.contract_storage target_address client in
    return
    @@ Check.(
         (String.trim storage = expected_storage)
           string
           ~error_msg:"Invalid contract storage: expecting '%R', got '%L'.")
  in
  let perform_rollup_execution_and_cement ~src client node ~payload
      ~blocks_to_wait =
    let* () =
      let json = Ezjsonm.list Ezjsonm.string [payload] in
      let msg = "hex:" ^ Ezjsonm.to_string ~minify:true json in
      Client.Sc_rollup.send_message ~src ~msg client
    in
    let* _ = Node.wait_for_level node (Node.get_level node + blocks_to_wait) in
    unit
  in
  let input_message client ?entrypoint contract_address parameters =
    let transaction =
      Sc_rollup_client.{destination = contract_address; entrypoint; parameters}
    in
    let* answer = Sc_rollup_client.encode_batch client [transaction] in
    match answer with
    | None -> failwith "Encoding of batch should not fail."
    | Some answer -> return answer
  in
  let trigger_outbox_message_execution ~src ~rollup_address rollup_client
      outbox_level ~parameters ~destination =
    let message_index = 0 in
    let* outbox =
      Runnable.run @@ Sc_rollup_client.outbox ~outbox_level rollup_client
    in
    Log.info "Outbox is %s" (JSON.encode outbox) ;
    let expected =
      JSON.parse ~origin:"trigger_outbox_message_execution"
      @@ Printf.sprintf
           {|
              [ { "outbox_level": %d, "message_index": "%d",
                  "message":
                  { "transactions":
                    [ { "parameters": { "int": "%s" },
                    "destination": "%s" } ] } } ] |}
           outbox_level
           message_index
           parameters
           destination
    in
    assert (JSON.encode expected = JSON.encode outbox) ;
    let* answer =
      Sc_rollup_client.outbox_proof_single
        rollup_client
        ~message_index
        ~outbox_level
        ~destination
        ~parameters
    in
    match answer with
    | None -> failwith "Unexpected error during proof generation"
    | Some {commitment_hash; proof} ->
        let*! () =
          Client.Sc_rollup.execute_outbox_message
            ~burn_cap:(Tez.of_int 10)
            ~rollup:rollup_address
            ~src
            ~commitment_hash
            ~proof
            client
        in
        Client.bake_for_and_wait client
  in
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
  let* target_contract_address =
    originate_target_contract operator.alias rollup_address
  in
  let payload = "37" in
  let* message = input_message rollup_client target_contract_address payload in
  (* value for mumbainet and mondaynet *)
  let* {commitment_period_in_blocks; challenge_window_in_blocks; _} =
    get_sc_rollup_constants client
  in
  (*   let commitment_period = 20 in *)
  (*   let challenge_window = 40 in *)
  let blocks_to_wait =
    2 + (2 * commitment_period_in_blocks) + challenge_window_in_blocks
  in
  let* () =
    perform_rollup_execution_and_cement
      ~src:operator.alias
      client
      node
      ~payload:message
      ~blocks_to_wait
  in
  let* () =
    trigger_outbox_message_execution
      ~src:operator.alias
      ~rollup_address
      rollup_client
      challenge_window_in_blocks
      ~parameters:payload
      ~destination:target_contract_address
  in
  let* () = check_target_contract_execution target_contract_address payload in
  unit

let register ~testnet =
  (*   Test.register *)
  (*     ~__FILE__ *)
  (*     ~title:"Rejection with proof" *)
  (*     ~tags:["rejection"] *)
  (*     (rejection_with_proof ~testnet) ; *)
  Test.register
    ~__FILE__
    ~title:"Rejection with proof (loser vs loser)"
    ~tags:["rejection"; "loser"]
    (rejection_with_proof_loser_vs_loser ~testnet)
(*   Test.register *)
(*     ~__FILE__ *)
(*     ~title:"cementation and outbox message execution." *)
(*     ~tags:["cementation"; "outbox"] *)
(*     (cement_and_outbox_msg ~testnet) *)
