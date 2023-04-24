open Tezt
open Tezt_tezos
open Tezt.Base

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
      tezos/tezos:master_9b10efc7_20230422025549 \
      -c "$(cat $STARTUP)"

    Login with:
    ssh tezos@localhost -p 30000 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

       *)

(**
    Notes on GUIX:
    ln -s /home/emma/.guix-home/profile/bin/ssh /no-such-path/ssh

    Notes on NIX:
    unset TMPDIR

    Notes:
    If an error like 'mkdir exited with code 255 (@@@@@@@ occurs, clean up the ~/.ssh/known_hosts file
        *)

let protocol = Protocol.Alpha

(* TODO: Should be a command-line argument *)
let ssh_user = "tezos"

(* TODO: Should be a command-line argument *)
let ssh_id = "/home/emma/.ssh/tutanota"

(* TODO: Should be a command-line argument *)
let ssh_address = "127.0.0.1"

let ssh_port = 30000

(* TODO: Should be a command-line argument *)
let network = "https://teztnets.xyz/mondaynet-2023-04-24"

(* TODO: Should be a command-line argument *)
let snapshot_url =
  "http://mondaynet.snapshots.s3-website.eu-central-1.amazonaws.com/mondaynet-rolling-snapshot"

let mint_and_deposit_contract = "KT1BN1N4Xoris8NPqpq62jjpkEATt8uXQVAP"

(* TODO: Should be a command-line argument *)
let runners =
  let l1_nodes_count = 1 in
  List.init l1_nodes_count (fun _ ->
      Runner.create ~ssh_user ~ssh_id ~ssh_port ~address:ssh_address ())

let rec port_forward ~port ~address ~(runner : Runner.t) =
  let args =
    [
      "ssh";
      "-L";
      Format.sprintf "%d:%s:%d" port address port;
      Format.sprintf "%s@%s" (Option.get runner.ssh_user) runner.address;
      "-p";
      Format.sprintf "%d" (Option.get runner.ssh_port);
      "-f";
      "-N";
      "-i";
      ssh_id;
    ]
  in
  let ssh_env =
    match (Sys.getenv_opt "SSH_AGENT_PID", Sys.getenv_opt "SSH_AUTH_SOCK") with
    | Some agent, Some sock ->
        [|"SSH_AGENT_PID=" ^ agent; "SSH_AUTH_SOCK=" ^ sock|]
    | _ ->
        (* Here, we assume we don't have an agent running. *)
        [||]
  in
  let process = Unix.open_process_full (String.concat " " args) ssh_env in
  let get_stderr (_, _, stderr) =
    try input_line stderr with End_of_file -> ""
  in
  let get_stdout (stdout, _, _) =
    try input_line stdout with End_of_file -> ""
  in
  let stderr = get_stderr process in
  let stdout = get_stdout process in
  let status = Unix.close_process_full process in
  Log.info
    "Port forward \n| %s |\nstdout: %s | \nstderr: %s"
    (String.concat " " args)
    stdout
    stderr ;
  match status with
  | Unix.WEXITED 0 -> ()
  | _ ->
      Log.error "Failed to port forward: %s" @@ String.concat " " args ;
      Unix.sleep 5 ;
      port_forward ~port ~runner ~address

(* TODO: Should be a command-line argument *)
let rollups_per_node = 1

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

  let wallet = "/home/emma/sources/mondaynet/docker-mount/tezos-client"

  let installer_kernel =
    project_root // Filename.dirname __FILE__ // "artifacts/installer.wasm"

  let tx_kernel =
    project_root // Filename.dirname __FILE__ // "artifacts/tx-kernel.wasm"
end

module Remote = struct
  let snapshot home = Format.sprintf "%s/snapshot" home

  let octez_node = "/usr/local/bin/octez-node"

  let octez_dac_node = "/usr/local/bin/octez-dac-node"

  let octez_client = "/usr/local/bin/octez-client"

  let smart_rollup_node =
    Format.sprintf
      "/usr/local/bin/octez-smart-rollup-node-%s"
      (Protocol.tag protocol)

  let wallet home = Format.sprintf "%s/.tezos-client" home
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
  Runnable.
    {
      value = process;
      run =
        (fun process ->
          let _ = Process.check process in
          Lwt.return ());
    }

let deploy ~runner ?r local_file dst =
  let open Runnable.Syntax in
  let*! () = deploy_runnable ~runner ?r local_file dst in
  Lwt.return ()

let download_snapshot ?runner home = function
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

let install_nodes i runner =
  let open Lwt.Syntax in
  let home = Temp.dir ~runner Format.(sprintf "%d" i) in
  Log.info "Downloading snapshot" ;
  let* () = download_snapshot ~runner home @@ `Url snapshot_url in
  Log.info "Deploying wallet %s" home ;
  let* () = deploy ~runner ~r:true Local.wallet (Remote.wallet home) in
  (* let* () = deploy ~runner snapshot_path (Remote.snapshot home) in *)
  (* let* () = deploy ~runner Local.octez_node (Remote.octez_node home) in *)
  (* let* () = *)
  (*   deploy ~runner Local.smart_rollup_node (Remote.smart_rollup_node home) *)
  (* in *)
  Lwt.return (home, runner)

(** [bootstrap_node snapshot_path ()] *)
let bootstrap_node (home, runner) =
  let open Lwt.Syntax in
  let l1_node_args =
    Node.[Expected_pow 26; Synchronisation_threshold 1; Network network]
  in
  let node = Node.create ~path:Remote.octez_node ~runner l1_node_args in

  let* () = Node.config_init node [] in
  let* () = Node.snapshot_import node (Remote.snapshot home) in

  Log.info "Snapshot imported for %s" (Node.name node) ;

  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in

  let client =
    Client.create
      ~runner
      ~path:Remote.octez_client
      ~base_dir:(Remote.wallet home)
      ~endpoint:(Node node)
      ()
  in
  let* () = Client.bootstrapped client in

  Log.info "%s ready" (Node.name node) ;

  Lwt.return (home, node, client)

let deposit_ticket ~rollup_node ~client ~content ~rollup ~no_pixel_addr
    ~rollup_id =
  let open Lwt.Syntax in
  Log.info "Depositing %s to %s" content rollup ;
  let* () =
    (* Internal message through forwarder *)
    let arg =
      sf {|Pair (Pair %S "%s") (Pair 450 "%s")|} rollup no_pixel_addr content
    in
    Client.transfer
      client
      ~wait:"1"
      ~amount:Tez.zero
      ~giver:(Format.sprintf "demo_%d" rollup_id)
      ~receiver:mint_and_deposit_contract
      ~arg
      ~burn_cap:(Tez.of_int 1000)
  in
  let* level = Client.level client in
  let+ _ = Sc_rollup_node.wait_for_level ~timeout:30. rollup_node level in
  ()

let setup_installer ~dac_node ~pk_0 ~pk_1 =
  let installer = read_file Local.installer_kernel in
  let tx_kernel = read_file Local.tx_kernel in
  let installer_dummy_hash =
    "1acaa995ef84bc24cc8bb545dd986082fbbec071ed1c3e9954abea5edc441ccd3a"
  in
  let dac_member_0_dummy =
    "555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555"
  in
  let (`Hex dac_member_0) =
    Tezos_crypto.Signature.Bls.Public_key.(
      pk_0 |> of_b58check_exn
      |> Data_encoding.Binary.to_bytes_exn encoding
      |> Hex.of_bytes)
  in
  Log.info "Dac member 0: %s" dac_member_0 ;
  assert (String.length dac_member_0_dummy = String.length dac_member_0) ;
  let dac_member_1_dummy =
    "666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666"
  in
  let (`Hex dac_member_1) =
    Tezos_crypto.Signature.Bls.Public_key.(
      pk_1 |> of_b58check_exn
      |> Data_encoding.Binary.to_bytes_exn encoding
      |> Hex.of_bytes)
  in
  Log.info "Dac member 1: %s" dac_member_1 ;
  assert (String.length dac_member_1_dummy = String.length dac_member_1) ;
  let* root_hash =
    RPC.call dac_node (Dac_rpc.Coordinator.post_preimage ~payload:tx_kernel)
  in
  (* Ensure reveal hash is correct length for installer. *)
  assert (String.length root_hash = 66) ;
  let installer =
    installer
    |> replace_string (rex installer_dummy_hash) ~by:root_hash
    |> replace_string (rex dac_member_0_dummy) ~by:dac_member_0
    |> replace_string (rex dac_member_1_dummy) ~by:dac_member_1
  in
  let (`Hex hex) = Hex.of_string installer in
  return hex

(* Run a committee member *)
let setup_dac_member ~coordinator ~rollup_id ~member_idx ~member client node =
  let open Lwt.Syntax in
  let Account.{aggregate_public_key_hash; _} = member in
  let dac_node =
    Dac_node.create_committee_member
      ~path:Remote.octez_dac_node
      ~name:(Format.sprintf "dac-member-%d-%d" rollup_id member_idx)
      ~node
      ~coordinator_rpc_host:(Dac_node.rpc_host coordinator)
      ~coordinator_rpc_port:(Dac_node.rpc_port coordinator)
      ~address:aggregate_public_key_hash
      ~client
      ()
  in
  let* _dir = Dac_node.init_config dac_node in
  let+ () = Dac_node.run dac_node ~wait_ready:true in
  dac_node

(* Run a dac observer *)
let setup_dac_observer ~coordinator ~rollup_id ~reveal_data_dir client node =
  let open Lwt.Syntax in
  let dac_node =
    Dac_node.create_observer
      ~path:Remote.octez_dac_node
      ~name:(Format.sprintf "dac-observer-%d" rollup_id)
      ~node
      ~coordinator_rpc_host:(Dac_node.rpc_host coordinator)
      ~coordinator_rpc_port:(Dac_node.rpc_port coordinator)
      ~client
      ~reveal_data_dir
      ()
  in
  let* _dir = Dac_node.init_config dac_node in
  let+ () = Dac_node.run dac_node ~wait_ready:true in
  dac_node

(* Initialise DAC committee via *)
let setup_dac home ~rollup_id node client =
  let open Lwt.Syntax in
  let runner = Node.runner node in
  let rollup_data_dir = home // Printf.sprintf "rollup-%d" rollup_id in
  let () = Runner.Sys.mkdir ?runner rollup_data_dir in
  let* committee_members =
    List.fold_left
      (fun keys i ->
        let* keys in
        let* key =
          Client.bls_gen_and_show_keys
            ~alias:(Format.sprintf "committee-member-%d" i)
            client
        in
        return (key :: keys))
      (return [])
      [0; 1]
  in
  let dac_node =
    Dac_node.create_coordinator
      ~name:(Format.sprintf "dac-coord-%d" rollup_id)
      ~path:Remote.octez_dac_node
      ~node
      ~client
      ~threshold:2
      ~committee_members:
        (List.map
           (fun (dc : Account.aggregate_key) -> dc.aggregate_public_key_hash)
           committee_members)
      ()
  in
  let* _dir = Dac_node.init_config dac_node in
  let* () = Dac_node.run dac_node in
  (* Bind local port *)
  Log.info
    "Port forwarding DAC node %d from %s:%d"
    rollup_id
    (Option.get runner).address
    (Dac_node.rpc_port dac_node) ;
  let () =
    port_forward
      ~runner:(Option.get runner)
      ~address:(Dac_node.rpc_host dac_node)
      ~port:(Dac_node.rpc_port dac_node)
  in
  let* members =
    Lwt_list.mapi_p
      (fun member_idx member ->
        setup_dac_member
          ~coordinator:dac_node
          ~rollup_id
          ~member_idx
          ~member
          client
          node)
      committee_members
  in
  let* observer =
    setup_dac_observer
      ~coordinator:dac_node
      ~rollup_id
      ~reveal_data_dir:(rollup_data_dir // "wasm_2_0_0")
      client
      node
  in
  let committee_members =
    match committee_members with
    | [mem_0; mem_1] -> (mem_0, mem_1)
    | _ -> failwith "expected two dac members"
  in
  return (rollup_data_dir, dac_node, members, observer, committee_members)

let setup_rollup home rollup_id node client =
  let open Lwt.Syntax in
  let runner = Option.get (Node.runner node) in
  let funded_account = Format.asprintf "demo_%d" rollup_id in
  let* ( data_dir,
         dac_node,
         _dac_members,
         _dac_observer,
         (dac_member_0, dac_member_1) ) =
    setup_dac home ~rollup_id node client
  in
  let* installer =
    setup_installer
      ~dac_node
      ~pk_0:dac_member_0.aggregate_public_key
      ~pk_1:dac_member_1.aggregate_public_key
  in
  let* rollup =
    Client.Sc_rollup.originate
      client
      ~wait:"0"
      ~src:funded_account
      ~kind:"wasm_2_0_0"
      ~parameters_ty:"(pair string (ticket string))"
      ~boot_sector:installer
      ~burn_cap:(Tez.of_int 2)
  in

  Log.info "Rollup %s originated from %s" rollup (Node.name node) ;

  let rollup_node =
    Sc_rollup_node.create
      ~path:Remote.smart_rollup_node
      ~runner
      ~base_dir:(Remote.wallet home)
      ~default_operator:funded_account
      ~data_dir
      ~protocol
      Operator
      node
  in

  let* _ = Sc_rollup_node.config_init rollup_node rollup in
  Log.info "Starting %s to track %s" (Sc_rollup_node.name rollup_node) rollup ;
  let* () =
    Sc_rollup_node.run
      rollup_node
      rollup
      [
        "--log-kernel-debug";
        "--log-kernel-debug-file";
        Format.sprintf "/home/tezos/logs/kernel-%d.log" rollup_id;
      ]
  in
  (* TODO: keys file *)
  let no_pixel_addr = "tz1emVNqFCsNRPkVWR5nAK9FmxbU3cXMdQGx" in
  let* () =
    deposit_ticket
      ~rollup_node
      ~client
      ~content:"R"
      ~rollup
      ~no_pixel_addr
      ~rollup_id
  in
  let* () =
    deposit_ticket
      ~rollup_node
      ~client
      ~content:"G"
      ~rollup
      ~no_pixel_addr
      ~rollup_id
  in
  let* () =
    deposit_ticket
      ~rollup_node
      ~client
      ~content:"B"
      ~rollup
      ~no_pixel_addr
      ~rollup_id
  in
  Lwt.return (node, client, rollup, rollup_node)

let setup_rollups rollups_per_node i (home, node, client) =
  Lwt_list.map_s
    (fun x -> setup_rollup home ((i * rollups_per_node) + x) node client)
    (List.init rollups_per_node Fun.id)

let rec get_continue_conf () =
  Log.info "Continue? (yes)" ;
  let line = read_line () in
  if line = "yes" then ()
  else (
    Log.warn "'yes' required" ;
    get_continue_conf ())

let main () =
  let open Lwt.Syntax in
  (* install nodes on runners *)
  Log.info "Deploying nodes" ;
  let* runners = Lwt_list.mapi_p install_nodes runners in
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
  Log.info "Start transfers?" ;
  get_continue_conf () ;
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

let () =
  Tezt.Test.register
    ~__FILE__
    ~title:"1MTPS demo orchestrator"
    ~tags:["demo"]
    main ;
  Tezt.Test.run ()
