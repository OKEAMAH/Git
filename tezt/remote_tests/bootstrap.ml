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

(* General description -------------------

   This module aims to define a basic scenario that could be run on a
   large number of machines. Those machines could be run via AWS. This
   scenario is quite simple and aims to be an example to define more
   complex scenarios using AWS.

   For testing this scenario, we can also run it on localhost using a
   smaller number of machines.

   The scenario is built around a master/slave architecture:

   - We run locally a master that will spawn "n" machines (on
   localhost, this is done via ssh)

   - The master connects to the "n" machines via ssh.

   - For this scenario, the master calls the Tezt slave scenario of
   those machines.

   - The slave scenario is quite simple: It connects to the other
   slaves, activates protocol Alpha, bakes some blocks and then
   stops. The keys are spread among the different machines. *)

(* If remote machines are on AWS, a token is expected. *)
type token = Localhost | AWS of string

type version =
  | Default (* The master branch. *)
  | Docker_image of string (* A specific docker image. *)
  | Git_branch of string (* A specific Git branch. *)

let read_token () =
  Cli.get ~default:Localhost (fun token -> Some (AWS token)) "aws-token"

let read_version n =
  let git_version_name = Printf.sprintf "node-%d-git" n in
  let docker_image_name = Printf.sprintf "node-%d-docker" n in
  (* Check first whether a git version for this node was specified,
       and second, whether adocker image  was specified. *)
  Cli.get
    ~default:
      (Cli.get
         ~default:Default
         (fun version -> Some (Docker_image version))
         docker_image_name)
    (fun version -> Some (Git_branch version))
    git_version_name

let runner_localhost = Runner.create ~address:"localhost" ()

let path_localhost = "~/Git/tezos/"

let check_localhost_version version =
  match version with
  | Default -> ()
  | Docker_image _ | Git_branch _ ->
      failwith "TODO: the version parameter is currently not supported locally."

let runner_of_json json =
  let open JSON in
  let address = json |-> "address" |> as_string in
  let ssh_id = json |-> "ssh_id" |> as_string_opt in
  let ssh_port = json |-> "ssh_port" |> as_int_opt in
  let ssh_user = json |-> "ssh_user" |> as_string_opt in
  let ssh_alias = json |-> "ssh_alias" |> as_string_opt in
  Runner.create ?ssh_alias ?ssh_user ?ssh_port ?ssh_id ~address ()

let path_of_json json = JSON.(json |-> "tezos-path" |> as_string)

(* This function aims to be called in parallel. *)
let spawn_aws_machine ~token ~version =
  let spawn_script = failwith "DevOps this is your job" in
  let version_arguments =
    match version with
    | Default -> []
    | Docker_image version -> ["--docker-image"; version]
    | Git_branch version -> ["--git-branch"; version]
  in
  let arguments = "--token" :: token :: version_arguments in
  let* output = Process.run_and_read_stdout spawn_script arguments in
  let json = JSON.parse ~origin:spawn_script output in
  let runner = runner_of_json json in
  let path = path_of_json json in
  return (runner, path)

let spawn n =
  let token = read_token () in
  let version = read_version n in
  match token with
  | Localhost ->
      check_localhost_version version ;
      let runner = runner_localhost in
      let path = path_localhost in
      return (n, runner, path)
  | AWS token ->
      let* runner, path = spawn_aws_machine ~token ~version in
      return (n, runner, path)

(* Number of machines to be run. *)
let read_n () = Cli.get_int "n"

(* FIXME: Need to think a bit more deeply about the logging.

   This is redundant with the "-v" mode of Tezt. and the timestamp is
   printed twice. *)
let rec echo_input_channel name input_channel =
  let* line = Lwt_io.read_line_opt input_channel in
  match line with
  | None -> return ()
  | Some line ->
      Log.info " (%s): %s" name line ;
      echo_input_channel name input_channel

(* The master node does the following steps:

   - spawns "n" machines (n being given by the user)

   - Calls the Tezt slave scenario on those "n" machines

   - Gather the Tezt output and print int in Info mode

   - Wait for all the slaves to finish
*)
let run_master_node () =
  Test.register ~__FILE__ ~title:"master" ~tags:["runner"; "main"] @@ fun () ->
  let number_of_machines = read_n () in
  (* FIXME:

     To speed up the test, we should be able to run this call in
     parallel. But if the number of machines is larger enough, Linux
     may start to kill processes one by one. So probably we should
     have a wrapper of `map_p` that allows to spawn at most a fixed
     number of processes. *)
  let* runners =
    Lwt_list.map_s (fun id -> spawn id) (range 1 number_of_machines)
  in
  (* We activate the protocol in the present. *)
  let timestamp_shift = 0. in
  (* FIXME: This should be exported by Tezt. *)
  let base_port = 16384 in
  (* FIXME: 10 is a bit arbitrary, it is an upper bound of the number
     of ports required by each slave. *)
  let port_of_id id = base_port + (id * 10) in
  let peers =
    List.map
      (fun (id, runner, _path) ->
        let port = port_of_id id in
        (* FIXME: we assume that the first time [Port.fresh ()] is
           called is to run the node. We should find a more robust
           way. *)
        (id, (Runner.address (Some runner), port)))
      runners
  in
  let peers_string_from_id id =
    List.filter_map
      (fun (id', peer) ->
        if id = id' then None
        else Some (Printf.sprintf "%s:%d" (fst peer) (snd peer)))
      peers
    |> String.concat ";"
  in
  let processes =
    List.map
      (fun (id, runner, path) ->
        (* FIXME: Can we find a better way to do that? *)
        let name = Format.asprintf "tezt-%d" id in
        let tezt_path = "tezt/remote_tests/main.exe" in
        let dune_path = "dune" in
        let command = "bash" in
        (* FIXME:

           All the nodes must use an explicit timestamp so that
           activating a protocol can be run on all the runners and
           producing the same block. One could try to find a better
           and more robust way to activate the protocol. *)
        let subcommand =
          Printf.sprintf
            "cd %s && eval $(opam env) && %s exec %s -- --file bootstrap.ml \
             slave -i --starting-port %d -a timestamp_shift=%f -a self=%d -a \
             n=%d -a peers='%s'"
            path
            dune_path
            tezt_path
            (port_of_id id)
            timestamp_shift
            id
            number_of_machines
            (peers_string_from_id id)
        in
        let arguments = ["-c"; subcommand] in
        Process.spawn ~runner ~name command arguments)
      runners
  in
  List.iter
    (fun process ->
      let name = Process.name process in
      let stdout = Process.stdout process in
      let stderr = Process.stderr process in
      Background.register (echo_input_channel name stdout) ;
      Background.register (echo_input_channel name stderr))
    processes ;
  (* FIXME: If the slave process fails, the remote note is not killed
     properly. *)
  let wait_processes =
    List.map (fun process -> Process.check process) processes
  in
  Lwt.join wait_processes

(* The slave does the following steps:

   - Initialize a node and a client

   - Initialize a wallet common to all the slaves

   - The slave 1 bakes the activation block

   - Only extract its relevant part of the wallet (a key is used by at
   most one slave)

   - Initialize a baker

   - Wait the node to be at level 10
*)
let run_slave_node =
  Protocol.register_test ~__FILE__ ~title:"slave" ~tags:["runner"; "slave"]
  @@ fun protocol ->
  let timestamp =
    Cli.get
      ~default:Client.default_timestamp
      (fun timestamp ->
        Some Client.(Ago (Time.Span.of_seconds_exn (float_of_string timestamp))))
      "timestamp_shift"
  in
  let peers =
    Cli.get (fun str -> Some (String.split_on_char ';' str)) "peers"
  in
  let nodes_args =
    let open Node in
    let peers = List.map (fun peer -> Peer peer) peers in
    Synchronisation_threshold 0 :: Connections (List.length peers) :: peers
  in
  let self_id = Cli.get (fun id -> Some (int_of_string id)) "self" in
  let bootstrap_accounts = 10 in
  let additional_bootstrap_account_count =
    bootstrap_accounts - Array.length Account.Bootstrap.keys
  in
  (* FIXME

     It is important that the generation of bootstrap accounts is
      deterministic, this is guaranteed by Tezt (well actually the
      stresstest command behind it. *)
  let* node, client =
    if self_id = 1 then
      Client.init_with_protocol
        ~additional_bootstrap_account_count
        ~timestamp
        ~protocol
        ~nodes_args
        `Client
        ()
    else
      let* node = Node.init nodes_args in
      let* client = Client.init ~endpoint:(Node node) () in
      let* _ =
        Client.stresstest_gen_keys additional_bootstrap_account_count client
      in
      return (node, client)
  in
  let number_of_machines = Cli.get (fun n -> Some (int_of_string n)) "n" in
  (* FIXME

     The code below is here to split the wallet between the different
     machines. There must be smarter way to split a wallet between
     several machines? *)
  let accounts_id = List.init bootstrap_accounts (fun i -> i + 1) in
  let in_wallet id =
    let wallet_size = bootstrap_accounts / number_of_machines in
    let lowest_id = 1 + (wallet_size * (self_id - 1)) in
    let lowest_next_id = 1 + (wallet_size * (self_id - 1)) + wallet_size in
    lowest_id <= id && id < lowest_next_id
  in
  let aliases_to_remove =
    List.filter (fun id -> not (in_wallet id)) accounts_id
    |> List.map (fun id -> Printf.sprintf "bootstrap%d" id)
  in
  let* () =
    Lwt_list.iter_s
      (fun alias -> Client.forget_address ~force:true ~alias client)
      aliases_to_remove
  in
  Node.on_event node (fun {name; value} ->
      match name with
      | "head_increment.v0" | "branch_switch.v0" -> (
          match JSON.(value |-> "level" |> as_int_opt) with
          | None -> assert false
          | Some level -> Log.info "Updated to %d" level)
      | _ -> ()) ;
  let* _baker = Baker.init ~protocol node client in
  let* _ = Node.wait_for_level node 10 in
  (* FIXME:

     Do not kill the node right away to let some time for
     propagation of messages. Maybe there is a better way to handle
     the end of the scenario? *)
  let* () = Lwt_unix.sleep 1. in
  return ()

let register ~protocols =
  run_master_node () ;
  run_slave_node protocols
