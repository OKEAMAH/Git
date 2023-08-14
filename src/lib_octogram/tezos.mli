type start_octez_node_r = {
  name : string;
  rpc_port : int;
  metrics_port : int;
  net_port : int;
}

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

type 'uri activate_protocol = {
  endpoint : 'uri;
  path_client : 'uri;
  protocol : string;
  parameter_file : 'uri;
}

type 'uri client_base_args = {path_client : 'uri; endpoint : 'uri}

type 'uri wait_for_bootstrapped = 'uri client_base_args

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

type 'uri prepare_kernel_installer = {
  installer_generator_path : 'uri;
  kernel_path : 'uri;
  preimage_directory_path : string;
  installer_kernel_path : string;
  setup : string option;
}

type 'uri message =
  | Text : string -> 'uri message
  | Hex : string -> 'uri message
  | File : 'uri -> 'uri message

type 'uri smart_rollups_add_messages = {
  client_base : 'uri client_base_args;
  wallet : string;
  source : string;
  messages : 'uri message list;
  wait : string;
}

type (_, _) Remote_procedure.t +=
  | Start_octez_node :
      'uri start_octez_node
      -> (start_octez_node_r, 'uri) Remote_procedure.t
  | Wait_for_bootstrapped :
      'uri wait_for_bootstrapped
      -> (unit, 'uri) Remote_procedure.t
  | Originate_smart_rollup :
      'uri originate_smart_rollup
      -> (originate_smart_rollup_r, 'uri) Remote_procedure.t
  | Start_rollup_node :
      'uri start_rollup_node
      -> (start_rollup_node_r, 'uri) Remote_procedure.t
  | Prepare_kernel_installer :
      'uri prepare_kernel_installer
      -> (unit, 'uri) Remote_procedure.t
  | Smart_rollups_add_messages :
      'uri smart_rollups_add_messages
      -> (unit, 'uri) Remote_procedure.t

val register_procedures : unit -> unit
