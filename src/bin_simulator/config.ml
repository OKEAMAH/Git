type chain_name = Distributed_db_version.Name.t

type blockchain_network = {
  alias : string option;
  genesis : Genesis.t;
  genesis_parameters : Genesis.Parameters.t option;
  chain_name : chain_name;
  old_chain_name : chain_name option;
  incompatible_chain_name : chain_name option;
  sandboxed_chain_name : chain_name;
  user_activated_upgrades : User_activated.upgrades;
  user_activated_protocol_overrides : User_activated.protocol_overrides;
  default_bootstrap_peers : string list;
}

let make_blockchain_network ~alias ~chain_name ?old_chain_name
    ?incompatible_chain_name ~sandboxed_chain_name
    ?(user_activated_upgrades = []) ?(user_activated_protocol_overrides = [])
    ?(default_bootstrap_peers = []) ?genesis_parameters genesis =
  let of_string = Distributed_db_version.Name.of_string in
  {
    alias = Some alias;
    genesis;
    genesis_parameters;
    chain_name = of_string chain_name;
    old_chain_name = Option.map of_string old_chain_name;
    incompatible_chain_name = Option.map of_string incompatible_chain_name;
    sandboxed_chain_name = of_string sandboxed_chain_name;
    user_activated_upgrades =
      List.map
        (fun (l, h) -> (l, Protocol_hash.of_b58check_exn h))
        user_activated_upgrades;
    user_activated_protocol_overrides =
      List.map
        (fun (a, b) ->
          (Protocol_hash.of_b58check_exn a, Protocol_hash.of_b58check_exn b))
        user_activated_protocol_overrides;
    default_bootstrap_peers;
  }

let sandbox_user_activated_upgrades = []

let blockchain_network_sandbox =
  make_blockchain_network
    ~alias:"sandbox"
    {
      time = Time.Protocol.of_notation_exn "2018-06-30T16:07:32Z";
      block =
        Block_hash.of_b58check_exn
          "BLockGenesisGenesisGenesisGenesisGenesisf79b5d1CoW2";
      protocol =
        Protocol_hash.of_b58check_exn
          "ProtoGenesisGenesisGenesisGenesisGenesisGenesk612im";
    }
    ~genesis_parameters:
      (* Genesis public key corresponds to the following private key:
         unencrypted:edsk31vznjHSSpGExDMHYASz45VZqXN4DPxvsa4hAyY8dHM28cZzp6 *)
      {
        context_key = "sandbox_parameter";
        values =
          `O
            [
              ( "genesis_pubkey",
                `String "edpkuSLWfVU1Vq7Jg9FucPyKmma6otcMHac9zG4oU1KMHSTBpJuGQ2"
              );
            ];
      }
    ~chain_name:"TEZOS"
    ~sandboxed_chain_name:"SANDBOXED_TEZOS"
    ~user_activated_upgrades:sandbox_user_activated_upgrades

type t = {
  data_dir : string;
  disable_config_validation : bool;
  p2p : p2p;
  rpc : rpc;
  log : Lwt_log_sink_unix.cfg;
  internal_events : Internal_event_config.t;
  shell : shell;
  blockchain_network : blockchain_network;
  metrics_addr : string list;
}

and p2p = {
  expected_pow : float;
  bootstrap_peers : string list option;
  listen_addr : string option;
  advertised_net_port : int option;
  discovery_addr : string option;
  private_mode : bool;
  limits : P2p_config.limits;
  disable_mempool : bool;
  enable_testchain : bool;
}

and rpc = {
  listen_addrs : string list;
  cors_origins : string list;
  cors_headers : string list;
  tls : tls option;
}

and tls = {cert : string; key : string}

and shell = {
  block_validator_limits : Block_validator.limits;
  prevalidator_limits : Prevalidator.limits;
  peer_validator_limits : Peer_validator.limits;
  chain_validator_limits : Chain_validator.limits;
}

let default_p2p_limits : P2p.limits =
  let greylist_timeout = Time.System.Span.of_seconds_exn 86400. (* one day *) in
  {
    connection_timeout = Time.System.Span.of_seconds_exn 10.;
    authentication_timeout = Time.System.Span.of_seconds_exn 5.;
    greylist_timeout;
    maintenance_idle_time =
      Time.System.Span.of_seconds_exn 120. (* two minutes *);
    min_connections = 10;
    expected_connections = 50;
    max_connections = 100;
    backlog = 20;
    max_incoming_connections = 20;
    max_download_speed = None;
    max_upload_speed = None;
    read_buffer_size = 1 lsl 14;
    read_queue_size = None;
    write_queue_size = None;
    incoming_app_message_queue_size = None;
    incoming_message_queue_size = None;
    outgoing_message_queue_size = None;
    max_known_points = Some (400, 300);
    max_known_peer_ids = Some (400, 300);
    peer_greylist_size = 1023 (* historical value *);
    ip_greylist_size_in_kilobytes =
      2 * 1024 (* two megabytes has shown good properties in simulation *);
    ip_greylist_cleanup_delay = greylist_timeout;
    swap_linger = Time.System.Span.of_seconds_exn 30.;
    binary_chunks_size = None;
  }

let empty_p2p_config : P2p.config =
  {
    listening_addr = None;
    listening_port = None;
    advertised_port = None;
    discovery_addr = None;
    discovery_port = None;
    trusted_points = [];
    peers_file = "";
    private_mode = false;
    reconnection_config = P2p_point_state.Info.default_reconnection_config;
    identity = P2p_identity.generate_with_pow_target_0 ();
    proof_of_work_target = Crypto_box.default_pow_target;
    trust_discovered_peers = true;
  }

let default_p2p =
  {
    expected_pow = 26.;
    bootstrap_peers = None;
    listen_addr = Some ("[::]:" ^ string_of_int 0);
    advertised_net_port = None;
    discovery_addr = None;
    private_mode = false;
    limits = default_p2p_limits;
    disable_mempool = false;
    enable_testchain = false;
  }

let default_rpc =
  {listen_addrs = []; cors_origins = []; cors_headers = []; tls = None}

let default_shell =
  {
    block_validator_limits = Node.default_block_validator_limits;
    prevalidator_limits = Node.default_prevalidator_limits;
    peer_validator_limits = Node.default_peer_validator_limits;
    chain_validator_limits = Node.default_chain_validator_limits;
  }

let default_disable_config_validation = false

let log output =
  let open Lwt_log_sink_unix in
  let level = Tezos_event_logging.Internal_event.Error in
  create_cfg ~output ~default_level:level ()

let config name output =
  {
    data_dir = Format.asprintf "/tmp/%s" name;
    p2p = default_p2p;
    rpc = default_rpc;
    log = log output;
    internal_events = Internal_event_config.default;
    shell = default_shell;
    blockchain_network = blockchain_network_sandbox;
    disable_config_validation = default_disable_config_validation;
    metrics_addr = [];
  }

let node_config config : Node.config =
  let genesis = config.blockchain_network.genesis in
  let patch_context =
    Patch_context.patch_context
      genesis
      (Option.map
         (fun (parameters : Genesis.Parameters.t) ->
           (parameters.context_key, parameters.values))
         config.blockchain_network.genesis_parameters)
  in
  {
    genesis;
    chain_name = config.blockchain_network.chain_name;
    sandboxed_chain_name = config.blockchain_network.sandboxed_chain_name;
    user_activated_upgrades = config.blockchain_network.user_activated_upgrades;
    user_activated_protocol_overrides =
      config.blockchain_network.user_activated_protocol_overrides;
    operation_metadata_size_limit =
      config.shell.block_validator_limits.operation_metadata_size_limit;
    patch_context = Some patch_context;
    data_dir = config.data_dir;
    store_root = Format.asprintf "%s/%s" config.data_dir "store";
    context_root = Format.asprintf "%s/%s" config.data_dir "context";
    protocol_root = Format.asprintf "%s/%s" config.data_dir "protocol";
    p2p = Some (empty_p2p_config, default_p2p_limits);
    target = None;
    enable_testchain = false;
    disable_mempool = false;
  }
