open Jingoo.Jg_types
open Agent_state
open Services_cache

let parse_endpoint str =
  match str =~*** rex {|^(https?)://(.*):(\d+)|} with
  | Some (scheme, host, port_str) ->
      Foreign_endpoint.{host; scheme; port = int_of_string port_str}
  | None -> (
      match str =~** rex {|^(.*):(\d+)|} with
      | Some (host, port_str) ->
          {host; scheme = "http"; port = int_of_string port_str}
      | None -> raise (Invalid_argument "parse_endpoint"))

type _ key += Octez_node_k : string -> Node.t key

module Octez_node_key = struct
  type t = string

  type r = Node.t

  let proj : type a. a key -> (t * (a, r) eq) option = function
    | Octez_node_k name -> Some (name, Eq)
    | _ -> None

  let compare = String.compare
end

let () = Agent_state.register_key (module Octez_node_key)

type _ key += Rollup_node_k : string -> Sc_rollup_node.t key

module Rollup_node_key = struct
  type t = string

  type r = Sc_rollup_node.t

  let proj : type a. a key -> (t * (a, r) eq) option = function
    | Rollup_node_k name -> Some (name, Eq)
    | _ -> None

  let compare = String.compare
end

let () = Agent_state.register_key (module Rollup_node_key)

type dac_mode_k = [`Coordinator | `Member | `Observer]

let dac_mode_k_compare k1 k2 =
  let int_of_dac_mode_k = function
    | `Coordinator -> 0
    | `Member -> 1
    | `Observer -> 2
  in
  Int.compare (int_of_dac_mode_k k1) (int_of_dac_mode_k k2)

type _ key += Dac_node_k : dac_mode_k * string -> Dac_node.t key

module Dac_node_key = struct
  type t = dac_mode_k * string

  type r = Dac_node.t

  let proj : type a. a key -> (t * (a, r) eq) option = function
    | Dac_node_k (m, name) -> Some ((m, name), Eq)
    | _ -> None

  let compare k1 k2 =
    let r = dac_mode_k_compare (fst k1) (fst k2) in
    if r = 0 then String.compare (snd k1) (snd k2) else r
end

let () = Agent_state.register_key (module Dac_node_key)

let octez_endpoint state endpoint =
  match endpoint with
  | Uri.Owned {name = node} ->
      Client.Node (Agent_state.find (Octez_node_k node) state)
  | Remote {endpoint} -> Foreign_endpoint (parse_endpoint endpoint)

let dac_rpc_info state mode endpoint =
  match endpoint with
  | Uri.Owned {name = node} ->
      let dac_node = Agent_state.find (Dac_node_k (mode, node)) state in
      ("127.0.0.1", Dac_node.rpc_port dac_node)
  | Remote {endpoint} ->
      let foreign = parse_endpoint endpoint in
      (Foreign_endpoint.rpc_host foreign, Foreign_endpoint.rpc_port foreign)

let dac_endpoint state mode endpoint =
  match endpoint with
  | Uri.Owned {name = node} ->
      let dac_node = Agent_state.find (Dac_node_k (mode, node)) state in
      Dac_client.Node dac_node
  | Remote {endpoint} ->
      let foreign = parse_endpoint endpoint in
      Foreign_endpoint foreign

type start_octez_node_r = {
  name : string;
  rpc_port : int;
  metrics_port : int;
  net_port : int;
}

let resolve_octez_rpc_global_uri ~self ~resolver =
  Uri.agent_uri_of_global_uri ~self ~services:(resolver Octez_node Rpc)

let resolve_dac_rpc_global_uri ~self ~resolver =
  Uri.agent_uri_of_global_uri ~self ~services:(resolver Dac_node Rpc)

type 'uri start_octez_node = {
  name : string option;
  path_node : 'uri;
  network : string;
  snapshot : 'uri option;
  sync_threshold : int;
  peers : string list;
  net_port : string option;
  metrics_port : string option;
  rpc_port : string option;
}

type (_, _) Remote_procedure.t +=
  | Start_octez_node :
      'uri start_octez_node
      -> (start_octez_node_r, 'uri) Remote_procedure.t

module Start_octez_node = struct
  let name = "tezos.start_node"

  type 'uri t = 'uri start_octez_node

  type r = start_octez_node_r

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Start_octez_node args -> Some args
    | _ -> None

  let to_remote_procedure args = Start_octez_node args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Start_octez_node _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {
               name;
               path_node;
               network;
               snapshot;
               sync_threshold;
               peers;
               net_port;
               metrics_port;
               rpc_port;
             } ->
          ( name,
            path_node,
            network,
            snapshot,
            sync_threshold,
            peers,
            net_port,
            metrics_port,
            rpc_port ))
        (fun ( name,
               path_node,
               network,
               snapshot,
               sync_threshold,
               peers,
               net_port,
               metrics_port,
               rpc_port ) ->
          {
            name;
            path_node;
            network;
            snapshot;
            sync_threshold;
            peers;
            net_port;
            metrics_port;
            rpc_port;
          })
        Data_encoding.(
          obj9
            (opt "name" string)
            (req "path_node" uri_encoding)
            (dft "network" string "{{ network }}")
            (opt "snapshot" uri_encoding)
            (dft "synchronization_threshold" int31 2)
            (dft "peers" (list string) [])
            (opt "net_port" string)
            (opt "metrics_port" string)
            (opt "rpc_port" string)))

  let r_encoding =
    Data_encoding.(
      conv
        (fun ({rpc_port; metrics_port; net_port; name} : start_octez_node_r) ->
          (rpc_port, metrics_port, net_port, name))
        (fun (rpc_port, metrics_port, net_port, name) ->
          {rpc_port; metrics_port; net_port; name})
        (obj4
           (req "rpc_port" int31)
           (req "metrics_port" int31)
           (req "net_port" int31)
           (req "name" string)))

  let tvalue_of_r ({rpc_port; metrics_port; net_port; name} : r) =
    Tobj
      [
        ("rpc_port", Tint rpc_port);
        ("metrics_port", Tint metrics_port);
        ("net_port", Tint net_port);
        ("name", Tstr name);
      ]

  let expand ~self ~run
      {
        name;
        path_node;
        network;
        snapshot;
        sync_threshold;
        peers;
        net_port;
        metrics_port;
        rpc_port;
      } =
    let name = Option.map run name in
    let path_node =
      Remote_procedure.global_uri_of_string ~self ~run path_node
    in
    let snapshot =
      Option.map (Remote_procedure.global_uri_of_string ~self ~run) snapshot
    in
    let net_port = Option.map run net_port in
    let metrics_port = Option.map run metrics_port in
    let rpc_port = Option.map run rpc_port in
    let network = run network in
    let peers = List.map run peers in
    (* TODO: allow to expand [sync_threshold] *)
    {
      name;
      path_node;
      network;
      snapshot;
      sync_threshold;
      peers;
      net_port;
      metrics_port;
      rpc_port;
    }

  let resolve ~self resolver
      {
        name;
        path_node;
        network;
        snapshot;
        sync_threshold;
        peers;
        net_port;
        metrics_port;
        rpc_port;
      } =
    let path_node = Remote_procedure.file_agent_uri ~self ~resolver path_node in
    let snapshot =
      Option.map (Remote_procedure.file_agent_uri ~self ~resolver) snapshot
    in
    {
      name;
      path_node;
      network;
      snapshot;
      sync_threshold;
      peers;
      net_port;
      metrics_port;
      rpc_port;
    }

  let setup_octez_node ~network ~sync_threshold ~path_node ~metrics_port
      ~rpc_port ~net_port ~peers ?name ?snapshot () =
    let l1_node_args =
      Node.
        [
          (* By default, Tezt set the difficulty to generate the identity file
             of the Octez node to 0 (`--expected-pow 0`). The default value
             used in network like mainnet, Mondaynet etc. is 26 (see
             `lib_node_config/config_file.ml`). *)
          Expected_pow 0;
          Synchronisation_threshold sync_threshold;
          Network network;
          Metrics_addr (sf "0.0.0.0:%d" metrics_port);
        ]
      @ List.map (fun x -> Node.Peer x) peers
    in
    let node =
      Node.create
        ?name
        ~net_addr:"0.0.0.0"
        ~rpc_host:"0.0.0.0"
        ~rpc_port
        ~net_port
        ~path:path_node
        l1_node_args
    in
    let* () = Node.config_init node [] in
    let* () =
      match snapshot with
      | Some snapshot ->
          Log.info "Import snapshot" ;
          let* () = Node.snapshot_import ~no_check:true node snapshot in
          Log.info "Snapshot imported" ;
          unit
      | None -> unit
    in
    let* () = Node.run node [] in
    let* () = Node.wait_for_ready node in
    return node

  let run state args =
    let* path_node =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_node
    in
    let* snapshot =
      match args.snapshot with
      | Some snapshot ->
          let* local_path =
            Http_client.local_path_from_agent_uri
              (Agent_state.http_client state)
              snapshot
          in
          return (Some local_path)
      | None -> return None
    in
    let metrics_port =
      match args.metrics_port with
      | Some port -> int_of_string port
      | None -> Port.fresh ()
    in
    let rpc_port =
      match args.rpc_port with
      | Some port -> int_of_string port
      | None -> Port.fresh ()
    in
    let net_port =
      match args.net_port with
      | Some port -> int_of_string port
      | None -> Port.fresh ()
    in
    let* octez_node =
      setup_octez_node
        ?name:args.name
        ~rpc_port
        ~path_node
        ~network:args.network
        ~sync_threshold:args.sync_threshold
        ~net_port
        ~metrics_port
        ~peers:args.peers
        ?snapshot
        ()
    in
    Agent_state.add (Octez_node_k (Node.name octez_node)) octez_node state ;
    return
      {
        rpc_port = Node.rpc_port octez_node;
        metrics_port;
        net_port = Node.net_port octez_node;
        name = Node.name octez_node;
      }

  let on_completion ~on_new_service ~on_new_metrics_source (res : r) =
    let open Services_cache in
    on_new_service res.name Octez_node Rpc res.rpc_port ;
    on_new_service res.name Octez_node Metrics res.metrics_port ;
    on_new_service res.name Octez_node P2p res.net_port ;
    on_new_metrics_source res.name Octez_node res.metrics_port
end

type 'uri activate_protocol = {
  endpoint : 'uri;
  path_client : 'uri;
  protocol : string;
}

let protocol_of_string = function
  | "alpha" -> Protocol.Alpha
  | protocol -> Test.fail "Unrecgonized protocol name: %s" protocol

type (_, _) Remote_procedure.t +=
  | Active_protocol : 'uri activate_protocol -> (unit, 'uri) Remote_procedure.t

module Activate_protocol = struct
  let name = "tezos.activate_protocol"

  type 'uri t = 'uri activate_protocol

  type r = unit

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Active_protocol args -> Some args
    | _ -> None

  let to_remote_procedure args = Active_protocol args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Active_protocol _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    let open Data_encoding in
    conv
      (fun {endpoint; path_client; protocol} ->
        (endpoint, path_client, protocol))
      (fun (endpoint, path_client, protocol) ->
        {endpoint; path_client; protocol})
      (obj3
         (req "endpoint" uri_encoding)
         (req "path_client" uri_encoding)
         (req "protocol" string))

  let r_encoding = Data_encoding.empty

  let tvalue_of_r () = Tnull

  let expand ~self ~run base =
    let path_client =
      Remote_procedure.global_uri_of_string ~self ~run base.path_client
    in
    let endpoint =
      Remote_procedure.global_uri_of_string ~self ~run base.endpoint
    in
    {base with path_client; endpoint}

  let resolve ~self resolver base =
    let path_client =
      Remote_procedure.file_agent_uri ~self ~resolver base.path_client
    in
    let endpoint = resolve_octez_rpc_global_uri ~self ~resolver base.endpoint in
    {base with path_client; endpoint}

  let run state {endpoint; path_client; protocol} =
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        path_client
    in
    let endpoint = octez_endpoint state endpoint in
    let client = Client.create ~path:path_client ~endpoint () in
    Account.write Constant.all_secret_keys ~base_dir:(Client.base_dir client) ;
    let protocol = protocol_of_string protocol in
    Client.activate_protocol
      ~protocol
      ~parameter_file:"sandbox-parameters.json"
      client

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ () = ()
end

type 'uri client_base_args = {path_client : 'uri; endpoint : 'uri}

let client_base_args_encoding uri_encoding =
  Data_encoding.(
    conv
      (fun {path_client; endpoint} -> (path_client, endpoint))
      (fun (path_client, endpoint) -> {path_client; endpoint})
      (obj2 (req "path_client" uri_encoding) (req "endpoint" uri_encoding)))

let expand_client_base_args ~self ~run base =
  let path_client =
    Remote_procedure.global_uri_of_string ~self ~run base.path_client
  in
  let endpoint =
    Remote_procedure.global_uri_of_string ~self ~run base.endpoint
  in
  {path_client; endpoint}

let resolve_client_args_base ~self resolver base =
  let path_client =
    Remote_procedure.file_agent_uri ~self ~resolver base.path_client
  in
  let endpoint = resolve_octez_rpc_global_uri ~self ~resolver base.endpoint in
  {path_client; endpoint}

type 'uri wait_for_bootstrapped = 'uri client_base_args

type (_, _) Remote_procedure.t +=
  | Wait_for_bootstrapped :
      'uri wait_for_bootstrapped
      -> (unit, 'uri) Remote_procedure.t

module Wait_for_bootstrapped = struct
  let name = "tezos.wait_for_bootstrapped"

  type 'uri t = 'uri wait_for_bootstrapped

  type r = unit

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Wait_for_bootstrapped args -> Some args
    | _ -> None

  let to_remote_procedure args = Wait_for_bootstrapped args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Wait_for_bootstrapped _ -> Eq
    | _ -> Neq

  let encoding uri_encoding = client_base_args_encoding uri_encoding

  let r_encoding = Data_encoding.empty

  let tvalue_of_r () = Tnull

  let expand = expand_client_base_args

  let resolve = resolve_client_args_base

  let run state args =
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_client
    in
    let endpoint = octez_endpoint state args.endpoint in
    let client = Client.create ~path:path_client ~endpoint () in
    let* () = Client.bootstrapped client in
    unit

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ () = ()
end

type 'uri originate_smart_rollup = {
  client_base : 'uri client_base_args;
  wallet : string;
  alias : string;
  src : string;
  kernel_path : 'uri;
  parameters_type : string;
  wait : string;
}

type originate_smart_rollup_r = {address : string; hex_address : string}

type (_, _) Remote_procedure.t +=
  | Originate_smart_rollup :
      'uri originate_smart_rollup
      -> (originate_smart_rollup_r, 'uri) Remote_procedure.t

module Originate_smart_rollup = struct
  let name = "tezos.operations.originate_smart_rollup"

  type 'uri t = 'uri originate_smart_rollup

  type r = originate_smart_rollup_r

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Originate_smart_rollup args -> Some args
    | _ -> None

  let to_remote_procedure args = Originate_smart_rollup args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Originate_smart_rollup _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {
               client_base;
               wallet;
               alias;
               src;
               kernel_path;
               parameters_type;
               wait;
             } ->
          (client_base, (wallet, alias, src, kernel_path, parameters_type, wait)))
        (fun ( client_base,
               (wallet, alias, src, kernel_path, parameters_type, wait) ) ->
          {client_base; wallet; alias; src; kernel_path; parameters_type; wait})
        (merge_objs
           (client_base_args_encoding uri_encoding)
           (obj6
              (req "wallet" string)
              (dft "alias" string "rollup")
              (req "source" string)
              (req "kernel_path" uri_encoding)
              (req "parameters_type" string)
              (dft "wait" string "0"))))

  let r_encoding =
    Data_encoding.(
      conv
        (fun {address; hex_address} -> (address, hex_address))
        (fun (address, hex_address) -> {address; hex_address})
        (obj2 (req "address" string) (req "hex_address" string)))

  let tvalue_of_r {address; hex_address} =
    Tobj [("address", Tstr address); ("hex_address", Tstr hex_address)]

  let expand ~self ~run args =
    let client_base = expand_client_base_args ~self ~run args.client_base in
    let wallet = run args.wallet in
    let alias = run args.alias in
    let src = run args.src in
    let kernel_path =
      Remote_procedure.global_uri_of_string ~self ~run args.kernel_path
    in
    let wait = run args.wait in
    let parameters_type = run args.parameters_type in
    {client_base; wallet; alias; src; kernel_path; parameters_type; wait}

  let resolve ~self resolver args =
    let client_base =
      resolve_client_args_base ~self resolver args.client_base
    in
    let kernel_path =
      Remote_procedure.file_agent_uri ~self ~resolver args.kernel_path
    in
    {args with client_base; kernel_path}

  let run state args =
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.client_base.path_client
    in
    let endpoint = octez_endpoint state args.client_base.endpoint in

    let client =
      Client.create ~path:path_client ~endpoint ~base_dir:args.wallet ()
    in

    let* kernel_path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.kernel_path
    in

    let boot_sector = read_file kernel_path in

    let* address =
      Client.Sc_rollup.originate
        client
        ~wait:args.wait
        ~alias:args.alias
        ~src:args.src
        ~kind:"wasm_2_0_0"
        ~parameters_ty:args.parameters_type
        ~boot_sector
        ~burn_cap:(Tez.of_int 2)
    in
    Log.info "Rollup %s originated" address ;
    let (`Hex hex_address) =
      Tezos_crypto.Hashed.Smart_rollup_address.(
        of_b58check_exn address |> to_string |> Hex.of_string)
    in
    return {address; hex_address}

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_
      {address = _; hex_address = _} =
    ()
end

type 'uri originate_smart_contract = {
  client_base : 'uri client_base_args;
  wallet : string;
  alias : string;
  src : string;
  script_path : 'uri;
  amount : Tez.t;
  init : string;
  wait : string;
}

type originate_smart_contract_r = {address : string; hex_address : string}

type (_, _) Remote_procedure.t +=
  | Originate_smart_contract :
      'uri originate_smart_contract
      -> (originate_smart_contract_r, 'uri) Remote_procedure.t

let tez_encoding =
  Data_encoding.conv Tez.to_mutez Tez.of_mutez_int Data_encoding.int31

module Originate_smart_contract = struct
  let contract_hash = "\002\090\121" (* KT1(36) *)

  module H =
    Tezos_crypto.Blake2B.Make
      (Tezos_crypto.Base58)
      (struct
        let name = "Contract_hash"

        let title = "A contract ID"

        let b58check_prefix = contract_hash

        let size = Some 20
      end)

  let name = "tezos.operations.originate_smart_contract"

  type 'uri t = 'uri originate_smart_contract

  type r = originate_smart_contract_r

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Originate_smart_contract args -> Some args
    | _ -> None

  let to_remote_procedure args = Originate_smart_contract args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Originate_smart_contract _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {client_base; wallet; alias; src; script_path; amount; init; wait} ->
          (client_base, (wallet, alias, src, script_path, amount, init, wait)))
        (fun (client_base, (wallet, alias, src, script_path, amount, init, wait))
             ->
          {client_base; wallet; alias; src; script_path; amount; init; wait})
        (merge_objs
           (client_base_args_encoding uri_encoding)
           (obj7
              (req "wallet" string)
              (dft "alias" string "rollup")
              (req "source" string)
              (req "script_path" uri_encoding)
              (dft "amount" tez_encoding Tez.zero)
              (req "init" string)
              (dft "wait" string "1"))))

  let r_encoding =
    Data_encoding.(
      conv
        (fun {address; hex_address} -> (address, hex_address))
        (fun (address, hex_address) -> {address; hex_address})
        (obj2 (req "address" string) (req "hex_address" string)))

  let tvalue_of_r {address; hex_address} =
    Tobj [("address", Tstr address); ("hex_address", Tstr hex_address)]

  let expand ~self ~run args =
    let client_base = expand_client_base_args ~self ~run args.client_base in
    let wallet = run args.wallet in
    let alias = run args.alias in
    let src = run args.src in
    let script_path =
      Remote_procedure.global_uri_of_string ~self ~run args.script_path
    in
    let init = run args.init in
    let wait = run args.wait in
    {
      client_base;
      wallet;
      alias;
      src;
      script_path;
      amount = args.amount;
      init;
      wait;
    }

  let resolve ~self resolver args =
    let client_base =
      resolve_client_args_base ~self resolver args.client_base
    in
    let script_path =
      Remote_procedure.file_agent_uri ~self ~resolver args.script_path
    in
    {args with client_base; script_path}

  let run state args =
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.client_base.path_client
    in
    let endpoint = octez_endpoint state args.client_base.endpoint in

    let client =
      Client.create ~path:path_client ~endpoint ~base_dir:args.wallet ()
    in

    let* script_path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.script_path
    in

    let script = read_file script_path in

    let* address =
      Client.originate_contract
        client
        ~wait:args.wait
        ~alias:args.alias
        ~src:args.src
        ~prg:script
        ~burn_cap:(Tez.of_int 2)
        ~amount:args.amount
        ~init:args.init
    in
    Log.info "Contract %s originated" address ;
    let (`Hex hex_address) =
      H.(of_b58check_exn address |> to_string |> Hex.of_string)
    in
    return {address; hex_address}

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_
      {address = _; hex_address = _} =
    ()
end

type 'uri transfer = {
  client_base : 'uri client_base_args;
  wallet : string;
  src : string;
  dst : string;
  amount : Tez.t;
  arg : string option;
  entrypoint : string option;
  wait : string;
}

type (_, _) Remote_procedure.t +=
  | Transfer : 'uri transfer -> (unit, 'uri) Remote_procedure.t

module Transfer = struct
  let name = "tezos.operations.transfer"

  type 'uri t = 'uri transfer

  type r = unit

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Transfer args -> Some args
    | _ -> None

  let to_remote_procedure args = Transfer args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Transfer _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {client_base; wallet; src; dst; amount; entrypoint; arg; wait} ->
          (client_base, (wallet, src, dst, amount, entrypoint, arg, wait)))
        (fun (client_base, (wallet, src, dst, amount, entrypoint, arg, wait)) ->
          {client_base; wallet; src; dst; amount; entrypoint; arg; wait})
        (merge_objs
           (client_base_args_encoding uri_encoding)
           (obj7
              (req "wallet" string)
              (req "source" string)
              (req "destination" string)
              (dft "amount" tez_encoding Tez.zero)
              (opt "entrypoint" string)
              (opt "arg" string)
              (dft "wait" string "0"))))

  let r_encoding = Data_encoding.empty

  let tvalue_of_r () = Tnull

  let expand ~self ~run args =
    let client_base = expand_client_base_args ~self ~run args.client_base in
    let wallet = run args.wallet in
    let src = run args.src in
    let dst = run args.dst in
    let arg = Option.map run args.arg in
    let entrypoint = Option.map run args.entrypoint in
    let wait = run args.wait in
    {client_base; wallet; src; dst; amount = args.amount; arg; entrypoint; wait}

  let resolve ~self resolver args =
    let client_base =
      resolve_client_args_base ~self resolver args.client_base
    in
    {args with client_base}

  let run state args =
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.client_base.path_client
    in
    let endpoint = octez_endpoint state args.client_base.endpoint in

    let client =
      Client.create ~path:path_client ~endpoint ~base_dir:args.wallet ()
    in

    let* () =
      Client.transfer
        client
        ~wait:args.wait
        ~giver:args.src
        ~receiver:args.dst
        ~burn_cap:(Tez.of_int 2)
        ~amount:args.amount
        ?arg:args.arg
        ?entrypoint:args.entrypoint
    in

    unit

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ () = ()
end

let () = Remote_procedure.register (module Transfer)

type 'uri start_rollup_node = {
  name : string option;
  path_rollup_node : 'uri;
  path_client : 'uri;
  wallet : string;
  endpoint : 'uri;
  operator : string;
  mode : string;
  address : string;
  data_dir_path : string option;
  rpc_port : string option;
  metrics_port : string option;
  kernel_log_path : string option;
}

type start_rollup_node_r = {name : string; rpc_port : int; metrics_port : int}

type (_, _) Remote_procedure.t +=
  | Start_rollup_node :
      'uri start_rollup_node
      -> (start_rollup_node_r, 'uri) Remote_procedure.t

module Start_rollup_node = struct
  let name = "smart_rollup.start_node"

  type 'uri t = 'uri start_rollup_node

  type r = start_rollup_node_r

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Start_rollup_node args -> Some args
    | _ -> None

  let to_remote_procedure args = Start_rollup_node args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Start_rollup_node _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {
               name;
               path_rollup_node;
               path_client;
               wallet;
               endpoint;
               operator;
               mode;
               address;
               data_dir_path;
               rpc_port;
               metrics_port;
               kernel_log_path;
             } ->
          ( ( name,
              path_rollup_node,
              path_client,
              wallet,
              endpoint,
              operator,
              mode,
              address,
              data_dir_path,
              rpc_port ),
            (metrics_port, kernel_log_path) ))
        (fun ( ( name,
                 path_rollup_node,
                 path_client,
                 wallet,
                 endpoint,
                 operator,
                 mode,
                 address,
                 data_dir_path,
                 rpc_port ),
               (metrics_port, kernel_log_path) ) ->
          {
            name;
            path_rollup_node;
            path_client;
            wallet;
            endpoint;
            operator;
            mode;
            address;
            data_dir_path;
            rpc_port;
            metrics_port;
            kernel_log_path;
          })
        (merge_objs
           (obj10
              (opt "name" string)
              (req "path_rollup_node" uri_encoding)
              (req "path_client" uri_encoding)
              (req "wallet" string)
              (req "endpoint" uri_encoding)
              (req "operator" string)
              (req "mode" string)
              (req "address" string)
              (opt "data_dir_path" string)
              (opt "rpc_port" string))
           (obj2 (opt "metrics_port" string) (opt "kernel_log_path" string))))

  let r_encoding =
    Data_encoding.(
      conv
        (fun ({rpc_port; metrics_port; name} : r) ->
          (rpc_port, metrics_port, name))
        (fun (rpc_port, metrics_port, name) -> {rpc_port; metrics_port; name})
        (obj3
           (req "rpc_port" int31)
           (req "metrics_port" int31)
           (req "name" string)))

  let tvalue_of_r ({rpc_port; metrics_port; name} : r) =
    Tobj
      [
        ("rpc_port", Tint rpc_port);
        ("metrics_port", Tint metrics_port);
        ("name", Tstr name);
      ]

  let expand ~self ~run (args : _ t) =
    let name = Option.map run args.name in
    let path_rollup_node =
      Remote_procedure.global_uri_of_string ~self ~run args.path_rollup_node
    in
    let path_client =
      Remote_procedure.global_uri_of_string ~self ~run args.path_client
    in
    let wallet = run args.wallet in
    let endpoint =
      Remote_procedure.global_uri_of_string ~self ~run args.endpoint
    in
    let operator = run args.operator in
    let mode = run args.mode in
    let address = run args.address in
    let data_dir_path = Option.map run args.data_dir_path in
    let rpc_port = Option.map run args.rpc_port in
    let metrics_port = Option.map run args.metrics_port in
    let kernel_log_path = Option.map run args.kernel_log_path in
    {
      name;
      path_rollup_node;
      path_client;
      wallet;
      endpoint;
      operator;
      mode;
      address;
      data_dir_path;
      rpc_port;
      metrics_port;
      kernel_log_path;
    }

  let resolve ~self resolver args =
    let path_rollup_node =
      Remote_procedure.file_agent_uri ~self ~resolver args.path_rollup_node
    in
    let path_client =
      Remote_procedure.file_agent_uri ~self ~resolver args.path_client
    in
    let endpoint = resolve_octez_rpc_global_uri ~self ~resolver args.endpoint in
    {args with path_rollup_node; path_client; endpoint}

  let run state args =
    let* path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_rollup_node
    in
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_client
    in
    let l1_endpoint = octez_endpoint state args.endpoint in
    let metrics_port =
      match args.metrics_port with
      | Some x -> int_of_string x
      | _ -> Port.fresh ()
    in
    let rollup_node =
      Sc_rollup_node.(
        create_with_endpoint
          ?name:args.name
          ~rpc_host:"0.0.0.0"
          ?data_dir:args.data_dir_path
          ?rpc_port:(Option.map int_of_string args.rpc_port)
          ~path
          (mode_of_string args.mode)
          ~default_operator:args.operator
          l1_endpoint
          ~base_dir:args.wallet)
    in
    let kernel_log_args =
      match args.kernel_log_path with
      | Some path -> ["--log-kernel-debug"; "--log-kernel-debug-file"; path]
      | None -> []
    in
    let* () =
      Sc_rollup_node.run rollup_node args.address
      @@ ["--metrics-addr"; sf "0.0.0.0:%d" metrics_port]
      @ kernel_log_args
    in

    let* _ = Sc_rollup_node.unsafe_wait_sync ~path_client rollup_node in
    Agent_state.add
      (Rollup_node_k (Sc_rollup_node.name rollup_node))
      rollup_node
      state ;
    return
      {
        name = Sc_rollup_node.name rollup_node;
        rpc_port = Sc_rollup_node.rpc_port rollup_node;
        metrics_port;
      }

  let on_completion ~on_new_service ~on_new_metrics_source (res : r) =
    let open Services_cache in
    on_new_service res.name Rollup_node Rpc res.rpc_port ;
    on_new_service res.name Rollup_node Metrics res.metrics_port ;
    on_new_metrics_source res.name Octez_node res.metrics_port
end

type 'uri prepare_kernel_installer = {
  installer_generator_path : 'uri;
  kernel_path : 'uri;
  preimage_directory_path : string;
  installer_kernel_path : string;
  setup : string option;
}

type (_, _) Remote_procedure.t +=
  | Prepare_kernel_installer :
      'uri prepare_kernel_installer
      -> (unit, 'uri) Remote_procedure.t

module Prepare_kernel_installer = struct
  let name = "smart_rollup.prepare_kernel_installer"

  type 'uri t = 'uri prepare_kernel_installer

  type r = unit

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Prepare_kernel_installer args -> Some args
    | _ -> None

  let to_remote_procedure args = Prepare_kernel_installer args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Prepare_kernel_installer _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {
               installer_generator_path;
               kernel_path;
               preimage_directory_path;
               installer_kernel_path;
               setup;
             } ->
          ( installer_generator_path,
            kernel_path,
            preimage_directory_path,
            installer_kernel_path,
            setup ))
        (fun ( installer_generator_path,
               kernel_path,
               preimage_directory_path,
               installer_kernel_path,
               setup ) ->
          {
            installer_generator_path;
            kernel_path;
            preimage_directory_path;
            installer_kernel_path;
            setup;
          })
        (obj5
           (req "installer_generator_path" uri_encoding)
           (req "kernel_path" uri_encoding)
           (req "preimages_directory_path" string)
           (req "installer_kernel_path" string)
           (opt "setup" string)))

  let r_encoding = Data_encoding.empty

  let tvalue_of_r () = Tnull

  let expand ~self ~run args =
    let installer_generator_path =
      Remote_procedure.global_uri_of_string
        ~self
        ~run
        args.installer_generator_path
    in
    let kernel_path =
      Remote_procedure.global_uri_of_string ~self ~run args.kernel_path
    in
    let preimage_directory_path = run args.preimage_directory_path in
    let installer_kernel_path = run args.installer_kernel_path in
    let setup = Option.map run args.setup in
    {
      installer_generator_path;
      kernel_path;
      preimage_directory_path;
      installer_kernel_path;
      setup;
    }

  let resolve ~self resolver args =
    let installer_generator_path =
      Remote_procedure.file_agent_uri
        ~self
        ~resolver
        args.installer_generator_path
    in
    let kernel_path =
      Remote_procedure.file_agent_uri ~self ~resolver args.kernel_path
    in
    {args with kernel_path; installer_generator_path}

  let run state args =
    assert (Filename.is_relative args.installer_kernel_path) ;
    assert (Filename.is_relative args.preimage_directory_path) ;
    let* installer_generator_path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.installer_generator_path
    in
    let* kernel_path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.kernel_path
    in
    let preimage_dir = args.preimage_directory_path // "wasm_2_0_0" in
    let* () = Helpers.mkdir ~p:true preimage_dir in
    let* () = Helpers.mkdir ~p:true (Filename.dirname kernel_path) in
    let setup_file =
      match args.setup with
      | Some contents ->
          let path = Temp.file "setup_file" in
          write_file path ~contents ;
          ["-S"; path]
      | _ -> []
    in

    let* () =
      Helpers.exec installer_generator_path
      @@ [
           "get-reveal-installer";
           "-u";
           kernel_path;
           "-P";
           preimage_dir;
           "-o";
           args.installer_kernel_path;
         ]
      @ setup_file
    in
    unit

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ () = ()
end

type 'uri message =
  | Text : string -> 'uri message
  | Hex : string -> 'uri message
  | File : 'uri -> 'uri message

let message_encoding (type uri) (uri_encoding : uri Data_encoding.t) :
    uri message Data_encoding.t =
  let c = Helpers.make_mk_case () in
  Data_encoding.(
    union
      [
        c.mk_case
          "text"
          (obj1 (req "text" string))
          (function Text str -> Some str | _ -> None)
          (fun str -> Text str);
        c.mk_case
          "hex"
          (obj1 (req "hex" string))
          (function (Hex str : uri message) -> Some str | _ -> None)
          (fun str -> Hex str);
        c.mk_case
          "file"
          (obj1 (req "file" uri_encoding))
          (function File uri -> Some uri | _ -> None)
          (fun uri -> File uri);
      ])

let message_maximum_size = 4_095

let expand_message ~self ~run = function
  | Text str ->
      let str = run str in
      assert (String.length str <= 4_095) ;
      Text str
  | Hex str ->
      let str = run str in
      assert (String.length str <= 4_095 * 2) ;
      assert (str =~ rex {|^[a-f0-9]+$|}) ;
      Hex str
  | File uri ->
      let uri = Remote_procedure.global_uri_of_string ~self ~run uri in
      File uri

let resolve_message ~self resolver = function
  | Text str -> Text str
  | Hex str -> Hex str
  | File uri -> File (Remote_procedure.file_agent_uri ~self ~resolver uri)

let octez_client_arg_of_message state = function
  | Text str ->
      let (`Hex str) = Hex.of_string str in
      assert (String.length str <= message_maximum_size * 2) ;
      return str
  | Hex str ->
      assert (String.length str <= message_maximum_size * 2) ;
      return str
  | File uri ->
      let* path =
        Http_client.local_path_from_agent_uri
          (Agent_state.http_client state)
          uri
      in
      let contents = read_file path in
      let (`Hex str) = Hex.of_string contents in
      assert (String.length str <= message_maximum_size * 2) ;
      return str

type 'uri smart_rollups_add_messages = {
  client_base : 'uri client_base_args;
  wallet : string;
  source : string;
  messages : 'uri message list;
  wait : string;
}

type (_, _) Remote_procedure.t +=
  | Smart_rollups_add_messages :
      'uri smart_rollups_add_messages
      -> (unit, 'uri) Remote_procedure.t

module Smart_rollups_add_messages = struct
  let name = "tezos.operations.add_messages"

  type 'uri t = 'uri smart_rollups_add_messages

  type r = unit

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Smart_rollups_add_messages args -> Some args
    | _ -> None

  let to_remote_procedure args = Smart_rollups_add_messages args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Smart_rollups_add_messages _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {client_base; wallet; source; messages; wait} ->
          (client_base, (wallet, source, messages, wait)))
        (fun (client_base, (wallet, source, messages, wait)) ->
          {client_base; wallet; source; messages; wait})
        (merge_objs
           (client_base_args_encoding uri_encoding)
           (obj4
              (req "wallet" string)
              (req "source" string)
              (req "messages" (list (message_encoding uri_encoding)))
              (dft "wait" string "0"))))

  let r_encoding = Data_encoding.empty

  let tvalue_of_r () = Tnull

  let expand ~self ~run args =
    let client_base = expand_client_base_args ~self ~run args.client_base in
    let wallet = run args.wallet in
    let source = run args.source in
    let messages = List.map (expand_message ~self ~run) args.messages in
    let wait = run args.wait in
    {client_base; wallet; source; messages; wait}

  let resolve ~self resolver args =
    let client_base =
      resolve_client_args_base ~self resolver args.client_base
    in
    let messages = List.map (resolve_message ~self resolver) args.messages in
    {args with client_base; messages}

  let run state args =
    let* messages =
      Lwt_list.map_p
        (fun m ->
          let* str = octez_client_arg_of_message state m in
          return (`String str))
        args.messages
    in
    let payload = "hex:" ^ Ezjsonm.to_string (`A messages) in

    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.client_base.path_client
    in
    let endpoint = octez_endpoint state args.client_base.endpoint in

    let client =
      Client.create ~path:path_client ~base_dir:args.wallet ~endpoint ()
    in
    Client.Sc_rollup.send_message
      ~wait:args.wait
      ~msg:payload
      ~src:args.source
      client

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ _args = ()
end

type 'uri dac_mode =
  | Coordinator of {committee_members_aliases : string list}
  | Member of {coordinator : 'uri; alias : string}
  | Observer of {
      coordinator : 'uri;
      committee_members : 'uri list;
      reveal_data_dir_path : string;
    }

let dac_mode_encoding uri_encoding =
  let c = Helpers.make_mk_case () in
  Data_encoding.(
    union
      [
        c.mk_case
          "coordinator"
          (obj2
             (req "mode" (constant "coordinator"))
             (req "committee_members_aliases" (list string)))
          (function
            | Coordinator {committee_members_aliases} ->
                Some ((), committee_members_aliases)
            | _ -> None)
          (fun ((), committee_members_aliases) ->
            Coordinator {committee_members_aliases});
        c.mk_case
          "member"
          (obj3
             (req "mode" (constant "member"))
             (req "alias" string)
             (req "coordinator" uri_encoding))
          (function
            | Member {alias; coordinator} -> Some ((), alias, coordinator)
            | _ -> None)
          (fun ((), alias, coordinator) -> Member {alias; coordinator});
        c.mk_case
          "observer"
          (obj4
             (req "mode" (constant "observer"))
             (req "coordinator" uri_encoding)
             (req "committee_members" (list uri_encoding))
             (req "reveal_data_dir_path" string))
          (function
            | Observer {coordinator; committee_members; reveal_data_dir_path} ->
                Some ((), coordinator, committee_members, reveal_data_dir_path)
            | _ -> None)
          (fun ((), coordinator, committee_members, reveal_data_dir_path) ->
            Observer {coordinator; committee_members; reveal_data_dir_path});
      ])

let expand_dac_mode ~self ~run = function
  | Coordinator {committee_members_aliases} ->
      let committee_members_aliases = List.map run committee_members_aliases in
      Coordinator {committee_members_aliases}
  | Member {alias; coordinator} ->
      let alias = run alias in
      let coordinator =
        Remote_procedure.global_uri_of_string ~self ~run coordinator
      in
      Member {alias; coordinator}
  | Observer {coordinator; committee_members; reveal_data_dir_path} ->
      let coordinator =
        Remote_procedure.global_uri_of_string ~self ~run coordinator
      in
      let committee_members =
        List.map
          (Remote_procedure.global_uri_of_string ~self ~run)
          committee_members
      in
      let reveal_data_dir_path = run reveal_data_dir_path in
      Observer {coordinator; committee_members; reveal_data_dir_path}

let resolve_dac_mode ~self resolver = function
  | Coordinator args -> Coordinator args
  | Member args ->
      let coordinator =
        resolve_dac_rpc_global_uri ~self ~resolver args.coordinator
      in
      Member {args with coordinator}
  | Observer {coordinator; committee_members; reveal_data_dir_path} ->
      let coordinator =
        resolve_dac_rpc_global_uri ~self ~resolver coordinator
      in
      let committee_members =
        List.map (resolve_dac_rpc_global_uri ~self ~resolver) committee_members
      in
      Observer {coordinator; committee_members; reveal_data_dir_path}

type 'uri start_dac_node = {
  path_dac_node : 'uri;
  path_client : 'uri;
  endpoint : 'uri;
  name : string option;
  wallet : string;
  rpc_port : string option;
  mode : 'uri dac_mode;
}

type start_dac_node_r = {name : string; rpc_port : int}

type (_, _) Remote_procedure.t +=
  | Start_dac_node :
      'uri start_dac_node
      -> (start_dac_node_r, 'uri) Remote_procedure.t

module Start_dac_node = struct
  let name = "dac.start_node"

  type 'uri t = 'uri start_dac_node

  type r = start_dac_node_r

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {
               path_dac_node;
               path_client;
               endpoint;
               name;
               wallet;
               rpc_port;
               mode;
             } ->
          (path_dac_node, path_client, endpoint, name, wallet, rpc_port, mode))
        (fun (path_dac_node, path_client, endpoint, name, wallet, rpc_port, mode)
             ->
          {path_dac_node; path_client; endpoint; name; wallet; rpc_port; mode})
        (obj7
           (req "path_dac_node" uri_encoding)
           (req "path_client" uri_encoding)
           (req "endpoint" uri_encoding)
           (opt "name" string)
           (req "wallet" string)
           (opt "rpc_port" string)
           (req "settings" (dac_mode_encoding uri_encoding))))

  let r_encoding =
    Data_encoding.(
      conv
        (fun {rpc_port; name} -> (rpc_port, name))
        (fun (rpc_port, name) -> {rpc_port; name})
        (obj2 (req "rpc_port" int31) (req "name" string)))

  let tvalue_of_r res =
    Tobj [("rpc_port", Tint res.rpc_port); ("name", Tstr res.name)]

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Start_dac_node args -> Some args
    | _ -> None

  let to_remote_procedure args = Start_dac_node args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Start_dac_node _ -> Eq
    | _ -> Neq

  let expand ~self ~run (args : _ t) =
    let name = Option.map run args.name in
    let path_dac_node =
      Remote_procedure.global_uri_of_string ~self ~run args.path_dac_node
    in
    let path_client =
      Remote_procedure.global_uri_of_string ~self ~run args.path_client
    in
    let endpoint =
      Remote_procedure.global_uri_of_string ~self ~run args.endpoint
    in
    let wallet = run args.wallet in
    let rpc_port = Option.map run args.rpc_port in
    let mode = expand_dac_mode ~self ~run args.mode in
    {name; path_dac_node; path_client; endpoint; wallet; rpc_port; mode}

  let resolve ~self resolver args =
    let path_dac_node =
      Remote_procedure.file_agent_uri ~self ~resolver args.path_dac_node
    in
    let path_client =
      Remote_procedure.file_agent_uri ~self ~resolver args.path_client
    in
    let endpoint = resolve_octez_rpc_global_uri ~self ~resolver args.endpoint in
    let mode = resolve_dac_mode ~self resolver args.mode in
    {args with path_dac_node; path_client; endpoint; mode}

  let run state args =
    let* path_dac_node =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_dac_node
    in
    let* path_client =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.path_client
    in
    let rpc_port =
      match args.rpc_port with
      | Some port_str -> int_of_string port_str
      | None -> Port.fresh ()
    in
    let endpoint = octez_endpoint state args.endpoint in
    let client =
      Client.create ~path:path_client ~base_dir:args.wallet ~endpoint ()
    in
    let* dac_node =
      match args.mode with
      | Coordinator {committee_members_aliases} ->
          let* committee_members =
            Lwt_list.map_p
              (fun name ->
                let* account = Client.bls_show_address client ~alias:name in
                return account.aggregate_public_key)
              committee_members_aliases
          in
          let dac_node =
            Dac_node.create_coordinator_with_endpoint
              ~path:path_dac_node
              ~rpc_host:"0.0.0.0"
              ~rpc_port
              ?name:args.name
              ~client
              ~endpoint
              ~committee_members
              ()
          in
          Agent_state.add
            (Dac_node_k (`Coordinator, Dac_node.name dac_node))
            dac_node
            state ;
          return dac_node
      | Member {alias; coordinator} ->
          let* member_account = Client.bls_show_address client ~alias in
          let coordinator_rpc_host, coordinator_rpc_port =
            dac_rpc_info state `Coordinator coordinator
          in
          let dac_node =
            Dac_node.create_committee_member_with_endpoint
              ~path:path_dac_node
              ~rpc_host:"0.0.0.0"
              ~rpc_port
              ?name:args.name
              ~client
              ~endpoint
              ~address:member_account.aggregate_public_key_hash
              ~coordinator_rpc_host
              ~coordinator_rpc_port
              ()
          in
          Agent_state.add
            (Dac_node_k (`Member, Dac_node.name dac_node))
            dac_node
            state ;
          return dac_node
      | Observer {coordinator; committee_members; reveal_data_dir_path} ->
          let coordinator_rpc_host, coordinator_rpc_port =
            dac_rpc_info state `Coordinator coordinator
          in
          let committee_member_rpcs =
            List.map (dac_rpc_info state `Member) committee_members
          in
          let dac_node =
            Dac_node.create_observer_with_endpoint
              ~path:path_dac_node
              ~rpc_host:"0.0.0.0"
              ?name:args.name
              ~client
              ~endpoint
              ~coordinator_rpc_host
              ~coordinator_rpc_port
              ~committee_member_rpcs
              ~reveal_data_dir:reveal_data_dir_path
              ()
          in
          Agent_state.add
            (Dac_node_k (`Observer, Dac_node.name dac_node))
            dac_node
            state ;
          return dac_node
    in

    let* _dir = Dac_node.init_config dac_node in
    let* () = Dac_node.run dac_node in
    return
      {name = Dac_node.name dac_node; rpc_port = Dac_node.rpc_port dac_node}

  let on_completion ~on_new_service ~on_new_metrics_source:_ res =
    on_new_service res.name Dac_node Rpc res.rpc_port
end

type 'uri dac_post_file = {
  dac_client_path : 'uri;
  coordinator : 'uri;
  file_path : 'uri;
  wallet : string;
  threshold : int;
}

type dac_post_file_r = {certificate : Hex.t}

type (_, _) Remote_procedure.t +=
  | Dac_post_file :
      'uri dac_post_file
      -> (dac_post_file_r, 'uri) Remote_procedure.t

module Dac_post_file = struct
  let name = "dac.post_file"

  type 'uri t = 'uri dac_post_file

  type r = dac_post_file_r

  let of_remote_procedure :
      type a. (a, 'uri) Remote_procedure.t -> 'uri t option = function
    | Dac_post_file args -> Some args
    | _ -> None

  let to_remote_procedure args = Dac_post_file args

  let unify : type a. (a, 'uri) Remote_procedure.t -> (a, r) Remote_procedure.eq
      = function
    | Dac_post_file _ -> Eq
    | _ -> Neq

  let encoding uri_encoding =
    Data_encoding.(
      conv
        (fun {dac_client_path; coordinator; file_path; wallet; threshold} ->
          (dac_client_path, coordinator, file_path, wallet, threshold))
        (fun (dac_client_path, coordinator, file_path, wallet, threshold) ->
          {dac_client_path; coordinator; file_path; wallet; threshold})
        (obj5
           (req "dac_client_path" uri_encoding)
           (req "coordinator" uri_encoding)
           (req "file_path" uri_encoding)
           (req "wallet" string)
           (req "threshold" int31)))

  let r_encoding =
    Data_encoding.(
      conv
        (fun {certificate = `Hex s} -> s)
        (fun s -> {certificate = `Hex s})
        (obj1 (req "certificate" string)))

  let tvalue_of_r {certificate = `Hex s} = Tobj [("certificate", Tstr s)]

  let expand ~self ~run args =
    let dac_client_path =
      Remote_procedure.global_uri_of_string ~self ~run args.dac_client_path
    in
    let file_path =
      Remote_procedure.global_uri_of_string ~self ~run args.file_path
    in
    let coordinator =
      Remote_procedure.global_uri_of_string ~self ~run args.coordinator
    in
    let wallet = run args.wallet in
    {args with dac_client_path; wallet; coordinator; file_path}

  let resolve ~self resolver args =
    let dac_client_path =
      Remote_procedure.file_agent_uri ~self ~resolver args.dac_client_path
    in
    let file_path =
      Remote_procedure.file_agent_uri ~self ~resolver args.file_path
    in
    let coordinator =
      resolve_dac_rpc_global_uri ~self ~resolver args.coordinator
    in
    {args with dac_client_path; file_path; coordinator}

  let run state args =
    let* client_path =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.dac_client_path
    in
    let endpoint = dac_endpoint state `Coordinator args.coordinator in
    let client =
      Dac_client.create_with_endpoint
        ~path:client_path
        ~base_dir:args.wallet
        endpoint
    in
    let* file =
      Http_client.local_path_from_agent_uri
        (Agent_state.http_client state)
        args.file_path
    in
    let* output =
      Dac_client.send_payload_from_file client file ~threshold:args.threshold
    in
    match output with
    | Certificate hex -> return {certificate = hex}
    | _ -> Test.fail "Should be a certificate"

  let on_completion ~on_new_service:_ ~on_new_metrics_source:_ _res = ()
end

let register_procedures () =
  Remote_procedure.register (module Start_octez_node) ;
  Remote_procedure.register (module Activate_protocol) ;
  Remote_procedure.register (module Wait_for_bootstrapped) ;
  Remote_procedure.register (module Originate_smart_rollup) ;
  Remote_procedure.register (module Originate_smart_contract) ;
  Remote_procedure.register (module Start_rollup_node) ;
  Remote_procedure.register (module Prepare_kernel_installer) ;
  Remote_procedure.register (module Smart_rollups_add_messages) ;
  Remote_procedure.register (module Start_dac_node) ;
  Remote_procedure.register (module Dac_post_file)
