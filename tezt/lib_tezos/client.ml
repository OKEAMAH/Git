(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Runnable.Syntax
include Client_base

type stresstest_gas_estimation = {
  regular : int;
  smart_contracts : (string * int) list;
}

type stresstest_contract_parameters = {
  probability : float;
  invocation_fee : Tez.t;
  invocation_gas_limit : int;
}

let optional_switch ~name = function false -> [] | true -> ["--" ^ name]

let optional_arg ~name f = function None -> [] | Some x -> ["--" ^ name; f x]

let wait_monitor_operation ?endpoint operation_hash_promise (client : t) =
  let promise, resolver = Lwt.task () in
  let* () =
    RPC.Monitor.operations
      ?endpoint
      ~applied:true
      ~refused:true
      ~branch_delayed:true
      ~outdated:true
      ~branch_refused:true
      client
    @@ fun json ->
    let mempool = JSON.as_list json in
    let* expected_operation_hash = operation_hash_promise in
    match
      List.find_opt
        (fun op ->
          let operation_hash = JSON.(op |-> "hash" |> as_string) in
          operation_hash = expected_operation_hash)
        mempool
    with
    | None -> return `Continue
    | Some op ->
        let error = JSON.(op |-> "error") in
        if not (JSON.is_null error) then (
          Lwt.cancel promise ;
          Test.fail
            "Operation %s is in mempool with error: %s"
            expected_operation_hash
            (JSON.encode error))
        else (
          Lwt.wakeup_later resolver op ;
          return `Stop)
  in
  promise

let with_monitor_injection ?(timeout = 10) ?endpoint (client : t) spawn_inject =
  let oph_promise, oph_resolver = Lwt.task () in
  let monitor =
    let* _ = wait_monitor_operation ?endpoint oph_promise client in
    return `Found_operation
  in
  let process = spawn_inject ?endpoint client in
  let* client_output = Process.check_and_read_stdout process in
  match client_output =~* rex "Operation hash is '(.*)'" with
  | None ->
      Test.fail
        "Cannot extract operation hash from client_output: %s"
        client_output
  | Some oph -> (
      Lwt.wakeup_later oph_resolver oph ;
      let timeout_promise =
        let* () = Lwt_unix.sleep (float_of_int timeout) in
        return `Timeout
      in
      let* result = Lwt.pick [monitor; timeout_promise] in
      match result with
      | `Timeout ->
          Test.fail
            "Operation %s was not seen in mempool after %d seconds"
            oph
            timeout
      | `Found_operation -> return (process, client_output))

let check_injection ?(monitor_mempool = true) ?(expect_failure = false) ?timeout
    ?endpoint (client : t) spawn_inject =
  if expect_failure || not monitor_mempool then
    spawn_inject ?endpoint client |> Process.check ~expect_failure
  else
    let* _ = with_monitor_injection ?timeout ?endpoint client spawn_inject in
    unit

let check_injection_output ?(monitor_mempool = true) ?(expect_failure = false)
    ?timeout ?endpoint (client : t) spawn_inject =
  if expect_failure || not monitor_mempool then
    spawn_inject ?endpoint client
    |> Process.check_and_read_stdout ~expect_failure
  else
    let* _, output =
      with_monitor_injection ?timeout ?endpoint client spawn_inject
    in
    return output

let check_injection_process ?(monitor_mempool = true) ?timeout ?endpoint
    (client : t) spawn_inject =
  if not monitor_mempool then return (spawn_inject ?endpoint client)
  else
    let* process, _ =
      with_monitor_injection ?timeout ?endpoint client spawn_inject
    in
    return process

let spawn_shell_header ?endpoint ?(chain = "main") ?(block = "head") client =
  let path = ["chains"; chain; "blocks"; block; "header"; "shell"] in
  spawn_rpc ?endpoint GET path client

let shell_header ?endpoint ?chain ?block client =
  spawn_shell_header ?endpoint ?chain ?block client
  |> Process.check_and_read_stdout

let level ?endpoint ?chain ?block client =
  let* shell = shell_header ?endpoint ?chain ?block client in
  let json = JSON.parse ~origin:"level" shell in
  JSON.get "level" json |> JSON.as_int |> return

let parse_list_protocols_output output =
  String.split_on_char '\n' output |> List.filter (fun s -> s <> "")

module Admin = struct
  let spawn_command = spawn_command ~admin:true

  let spawn_trust_address ?endpoint ~peer client =
    spawn_command
      ?endpoint
      client
      [
        "trust";
        "address";
        Printf.sprintf
          "%s:%d"
          (address ?from:endpoint (Node peer))
          (Node.net_port peer);
      ]

  let trust_address ?endpoint ~peer client =
    spawn_trust_address ?endpoint ~peer client |> Process.check

  let spawn_connect_address ?endpoint ~peer client =
    spawn_command
      ?endpoint
      client
      [
        "connect";
        "address";
        Printf.sprintf
          "%s:%d"
          (address ?from:endpoint (Node peer))
          (Node.net_port peer);
      ]

  let connect_address ?endpoint ~peer client =
    spawn_connect_address ?endpoint ~peer client |> Process.check

  let spawn_kick_peer ?endpoint ~peer client =
    spawn_command ?endpoint client ["kick"; "peer"; peer]

  let kick_peer ?endpoint ~peer client =
    spawn_kick_peer ?endpoint ~peer client |> Process.check

  let spawn_inject_protocol ?endpoint ~protocol_path client =
    spawn_command ?endpoint client ["inject"; "protocol"; protocol_path]

  let inject_protocol ?endpoint ~protocol_path client =
    let process = spawn_inject_protocol ?endpoint ~protocol_path client in
    let* () = Process.check process
    and* output = Lwt_io.read (Process.stdout process) in
    match output =~* rex "Injected protocol ([^ ]+) successfully" with
    | None ->
        Test.fail
          "tezos-admin-client inject protocol did not answer \"Injected \
           protocol ... successfully\""
    | Some hash -> return hash

  let spawn_list_protocols ?endpoint client =
    spawn_command ?endpoint client ["list"; "protocols"]

  let list_protocols ?endpoint client =
    let process = spawn_list_protocols ?endpoint client in
    let* () = Process.check process
    and* output = Lwt_io.read (Process.stdout process) in
    return (parse_list_protocols_output output)
end

let spawn_version client = spawn_command client ["--version"]

let version client = spawn_version client |> Process.check

let spawn_import_secret_key ?endpoint client (key : Account.key) =
  let sk_uri =
    let (Unencrypted sk) = key.secret_key in
    "unencrypted:" ^ sk
  in
  spawn_command ?endpoint client ["import"; "secret"; "key"; key.alias; sk_uri]

let spawn_import_signer_key ?endpoint ?(force = false) client
    (key : Account.key) signer_uri =
  let uri = Uri.with_path signer_uri key.public_key_hash in
  spawn_command
    ?endpoint
    client
    (["import"; "secret"; "key"; key.alias; Uri.to_string uri]
    @ if force then ["--force"] else [])

let import_signer_key ?endpoint ?force client key signer_uri =
  spawn_import_signer_key ?endpoint ?force client key signer_uri
  |> Process.check

let import_secret_key ?endpoint client key =
  spawn_import_secret_key ?endpoint client key |> Process.check

module Time = Tezos_base.Time.System

let default_delay = Time.Span.of_seconds_exn (3600. *. 24. *. 365.)

type timestamp = Now | Ago of Time.Span.t | At of Time.t

let time_of_timestamp timestamp =
  match timestamp with
  | Now -> Time.now ()
  | Ago delay -> (
      match Ptime.sub_span (Time.now ()) delay with
      | None -> Ptime.epoch
      | Some tm -> tm)
  | At tm -> tm

let spawn_activate_protocol ?endpoint ~protocol ?(fitness = 1)
    ?(key = Constant.activator.alias) ?(timestamp = Ago default_delay)
    ?parameter_file client =
  let timestamp = time_of_timestamp timestamp in
  spawn_command
    ?endpoint
    client
    [
      "activate";
      "protocol";
      Protocol.hash protocol;
      "with";
      "fitness";
      string_of_int fitness;
      "and";
      "key";
      key;
      "and";
      "parameters";
      Option.value parameter_file ~default:(Protocol.parameter_file protocol);
      "--timestamp";
      Time.to_notation timestamp;
    ]

let activate_protocol ?endpoint ~protocol ?fitness ?key ?timestamp
    ?parameter_file client =
  spawn_activate_protocol
    ?endpoint
    ~protocol
    ?fitness
    ?key
    ?timestamp
    ?parameter_file
    client
  |> Process.check

let empty_mempool_file ?(filename = "mempool.json") () =
  let mempool_str = "[]" in
  let mempool = Temp.file filename in
  write_file mempool ~contents:mempool_str ;
  mempool

let spawn_bake_for ?endpoint ?protocol ?(keys = [Constant.bootstrap1.alias])
    ?minimal_fees ?minimal_nanotez_per_gas_unit ?minimal_nanotez_per_byte
    ?(minimal_timestamp = true) ?mempool ?(ignore_node_mempool = false) ?force
    ?context_path client =
  spawn_command
    ?endpoint
    client
    (optional_arg ~name:"protocol" Protocol.hash protocol
    @ ["bake"; "for"] @ keys
    @ optional_arg ~name:"minimal-fees" string_of_int minimal_fees
    @ optional_arg
        ~name:"minimal-nanotez-per-gas-unit"
        string_of_int
        minimal_nanotez_per_gas_unit
    @ optional_arg
        ~name:"minimal-nanotez-per-byte"
        string_of_int
        minimal_nanotez_per_byte
    @ optional_arg ~name:"operations-pool" Fun.id mempool
    @ (if ignore_node_mempool then ["--ignore-node-mempool"] else [])
    @ (if minimal_timestamp then ["--minimal-timestamp"] else [])
    @ (match force with None | Some false -> [] | Some true -> ["--force"])
    @ optional_arg ~name:"context" Fun.id context_path)

let bake_for ?endpoint ?protocol ?keys ?minimal_fees
    ?minimal_nanotez_per_gas_unit ?minimal_nanotez_per_byte ?minimal_timestamp
    ?mempool ?ignore_node_mempool ?force ?context_path client =
  spawn_bake_for
    ?endpoint
    ?keys
    ?minimal_fees
    ?minimal_nanotez_per_gas_unit
    ?minimal_nanotez_per_byte
    ?minimal_timestamp
    ?mempool
    ?ignore_node_mempool
    ?force
    ?context_path
    ?protocol
    client
  |> Process.check

let node_of_endpoint = function Node n -> Some n | Proxy_server _ -> None

let node_of_client_mode = function
  | Client (Some endpoint, _) -> node_of_endpoint endpoint
  | Proxy endpoint -> node_of_endpoint endpoint
  | Light (_, endpoints) -> List.find_map node_of_endpoint endpoints
  | Client (None, _) -> None
  | Mockup -> None

let bake_for_and_wait ?endpoint ?protocol ?keys ?minimal_fees
    ?minimal_nanotez_per_gas_unit ?minimal_nanotez_per_byte ?minimal_timestamp
    ?mempool ?ignore_node_mempool ?force ?context_path ?node client =
  let node =
    match node with
    | Some n -> n
    | None -> (
        match node_of_client_mode (get_mode client) with
        | Some n -> n
        | None -> Test.fail "No node found for bake_for_and_wait")
  in
  let level_before = Node.get_level node in
  let* () =
    bake_for
      ?endpoint
      ?protocol
      ?keys
      ?minimal_fees
      ?minimal_nanotez_per_gas_unit
      ?minimal_nanotez_per_byte
      ?minimal_timestamp
      ?mempool
      ?ignore_node_mempool
      ?force
      ?context_path
      client
  in
  let* _lvl = Node.wait_for_level node (level_before + 1) in
  unit

(* Handle endorsing and preendorsing similarly *)
type tenderbake_action = Preendorse | Endorse | Propose

let tenderbake_action_to_string = function
  | Preendorse -> "preendorse"
  | Endorse -> "endorse"
  | Propose -> "propose"

let spawn_tenderbake_action_for ~tenderbake_action ?endpoint ?protocol
    ?(key = [Constant.bootstrap1.alias]) ?(minimal_timestamp = false)
    ?(force = false) client =
  spawn_command
    ?endpoint
    client
    (optional_arg ~name:"protocol" Protocol.hash protocol
    @ [tenderbake_action_to_string tenderbake_action; "for"]
    @ key
    @ (if minimal_timestamp then ["--minimal-timestamp"] else [])
    @ if force then ["--force"] else [])

let spawn_endorse_for ?endpoint ?protocol ?key ?force client =
  spawn_tenderbake_action_for
    ~tenderbake_action:Endorse
    ~minimal_timestamp:false
    ?endpoint
    ?protocol
    ?key
    ?force
    client

let spawn_preendorse_for ?endpoint ?protocol ?key ?force client =
  spawn_tenderbake_action_for
    ~tenderbake_action:Preendorse
    ~minimal_timestamp:false
    ?endpoint
    ?protocol
    ?key
    ?force
    client

let spawn_propose_for ?endpoint ?minimal_timestamp ?protocol ?key ?force client
    =
  spawn_tenderbake_action_for
    ~tenderbake_action:Propose
    ?minimal_timestamp
    ?endpoint
    ?protocol
    ?key
    ?force
    client

let endorse_for ?monitor_mempool ?endpoint ?protocol ?key ?force client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_endorse_for ?protocol ?key ?force

let preendorse_for ?monitor_mempool ?endpoint ?protocol ?key ?force client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_preendorse_for ?protocol ?key ?force

let propose_for ?monitor_mempool ?endpoint ?(minimal_timestamp = true) ?protocol
    ?key ?force client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_propose_for ?protocol ?key ?force ~minimal_timestamp

let id = ref 0

let spawn_gen_keys ?alias client =
  let alias =
    match alias with
    | None ->
        incr id ;
        sf "tezt_%d" !id
    | Some alias -> alias
  in
  (spawn_command client ["gen"; "keys"; alias], alias)

let gen_keys ?alias client =
  let p, alias = spawn_gen_keys ?alias client in
  let* () = Process.check p in
  return alias

let spawn_show_address ~alias client =
  spawn_command client ["show"; "address"; alias; "--show-secret"]

let show_address ~alias client =
  let* client_output =
    spawn_show_address ~alias client |> Process.check_and_read_stdout
  in
  return @@ Account.parse_client_output ~alias ~client_output

let gen_and_show_keys ?alias client =
  let* alias = gen_keys ?alias client in
  show_address ~alias client

let spawn_bls_gen_keys ?hooks ?(force = false) ?alias client =
  let alias =
    match alias with
    | None ->
        incr id ;
        sf "tezt_%d" !id
    | Some alias -> alias
  in
  ( spawn_command
      ?hooks
      client
      (["bls"; "gen"; "keys"; alias] @ optional_switch ~name:"force" force),
    alias )

let bls_gen_keys ?hooks ?force ?alias client =
  let p, alias = spawn_bls_gen_keys ?hooks ?force ?alias client in
  let* () = Process.check p in
  return alias

let spawn_bls_list_keys ?hooks client =
  spawn_command ?hooks client ["bls"; "list"; "keys"]

let parse_list_keys output =
  output |> String.trim |> String.split_on_char '\n'
  |> List.map (fun s ->
         match s =~** rex "^(\\w+): (\\w{36})" with
         | Some s -> s
         | None ->
             Test.fail
               ~__LOC__
               "Cannot extract `list keys` format from client_output: %s"
               output)

let bls_list_keys ?hooks client =
  let* out =
    spawn_bls_list_keys ?hooks client |> Process.check_and_read_stdout
  in
  return (parse_list_keys out)

let spawn_bls_show_address ?hooks ~alias client =
  spawn_command ?hooks client ["bls"; "show"; "address"; alias; "--show-secret"]

let bls_show_address ?hooks ~alias client =
  let* out =
    spawn_bls_show_address ?hooks ~alias client |> Process.check_and_read_stdout
  in
  return (Account.parse_client_output_aggregate ~alias ~client_output:out)

let bls_gen_and_show_keys ?alias client =
  let* alias = bls_gen_keys ?alias client in
  bls_show_address ~alias client

let spawn_bls_import_secret_key ?hooks ?(force = false)
    (key : Account.aggregate_key) client =
  let sk_uri =
    let (Unencrypted sk) = key.aggregate_secret_key in
    "aggregate_unencrypted:" ^ sk
  in
  spawn_command
    ?hooks
    client
    (["bls"; "import"; "secret"; "key"; key.aggregate_alias; sk_uri]
    @ if force then ["--force"] else [])

let bls_import_secret_key ?hooks ?force key sc_client =
  spawn_bls_import_secret_key ?hooks ?force key sc_client |> Process.check

let spawn_transfer ?hooks ?log_output ?endpoint ?(wait = "none") ?burn_cap ?fee
    ?gas_limit ?storage_limit ?counter ?arg ?(simulation = false)
    ?(force = false) ~amount ~giver ~receiver client =
  spawn_command
    ?log_output
    ?endpoint
    ?hooks
    client
    (["--wait"; wait]
    @ ["transfer"; Tez.to_string amount; "from"; giver; "to"; receiver]
    @ Option.fold
        ~none:[]
        ~some:(fun f -> ["--fee"; Tez.to_string f; "--force-low-fee"])
        fee
    @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
    @ optional_arg ~name:"gas-limit" string_of_int gas_limit
    @ optional_arg ~name:"storage-limit" string_of_int storage_limit
    @ optional_arg ~name:"counter" string_of_int counter
    @ optional_arg ~name:"arg" Fun.id arg
    @ (if simulation then ["--simulation"] else [])
    @ if force then ["--force"] else [])

let transfer ?monitor_mempool ?hooks ?log_output ?endpoint ?wait ?burn_cap ?fee
    ?gas_limit ?storage_limit ?counter ?arg ?simulation ?force ?expect_failure
    ~amount ~giver ~receiver client =
  check_injection ?monitor_mempool ?endpoint ?expect_failure client
  @@ spawn_transfer
       ?log_output
       ?hooks
       ?wait
       ?burn_cap
       ?fee
       ?gas_limit
       ?storage_limit
       ?counter
       ?arg
       ?simulation
       ?force
       ~amount
       ~giver
       ~receiver

let spawn_multiple_transfers ?log_output ?endpoint ?(wait = "none") ?burn_cap
    ?fee_cap ?gas_limit ?storage_limit ?counter ?arg ~giver ~json_batch client =
  spawn_command
    ?log_output
    ?endpoint
    client
    (["--wait"; wait]
    @ ["multiple"; "transfers"; "from"; giver; "using"; json_batch]
    @ Option.fold
        ~none:[]
        ~some:(fun f -> ["--fee-cap"; Tez.to_string f; "--force-low-fee"])
        fee_cap
    @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
    @ optional_arg ~name:"gas-limit" string_of_int gas_limit
    @ optional_arg ~name:"storage-limit" string_of_int storage_limit
    @ optional_arg ~name:"counter" string_of_int counter
    @ optional_arg ~name:"arg" Fun.id arg)

let multiple_transfers ?monitor_mempool ?log_output ?endpoint ?wait ?burn_cap
    ?fee_cap ?gas_limit ?storage_limit ?counter ?arg ~giver ~json_batch client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_multiple_transfers
       ?log_output
       ?wait
       ?burn_cap
       ?fee_cap
       ?gas_limit
       ?storage_limit
       ?counter
       ?arg
       ~giver
       ~json_batch

let spawn_get_delegate ?endpoint ~src client =
  spawn_command ?endpoint client ["get"; "delegate"; "for"; src]

let get_delegate ?endpoint ~src client =
  let* output =
    spawn_get_delegate ?endpoint ~src client |> Process.check_and_read_stdout
  in
  Lwt.return (output =~* rex "(tz[a-zA-Z0-9]+) \\(.*\\)")

let set_delegate ?endpoint ?(wait = "none") ?fee ?fee_cap
    ?(force_low_fee = false) ~src ~delegate client =
  let value =
    spawn_command
      ?endpoint
      client
      (["--wait"; wait]
      @ ["set"; "delegate"; "for"; src; "to"; delegate]
      @ optional_arg ~name:"fee" Tez.to_string fee
      @ optional_arg ~name:"fee-cap" Tez.to_string fee_cap
      @ if force_low_fee then ["--force-low-fee"] else [])
  in
  {value; run = Process.check}

let reveal ?endpoint ?(wait = "none") ?fee ?fee_cap ?(force_low_fee = false)
    ~src client =
  let value =
    spawn_command
      ?endpoint
      client
      (["--wait"; wait]
      @ ["reveal"; "key"; "for"; src]
      @ optional_arg ~name:"fee" Tez.to_string fee
      @ optional_arg ~name:"fee-cap" Tez.to_string fee_cap
      @ if force_low_fee then ["--force-low-fee"] else [])
  in
  {value; run = Process.check}

let spawn_withdraw_delegate ?endpoint ?(wait = "none") ~src client =
  spawn_command
    ?endpoint
    client
    (["--wait"; wait] @ ["withdraw"; "delegate"; "for"; src])

let withdraw_delegate ?monitor_mempool ?endpoint ?wait ~src client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_withdraw_delegate ?wait ~src

let spawn_get_balance_for ?endpoint ~account client =
  spawn_command ?endpoint client ["get"; "balance"; "for"; account]

let get_balance_for ?endpoint ~account client =
  let process = spawn_get_balance_for ?endpoint ~account client in
  let* () = Process.check process
  and* output = Lwt_io.read (Process.stdout process) in
  return @@ Tez.parse_floating output

let spawn_create_mockup ?(sync_mode = Synchronous) ?parameter_file ~protocol
    client =
  let cmd =
    let common = ["--protocol"; Protocol.hash protocol; "create"; "mockup"] in
    (match sync_mode with
    | Synchronous -> common
    | Asynchronous -> common @ ["--asynchronous"])
    @ optional_arg ~name:"protocol-constants" Fun.id parameter_file
  in
  spawn_command client cmd

let create_mockup ?sync_mode ?parameter_file ~protocol client =
  spawn_create_mockup ?sync_mode ?parameter_file ~protocol client
  |> Process.check

let spawn_submit_proposals ?endpoint ?(key = Constant.bootstrap1.alias)
    ?(wait = "none") ?proto_hash ?(proto_hashes = []) client =
  let proto_hashes =
    match proto_hash with None -> proto_hashes | Some h -> h :: proto_hashes
  in
  spawn_command
    ?endpoint
    client
    ("--wait" :: wait :: "submit" :: "proposals" :: "for" :: key :: proto_hashes)

let submit_proposals ?monitor_mempool ?endpoint ?key ?wait ?proto_hash
    ?proto_hashes client =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_submit_proposals ?key ?wait ?proto_hash ?proto_hashes

type ballot = Nay | Pass | Yay

let spawn_submit_ballot ?endpoint ?(key = Constant.bootstrap1.alias)
    ?(wait = "none") ~proto_hash ~vote client =
  let string_of_vote = function
    | Yay -> "yay"
    | Nay -> "nay"
    | Pass -> "pass"
  in
  spawn_command
    ?endpoint
    client
    (["--wait"; wait]
    @ ["submit"; "ballot"; "for"; key; proto_hash; string_of_vote vote])

let submit_ballot ?monitor_mempool ?endpoint ?key ?wait ~proto_hash vote client
    =
  check_injection ?monitor_mempool ?endpoint client
  @@ spawn_submit_ballot ?key ?wait ~proto_hash ~vote

let set_deposits_limit ?monitor_mempool ?hooks ?endpoint ?(wait = "none") ~src
    ~limit client =
  check_injection_output ?monitor_mempool ?endpoint client
  @@ fun ?endpoint client ->
  spawn_command
    ?endpoint
    ?hooks
    client
    (["--wait"; wait] @ ["set"; "deposits"; "limit"; "for"; src; "to"; limit])

let unset_deposits_limit ?monitor_mempool ?hooks ?endpoint ?(wait = "none") ~src
    client =
  check_injection_output ?monitor_mempool ?endpoint client
  @@ fun ?endpoint client ->
  spawn_command
    ?hooks
    ?endpoint
    client
    (["--wait"; wait] @ ["unset"; "deposits"; "limit"; "for"; src])

let spawn_originate_contract ?hooks ?log_output ?endpoint ?(wait = "none") ?init
    ?burn_cap ~alias ~amount ~src ~prg client =
  spawn_command
    ?hooks
    ?log_output
    ?endpoint
    client
    (["--wait"; wait]
    @ [
        "originate";
        "contract";
        alias;
        "transferring";
        Tez.to_string amount;
        "from";
        src;
        "running";
        prg;
      ]
    @ optional_arg ~name:"init" Fun.id init
    @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)

let convert_michelson_to_json ~kind ?endpoint ~input client =
  let* client_output =
    spawn_command
      ?endpoint
      client
      ["convert"; kind; input; "from"; "michelson"; "to"; "json"]
    |> Process.check_and_read_stdout
  in
  Lwt.return (Ezjsonm.from_string client_output)

let convert_script_to_json ?endpoint ~script client =
  convert_michelson_to_json ~kind:"script" ?endpoint ~input:script client

let convert_data_to_json ?endpoint ~data client =
  convert_michelson_to_json ~kind:"data" ?endpoint ~input:data client

let originate_contract ?monitor_mempool ?hooks ?log_output ?endpoint ?wait ?init
    ?burn_cap ~alias ~amount ~src ~prg client =
  let* client_output =
    check_injection_output ?monitor_mempool ?endpoint client
    @@ spawn_originate_contract
         ?log_output
         ?hooks
         ?wait
         ?init
         ?burn_cap
         ~alias
         ~amount
         ~src
         ~prg
  in
  match client_output =~* rex "New contract ?(KT1\\w{33})" with
  | None ->
      Test.fail
        "Cannot extract contract hash from client_output: %s"
        client_output
  | Some hash -> return hash

let spawn_stresstest ?endpoint ?(source_aliases = []) ?(source_pkhs = [])
    ?(source_accounts = []) ?seed ?fee ?gas_limit ?transfers ?tps
    ?(single_op_per_pkh_per_block = false) ?fresh_probability
    ?smart_contract_parameters client =
  let sources =
    (* [sources] is a string containing all the [source_aliases],
       [source_pkhs], and [source_accounts] in JSON format, as
       expected by the [stresstest] client command. If all three lists
       [source_aliases], [source_pkhs], and [source_accounts] are
       empty (typically, when none of these optional arguments is
       provided to {!spawn_stresstest}), then [sources] instead
       contains the [Constant.bootstrap_keys] i.e. [bootstrap1], ...,
       [bootstrap5]. *)
    (* Note: We provide the sources JSON directly as a string, rather
       than writing it to a file, to avoid concurrency issues (we
       would need to ensure that each call writes to a different file:
       this would be doable, but providing a string containing the
       JSON is simpler). *)
    let open Account in
    let account_to_obj account =
      let (Unencrypted sk) = account.secret_key in
      `O
        [
          ("pkh", `String account.public_key_hash);
          ("pk", `String account.public_key);
          ("sk", `String sk);
        ]
    in
    let source_objs =
      List.map (fun alias -> `O [("alias", `String alias)]) source_aliases
      @ List.map (fun pkh -> `O [("pkh", `String pkh)]) source_pkhs
      @ List.map account_to_obj source_accounts
    in
    let source_objs =
      match source_objs with
      | [] -> Array.map account_to_obj Account.Bootstrap.keys |> Array.to_list
      | _ :: _ -> source_objs
    in
    `A source_objs
  in
  (* It is important to write the sources to a file because if we use a few
     thousands of sources the command line becomes too long. *)
  let sources_filename =
    Temp.file (Format.sprintf "sources-%s.json" (name client))
  in
  with_open_out sources_filename (fun ch ->
      output_string ch (JSON.encode_u sources)) ;
  let seed =
    (* Note: Tezt does not call [Random.self_init] so this is not
       randomized from one run to the other (if the exact same tests
       are run).

       The goal here is to use different seeds for instances of the
       [stresstest] command called in the same test, so that they
       don't all inject the same operations. *)
    (match seed with Some seed -> seed | None -> Random.int 0x3FFFFFFF)
    |> Int.to_string
  in
  let make_int_opt_arg (name : string) = function
    | Some (arg : int) -> [name; Int.to_string arg]
    | None -> []
  in
  let make_float_opt_arg (name : string) = function
    | Some (arg : float) -> [name; Float.to_string arg]
    | None -> []
  in
  let fee_arg =
    match fee with None -> [] | Some x -> ["--fee"; Tez.to_string x]
  in
  let smart_contract_parameters_arg =
    match smart_contract_parameters with
    | None -> []
    | Some items ->
        [
          "--smart-contract-parameters";
          Ezjsonm.value_to_string
            (`O
              (List.map
                 (fun ( alias,
                        {probability; invocation_fee; invocation_gas_limit} ) ->
                   ( alias,
                     `O
                       [
                         ("probability", Ezjsonm.float probability);
                         ( "invocation_fee",
                           Ezjsonm.string
                             (Int.to_string (Tez.to_mutez invocation_fee)) );
                         ( "invocation_gas_limit",
                           Ezjsonm.string (Int.to_string invocation_gas_limit)
                         );
                       ] ))
                 items));
        ]
  in
  spawn_command ?endpoint client
  @@ [
       "stresstest";
       "transfer";
       "using";
       "file:" ^ sources_filename;
       "--seed";
       seed;
     ]
  @ fee_arg
  @ make_int_opt_arg "--gas-limit" gas_limit
  @ make_int_opt_arg "--transfers" transfers
  @ make_int_opt_arg "--tps" tps
  @ make_float_opt_arg "--fresh-probability" fresh_probability
  @ smart_contract_parameters_arg
  @
  if single_op_per_pkh_per_block then ["--single-op-per-pkh-per-block"] else []

let stresstest ?endpoint ?source_aliases ?source_pkhs ?source_accounts ?seed
    ?fee ?gas_limit ?transfers ?tps ?single_op_per_pkh_per_block
    ?fresh_probability ?smart_contract_parameters client =
  spawn_stresstest
    ?endpoint
    ?source_aliases
    ?source_pkhs
    ?source_accounts
    ?seed
    ?fee
    ?gas_limit
    ?transfers
    ?tps
    ?single_op_per_pkh_per_block
    ?fresh_probability
    ?smart_contract_parameters
    client
  |> Process.check

let spawn_run_script ?hooks ?balance ?self_address ?source ?payer ~prg ~storage
    ~input client =
  spawn_command
    ?hooks
    client
    (["run"; "script"; prg; "on"; "storage"; storage; "and"; "input"; input]
    @ optional_arg ~name:"payer" Fun.id payer
    @ optional_arg ~name:"source" Fun.id source
    @ optional_arg ~name:"balance" Tez.to_string balance
    @ optional_arg ~name:"self-address" Fun.id self_address)

let stresstest_estimate_gas ?endpoint client =
  let* output =
    spawn_command ?endpoint client ["stresstest"; "estimate"; "gas"]
    |> Process.check_and_read_stdout
  in
  let json = JSON.parse ~origin:"transaction_costs" output in
  let regular = JSON.get "regular" json |> JSON.as_int in
  let prepare_pair (contract_name, json) = (contract_name, JSON.as_int json) in
  let smart_contracts =
    List.map prepare_pair (JSON.get "smart_contracts" json |> JSON.as_object)
  in
  Lwt.return {regular; smart_contracts}

let stresstest_originate_smart_contracts ?endpoint (source : Account.key) client
    =
  spawn_command
    ?endpoint
    client
    ["stresstest"; "originate"; "smart"; "contracts"; "from"; source.alias]
  |> Process.check

let run_script ?hooks ?balance ?self_address ?source ?payer ~prg ~storage ~input
    client =
  let* client_output =
    spawn_run_script
      ?hooks
      ?balance
      ?source
      ?payer
      ?self_address
      ~prg
      ~storage
      ~input
      client
    |> Process.check_and_read_stdout
  in
  match client_output =~* rex "storage\n(.*)" with
  | None ->
      Test.fail
        "Cannot extract new storage from client_output: %s"
        client_output
  | Some storage -> return @@ String.trim storage

let spawn_register_global_constant ?endpoint ?(wait = "none") ?burn_cap ~value
    ~src client =
  spawn_command
    ?endpoint
    client
    (["--wait"; wait]
    @ ["register"; "global"; "constant"; value; "from"; src]
    @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)

let register_global_constant ?monitor_mempool ?endpoint ?wait ?burn_cap ~src
    ~value client =
  let* client_output =
    check_injection_output ?monitor_mempool ?endpoint client
    @@ spawn_register_global_constant ?wait ?burn_cap ~src ~value
  in
  match client_output =~* rex "Global address: (expr\\w{50})" with
  | None ->
      Test.fail
        "Cannot extract constant hash from client_output: %s"
        client_output
  | Some hash -> return hash

let spawn_hash_data ?hooks ~data ~typ client =
  let cmd = ["hash"; "data"; data; "of"; "type"; typ] in
  spawn_command ?hooks client cmd

let hash_data ?expect_failure ?hooks ~data ~typ client =
  let* output =
    spawn_hash_data ?hooks ~data ~typ client
    |> Process.check_and_read_stdout ?expect_failure
  in
  let parse_line line =
    match line =~** rex "(.*): (.*)" with
    | None ->
        Log.warn
          "Unparsable output line of `hash data %s of type %s`: %s"
          data
          typ
          line ;
        None
    | Some _ as x -> x
  in
  (* Filtering avoids the last line (after the trailing \n).
     We don't want to produce a warning about an empty line. *)
  let lines = String.split_on_char '\n' output |> List.filter (( <> ) "") in
  let key_value_list = List.map parse_line lines |> List.filter_map Fun.id in
  Lwt.return key_value_list

let normalize_mode_to_string = function
  | Readable -> "Readable"
  | Optimized -> "Optimized"
  | Optimized_legacy -> "Optimized_legacy"

let spawn_normalize_data ?mode ?(legacy = false) ~data ~typ client =
  let mode_cmd =
    Option.map normalize_mode_to_string mode
    |> Option.map (fun s -> ["--unparsing-mode"; s])
  in
  let cmd =
    ["normalize"; "data"; data; "of"; "type"; typ]
    @ Option.value ~default:[] mode_cmd
    @ if legacy then ["--legacy"] else []
  in
  spawn_command client cmd

let normalize_data ?mode ?legacy ~data ~typ client =
  spawn_normalize_data ?mode ?legacy ~data ~typ client
  |> Process.check_and_read_stdout

let spawn_normalize_script ?mode ~script client =
  let mode_cmd =
    Option.map normalize_mode_to_string mode
    |> Option.map (fun s -> ["--unparsing-mode"; s])
  in
  let cmd =
    ["normalize"; "script"; script] @ Option.value ~default:[] mode_cmd
  in
  spawn_command client cmd

let normalize_script ?mode ~script client =
  spawn_normalize_script ?mode ~script client |> Process.check_and_read_stdout

let spawn_typecheck_script ~script ?(details = false) ?(emacs = false)
    ?(no_print_source = false) ?gas ?(legacy = false) client =
  let gas_cmd =
    Option.map Int.to_string gas |> Option.map (fun g -> ["--gas"; g])
  in
  let cmd =
    ["typecheck"; "script"; script]
    @ Option.value ~default:[] gas_cmd
    @ (if details then ["--details"] else [])
    @ (if emacs then ["--emacs"] else [])
    @ (if no_print_source then ["--no-print-source"] else [])
    @ if legacy then ["--legacy"] else []
  in
  spawn_command client cmd

let typecheck_script ~script ?(details = false) ?(emacs = false)
    ?(no_print_source = false) ?gas ?(legacy = false) client =
  spawn_typecheck_script
    ~script
    ~details
    ~emacs
    ~no_print_source
    ?gas
    ~legacy
    client
  |> Process.check_and_read_stdout

let spawn_run_view ?hooks ?source ?payer ?gas ?unparsing_mode ~view ~contract
    ?input ?(unlimited_gas = false) client =
  let input_params =
    match input with None -> [] | Some input -> ["with"; "input"; input]
  in
  spawn_command
    ?hooks
    client
    (["run"; "view"; view; "on"; "contract"; contract]
    @ input_params
    @ optional_arg ~name:"payer" Fun.id payer
    @ optional_arg ~name:"source" Fun.id source
    @ optional_arg
        ~name:"unparsing-mode"
        normalize_mode_to_string
        unparsing_mode
    @ optional_arg ~name:"gas" Int.to_string gas
    @ if unlimited_gas then ["--unlimited-gas"] else [])

let run_view ?hooks ?source ?payer ?gas ?unparsing_mode ~view ~contract ?input
    ?unlimited_gas client =
  spawn_run_view
    ?hooks
    ?source
    ?payer
    ?gas
    ?unparsing_mode
    ~view
    ~contract
    ?input
    ?unlimited_gas
    client
  |> Process.check_and_read_stdout

let spawn_list_protocols mode client =
  let mode_str =
    match mode with
    | `Mockup -> "mockup"
    | `Light -> "light"
    | `Proxy -> "proxy"
  in
  spawn_command client (mode_arg client @ ["list"; mode_str; "protocols"])

let list_protocols mode client =
  let process = spawn_list_protocols mode client in
  let* () = Process.check process
  and* output = Lwt_io.read (Process.stdout process) in
  return (parse_list_protocols_output output)

let spawn_migrate_mockup ~next_protocol client =
  spawn_command
    client
    (mode_arg client @ ["migrate"; "mockup"; "to"; Protocol.hash next_protocol])

let migrate_mockup ~next_protocol client =
  spawn_migrate_mockup ~next_protocol client |> Process.check

let spawn_sign_block client block_hex ~delegate =
  spawn_command client ["sign"; "block"; block_hex; "for"; delegate]

let sign_block client block_hex ~delegate =
  spawn_sign_block client block_hex ~delegate |> Process.check_and_read_stdout

module Tx_rollup = struct
  let spawn_originate ?endpoint ?(wait = "none")
      ?(burn_cap = Tez.of_int 9_999_999) ?(storage_limit = 60_000) ?fee ?hooks
      ~src client =
    spawn_command
      ?endpoint
      ?hooks
      client
      ([
         "--wait";
         wait;
         "originate";
         "tx";
         "rollup";
         "from";
         src;
         "--burn-cap";
         Tez.to_string burn_cap;
         "--storage-limit";
         string_of_int storage_limit;
       ]
      @ Option.fold
          ~none:[]
          ~some:(fun f ->
            [
              "--fee";
              Tez.to_string f;
              "--force-low-fee";
              "--fee-cap";
              Tez.to_string f;
            ])
          fee)

  let originate ?monitor_mempool ?endpoint ?wait ?burn_cap ?storage_limit ?fee
      ?hooks ~src client =
    let* output =
      check_injection_output ?monitor_mempool ?endpoint client
      @@ spawn_originate ?wait ?burn_cap ?storage_limit ?fee ?hooks ~src
    in
    output
    =~* rex "Originated tx rollup: ?(\\w*)"
    |> mandatory "tx rollup hash" |> return

  let submit_batch ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?storage_limit ?hooks ?log_output ?log_command ~content:(`Hex content)
      ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        ?log_output
        ?log_command
        client
        (["--wait"; wait]
        @ [
            "submit";
            "tx";
            "rollup";
            "batch";
            "0x" ^ content;
            "to";
            rollup;
            "from";
            src;
          ]
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let submit_commitment ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?storage_limit ?hooks ?predecessor ~level ~roots ~inbox_merkle_root
      ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ ["commit"; "to"; "tx"; "rollup"; rollup; "from"; src]
        @ ["for"; "level"; Int.to_string level]
        @ ["with"; "inbox"; "hash"; inbox_merkle_root]
        @ ["and"; "messages"; "result"; "hash"]
        @ roots
        @ optional_arg ~name:"predecessor-hash" (fun s -> s) predecessor
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let submit_finalize_commitment ?monitor_mempool ?endpoint ?(wait = "none")
      ?burn_cap ?storage_limit ?hooks ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ ["finalize"; "commitment"; "of"; "tx"; "rollup"; rollup; "from"; src]
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let submit_remove_commitment ?monitor_mempool ?endpoint ?(wait = "none")
      ?burn_cap ?storage_limit ?hooks ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ ["remove"; "commitment"; "of"; "tx"; "rollup"; rollup; "from"; src]
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let submit_rejection ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?storage_limit ?hooks ~level ~message ~position ~path ~message_result_hash
      ~rejected_message_result_path ~agreed_message_result_path ~proof
      ~context_hash ~withdraw_list_hash ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ ["reject"; "commitment"; "of"; "tx"; "rollup"; rollup]
        @ ["at"; "level"; string_of_int level]
        @ ["with"; "result"; "hash"; message_result_hash]
        @ ["and"; "result"; "path"; rejected_message_result_path]
        @ ["for"; "message"; "at"; "position"; string_of_int position]
        @ ["with"; "content"; message]
        @ ["and"; "path"; path]
        @ ["with"; "agreed"; "context"; "hash"; context_hash]
        @ ["and"; "withdraw"; "list"; "hash"; withdraw_list_hash]
        @ ["and"; "result"; "path"; agreed_message_result_path]
        @ ["using"; "proof"; proof; "from"; src]
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let submit_return_bond ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?storage_limit ?hooks ~rollup ~src client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ ["recover"; "bond"; "of"; src; "for"; "tx"; "rollup"; rollup]
        @ Option.fold
            ~none:[]
            ~some:(fun burn_cap -> ["--burn-cap"; Tez.to_string burn_cap])
            burn_cap
        @ Option.fold
            ~none:[]
            ~some:(fun s -> ["--storage-limit"; string_of_int s])
            storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let dispatch_tickets ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?storage_limit ?hooks ~tx_rollup ~src ~level ~message_position
      ~context_hash ~message_result_path ~ticket_dispatch_info_data_list client
      =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ [
            "dispatch";
            "tickets";
            "of";
            "tx";
            "rollup";
            tx_rollup;
            "from";
            src;
            "at";
            "level";
            string_of_int level;
            "for";
            "the";
            "message";
            "at";
            "index";
            string_of_int message_position;
            "with";
            "the";
            "context";
            "hash";
            context_hash;
            "and";
            "path";
            message_result_path;
            "and";
            "tickets";
            "info";
          ]
        @ ticket_dispatch_info_data_list
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap
        @ optional_arg ~name:"storage-limit" string_of_int storage_limit)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}

  let transfer_tickets ?monitor_mempool ?endpoint ?(wait = "none") ?burn_cap
      ?hooks ~qty ~src ~destination ~entrypoint ~contents ~ty ~ticketer client =
    let process =
      check_injection_process ?monitor_mempool ?endpoint client
      @@ fun ?endpoint client ->
      spawn_command
        ?endpoint
        ?hooks
        client
        (["--wait"; wait]
        @ [
            "transfer";
            Int64.to_string qty;
            "tickets";
            "from";
            src;
            "to";
            destination;
            "with";
            "entrypoint";
            entrypoint;
            "and";
            "contents";
            contents;
            "and";
            "type";
            ty;
            "and";
            "ticketer";
            ticketer;
          ]
        @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)
    in
    let parse process = Lwt.bind process Process.check in
    {value = process; run = parse}
end

let spawn_show_voting_period ?endpoint client =
  spawn_command ?endpoint client (mode_arg client @ ["show"; "voting"; "period"])

let show_voting_period ?endpoint client =
  let process = spawn_show_voting_period ?endpoint client in
  let* () = Process.check process
  and* output = Lwt_io.read (Process.stdout process) in
  match output =~* rex "Current period: \"([a-z]+)\"" with
  | None ->
      Test.fail
        "tezos-client show voting period did not print the current period"
  | Some period -> return period

module Sc_rollup = struct
  let spawn_originate ?endpoint ?hooks ?(wait = "none") ?burn_cap ~src ~kind
      ~boot_sector client =
    spawn_command
      ?endpoint
      ?hooks
      client
      (["--wait"; wait]
      @ [
          "originate";
          "sc";
          "rollup";
          "from";
          src;
          "of";
          "kind";
          kind;
          "booting";
          "with";
          boot_sector;
        ]
      @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)

  let parse_rollup_address_in_receipt output =
    match output =~* rex "Address: (.*)" with
    | None -> Test.fail "Cannot extract rollup address from receipt."
    | Some x -> return x

  let originate ?monitor_mempool ?endpoint ?hooks ?wait ?burn_cap ~src ~kind
      ~boot_sector client =
    let* output =
      check_injection_output ?monitor_mempool ?endpoint client
      @@ spawn_originate ?hooks ?wait ?burn_cap ~src ~kind ~boot_sector
    in
    parse_rollup_address_in_receipt output

  let spawn_send_message ?endpoint ?hooks ?(wait = "none") ?burn_cap ~msg ~src
      ~dst client =
    spawn_command
      ?endpoint
      ?hooks
      client
      (["--wait"; wait]
      @ ["send"; "sc"; "rollup"; "message"; msg; "from"; src; "to"; dst]
      @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)

  let send_message ?monitor_mempool ?endpoint ?hooks ?wait ?burn_cap ~msg ~src
      ~dst client =
    check_injection ?monitor_mempool ?endpoint client
    @@ spawn_send_message ?hooks ?wait ?burn_cap ~msg ~src ~dst

  let spawn_cement_commitment ?endpoint ?hooks ?(wait = "none") ?burn_cap ~hash
      ~src ~dst client =
    spawn_command
      ?endpoint
      ?hooks
      client
      (["--wait"; wait]
      @ ["cement"; "commitment"; hash; "from"; src; "for"; "sc"; "rollup"; dst]
      @ optional_arg ~name:"burn-cap" Tez.to_string burn_cap)

  let cement_commitment ?monitor_mempool ?endpoint ?hooks ?wait ?burn_cap ~hash
      ~src ~dst client =
    check_injection ?monitor_mempool ?endpoint client
    @@ spawn_cement_commitment ?hooks ?wait ?burn_cap ~hash ~src ~dst
end

let init ?path ?admin_path ?name ?color ?base_dir ?endpoint ?media_type () =
  let client =
    create ?path ?admin_path ?name ?color ?base_dir ?endpoint ?media_type ()
  in
  Account.write Constant.all_secret_keys ~base_dir:(Client_base.base_dir client) ;
  return client

let init_mockup ?path ?admin_path ?name ?color ?base_dir ?sync_mode
    ?parameter_file ?constants ~protocol () =
  (* The mockup's public documentation doesn't use `--mode mockup`
     for `create mockup` (as it is not required). We wanna do the same here.
     Hence `Client None` here: *)
  let client =
    create_with_mode
      ?path
      ?admin_path
      ?name
      ?color
      ?base_dir
      (Client (None, None))
  in
  let parameter_file =
    Option.value
      ~default:(Protocol.parameter_file ?constants protocol)
      parameter_file
  in
  let* () = create_mockup ?sync_mode ~parameter_file ~protocol client in
  (* We want, however, to return a mockup client; hence the following: *)
  set_mode Mockup client ;
  return client

let init_light ?path ?admin_path ?name ?color ?base_dir ?(min_agreement = 0.66)
    ?event_level ?event_sections_levels ?(nodes_args = []) () =
  let filter_node_arg = function
    | Node.Connections _ | Synchronisation_threshold _ -> None
    | x -> Some x
  in
  let nodes_args =
    List.filter_map filter_node_arg nodes_args
    @ Node.[Connections 1; Synchronisation_threshold 0]
  in
  let* node1 =
    Node.init ?event_level ?event_sections_levels ~name:"node1" nodes_args
  and* node2 =
    Node.init ?event_level ?event_sections_levels ~name:"node2" nodes_args
  in
  let nodes = [node1; node2] in
  let client =
    create_with_mode
      ?path
      ?admin_path
      ?name
      ?color
      ?base_dir
      (Light (min_agreement, List.map (fun n -> Node n) nodes))
  in
  let* () =
    write_sources_file
      ~min_agreement
      ~uris:
        (List.map
           (fun node ->
             sf "http://%s:%d" (Node.rpc_host node) (Node.rpc_port node))
           nodes)
      client
  in
  let json = JSON.parse_file (sources_file client) in
  Log.info "%s" @@ JSON.encode json ;
  Log.info "Importing keys" ;
  Account.write Constant.all_secret_keys ~base_dir:(Client_base.base_dir client) ;
  Log.info "Syncing peers" ;
  let* () =
    assert (nodes <> []) ;
    (* endpoint_arg is the first element of the list by default so we sync it
       with all other nodes. *)
    Lwt_list.iter_s
      (fun peer -> Admin.connect_address ~peer client)
      (List.tl nodes)
  in
  return (client, node1, node2)

let stresstest_gen_keys ?endpoint n client =
  let* output =
    spawn_command
      ?endpoint
      client
      ["stresstest"; "gen"; "keys"; Int.to_string n]
    |> Process.check_and_read_stdout
  in
  let json = JSON.parse ~origin:"stresstest_gen_keys" output in
  let read_one i json : Account.key =
    let bootstrap_accounts = Account.Bootstrap.keys |> Array.length in
    let alias = Account.Bootstrap.alias (i + bootstrap_accounts + 1) in
    let public_key_hash = JSON.(json |-> "pkh" |> as_string) in
    let public_key = JSON.(json |-> "pk" |> as_string) in
    let secret_key = Account.Unencrypted JSON.(json |-> "sk" |> as_string) in
    {alias; public_key_hash; public_key; secret_key}
  in
  let additional_bootstraps = List.mapi read_one (JSON.as_list json) in
  set_additional_bootstraps client additional_bootstraps ;
  Lwt.return additional_bootstraps

let get_parameter_file ?additional_bootstrap_accounts ?default_accounts_balance
    ?parameter_file protocol =
  match additional_bootstrap_accounts with
  | None -> return parameter_file
  | Some additional_account_keys ->
      let additional_bootstraps =
        List.map
          (fun x -> (x, default_accounts_balance))
          additional_account_keys
      in
      let* parameter_file =
        Protocol.write_parameter_file
          ~additional_bootstrap_accounts:additional_bootstraps
          ~base:
            (Option.fold
               ~none:(Either.right protocol)
               ~some:Either.left
               parameter_file)
          []
      in
      return (Some parameter_file)

let init_with_node ?path ?admin_path ?name ?color ?base_dir ?event_level
    ?event_sections_levels
    ?(nodes_args = Node.[Connections 0; Synchronisation_threshold 0])
    ?(keys = Constant.all_secret_keys) tag () =
  match tag with
  | (`Client | `Proxy) as mode ->
      let* node = Node.init ?event_level ?event_sections_levels nodes_args in
      let endpoint = Node node in
      let mode =
        match mode with
        | `Client -> Client (Some endpoint, None)
        | `Proxy -> Proxy endpoint
      in
      let client =
        create_with_mode ?path ?admin_path ?name ?color ?base_dir mode
      in
      Account.write keys ~base_dir:(Client_base.base_dir client) ;
      return (node, client)
  | `Light ->
      let* client, node1, _ =
        init_light ?path ?admin_path ?name ?color ?base_dir ~nodes_args ()
      in
      return (node1, client)

let init_with_protocol ?path ?admin_path ?name ?color ?base_dir ?event_level
    ?event_sections_levels ?nodes_args ?additional_bootstrap_account_count
    ?default_accounts_balance ?parameter_file ?timestamp ?keys tag ~protocol ()
    =
  let* node, client =
    init_with_node
      ?path
      ?admin_path
      ?name
      ?color
      ?base_dir
      ?event_level
      ?event_sections_levels
      ?nodes_args
      ?keys
      tag
      ()
  in
  let* additional_bootstrap_accounts =
    match additional_bootstrap_account_count with
    | None -> return None
    | Some n ->
        let* r = stresstest_gen_keys n client in
        return (Some r)
  in
  let* parameter_file =
    get_parameter_file
      ?additional_bootstrap_accounts
      ?default_accounts_balance
      ?parameter_file
      (protocol, None)
  in
  let* () = activate_protocol ?parameter_file ~protocol ?timestamp client in
  let* _ = Node.wait_for_level node 1 in
  return (node, client)

let spawn_register_key owner client =
  spawn_command
    client
    ["--wait"; "none"; "register"; "key"; owner; "as"; "delegate"]

let register_key owner client = spawn_register_key owner client |> Process.check

let contract_storage ?unparsing_mode address client =
  spawn_command
    client
    (["get"; "contract"; "storage"; "for"; address]
    @ optional_arg
        ~name:"unparsing-mode"
        normalize_mode_to_string
        unparsing_mode)
  |> Process.check_and_read_stdout

let sign_bytes ~signer ~data client =
  let* output =
    spawn_command client ["sign"; "bytes"; data; "for"; signer]
    |> Process.check_and_read_stdout
  in
  match output =~* rex "Signature: ([a-zA-Z0-9]+)" with
  | Some signature -> Lwt.return signature
  | None -> Test.fail "Couldn't sign message '%s' for %s." data signer

let convert_script ~script ~src_format ~dst_format client =
  let fmt_to_string = function
    | `Michelson -> "michelson"
    | `Binary -> "binary"
    | `Json -> "json"
  in
  spawn_command
    client
    [
      "convert";
      "script";
      script;
      "from";
      fmt_to_string src_format;
      "to";
      fmt_to_string dst_format;
    ]
  |> Process.check_and_read_stdout
