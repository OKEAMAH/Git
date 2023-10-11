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

open Dal_helpers
module Dal = Dal_common

module Dal_RPC = struct
  include Dal.RPC

  (* We override call_xx RPCs in Dal.RPC to use a DAL node in this file. *)
  include Dal.RPC.Local
end

let trim_trailing_zeros str =
  let rec trim idx =
    if idx < 0 then ""
    else if str.[idx] = '0' then trim (idx - 1)
    else String.sub str 0 (idx + 1)
  in
  let last_index = String.length str - 1 in
  trim last_index

let make_even_length str =
  if String.length str mod 2 == 1 then str ^ "0" else str

(* Publish a slot, hopefully at level [level]. It's not clear though when the
   slot will be included in a block, so at which level it will actually be
   included. *)
let publish_slot dal_node client source ~slot_size ~level ~slot_index =
  let slot_content =
    Format.sprintf "DATA for level %d with index %d" level slot_index
  in
  Log.info "Publishing slot data '%s'..." slot_content ;
  let slot = Dal.Helpers.make_slot ~slot_size slot_content in
  let* commitment = Dal_RPC.(call dal_node @@ post_commitment slot) in
  let* () =
    Dal_RPC.(call dal_node @@ put_commitment_shards ~with_proof:true commitment)
  in
  let commitment_hash =
    match Dal.Cryptobox.Commitment.of_b58check_opt commitment with
    | None -> assert false
    | Some hash -> hash
  in
  let* proof =
    let* proof = Dal_RPC.(call dal_node @@ get_commitment_proof commitment) in
    Dal.Commitment.proof_of_string proof |> return
  in
  Operation.Manager.(
    inject
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/6127
       Think of a better strategy to push slots *)
      ~force:true
      [
        make ~source
        @@ dal_publish_slot_header
             ~index:slot_index
             ~commitment:commitment_hash
             ~proof;
      ]
      client)

(* [check_attestations level] checks that the attested slot indexes posted to
   L1 at level [level] matches the slot indexes classified as attestable by
   the DAL node.  Returns a pair of (number of published slot headers, number
   of attested slot indexes) at the given level. *)
let check_attestations node dal_node ~lag ~number_of_slots ~published_level =
  let module Map = Map.Make (String) in
  let* slot_headers =
    Dal_RPC.(call dal_node @@ get_published_level_headers published_level)
  in
  let map =
    List.fold_left
      (fun acc Dal_RPC.{status; slot_index; _} ->
        Map.update
          status
          (function
            | None -> Some (1, [slot_index])
            | Some (c, indexes) -> Some (c + 1, slot_index :: indexes))
          acc)
      Map.empty
      slot_headers
  in
  let pp_map =
    let open Format in
    pp_print_list
      ~pp_sep:(fun fmt () -> pp_print_string fmt ", ")
      (fun fmt (status, (c, _indexes)) -> Format.fprintf fmt "%d %s" c status)
  in
  let attested_level = string_of_int (published_level + lag) in
  let* metadata =
    Node.RPC.(call node @@ get_chain_block_metadata ~block:attested_level ())
  in
  let pp_array fmt a =
    for i = 0 to Array.length a - 1 do
      let b = if a.(i) then 1 else 0 in
      Format.fprintf fmt "%d" b
    done
  in
  let proto_attestation =
    match metadata.dal_attestation with
    | None -> Array.make number_of_slots false
    | Some x ->
        let len = Array.length x in
        if len < number_of_slots then (
          let a = Array.make number_of_slots false in
          for i = 0 to number_of_slots - 1 do
            if i < len then a.(i) <- x.(i)
          done ;
          a)
        else x
  in
  let num_attested, indexes =
    match Map.find_opt "attested" map with
    | None -> (0, [])
    | Some (c, l) -> (c, l)
  in
  let node_attestation =
    (* build array from list *)
    let a = Array.make number_of_slots false in
    List.iter (fun i -> a.(i) <- true) indexes ;
    a
  in
  if proto_attestation <> node_attestation then
    Test.fail
      "At published_level %d, attestations in the L1 and DAL nodes differ %a \
       vs %a"
      published_level
      pp_array
      proto_attestation
      pp_array
      node_attestation ;
  let num_published = List.length slot_headers in
  let* ops =
    Node.RPC.(
      call node
      @@ get_chain_block_operations_validation_pass
           ~block:attested_level
           ~validation_pass:0
           ())
  in
  let attestations =
    List.filter
      (fun op ->
        let op_type = JSON.(op |-> "contents" |=> 0 |-> "kind" |> as_string) in
        String.equal op_type "dal_attestation")
      (JSON.as_list ops)
  in
  Log.info
    "At published_level %d, published slots: %d, status: %a (%d attestations)"
    published_level
    (List.length slot_headers)
    pp_map
    (Map.bindings map)
    (List.length attestations) ;
  return (num_published, num_attested)

let scenario_without_rollup_node node dal_node client proto_parameters
    num_levels keys =
  let num_accounts = List.length keys in
  let key_indices = range 0 (num_accounts - 1) in
  let block_times =
    JSON.(
      proto_parameters |-> "minimal_block_delay" |> as_string |> int_of_string)
  in
  let dal_parameters =
    Dal.Parameters.from_protocol_parameters proto_parameters
  in
  let cryptobox = dal_parameters.cryptobox in
  let number_of_slots = dal_parameters.number_of_slots in
  let lag = dal_parameters.attestation_lag in

  let* first_level =
    let* level = Node.wait_for_level node 0 in
    1 + level |> return
  in

  let rec publish_for_index key_index =
    let* current_level = Node.get_level node in
    if current_level >= first_level + num_levels then return ()
    else
      let slot_index = key_index mod number_of_slots in
      let source = List.nth keys key_index in
      let* _op_hash =
        publish_slot
          dal_node
          client
          ~slot_size:cryptobox.slot_size
          source
          ~level:(current_level + 1)
          ~slot_index
      in
      let* _ = Node.wait_for_level node (current_level + 1) in
      publish_for_index key_index
  in
  let* () = Lwt_list.iter_p (fun i -> publish_for_index i) key_indices in
  Log.info "Waiting for the attestation period to pass..." ;
  let* _ =
    Lwt_unix.sleep
      (5.
      +. float_of_int
           (dal_parameters.Dal.Parameters.attestation_lag * block_times))
  in

  let* last_level = Node.get_level node in
  let expected_min_level = first_level + num_levels + lag in
  Check.(
    (last_level >= expected_min_level)
      int
      ~error_msg:"Node level is %L, expected to be at least %R") ;

  Log.info
    "Stats on attestations at levels %d to %d:"
    first_level
    (first_level + num_levels - 1) ;
  let* published, attested =
    Lwt_list.fold_left_s
      (fun (total_published, total_attested) level ->
        let* published, attested =
          check_attestations
            node
            dal_node
            ~lag
            ~number_of_slots
            ~published_level:level
        in
        return (total_published + published, total_attested + attested))
      (0, 0)
      (range first_level (first_level + num_levels - 1))
  in
  let avg_pub, avg_att =
    let n = float_of_int num_levels in
    (float_of_int published /. n, float_of_int attested /. n)
  in
  Log.info
    "With %d accounts, average slots per level over %d levels: published = \
     %.2f attested = %.2f"
    num_accounts
    num_levels
    avg_pub
    avg_att ;
  unit

let scenario_with_rollup_node node dal_node client proto_parameters num_levels
    keys =
  let dal_parameters =
    Dal.Parameters.from_protocol_parameters proto_parameters
  in
  let cryptobox = dal_parameters.cryptobox in
  let lag = dal_parameters.attestation_lag in
  let number_of_slots = dal_parameters.number_of_slots in

  let originate = Cli.get ~default:None (fun _ -> Some (Some ())) "originate" in
  let rollup_alias = "dal_echo_rollup" in
  let rollup_node =
    Sc_rollup_node.create
      ~dal_node
      Operator
      node
      ~base_dir:(Client.base_dir client)
      ~default_operator:Wallet.Airdrop.giver_alias
  in
  let* () =
    match originate with
    | None -> unit
    | Some () ->
        let* boot_sector =
          Sc_rollup_helpers.prepare_installer_kernel
            ~base_installee:"./"
            ~preimages_dir:
              (Filename.concat
                 (Sc_rollup_node.data_dir rollup_node)
                 "wasm_2_0_0")
            "dal_echo_kernel"
        in
        let* rollup_address =
          Client.Sc_rollup.originate
            ~force:true (* because the alias might have already been used *)
            ~burn_cap:Tez.(of_int 10)
            ~alias:rollup_alias
            ~src:Wallet.Airdrop.giver_alias
            ~kind:"wasm_2_0_0"
            ~boot_sector
            ~parameters_ty:"unit"
            client
        in
        Log.info
          "Originated rollup %s with address: %s"
          rollup_alias
          rollup_address ;
        let* _level =
          let* level = Node.get_level node in
          Node.wait_for_level node (level + 1)
        in
        unit
  in
  let* () =
    Sc_rollup_node.run rollup_node rollup_alias ["--log-kernel-debug"]
  in
  let rollup_client =
    (* TODO: Mondaynet starts with [Protocol.(previous_protocol Alpha)]... *)
    Sc_rollup_client.create ~protocol:Protocol.Alpha rollup_node
  in

  let* first_level =
    let* crt = Node.get_level node in
    crt + 1 |> return
  in
  Log.info "Monitoring the rollup node starting with level %d" first_level ;
  let* _level = Sc_rollup_node.wait_for_level rollup_node first_level in

  let slot_producer = List.hd keys in
  (* Try to publish a slot for (around) [num_levels], that is for levels from
     [first_level] to [first_level + num_levels]. *)
  let rec publish () =
    let* current_level = Node.get_level node in
    if current_level >= first_level + num_levels then return ()
    else
      let* _op_hash =
        publish_slot
          dal_node
          client
          ~slot_size:cryptobox.slot_size
          slot_producer
          ~level:(current_level + 1)
          ~slot_index:0
      in
      let* _ = Node.wait_for_level node (current_level + 1) in
      publish ()
  in

  let rec get_stored_slot published_level =
    if published_level >= first_level + num_levels + 2 then unit
    else
      let queried_level = published_level + lag in
      let* _level =
        (* Wait one more level to be sure the rollup node processed the
           block. *)
        Sc_rollup_node.wait_for_level rollup_node (queried_level + 1)
      in
      let path =
        [
          "global";
          "block";
          string_of_int queried_level;
          "durable";
          "wasm_2_0_0";
          "value";
        ]
      in
      let*! json =
        Sc_rollup_client.rpc_get_rich
          rollup_client
          path
          [("key", "/output/slot-0")]
      in
      let decode s = Hex.to_string (`Hex s) in
      let slot =
        JSON.as_string json |> trim_trailing_zeros |> make_even_length |> decode
      in
      Log.info
        "For published level %d, the stored slot data is: '%s'"
        published_level
        slot ;
      get_stored_slot (published_level + 1)
  in

  let rec check published_level =
    if published_level >= first_level + num_levels + 2 then return ()
    else
      let attested_level = published_level + lag in
      let* _level =
        (* Wait 1 level for the block to be final, wait another one to be sure
           the DAL node processed it. *)
        Node.wait_for_level node (attested_level + 2)
      in
      let* _ =
        check_attestations node dal_node ~lag ~number_of_slots ~published_level
      in
      check (published_level + 1)
  in
  Lwt.join [publish (); get_stored_slot first_level; check first_level]

(* This scenario starts a L1 node and a DAL node on the given testnet (Dailynet
   or Mondaynet), and it publishes slots for a number of levels and a number of
   slot producers (both given as arguments to the test). At the end of the test,
   the average number of published respectively attested slots are shown (with
   Log.info).

   To run the test, one can use:

   dune exec src/bin_testnet_scenarios/main.exe -- dal dailynet -a load -a save -a num_accounts=5 -a levels=10

   Use the arguments:
   - `load`: to load an existing data-dir saved (with `save`, see next) in a previous run of the script
   - `save`: to save the current data-dir after the L1 node is synced and at the end of the test
   - `num_accounts=<int>`: to specify the number of slot producers
   - `levels`: to specify for how many levels to publish slots
*)
let scenario network kind f =
  let net_name = Network.short_name network in
  Test.register
    ~__FILE__
    ~title:(sf "Produce slots on %s %s rollup node" net_name kind)
    ~tags:["dal"; net_name; kind]
  @@ fun () ->
  let load = Cli.get ~default:None (fun _ -> Some (Some ())) "load" in
  let save = Cli.get ~default:None (fun _ -> Some (Some ())) "save" in
  let dal_peers = Cli.get ~default:[] (fun str -> Some [str]) "peers" in
  let num_accounts =
    Cli.get ~default:5 (fun str -> Some (int_of_string str)) "num_accounts"
  in
  let num_levels =
    Cli.get ~default:10 (fun str -> Some (int_of_string str)) "levels"
  in
  Log.info
    "Using %d keys for slot production, publishing for %d levels"
    num_accounts
    num_levels ;
  let key_indices = range 0 (num_accounts - 1) in

  let dailynet_baker =
    (* the one and only bootstrap delegate on Dailynet *)
    "tz1foXHgRzdYdaLgX6XhpZGxbBv42LZ6ubvE"
  in

  let node = Node.create [] in
  let dal_node = Dal_node.create ~node () in
  let tezt_data_dir = Node.data_dir node in
  let tezt_dal_data_dir = Dal_node.data_dir dal_node in
  let network_name = Network.name network in
  let network_url = Format.sprintf "https://teztnets.xyz/%s" network_name in
  let network_arg = Node.Network network_url in
  let l1_backup = Filename.get_temp_dir_name () // network_name in
  let dal_backup = Filename.get_temp_dir_name () // (network_name ^ "-dal") in
  let load () =
    let load_l1_dir, load_dal_dir =
      match load with
      | Some () ->
          if Sys.file_exists l1_backup then
            if Sys.file_exists dal_backup then (true, true)
            else (
              Log.info "Expected DAL data-dir %s does not exist." dal_backup ;
              (true, false))
          else (
            Log.info "Expected L1 data-dir %s does not exist." l1_backup ;
            (* Even if the DAL backup exists, we don't load it, because the DAL
               config depends on the L1 config. *)
            (false, false))
      | None -> (false, false)
    in
    let* () =
      if load_l1_dir then (
        Log.info
          "Loading data-dir from %s in current tezt workspace..."
          l1_backup ;
        let* () = Process.run "cp" ["-rT"; l1_backup; tezt_data_dir] in
        unit)
      else (
        Log.info "Initializing L1 node..." ;
        Node.config_init
          node
          [network_arg; Expected_pow 26; Synchronisation_threshold 2])
    in
    let* () =
      if load_dal_dir then (
        Log.info
          "Loading DAL data-dir from %s in current tezt workspace..."
          dal_backup ;
        let* () = Process.run "cp" ["-rT"; dal_backup; tezt_dal_data_dir] in
        (* We delete the config file, because it is not useful for subsequent runs
           and may be confusing (it contains in particular the net/rpc addresses
           which should not be reused by mistake). *)
        let config_file = tezt_dal_data_dir // "config.json" in
        if Sys.file_exists config_file then Process.run "rm" [config_file]
        else unit)
      else unit
    in
    Log.info "Initializing the DAL node..." ;
    let attester_profiles =
      match network with Dailynet -> [dailynet_baker] | Mondaynet -> []
    in
    Dal_node.init_config
      ~peers:dal_peers
      ~expected_pow:26.
      ~producer_profiles:key_indices
      ~attester_profiles
      dal_node
  in
  let* () = load () in
  Log.info "Run L1 node and wait for it to sync..." ;
  let wait_for_sync_promise = wait_for_sync node in
  let* () = Node.run node [network_arg] in
  let* () = Node.wait_for_ready node in
  let* () = Lwt.join [wait_for_sync_promise] in
  let client =
    Client.create
      ~base_dir:(Wallet.default_wallet network)
      ~endpoint:(Node node)
      ()
  in
  let aliases =
    List.map (fun i -> "slot-producer-" ^ string_of_int i) key_indices
  in
  let* keys = Wallet.load_wallet network client aliases in
  let save ~restart =
    match save with
    | None -> return ()
    | Some () ->
        Log.info
          "Save the current data-dirs into %s and %s..."
          l1_backup
          dal_backup ;
        let* () = Node.terminate node in
        let* () = Process.run "cp" ["-rT"; tezt_data_dir; l1_backup] in
        let* () = Process.run "cp" ["-rT"; tezt_dal_data_dir; dal_backup] in
        if restart then (
          Log.info "Restart L1 node and wait for it to sync..." ;
          let* () = Node.run node [network_arg] in
          let* () = Node.wait_for_ready node in
          wait_for_sync node)
        else return ()
  in
  let* () = save ~restart:true in
  let* () = Wallet.Airdrop.distribute_money client keys in
  let* () = Dal_node.run dal_node in
  let* proto_parameters =
    Client.RPC.call client @@ RPC.get_chain_block_context_constants ()
  in

  (* run the specific scenario given by [f] *)
  let* () = f node dal_node client proto_parameters num_levels keys in

  save ~restart:false

let register () =
  scenario Dailynet "without" scenario_without_rollup_node ;
  scenario Mondaynet "without" scenario_without_rollup_node ;
  scenario Dailynet "with" scenario_with_rollup_node ;
  scenario Mondaynet "with" scenario_with_rollup_node
