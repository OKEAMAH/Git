open Tezt
open Tezt_tezos
open Tezt.Base

type mode = Nodes | Rest

(** Running:
    The script will ssh in to a running docker container.

    Todo so, run the following off latest Mondaynet.

    STARTUP=$(mktemp)
    cat > $STARTUP << EOF
apk add --no-cache openssh;
apk add --no-cache curl;
apk add --no-cache shadow;

ssh-keygen -A;
mkdir -p /root/.ssh;

usermod -p '*' tezos;

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPr+aijjZzL8pewu/aail7psaA3V8eWRMOjDIPd2+Iv em.turner@tutanota.com"  > /home/tezos/.ssh/authorized_keys;
echo 'PasswordAuthentication no' > /etc/ssh/sshd_config;
/usr/sbin/sshd -D -p 30000 -e;
EOF
    docker run -it -p 30000:30000 -u root --entrypoint /bin/sh \
      -v $(pwd):/home/tezos/logs \
      --security-opt seccomp=../seccomp.json \
      tezos/tezos:master_f7a56991_20230505182326 \
      -c "$(cat $STARTUP)"

    Login with:
    ssh tezos@localhost -p 30000 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

    Run node:
    perf record --call-graph=dwarf -- /usr/local/bin/octez-smart-rollup-node-alpha --base-dir /tmp/tezt-23702/1/0/.tezos-client run --data-dir /tmp/tezt-23702/1/0/rollup-0 --log-kernel-debug --log-kernel-debug-file logs/kernel-0.log --rpc-addr 127.0.0.1 --rpc-port 52811 --endpoint http://0.0.0.0:40549



       *)

(**
    Notes on GUIX:
    ln -s /home/emma/.guix-home/profile/bin/ssh /no-such-path/ssh

    Notes on NIX:
    unset TMPDIR

    Notes:
    If an error like 'mkdir exited with code 255 (@@@@@@@ occurs, clean up the ~/.ssh/known_hosts file

    Ensure you cleanup any `ssh-tezos@` master connections

    Too many open files:
    for running process

check NOFILE limit:

$ prlimit -p 1930 -n
RESOURCE DESCRIPTION                 SOFT    HARD UNITS
NOFILE   max number of open files 1048576 1048576 files

change NOFILE limit

prlimit -n1048576
ulimit -S -n 1048576

        *)

(*
  ====
  FLOW
  ====

The flow of the orchestrator is of the following:

- We run the demo with N total rollups.
- We run the demo across M total machines.
- Every machine runs a single `octez-node`, connected to Mondaynet.

Each rollup has 5 components, which must all run on different machines (to ensure data travels over the network)
- Rollup: smart-rollup-node, dac-observer, smart-rollup-client. (The collector is already running.)
- Dac coordinator
- Dac member 1
- Dac member 2
- Clients: Dac client & Octez client

Therefore, to set up a Rollup ready for Demo, 5 Nodes are required.
*)
let protocol = Protocol.Alpha

(* TODO: Should be a command-line argument *)
let ssh_user = "tezos"

(* TODO: Should be a command-line argument *)
let ssh_id = "/home/emma/.ssh/tutanota"

(* TODO: Should be a command-line argument *)
(* - Must be a multiple of 5 *)
let internal_addresses_dac =
  [
    "10.10.0.31";
    "10.10.0.24";
    "10.10.0.33";
    "10.10.0.46";
    "10.10.0.2";
    "10.10.0.57";
    "10.10.0.48";
    "10.10.0.14";
    "10.10.0.16";
    "10.10.0.56";
    "10.10.0.29";
    "10.10.0.58";
    "10.10.0.60";
    "10.10.0.50";
    "10.10.0.44";
    "10.10.0.32";
    "10.10.0.28";
    "10.10.0.13";
    "10.10.0.25";
    "10.10.0.52";
    "10.10.0.27";
    "10.10.0.59";
    "10.10.0.36";
    "10.10.0.6";
    "10.10.0.23";
    "10.10.0.51";
    "10.10.0.34";
    "10.10.0.43";
    "10.10.0.38";
    "10.10.0.41";
  ]

let internal_addresses_rollup =
  [
    "10.10.0.21";
    "10.10.0.5";
    "10.10.0.45";
    "10.10.0.30";
    "10.10.0.8";
    "10.10.0.7";
    "10.10.0.26";
    "10.10.0.4";
    "10.10.0.55";
    "10.10.0.37";
    "10.10.0.20";
    "10.10.0.53";
    "10.10.0.49";
    "10.10.0.11";
    "10.10.0.18";
    "10.10.0.17";
    "10.10.0.19";
    "10.10.0.42";
    "10.10.0.47";
    "10.10.0.9";
    "10.10.0.15";
    "10.10.0.40";
    "10.10.0.54";
    "10.10.0.35";
    "10.10.0.10";
    "10.10.0.12";
    "10.10.0.61";
    "10.10.0.22";
    "10.10.0.39";
    "10.10.0.3";
  ]

let ssh_addresses_dac =
  [
    "130.211.83.176";
    "34.22.174.130";
    "34.79.160.23";
    "34.140.8.117";
    "34.78.44.120";
    "130.211.69.210";
    "34.77.158.111";
    "34.78.232.73";
    "34.78.114.102";
    "35.195.104.96";
    "35.195.174.242";
    "34.22.244.86";
    "35.241.207.73";
    "34.79.58.185";
    "34.22.183.48";
    "35.240.12.211";
    "34.140.68.167";
    "34.77.194.109";
    "34.22.182.92";
    "35.240.59.200";
    "34.140.197.226";
    "34.78.107.253";
    "35.189.192.149";
    "34.77.72.47";
    "146.148.26.153";
    "34.140.105.186";
    "35.241.252.226";
    "130.211.92.192";
    "34.78.182.110";
    "34.78.55.156";
  ]

let ssh_addresses_rollup =
  [
    "34.77.72.108";
    "35.195.141.226";
    "35.205.19.158";
    "23.251.136.157";
    "35.189.228.251";
    "34.78.248.58";
    "34.140.239.230";
    "35.205.157.146";
    "35.189.209.251";
    "34.79.136.103";
    "34.79.169.196";
    "34.140.183.67";
    "34.140.116.112";
    "35.240.100.49";
    "130.211.99.103";
    "34.76.205.159";
    "130.211.74.105";
    "35.205.24.197";
    "35.233.56.151";
    "35.187.18.56";
    "104.155.37.174";
    "35.189.240.191";
    "34.76.171.218";
    "34.76.189.93";
    "35.195.245.34";
    "35.205.24.221";
    "34.22.161.240";
    "34.78.183.228";
    "34.78.63.42";
    "34.77.52.162";
  ]

let ssh_port = 30000

let node_rpc_port = 50000

let dac_coord_base_port = 62500

(* TODO: Should be a command-line argument *)
let network = "https://teztnets.xyz/mondaynet-2023-05-15"

(* TODO: Should be a command-line argument *)
let _snapshot_url =
  "http://mondaynet.snapshots.s3-website.eu-central-1.amazonaws.com/mondaynet-rolling-snapshot"

let rollup_runners () =
  List.map
    (fun ssh_address ->
      Runner.create ~ssh_user ~ssh_id ~ssh_port ~address:ssh_address ())
    ssh_addresses_rollup

let dac_runners () =
  List.map
    (fun ssh_address ->
      Runner.create ~ssh_user ~ssh_id ~ssh_port ~address:ssh_address ())
    ssh_addresses_dac

(* TODO: Should be a command-line argument *)
let rollups_per_node = 4

(* TODO: Should be a command-line argument *)
let dacs_per_node = 4

module Local = struct
  (* TODO: Should be a command-line argument *)
  (* let octez_node = "/home/emma/sources/tezos/octez-node" *)

  (* TODO: Should be a command-line argument *)
  (* let octez_client = "/home/emma/sources/tezos/octez-client" *)

  (* TODO: Should be a command-line argument *)
  (* let smart_rollup_node = *)
  (*   Format.sprintf *)
  (*     "/home/sources/emma/tezos/octez-smart-rollup-node-%s" *)
  (*     (Protocol.tag protocol) *)

  let snapshot =
    project_root // Filename.dirname __FILE__ // "artifacts/snapshot.rolling"

  let snapshot_old =
    project_root // Filename.dirname __FILE__
    // "artifacts/snapshot.rolling.old"

  let wallet =
    project_root // Filename.dirname __FILE__ // "artifacts/tezos-client"

  let installer_kernel =
    project_root // Filename.dirname __FILE__ // "artifacts/installer.wasm"

  let tx_kernel =
    project_root // Filename.dirname __FILE__
    // "artifacts/tx-kernel-debug.wasm"

  let minter =
    project_root // Filename.dirname __FILE__ // "artifacts/mint_and_deposit.tz"

  let messages rollup_id =
    Format.sprintf
      "/home/emma/sources/wasm-demo/artifacts/rollup-messages/rollup%d.messages"
      rollup_id

  let no_pixel_address rollup_id =
    Format.sprintf
      "/home/emma/sources/wasm-demo/artifacts/rollup.no_pixel_addr/rollup.%d.no_pixel_addr"
      rollup_id

  let octez_node = project_root // "octez-node"

  let octez_client = project_root // "octez-client"
end

module Remote = struct
  let snapshot home = Format.sprintf "%s/snapshot" home

  let tx_kernel = "/home/tezos/tx-kernel.wasm"

  let installer home rollup = Format.sprintf "%s/installer-%d" home rollup

  let octez_node = "/usr/local/bin/octez-node"

  let octez_dac_node = "/usr/local/bin/octez-dac-node"

  let octez_client = "/usr/local/bin/octez-client"

  let octez_dac_client = "/usr/local/bin/octez-dac-client"

  let smart_rollup_node =
    Format.sprintf
      "/usr/local/bin/octez-smart-rollup-node-%s"
      (Protocol.tag protocol)

  let wallet home = Format.sprintf "%s/.tezos-client" home

  let messages home rollup_id =
    Format.sprintf "%s/rollup%i-messages" home rollup_id

  let message home rollup_id round =
    messages home rollup_id // Format.sprintf "%d-transfers.out" round
end

let deploy_runnable ~(runner : Runner.t) ?(r = false) local_file dst =
  let identity =
    Option.fold ~none:[] ~some:(fun i -> ["-i"; i]) runner.ssh_id
  in
  let recursive = if r then ["-r"] else [] in
  let port =
    Option.fold
      ~none:[]
      ~some:(fun p -> ["-P"; Format.sprintf "%d" p])
      runner.ssh_port
  in
  let dst =
    Format.(
      sprintf
        "%s%s:%s"
        (Option.fold ~none:"" ~some:(fun u -> sprintf "%s@" u) runner.ssh_user)
        runner.address
        dst)
  in
  let process =
    Process.spawn
      "scp"
      (*Use -O for original transfer protocol *)
      (["-O"] @ identity @ recursive @ port @ [local_file] @ [dst])
  in
  Runnable.{value = process; run = (fun process -> Process.check process)}

let deploy ~runner ?r local_file dst =
  Runnable.run @@ deploy_runnable ~runner ?r local_file dst

let _download_snapshot ?runner home = function
  | `Url url ->
      let open Runnable.Syntax in
      Log.info "Download snapshot from url" ;
      let snapshot_path = Remote.snapshot home in
      let*! _ =
        RPC.Curl.get_raw ?runner ~args:["--output"; snapshot_path] url
      in
      Log.info "Snapshot downloaded" ;
      Lwt.return_unit
  | `Path path -> Lwt.return path

let setup_artifacts internal_addresses per i runner ~mode =
  let open Lwt.Syntax in
  Log.info "Creating home %d" i ;
  let home = Temp.dir ~runner Format.(sprintf "%d" i) in
  Log.info "Created home %d %s" i home ;
  let* () =
    if mode = Nodes then (
      Log.info "Copying snapshot snapshot %d" i ;
      deploy ~runner ~r:false Local.snapshot (Remote.snapshot home))
    else return ()
  in
  Log.info "Deploying wallet %s (%d) to %s" Local.wallet i (Remote.wallet home) ;
  let* () = deploy ~runner ~r:true Local.wallet (Remote.wallet home) in
  let base_rollup_id = i * per in
  let rollup_ids = List.init per (fun i -> base_rollup_id + i) in
  let internal = List.nth internal_addresses i in
  Lwt.return (home, runner, rollup_ids, internal)

type group = {
  home : string;
  node : Node.t;
  client : Client.t;
  runner : Runner.t;
  internal : string;
}

let group_to_string (g : group) =
  Format.sprintf "Group: -h:%s -a:%s -i:%s" g.home g.runner.address g.internal

type rollup_runner = {
  rollup_id : int;
  client : group;
  rollup : group;
  dac_coord : group;
  dac_mem_1 : group;
  dac_mem_2 : group;
}

(** Distribute runners to ensure that all parts of a rollup are running on different machines. *)
let distribute_nodes rollup_client_nodes dac_client_nodes =
  rollup_client_nodes
  |> List.map (fun (home, node, client, rollup_ids, runner, internal) ->
         List.map
           (fun rollup_id ->
             let rollup = {home; node; client; runner; internal} in
             Log.info "Rollup %d rollup %s" rollup_id @@ group_to_string rollup ;

             let offset i nodes = (rollup_id + i) mod List.length nodes in
             let runner i nodes =
               let home, node, client, _, runner, internal =
                 List.nth nodes @@ offset i nodes
               in
               {home; node; runner; client; internal}
             in
             let dac_coord = runner 0 dac_client_nodes in
             Log.info "Rollup %d daccor %s" rollup_id
             @@ group_to_string dac_coord ;
             let client = runner 1 dac_client_nodes in
             Log.info "Rollup %d client %s" rollup_id @@ group_to_string client ;
             let dac_mem_1 = runner 2 dac_client_nodes in
             Log.info "Rollup %d dacme1 %s" rollup_id
             @@ group_to_string dac_mem_1 ;
             let dac_mem_2 = runner 3 dac_client_nodes in
             Log.info "Rollup %d dacme2 %s" rollup_id
             @@ group_to_string dac_mem_2 ;
             {rollup_id; client; rollup; dac_coord; dac_mem_1; dac_mem_2})
           rollup_ids)
  |> List.flatten

let prepare_snapshot ~mode () =
  let open Lwt.Syntax in
  if mode <> Nodes then return ()
  else
    let l1_node_args =
      Node.[Expected_pow 26; Synchronisation_threshold 1; Network network]
    in
    let node = Node.create ~path:Local.octez_node l1_node_args in

    let* () = Node.config_init node [] in

    let* () = Node.snapshot_import node Local.snapshot in
    Log.info "Snapshot imported for %s" (Node.name node) ;
    let* () = Node.run node [] in
    let* () = Node.wait_for_ready node in

    Log.info "Node %s ready" (Node.name node) ;

    let client =
      Client.create ~path:Local.octez_client ~endpoint:(Node node) ()
    in
    let* () = Client.bootstrapped client in
    let* level = Client.level client in
    Log.info "%s ready" (Node.name node) ;

    let* () = Node.terminate node in
    let () = Unix.rename Local.snapshot Local.snapshot_old in
    Node.snapshot_export
      ~history_mode:Rolling_history
      node
      ~export_level:(level - 1)
      Local.snapshot

let start_bootstrap_node (home, runner, rollup_ids, internal_ip) ~mode =
  let open Lwt.Syntax in
  let l1_node_args =
    Node.[Expected_pow 26; Synchronisation_threshold 1; Network network]
  in
  let node =
    Node.create
      ~path:Remote.octez_node
      ~runner
      ~rpc_host:"0.0.0.0"
      ~rpc_port:node_rpc_port
      l1_node_args
  in

  let+ () =
    if mode = Nodes then (
      let* () = Node.config_init node [] in

      let* () = Node.snapshot_import node (Remote.snapshot home) in
      Log.info "Snapshot imported for %s" (Node.name node) ;

      Node.run node [])
    else return ()
  in
  (home, runner, rollup_ids, internal_ip, node)

(** [bootstrap_node _snapshot_path ()] *)
let finish_bootstrap_node (home, runner, rollup_ids, internal_ip, node) ~mode =
  let open Lwt.Syntax in
  let* () =
    if mode = Nodes then
      let+ () = Node.wait_for_ready node in
      Log.info "Node %s ready" (Node.name node)
    else return ()
  in
  let client =
    Client.create
      ~runner
      ~path:Remote.octez_client
      ~base_dir:(Remote.wallet home)
      ~endpoint:(Address (node, "0.0.0.0", node_rpc_port))
      ()
  in
  let* () = Client.bootstrapped client in

  Log.info "%s ready" (Node.name node) ;

  Lwt.return (home, node, client, rollup_ids, runner, internal_ip)

let deposit_ticket ~rollup_node ~client ~content ~rollup ~no_pixel_addr
    ~rollup_id ~mint_and_deposit_contract =
  let open Lwt.Syntax in
  Log.info "Depositing %s to %s" content rollup ;
  let* () =
    (* Internal message through forwarder - 255 * 5000 per ticket needed *)
    let arg =
      sf {| Pair (Pair %S %S) (Pair 1275000 %S) |} rollup no_pixel_addr content
    in
    Client.transfer
      client
      ~wait:"0"
      ~amount:Tez.zero
      ~giver:(Format.sprintf "demo_%d" rollup_id)
      ~receiver:mint_and_deposit_contract
      ~arg
      ~burn_cap:(Tez.of_int 1000)
  in
  let _ = rollup_node in
  let+ _level = Client.level client in
  (* let+ _ = Sc_rollup_node.wait_for_level ~timeout:30. rollup_node level in *)
  ()

let setup_installer ~rollup ~dac_client ~pk_0 ~pk_1 =
  let installer = read_file Local.installer_kernel in
  (* let tx_kernel = Hex.of_string @@ read_file Local.tx_kernel in *)
  let installer_dummy_hash =
    "1acaa995ef84bc24cc8bb545dd986082fbbec071ed1c3e9954abea5edc441ccd3a"
  in
  let dac_member_0_dummy =
    "3433E5AA739292FDEB08AC05B4102095BD6E2602B76DA2E89322491929EDD730F62A536FFFC796FCA8CB5E261129F091"
  in
  let (`Hex dac_member_0) =
    Tezos_crypto.Signature.Bls.Public_key.(
      pk_0 |> of_b58check_exn
      |> Data_encoding.Binary.to_bytes_exn encoding
      |> Hex.of_bytes)
  in
  Log.info "Dac (%d) member 0: %s | %s" rollup.rollup_id dac_member_0 pk_0 ;
  assert (String.length dac_member_0_dummy = String.length dac_member_0) ;
  let dac_member_1_dummy =
    "451141561F23E4BED315BBC4D7A77200446A5B4BE43376DB8F648BB4160DB261F5D2077A548936BC3B2FB4148849C41E"
  in
  let (`Hex dac_member_1) =
    Tezos_crypto.Signature.Bls.Public_key.(
      pk_1 |> of_b58check_exn
      |> Data_encoding.Binary.to_bytes_exn encoding
      |> Hex.of_bytes)
  in
  Log.info "Dac (%d) member 1: %s | %s" rollup.rollup_id dac_member_1 pk_1 ;
  assert (String.length dac_member_1_dummy = String.length dac_member_1) ;
  let* result = Dac_client.send_payload_from_file dac_client Remote.tx_kernel in
  let (`Hex root_hash) =
    match result with
    | Dac_client.Root_hash hash -> hash
    | Dac_client.Certificate c -> c
  in
  (* Ensure reveal hash is correct length for installer. *)
  assert (String.length root_hash = 66) ;
  let (`Hex installer) =
    installer
    |> replace_string (rex installer_dummy_hash) ~by:root_hash
    |> replace_string (rex dac_member_0_dummy) ~by:dac_member_0
    |> replace_string (rex dac_member_1_dummy) ~by:dac_member_1
    |> Hex.of_string
  in
  let file = Temp.file @@ Format.sprintf "installer-%d" rollup.rollup_id in
  write_file file ~contents:installer ;
  return file

(* Run a committee member *)
let setup_dac_member ~coordinator ~rollup_id ~member_idx ~member client node
    coord_group =
  let open Lwt.Syntax in
  let Account.{aggregate_public_key_hash; _} = member in
  let dac_node =
    Dac_node.create_committee_member
      ~path:Remote.octez_dac_node
      ~name:(Format.sprintf "dac-member-%d-%d" rollup_id member_idx)
      ~node
      ~coordinator_rpc_host:coord_group.internal
      ~coordinator_rpc_port:(Dac_node.rpc_port coordinator)
      ~address:aggregate_public_key_hash
      ~client
      ()
  in
  let* _dir = Dac_node.init_config dac_node in
  let+ () = Dac_node.run dac_node ~wait_ready:true in
  dac_node

(* Run a dac observer *)
let setup_dac_observer ~coordinator ~rollup_id ~reveal_data_dir client node
    coord_group =
  let open Lwt.Syntax in
  let dac_node =
    Dac_node.create_observer
      ~path:Remote.octez_dac_node
      ~name:(Format.sprintf "dac-observer-%d" rollup_id)
      ~node
      ~coordinator_rpc_host:coord_group.internal
      ~coordinator_rpc_port:(Dac_node.rpc_port coordinator)
      ~client
      ~reveal_data_dir
      ()
  in
  let* _dir = Dac_node.init_config dac_node in
  let+ () = Dac_node.run dac_node ~wait_ready:true in
  dac_node

(* Initialise DAC committee via *)
let setup_dac (rollup : rollup_runner) =
  Log.info "Setup DAC %d" rollup.rollup_id ;
  let open Lwt.Syntax in
  let rollup_data_dir =
    rollup.rollup.home // Printf.sprintf "rollup-%d" rollup.rollup_id
  in
  let () = Runner.Sys.mkdir ~runner:rollup.rollup.runner rollup_data_dir in
  Log.info "Setup DAC %d - generating committee keys" rollup.rollup_id ;
  let* key_1 =
    Client.bls_gen_and_show_keys
      ~alias:(Format.sprintf "committee-member-%d-1" rollup.rollup_id)
      rollup.dac_mem_1.client
  in
  let* key_2 =
    Client.bls_gen_and_show_keys
      ~alias:(Format.sprintf "committee-member-%d-2" rollup.rollup_id)
      rollup.dac_mem_2.client
  in
  Log.info
    "Setup DAC %d - importing committee keys to coordinator"
    rollup.rollup_id ;
  let* () = Client.bls_import_secret_key key_1 rollup.dac_coord.client in
  let* () = Client.bls_import_secret_key key_2 rollup.dac_coord.client in
  let port =
    dac_coord_base_port + rollup.rollup_id
    (* dac_coord_base_port + (rollup.rollup_id / List.length ssh_addresses_rollup) *)
  in
  Log.info
    "Setup DAC %d - creating coordinator (%s:%d)"
    rollup.rollup_id
    rollup.dac_coord.internal
    port ;
  let dac_node =
    Dac_node.create_coordinator
      ~name:(Format.sprintf "dac-coord-%d" rollup.rollup_id)
      ~path:Remote.octez_dac_node
      ~node:rollup.dac_coord.node
      ~client:rollup.dac_coord.client
      ~rpc_host:"0.0.0.0"
      ~rpc_port:port
      ~committee_members:
        (List.map
           (fun (dc : Account.aggregate_key) -> dc.aggregate_public_key_hash)
           [key_1; key_2])
      ()
  in
  Log.info "Setup DAC %d - initialising coordinator" rollup.rollup_id ;
  let* _dir = Dac_node.init_config dac_node in
  Log.info "Setup DAC %d - running coordinator" rollup.rollup_id ;
  let* () = Dac_node.run dac_node ~wait_ready:true in
  Log.info "Setup DAC %d - creating client" rollup.rollup_id ;
  let dac_client =
    Dac_client.create
      ~name:(Format.sprintf "dac-client-%d" rollup.rollup_id)
      ~path:Remote.octez_dac_client
      ~base_dir:(Remote.wallet rollup.client.home)
      ~rpc_host:rollup.dac_coord.internal
      ~runner:rollup.client.runner
      dac_node
  in
  Log.info "Setup DAC %d - testing coordinator reachable" rollup.rollup_id ;
  let* _ =
    Dac_client.send_payload_from_hex dac_client
    @@ Hex.of_string @@ String.make 100 '\000'
  in
  Log.info "Setup DAC %d - creating member 1" rollup.rollup_id ;
  let* member_1 =
    setup_dac_member
      ~coordinator:dac_node
      ~rollup_id:rollup.rollup_id
      ~member_idx:0
      ~member:key_1
      rollup.dac_mem_1.client
      rollup.dac_mem_1.node
      rollup.dac_coord
  in
  Log.info "Setup DAC %d - creating member 2" rollup.rollup_id ;
  let* member_2 =
    setup_dac_member
      ~coordinator:dac_node
      ~rollup_id:rollup.rollup_id
      ~member_idx:1
      ~member:key_2
      rollup.dac_mem_2.client
      rollup.dac_mem_2.node
      rollup.dac_coord
  in
  Log.info "Setup DAC %d - creating observer" rollup.rollup_id ;
  let* observer =
    setup_dac_observer
      ~coordinator:dac_node
      ~rollup_id:rollup.rollup_id
      ~reveal_data_dir:(rollup_data_dir // "wasm_2_0_0")
      rollup.rollup.client
      rollup.rollup.node
      rollup.dac_coord
  in
  Log.info "Setup DAC %d - complete" rollup.rollup_id ;
  return
    ( rollup,
      ( rollup_data_dir,
        dac_node,
        dac_client,
        (member_1, member_2),
        observer,
        (key_1, key_2) ) )

(* ---------------------------- *)
(* Submit DAC external messages *)
(* ---------------------------- *)
let rec submit_dac_messages ?(round = 1) rollup_ =
  let rollup, rollup_address, _rollup_node, _dac_node, dac_client = rollup_ in
  (* let message = *)
  (*   Hex.of_string @@ read_file *)
  (*   @@ Format.sprintf *)
  (*        "/home/emma/sources/wasm-demo/artifacts/rollup-messages/rollup%d.messages/%d-transfers.out" *)
  (*        rollup.rollup_id *)
  (*        round *)
  (* in *)
  (* Log.info "Submitting message for rollup %d at round %d" rollup.rollup_id round ; *)
  let open Tezos_protocol_alpha.Protocol.Alpha_context.Sc_rollup in
  let address =
    rollup_address |> Address.of_b58check_opt |> Option.get
    |> Data_encoding.Binary.to_string_exn Address.encoding
  in
  let* result =
    Dac_client.send_payload_from_file ~threshold:2 dac_client
    @@ Remote.message rollup.client.home rollup.rollup_id round
  in
  let certificate =
    match result with
    | Dac_client.Root_hash _hash -> failwith "Certificate required"
    | Dac_client.Certificate c -> Hex.to_string c
  in
  let (`Hex message) =
    String.concat "" ["\000"; address; certificate] |> Hex.of_string
  in
  write_file
    (Format.sprintf
       "/home/emma/sources/demo-debug/message-%d-%d"
       rollup.rollup_id
       round)
    ~contents:message ;
  let msg = Format.sprintf "hex:[\"%s\"]" message in
  let* () =
    Client.Sc_rollup.send_message
      ~wait:"0"
      ~src:(Format.sprintf "demo-submit-%d" rollup.rollup_id)
      ~msg
      rollup.client.client
  in
  if round >= 8 then return ()
  else submit_dac_messages rollup_ ~round:(round + 1)

let setup_rollup ~mint_and_deposit_contract
    ((rollup : rollup_runner), dac_committee) =
  let open Lwt.Syntax in
  let staked_account = Format.asprintf "demo_%d" rollup.rollup_id in
  let message_account = Format.sprintf "demo-submit-%d" rollup.rollup_id in
  let ( data_dir,
        (dac_node : Dac_node.t),
        (dac_client : Dac_client.t),
        (_dac_members : Dac_node.t * Dac_node.t),
        (_dac_observer : Dac_node.t),
        ( (dac_member_0 : Account.aggregate_key),
          (dac_member_1 : Account.aggregate_key) ) ) =
    dac_committee
  in

  Log.info "Setting up installer for %d" rollup.rollup_id ;
  let* installer =
    setup_installer
      ~rollup
      ~dac_client
      ~pk_0:dac_member_0.aggregate_public_key
      ~pk_1:dac_member_1.aggregate_public_key
  in
  let* () =
    deploy ~runner:rollup.client.runner installer
    @@ Remote.installer rollup.client.home rollup.rollup_id
  in
  Log.info "Originating rollup for %d" rollup.rollup_id ;
  let* rollup_address =
    Client.Sc_rollup.originate
      rollup.client.client
      ~wait:"0"
      ~alias:(Format.sprintf "rollup-%d" rollup.rollup_id)
      ~src:message_account
      ~kind:"wasm_2_0_0"
      ~parameters_ty:"(pair string (ticket string))"
      ~boot_sector:
        (Format.sprintf "file:%s"
        @@ Remote.installer rollup.client.home rollup.rollup_id)
      ~burn_cap:(Tez.of_int 2)
  in

  Log.info "Rollup %s originated - %d" rollup_address rollup.rollup_id ;

  let rollup_node =
    Sc_rollup_node.create
      ~name:(Format.sprintf "sc-rollup-node-%d" rollup.rollup_id)
      ~path:Remote.smart_rollup_node
      ~runner:rollup.rollup.runner
      ~base_dir:(Remote.wallet rollup.rollup.home)
      ~default_operator:staked_account
      ~data_dir
      ~protocol
      Operator
      rollup.rollup.node
  in

  let* _ = Sc_rollup_node.config_init rollup_node rollup_address in
  Log.info
    "Starting %s to track %s"
    (Sc_rollup_node.name rollup_node)
    rollup_address ;
  let* () =
    Sc_rollup_node.run
      rollup_node
      rollup_address
      [
        "--log-kernel-debug";
        "--log-kernel-debug-file";
        Format.sprintf "/home/tezos/logs/kernel-%d.log" rollup.rollup_id;
      ]
  in
  let* _ = Sc_rollup_node.wait_for_ready rollup_node in
  (* tz1 b58 hashes are 36 chars long *)
  let no_pixel_addr =
    read_file @@ Local.no_pixel_address rollup.rollup_id |> fun s ->
    String.sub s 0 36
  in
  Log.info "depositing to %s" @@ String.escaped no_pixel_addr ;
  let* () =
    deposit_ticket
      ~rollup_node
      ~client:rollup.client.client
      ~content:"R"
      ~rollup:rollup_address
      ~no_pixel_addr
      ~rollup_id:rollup.rollup_id
      ~mint_and_deposit_contract
  in
  let* () =
    deposit_ticket
      ~rollup_node
      ~client:rollup.client.client
      ~content:"G"
      ~rollup:rollup_address
      ~no_pixel_addr
      ~rollup_id:rollup.rollup_id
      ~mint_and_deposit_contract
  in
  let* () =
    deposit_ticket
      ~rollup_node
      ~client:rollup.client.client
      ~content:"B"
      ~rollup:rollup_address
      ~no_pixel_addr
      ~rollup_id:rollup.rollup_id
      ~mint_and_deposit_contract
  in
  Lwt.return (rollup, rollup_address, rollup_node, dac_node, dac_client)

let balance_accounts (rollup : rollup_runner) =
  let staked_account = Format.asprintf "demo_%d" rollup.rollup_id in
  let message_account = Format.sprintf "demo-submit-%d" rollup.rollup_id in
  let* balance =
    Client.get_balance_for ~account:message_account rollup.client.client
  in
  let required = Tez.of_int 50 in
  if balance < required then (
    Log.info
      "%s has insufficient balance, transferring extra tez"
      message_account ;
    Client.transfer
      ~wait:"0"
      ~amount:required
      ~giver:staked_account
      ~receiver:message_account
      ~burn_cap:(Tez.of_int 1)
      rollup.client.client)
  else Lwt.return ()

(* let rec get_continue_conf () = *)
(*   Log.info "===============" ; *)
(*   Log.info "Continue? (yes)" ; *)
(*   Log.info "===============" ; *)
(*   let* line = Lwt_io.read_line Lwt_io.stdin in *)
(*   if line = "yes" then Lwt.return () *)
(*   else ( *)
(*     Log.warn "'yes' required" ; *)
(*     get_continue_conf ()) *)

let rec get_mode () =
  Log.info "====================" ;
  Log.info "Mode? (nodes | rest)" ;
  Log.info "====================" ;
  let* line = Lwt_io.read_line Lwt_io.stdin in
  match line with
  | "nodes" -> return Nodes
  | "rest" -> return Rest
  | _ ->
      Log.warn "'nodes' or 'rest' required" ;
      get_mode ()

(* -------- *)
(* Run Demo *)
(* -------- *)
let main () =
  let open Lwt.Syntax in
  let* mode = get_mode () in
  Log.info "Preparing snapshot" ;
  let* () = prepare_snapshot ~mode () in
  (* install nodes on runners *)
  Log.info "Creating runners" ;
  let rollup_runners = rollup_runners () in
  let dac_runners = dac_runners () in
  Log.info "---------------------------" ;
  Log.info "Copying artifacts (rollups)" ;
  Log.info "---------------------------" ;
  let* rollup_runners =
    Lwt_list.mapi_p
      (setup_artifacts internal_addresses_rollup rollups_per_node ~mode)
      rollup_runners
  in
  Log.info "-----------------------" ;
  Log.info "Copying artifacts (dac)" ;
  Log.info "-----------------------" ;
  let* dac_runners =
    Lwt_list.mapi_p
      (setup_artifacts internal_addresses_dac dacs_per_node ~mode)
      dac_runners
  in
  Log.info "Bootstrapping nodes" ;
  (* setup L1 nodes *)
  let* rollup_client_nodes =
    Lwt_list.map_p (start_bootstrap_node ~mode) rollup_runners
  in
  let* dac_client_nodes =
    Lwt_list.map_p (start_bootstrap_node ~mode) dac_runners
  in
  Log.info "All nodes started" ;
  let* rollup_client_nodes =
    Lwt_list.map_p (finish_bootstrap_node ~mode) rollup_client_nodes
  in
  let* dac_client_nodes =
    Lwt_list.map_p (finish_bootstrap_node ~mode) dac_client_nodes
  in
  Log.info "----------------------" ;
  Log.info "All nodes bootstrapped" ;
  Log.info "----------------------" ;
  let* node =
    if mode <> Nodes then (
      let scenario_nodes =
        distribute_nodes rollup_client_nodes dac_client_nodes
      in
      let* () =
        Lwt_list.iter_p
          (fun rollup ->
            let* () =
              deploy
                ~runner:rollup.client.runner
                ~r:true
                (Local.messages rollup.rollup_id)
                (Remote.messages rollup.client.home rollup.rollup_id)
            in
            deploy ~runner:rollup.client.runner Local.tx_kernel Remote.tx_kernel)
          scenario_nodes
      in
      Log.info "----------------------" ;
      Log.info " Setting up DAC nodes " ;
      Log.info "----------------------" ;
      let* nodes_with_dac =
        Lwt_list.map_p (fun rollup -> setup_dac rollup) scenario_nodes
      in

      (* setup L2 nodes *)

      (* Deploy contract *)
      let client = List.hd scenario_nodes |> fun r -> r.client.client in
      let* mint_and_deposit_contract =
        Client.originate_contract
          ~wait:"1"
          ~alias:"mint_and_deposit"
          ~amount:Tez.zero
          ~src:"demo_0"
          ~init:"Unit"
          ~burn_cap:Tez.(of_int 1)
          client
          ~prg:(read_file Local.minter)
      in
      Log.info "----------------------" ;
      Log.info "  Balancing accounts  " ;
      Log.info "----------------------" ;
      let* () = Lwt_list.iter_p balance_accounts scenario_nodes in
      Log.info "----------------------" ;
      Log.info "       Dac ready      " ;
      Log.info "----------------------" ;
      let* nodes =
        nodes_with_dac
        |> Lwt_list.map_p @@ setup_rollup ~mint_and_deposit_contract
      in
      Log.info "----------------------" ;
      Log.info "   Start transfers?   " ;
      Log.info "Rollup nodes are ready" ;
      Log.info "----------------------" ;
      (* let* () = get_continue_conf () in *)
      (* Submit dac messages *)
      let+ () = Lwt_list.iter_p submit_dac_messages nodes in
      let node, _, _, _, _ = List.hd nodes in
      node.client.node)
    else
      let _, node, _, _, _, _ = List.hd rollup_client_nodes in
      return node
  in
  (* waiting enough time for several commitments to be posted *)
  let current_level = Node.get_level node in
  let target_level = current_level + 30000 in
  Log.info
    "Setup completed at level %d, waited for level %d now"
    current_level
    target_level ;
  Log.info "----------------------" ;
  Log.info "       Spinning       " ;
  Log.info "----------------------" ;
  let* _ = Node.wait_for_level node target_level in
  (* exit *)
  Lwt.return ()

let () =
  Tezt.Test.register
    ~__FILE__
    ~title:"1MTPS demo orchestrator"
    ~tags:["demo"]
    main ;
  Tezt.Test.run ()
