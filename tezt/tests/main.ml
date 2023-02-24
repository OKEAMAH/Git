(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2020 Metastate AG <hello@metastate.dev>                     *)
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
   Component: All
   Invocation: make test-tezt
   Subject: This file is the entrypoint of all Tezt tests. It dispatches to
            other files.
*)

let migrate_to = Protocol.Alpha

let alpha_can_stitch_from_its_predecessor = false

(* This module runs the tests implemented in all other modules of this directory.
   Each module defines tests which are thematically related,
   as functions to be called here. *)

(* Tests that are protocol-independent.
   They do not take a protocol as a parameter and thus need to be registered only once. *)
let register_protocol_independent_tests () =
  Binaries.register_protocol_independent () ;
  Bootstrap.register_protocol_independent () ;
  Cli_tezos.register_protocol_independent () ;
  Client_config.register_protocol_independent () ;
  Client_keys.register_protocol_independent () ;
  Client_chain_id.register_protocol_independent () ;
  Config.register () ;
  Demo_protocols.register () ;
  Injection.register_protocol_independent () ;
  Forge_block.register_protocol_independent () ;
  Light.register_protocol_independent () ;
  Mockup.register_protocol_independent () ;
  P2p.register_protocol_independent () ;
  Proxy.register_protocol_independent () ;
  Rpc_tls.register_protocol_independent () ;
  Snoop_codegen.register_protocol_independent ()

(* Tests related to protocol migration. *)
let register_protocol_migration_tests () =
  let migrate_from = Option.get @@ Protocol.previous_protocol migrate_to in
  Mockup.register_constant_migration ~migrate_from ~migrate_to ;
  Protocol_migration.register ~migrate_from ~migrate_to ;
  Protocol_table_update.register ~migrate_from ~migrate_to ;
  User_activated_upgrade.register ~migrate_from ~migrate_to ;
  (if alpha_can_stitch_from_its_predecessor then
   Protocol.previous_protocol Alpha
   |> Option.iter @@ fun from_protocol ->
      Voting.register
        ~from_protocol
        ~to_protocol:(Known Alpha)
        ~loser_protocols:[]) ;
  Voting.register
    ~from_protocol:migrate_to
    ~to_protocol:Injected_test
    ~loser_protocols:[migrate_from] ;
  Voting.register
    ~from_protocol:migrate_to
    ~to_protocol:Demo
    ~loser_protocols:[migrate_from] ;
  Sc_rollup.register_migration ~migrate_from ~migrate_to ;
  Dal.register_migration ~migrate_from ~migrate_to

let register_old_protocol_migration_tests () =
  List.iter
    (fun p ->
      match (p, Protocol.next_protocol p) with
      | _, Some Alpha -> () (* Already in register_protocol_migration_tests *)
      | _, None -> ()
      | migrate_from, Some migrate_to ->
          Sc_rollup.register_migration ~migrate_from ~migrate_to)
    Protocol.all

(* Register tests that use [Protocol.register_test] and for which we rely on
   [?supports] to decide which protocols the tests should run on.
   As a consequence, all those tests should be registered with [Protocol.all]
   as the list of protocols.

   In the future, we could remove the [Protocol.t list] arguments from
   [Protocol.register_test]. It would use [Protocol.all] directly instead.
   Then we could remove the [~protocols] argument from all register functions. *)
let register_protocol_tests_that_use_supports_correctly () =
  let protocols = Protocol.all in
  Bad_annot.register ~protocols ;
  Bad_indentation.register ~protocols ;
  Baker_test.register ~protocols ;
  Baker_operations_cli_options.register ~protocols ;
  Baking.register ~protocols ;
  Baking.register_operations_pool ~protocols ;
  Basic.register ~protocols ;
  Big_map_all.register ~protocols ;
  Big_map_arity.register ~protocols ;
  Bootstrap.register ~protocols ;
  Cache_cache.register ~protocols ;
  Client_commands.register ~protocols ;
  Client_config.register ~protocols ;
  Client_fa12.register ~protocols ;
  Client_keys.register ~protocols ;
  Client_run_view.register ~protocols ;
  Client_simulation_flag.register ~protocols ;
  Comparable_datatype.register ~protocols ;
  Consensus_key.register ~protocols ;
  Contract_baker.register ~protocols ;
  Contract_big_map_to_self.register ~protocols ;
  Contract_entrypoints.register ~protocols ;
  Contract_hash_fun.register ~protocols ;
  Contract_hash_with_origination.register ~protocols ;
  Contract_liquidity_baking.register ~protocols ;
  Contract_non_regressions.register protocols ;
  Contract_onchain_opcodes.register ~protocols ;
  Contract_opcodes.register ~protocols ;
  Contract_typecheck_contract.register ~protocols ;
  Contract_typecheck_regression.register ~protocols ;
  Contract_macros.register ~protocols ;
  Contract_mini_scenarios.register ~protocols ;
  Contract_bootstrap.register ~protocols ;
  Create_contract.register ~protocols ;
  Deposits_limit.register ~protocols ;
  Double_bake.register ~protocols ;
  Double_consensus.register ~protocols ;
  Encoding.register ~protocols ;
  Events.register ~protocols ;
  External_validation.register ~protocols ;
  Forge.register ~protocols ;
  Fork.register ~protocols ;
  Gas_bound.register ~protocols ;
  Global_constants.register ~protocols ;
  Hash_data.register ~protocols ;
  Increase_paid_storage.register ~protocols ;
  Large_metadata.register ~protocols ;
  Light.register ~protocols ;
  Liquidity_baking_per_block_votes.register ~protocols ;
  Manager_operations.register ~protocols ;
  Mockup.register ~protocols ;
  Mockup.register_global_constants ~protocols ;
  Monitor_operations.register ~protocols ;
  Multiple_transfers.register ~protocols ;
  Multisig.register ~protocols ;
  Node_cors.register ~protocols ;
  Node_event_level.register ~protocols ;
  Nonce_seed_revelation.register ~protocols ;
  Normalize.register ~protocols ;
  Operation_validation.register ~protocols ;
  Operation_size.register ~protocols ;
  Order_in_top_level.register ~protocols ;
  P2p.register ~protocols ;
  Precheck.register ~protocols ;
  Prevalidator.register ~protocols ;
  Protocol_limits.register ~protocols ;
  Proxy.register ~protocols ;
  Proxy_server_test.register ~protocols ;
  RPC_test.register protocols ;
  Rpc_versioning_attestation.register ~protocols ;
  Reject_malformed_micheline.register ~protocols ;
  Replace_by_fees.register ~protocols ;
  Retro.register ~protocols ;
  Rpc_config_logging.register ~protocols ;
  Run_operation_RPC.register ~protocols ;
  Run_script.register ~protocols ;
  Runtime_script_failure.register ~protocols ;
  Sapling.register ~protocols ;
  Script_annotations.register ~protocols ;
  Script_chain_id.register ~protocols ;
  Script_execution_ordering.register ~protocols ;
  Script_hash_regression.register ~protocols ;
  Script_hash_multiple.register ~protocols ;
  Script_manager_contracts.register ~protocols ;
  Script_conversion.register ~protocols ;
  Script_illtyped.register ~protocols ;
  Sc_rollup.register ~protocols ;
  Self_address_transfer.register ~protocols ;
  Signer_test.register ~protocols ;
  Storage_reconstruction.register ~protocols ;
  Storage_snapshots.register ~protocols ;
  Stresstest_command.register ~protocols ;
  Synchronisation_heuristic.register ~protocols ;
  Tenderbake.register ~protocols ;
  Testnet_dictator.register ~protocols ;
  Test_contract_bls12_381.register ~protocols ;
  Ticket_receipt_and_rpc.register ~protocols ;
  Transfer.register ~protocols ;
  Tickets.register ~protocols ;
  Tzip4_view.register ~protocols ;
  Used_paid_storage_spaces.register ~protocols ;
  Vdf_test.register ~protocols ;
  Views.register ~protocols ;
  Zk_rollup.register ~protocols

(* Regression tests are not easy to maintain for multiple protocols because one needs
   to update and maintain all the expected output files. Some of them, such as
   those in [create_contract.ml] and [deposits_limit.ml], already support all protocols.
   Some do not. Those that do not are declared here. *)
let register_protocol_specific_because_regression_tests () =
  Dal.register ~protocols:[Alpha] ;
  Dac.register ~protocols:[Alpha] ;
  Dac.register_with_unsupported_protocol ~protocols:[Mumbai] ;
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4652
           re-enable Mumbai when DAC is separated from Dal node. *)
  Evm_rollup.register ~protocols:[Alpha] ;
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4652
         re-enable Mumbai when DAC is separated from Dal node. *)
  Tx_sc_rollup.register ~protocols:[Alpha] ;
  Sc_sequencer.register ~protocols:[Alpha] ;
  Snoop_codegen.register ~protocols:[Alpha] ;
  Timelock.register ~protocols:[Alpha] ;
  Timelock_disabled.register ~protocols:[Mumbai]

type coverage_action = Merge | Verify
let () =
  let coverage_action = match Cli.get_string_opt "coverage_action" with
  | Some "merge" -> Some Merge
  | Some "verify" -> Some Verify
  | Some action -> Test.fail "Invalid Tezt test argument 'coverage_action': %s. Should be one of 'verify' or 'merge'." action
  | None -> None
  in
  let coverage_output test =
    let title = Test.title test in
    let file = Test.file test in
    let output_dir =
      (* hack here hardcoding coverage location *)
      project_root // "tezt/tests" // "_coverage_output"
    in
    let relative_output_dir =
      let test_title_file =
        let sanitize_char = function
          | ( 'a' .. 'z'
            | 'A' .. 'Z'
            | '0' .. '9'
            | '_' | '-' | '.' | ' ' | '(' | ')' ) as x ->
              x
          | _ -> '-'
        in
        let full = String.map sanitize_char title in
        let max_length = 80 in
        let title = if String.length full > max_length then String.sub full 0 max_length
        else full in
        sf "%d-%s" (Unix.getpid ()) title
      in
      file // test_title_file
    in
    output_dir // relative_output_dir
  in
  let reset test =
    let rec create_parents dirname =
      let parent = Filename.dirname dirname in
      if String.length parent < String.length dirname then (
        create_parents parent ;
        if not (Sys.file_exists dirname) then
          try
            Log.info "Create %S" dirname ;
            Unix.mkdir dirname 0o755
          with Unix.Unix_error (EEXIST, _, _) ->
            (* Can happen with [-j] in particular. *)
            ())
    in
    let stored_full_output_dir = coverage_output test in
    create_parents stored_full_output_dir ;
    Unix.putenv "BISECT_FILE" (stored_full_output_dir ^ "/") ;
    Log.debug "Storing coverage in %S" stored_full_output_dir
  in
  let cleanup coverage_action test =
    let coverage_directory = coverage_output test in
    let coverage_files =
      Sys.readdir coverage_directory
      |> Array.to_list
      |> List.filter @@ fun filename -> filename =~ rex "^\\d+\\.coverage$"
    in
    let* () = (match coverage_files with
    | [] ->
        Log.info "Test '%s' did not produce any coverage" (Test.title test) ;
        unit
    | _ ->
        (* merge coverage *)
        match coverage_action with
          | Merge ->
            let* () =
              Process.run "bisect-ppx-report"
              @@ [
                "merge";
                "--coverage-path";
                coverage_directory;
                coverage_directory // "merged.coverage";
              ]
            in
            (* remove unmerged *)
            List.iter
              (fun filename ->
                 let filename = coverage_directory // filename in
                 Sys.remove filename ;
                 Log.info "(not) Removed coverage trace: %s" filename)
              coverage_files ;
            unit
          | Verify ->
            let* () =
              Lwt_list.iter_s
                (fun filename ->
                   let filename = coverage_directory // filename in
                   let* () =
                     Process.run "bisect-ppx-report" @@ ["summary"; filename]
                   in
                   Log.info "Coverage trace %s is not corrupt" filename ;
                   unit)
                coverage_files
            in
            unit)
    in
    (* Reset to a default location to get the coverage of the tezt execution it self *)
    Unix.putenv "BISECT_FILE" (project_root // "tezt/tests/_coverage_output/") ;
    unit
  in
  match coverage_action with
  | Some coverage_action ->
    Test.declare_reset_function reset ;
    Test.declare_cleanup_function (cleanup coverage_action)
  | None -> ()

let () =
  register_protocol_independent_tests () ;
  register_protocol_migration_tests () ;
  register_old_protocol_migration_tests () ;
  register_protocol_tests_that_use_supports_correctly () ;
  register_protocol_specific_because_regression_tests () ;
  Tezos_scoru_wasm_regressions.register () ;
  (* Test.run () should be the last statement, don't register afterwards! *)
  Test.run ()
