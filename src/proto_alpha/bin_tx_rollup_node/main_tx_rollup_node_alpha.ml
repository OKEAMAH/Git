(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2021 Marigold, <team@marigold.dev>                          *)
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

let data_dir_doc =
  Format.sprintf
    "The path to the transaction rollup node data directory. Default value is \
     %s"

let rpc_addr_doc =
  Format.asprintf "The address the node listens. Default value is %s"

let rpc_port_doc =
  Format.asprintf "The port the node listens. Default value is %d"

let data_dir_arg =
  let default = Configuration.default_data_dir in
  let doc = data_dir_doc default in
  Clic.default_arg
    ~long:"data-dir"
    ~placeholder:"data_dir"
    ~doc
    ~default
    Client_proto_args.string_parameter

let operator_arg =
  let doc = "" in
  Clic.arg
    ~long:"operator"
    ~placeholder:"public_key"
    ~doc
    (Clic.parameter (fun _ -> Client_keys.Public_key_hash.of_source))

let rollup_id_arg =
  Clic.arg
    ~long:"rollup-id"
    ~placeholder:"rollup_id"
    ~doc:"The rollup id of the rollup to target"
    (Clic.parameter (fun _ s ->
         match Protocol.Alpha_context.Tx_rollup.of_b58check s with
         | Ok x -> return x
         | Error _ -> failwith "Invalid Rollup Id"))

let block_hash_arg =
  Clic.arg
    ~long:"block-hash"
    ~placeholder:"block_hash"
    ~doc:"The hash of the block wherein the rollup was created"
    (Clic.parameter (fun _ str ->
         Option.fold_f
           ~none:(fun () -> failwith "Invalid Block Hash")
           ~some:return
         @@ Block_hash.of_b58check_opt str))

let rpc_addr_arg =
  let default = Configuration.default_rpc_addr in
  let doc = rpc_addr_doc default in
  Clic.default_arg
    ~long:"rpc-addr"
    ~placeholder:"address|ip"
    ~doc
    ~default
    Client_proto_args.string_parameter

let rpc_port_arg =
  let default = Configuration.default_rpc_port in
  let doc = rpc_port_doc default in
  Clic.default_arg
    ~long:"rpc-port"
    ~placeholder:"port"
    ~doc
    ~default:(string_of_int default)
    Client_proto_args.int_parameter

let group =
  Clic.
    {
      name = "tx_rollup.node";
      title = "Commands related to the transaction rollup node";
    }

let to_tzresult msg = function
  | Some x -> Error_monad.return x
  | None -> Error_monad.failwith msg

let configuration_init_command =
  let open Clic in
  command
    ~group
    ~desc:"Configure the transaction rollup daemon."
    (args6
       data_dir_arg
       operator_arg
       rollup_id_arg
       block_hash_arg
       rpc_addr_arg
       rpc_port_arg)
    (prefixes ["config"; "init"; "on"] @@ stop)
    (fun (data_dir, client_keys, rollup_id, block_hash, rpc_addr, rpc_port)
         cctxt ->
      let open Lwt_result_syntax in
      let* client_keys = to_tzresult "Missing arg --operator" client_keys in
      let* rollup_id = to_tzresult "Missing arg --rollup_id" rollup_id in
      let* block_hash = to_tzresult "Missing arg --block_hash" block_hash in
      let config =
        Configuration.
          {data_dir; client_keys; rollup_id; block_hash; rpc_addr; rpc_port}
      in
      let file = Configuration.get_configuration_filename config in
      let* () = Configuration.save config in
      (* Necessary since the node is not launched so we can't relay on event listening. *)
      cctxt#message "Configuration written in %s" file >>= fun _ ->
      Event.configuration_written ~into:file ~config)

let run_command =
  let open Clic in
  command
    ~group
    ~desc:"Run the transaction rollup daemon."
    (args1 data_dir_arg)
    (prefixes ["run"] @@ stop)
    (fun data_dir cctxt -> Daemon.run ~data_dir cctxt)

let tx_rollup_commands () =
  List.map
    (Clic.map_command (new Protocol_client_context.wrap_full))
    [configuration_init_command; run_command]

let select_commands _ _ =
  return (tx_rollup_commands () @ Client_helpers_commands.commands ())

let () = Client_main_run.run (module Client_config) ~select_commands
