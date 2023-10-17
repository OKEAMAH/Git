(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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
   Component:    DAL
   Invocation:   dune exec tezt/manual_tests/main.exe -- --file dal.ml --test-arg output-file=<file>
   Subject:      Test getting informaton about the DAL distribution.
*)

module Dal = Dal_common

module Helpers = struct
  include Dal.Helpers

  (* We override store slot so that it uses a DAL node in this file. *)
  let store_slot dal_node ?with_proof slot =
    store_slot (Either.Left dal_node) ?with_proof slot
end

module Dal_RPC = struct
  include Dal.RPC

  (* We override call_xx RPCs in Dal.RPC to use a DAL node in this file. *)
  include Dal.RPC.Local
end

let dal_distribution () =
  Test.register
    ~__FILE__
    ~title:"Get the DAL distribution"
    ~tags:["dal"; "distribution"]
  @@ fun () ->
  let open Dal.Cryptobox in
  let number_of_shards = Cli.get_int "number_of_shards" in
  let slot_size = Cli.get_int "slot_size" in
  let redundancy_factor = Cli.get_int "redundancy_factor" in
  let page_size = Cli.get_int "page_size" in
  let parameters =
    {number_of_shards; redundancy_factor; page_size; slot_size}
  in
  Internal_for_tests.parameters_initialisation parameters
  |> Internal_for_tests.load_parameters ;
  match make parameters with
  | Ok _ ->
      Log.report "Set of parameters is valid" ;
      unit
  | Error (`Fail s) ->
      Test.fail "The set of parameters is invalid. Reason:@.%s@." s

(** Start a layer 1 node on the given network, with the given data-dir and
    rpc-port if any. *)
let start_layer_1_node ~network ?data_dir ?rpc_port ?net_port () =
  let node = Node.create ?data_dir ?rpc_port ?net_port [] in
  let* () =
    Node.config_reset
      node
      [Network network; Synchronisation_threshold 1; Expected_pow 26]
  in
  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in
  return node

(** Start a DAL node with the given information and wait until it's ready. *)
let start_dal_node ~peers ?data_dir ?rpc_port ?net_port ?public_ip_addr
    ?producer_profiles ?attester_profiles ?bootstrap_profile node =
  let listen_addr = Option.map (sf "0.0.0.0:%d") net_port in
  let public_addr =
    Option.map
      (fun ip -> Option.fold net_port ~none:ip ~some:(sf "%s:%d" ip))
      public_ip_addr
  in
  let dal_node =
    Dal_node.create ?data_dir ?rpc_port ?listen_addr ?public_addr ~node ()
  in
  let* () =
    Dal_node.init_config
      ~expected_pow:26.
      ~peers
      ?producer_profiles
      ?attester_profiles
      ?bootstrap_profile
      dal_node
  in
  let* () = Dal_node.run ~wait_ready:true dal_node in
  return dal_node

(** This function determines the teztnet network date depending on the current
    time. *)
let teztnet_network_target =
  let dailynet () = Ptime_clock.now () |> Ptime.to_date in
  let mondaynet () =
    let t = Ptime_clock.now () in
    let days_since_monday = (Ptime.weekday_num t + 6) mod 7 in
    let span = Ptime.Span.of_int_s @@ (days_since_monday * 3600 * 24) in
    match Ptime.sub_span t span with
    | Some t -> t |> Ptime.to_date
    | _ -> assert false (* Unreachable*)
  in
  fun ~network ~teztnet_network_day ->
    Option.value
      teztnet_network_day
      ~default:
        (let year, month, day =
           match network with
           | "dailynet" -> dailynet ()
           | "mondaynet" -> mondaynet ()
           | s -> Test.fail "Unknown network %s@." s
         in
         Printf.sprintf "%04d-%02d-%02d" year month day)

(** This function allows to run a [main_scenario] function on a teztnet network
    after initializing an L1 and DAL node and bootstrapping them. *)
let scenario_on_teztnet =
  let ( //> ) =
    let ( // ) = Filename.concat in
    fun a_opt b ->
      Option.map
        (fun a ->
          let dir = a // b in
          ignore @@ Sys.command (sf "mkdir -p %s" dir) ;
          dir)
        a_opt
  in
  fun ~network ?producer_profiles ?attester_profiles ~main_scenario () ->
    (* Parse CLI arguments *)
    let working_dir = Cli.get_string_opt "working-dir" in
    let public_ip_addr = Cli.get_string_opt "public-ip-addr" in
    let teztnet_network_day = Cli.get_string_opt "teztnet-network-day" in
    let net_port = Cli.get_int_opt "net-port" in
    let dal_net_port = Cli.get_int_opt "dal-net-port" in
    let rpc_port = Cli.get_int_opt "rpc-port" in
    let dal_rpc_port = Cli.get_int_opt "dal-rpc-port" in

    (* Determine the right network day *)
    let teztnet_network_day =
      teztnet_network_target ~network ~teztnet_network_day
    in
    (* prepare directories *)
    let working_dir = working_dir //> teztnet_network_day in
    let data_l1 = working_dir //> "layer-1" in
    let dal_producer = working_dir //> "dal-producer" in
    let wallet = working_dir //> "wallet" in

    (* Start L1 node and wait until it's bootstrapped *)
    let* l1_node =
      let network =
        sf "https://teztnets.xyz/%s-%s" network teztnet_network_day
      in
      start_layer_1_node ~network ?data_dir:data_l1 ?net_port ?rpc_port ()
    in
    let client =
      Client.create
        ?base_dir:wallet
        ~endpoint:(Node l1_node)
        ~media_type:Json
        ()
    in
    let* () = Client.bootstrapped client in

    (* Start DAL node  *)
    let peer = sf "dal.%s-%s.teztnets.xyz:11732" network teztnet_network_day in
    let* dal_node =
      start_dal_node
        ~peers:[peer]
        ?data_dir:dal_producer
        ?producer_profiles
        ?attester_profiles
        ?public_ip_addr
        ?net_port:dal_net_port
        ?rpc_port:dal_rpc_port
        l1_node
    in
    (* Prepare airdropper account. Secret key of
       tz1PEhbjTyVvjQ2Zz8g4bYU2XPTbhvG8JMFh, a funded key on periodic testnets. *)
    let airdropper_sk =
      "edsk3AWajGUgzzGi3UrQiNWeRZR1YMRYVxfe642AFSKBTFXaoJp5hu"
    in
    let airdropper_alias = "airdropper" in
    let* () =
      Client.import_secret_key
        client
        (Account.Unencrypted airdropper_sk)
        ~alias:airdropper_alias
        ~force:true
    in
    main_scenario ~airdropper_alias client dal_node l1_node

(** This function allows to injects DAL slots in the given network. *)
let slots_injector_scenario ?publisher_sk ~airdropper_alias client dal_node
    l1_node ~slot_index =
  let ( let*! ) = Runnable.Syntax.( let*! ) in
  let alias = "publisher" in
  let* () =
    match publisher_sk with
    | None ->
        let* _alias = Client.gen_keys ~alias client ~force:true in
        unit
    | Some account_sk ->
        Client.import_secret_key
          client
          (Account.Unencrypted account_sk)
          ~alias
          ~force:true
  in

  (* Airdrop publisher if needed *)
  let* balance_publisher = Client.get_balance_for ~account:alias client in
  let* () =
    if Tez.to_mutez balance_publisher > 5_000_000 then unit
    else
      Client.transfer
        ~amount:(Tez.of_mutez_int 50_000_000)
        ~giver:airdropper_alias
        ~receiver:alias
        ~burn_cap:(Tez.of_mutez_int 70_000)
        ~wait:"2"
        client
  in
  (* Fetch slots size from protocol parameters *)
  let* proto_parameters =
    Client.RPC.call client @@ RPC.get_chain_block_context_constants ()
  in
  let dal_parameters =
    Dal.Parameters.from_protocol_parameters proto_parameters
  in
  let slot_size = dal_parameters.cryptobox.slot_size in
  (* Endless loop that injects slots *)
  let rec loop level =
    let slot =
      sf "slot=%d/payload=%d" slot_index level |> Helpers.make_slot ~slot_size
    in
    let* commitment, proof =
      Helpers.store_slot dal_node ~with_proof:true slot
    in
    let* level = Node.wait_for_level l1_node (level + 1) in
    let*! () =
      Client.publish_dal_commitment
        ~src:alias
        ~slot_index
        ~commitment
        ~proof
        client
    in
    loop level
  in
  let* level = Client.level client in
  loop level

(** A slots injects test parameterized by a network *)
let slots_injector_test ~network =
  Test.register
    ~__FILE__
    ~title:(sf "Join %s and inject slots" network)
    ~tags:["dal"; "slot"; "producer"; network]
  @@ fun () ->
  let slot_index = Cli.get_int "slot-index" in
  let publisher_sk = Cli.get_string_opt "publisher-sk" in
  scenario_on_teztnet
    ~network
    ~main_scenario:(slots_injector_scenario ~slot_index ?publisher_sk)
    ~producer_profiles:[slot_index]
    ()

let register () =
  dal_distribution () ;
  slots_injector_test ~network:"dailynet" ;
  slots_injector_test ~network:"mondaynet" ;
  ()
