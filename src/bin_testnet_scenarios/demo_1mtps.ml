open Tezt
open Tezt.Base
open Tezt_tezos

(* TODO: Should be a command-line argument *)
let ssh_user = "lthms"

(* TODO: Should be a command-line argument *)
let ssh_id = "/home/lthms/.ssh/localhost"

(* TODO: Should be a command-line argument *)
let ssh_address = "localhost"

(* TODO: Should be a command-line argument *)
let runners =
  let l1_nodes_count = 5 in
  List.init l1_nodes_count (fun _ ->
      Runner.create ~ssh_user ~ssh_id ~address:ssh_address ())

(* TODO: Should be a command-line argument *)
let rollups_per_node = 5

module Local = struct
  (* TODO: Should be a command-line argument *)
  let octez_node = "/home/lthms/git/tezos/octez-node"

  (* TODO: Should be a command-line argument *)
  let octez_client = "/home/lthms/git/tezos/octez-client"

  (* TODO: Should be a command-line argument *)
  let smart_rollup_node =
    Format.sprintf
      "/home/lthms/git/tezos/octez-smart-rollup-node-%s"
      (Protocol.tag Testnet.protocol)

  let wallet = "/home/lthms/demo/demo_wallet"
end

module Remote = struct
  let snapshot home = Format.sprintf "%s/snapshot" home

  let octez_node home = Format.sprintf "%s/octez-node" home

  let smart_rollup_node home =
    Format.sprintf
      "%s/octez-smart-rollup-node-%s"
      home
      (Protocol.tag Testnet.protocol)

  let wallet home = Format.sprintf "%s/demo_wallet" home
end

let bootstrap_node (home, runner) =
  let open Lwt.Syntax in
  let l1_node_args =
    Node.[Expected_pow 26; Synchronisation_threshold 1; Network Testnet.network]
  in
  let node = Node.create ~path:(Remote.octez_node home) ~runner l1_node_args in

  let* () = Node.config_init node [] in
  let* () = Node.snapshot_import node (Remote.snapshot home) in

  Log.info "Snapshot imported for %s" (Node.name node) ;

  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in

  let client =
    Client.create
      ~path:Local.octez_client
      ~base_dir:Local.wallet
      ~endpoint:(Node node)
      ()
  in
  let* () = Client.bootstrapped client in

  Log.info "%s ready" (Node.name node) ;

  Lwt.return (home, node, client)

let install_nodes snapshot_path i runner =
  let open Lwt.Syntax in
  let home = Temp.dir ~runner Format.(sprintf "%d" i) in
  Log.info "Deploying in %s." home ;
  let* () = Helpers.deploy ~runner ~r:true Local.wallet (Remote.wallet home) in
  let* () = Helpers.deploy ~runner snapshot_path (Remote.snapshot home) in
  let* () = Helpers.deploy ~runner Local.octez_node (Remote.octez_node home) in
  let* () =
    Helpers.deploy
      ~runner
      Local.smart_rollup_node
      (Remote.smart_rollup_node home)
  in
  Lwt.return (home, runner)

let setup_rollup home rollup_id node client =
  let open Lwt.Syntax in
  let runner = Option.get (Node.runner node) in
  let funded_account = Format.asprintf "demo_%d" rollup_id in
  let* rollup =
    Client.Sc_rollup.originate
      client
      ~wait:"0"
      ~src:funded_account
      ~kind:"wasm_2_0_0"
      ~parameters_ty:"bytes"
      ~boot_sector:Constant.wasm_echo_kernel_boot_sector
      ~burn_cap:(Tez.of_int 2)
  in

  Log.info "Rollup %s originated from %s" rollup (Node.name node) ;

  let rollup_node =
    Sc_rollup_node.create
      ~path:(Remote.smart_rollup_node home)
      ~runner
      ~base_dir:(Remote.wallet home)
      ~default_operator:funded_account
      ~protocol:Testnet.protocol
      Operator
      node
  in

  let* _ = Sc_rollup_node.config_init rollup_node rollup in
  Log.info "Starting %s to track %s" (Sc_rollup_node.name rollup_node) rollup ;
  let* () = Sc_rollup_node.run rollup_node [] in

  Lwt.return (node, client, rollup, rollup_node)

let setup_rollups rollups_per_node i (home, node, client) =
  Lwt_list.map_s
    (fun x -> setup_rollup home ((i * rollups_per_node) + x) node client)
    (List.init rollups_per_node Fun.id)

let onemtps_demo () =
  (* Fetch a fresh snapshot *)
  let* snapshot_path = Helpers.download Testnet.snapshot_url "snapshot" in
  (* install nodes on runners *)
  Log.info "Deploying nodes" ;
  let* runners = Lwt_list.mapi_p (install_nodes snapshot_path) runners in
  Log.info "Nodes deployed" ;
  (* setup L1 nodes *)
  let* nodes = Lwt_list.map_p bootstrap_node runners in
  (* setup L2 nodes *)
  let* nodes = Lwt_list.mapi_p (setup_rollups rollups_per_node) nodes in
  let nodes = List.concat nodes in
  (* wait for every rollup nodes to be ready *)
  let* () =
    Lwt_list.iter_p
      (fun (_, _, _, rollup_node) ->
        let* _ = Sc_rollup_node.wait_for_ready rollup_node in
        Lwt.return ())
      nodes
  in
  Log.info "Rollup nodes are ready" ;
  (* waiting enough time for several commitments to be posted *)
  let node, _, _, _ = List.hd nodes in
  let current_level = Node.get_level node in
  let target_level = current_level + 150 in
  Log.info
    "Setup completed at level %d, waited for level %d now"
    current_level
    target_level ;
  let* _ = Node.wait_for_level node target_level in
  (* exit *)
  Lwt.return ()

let register () =
  Tezt.Test.register
    ~__FILE__
    ~title:"1MTPS demo orchestrator"
    ~tags:["demo"]
    onemtps_demo
