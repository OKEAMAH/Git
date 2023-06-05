let default_tcp_host =
  match Sys.getenv_opt "TEZOS_INJECTOR_TCP_HOST" with
  | None -> "127.0.0.1"
  | Some host -> host

let default_http_port =
  match Sys.getenv_opt "TEZOS_INJECTOR_HTTP_PORT" with
  | None -> "6734"
  | Some port -> port

let group =
  {
    Tezos_clic.name = "octez-injector";
    title = "Commands related to the injector server";
  }

let commands : Client_context.full Tezos_clic.command list =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  [
    command
      ~group
      ~desc:"Run the injector server"
      (args2
         (default_arg
            ~doc:"listening address or host name"
            ~short:'a'
            ~long:"address"
            ~placeholder:"host|address"
            ~default:default_tcp_host
            (parameter (fun _ s -> return s)))
         (default_arg
            ~doc:"listening HTTP port"
            ~short:'p'
            ~long:"port"
            ~placeholder:"port number"
            ~default:default_http_port
            (parameter (fun _ x ->
                 try return (int_of_string x)
                 with Failure _ -> failwith "Invalid port %s" x))))
      (prefixes ["run"] @@ stop)
      (fun (rpc_address, rpc_port) cctxt ->
        Injector_daemon_http.run ~rpc_address ~rpc_port cctxt);
  ]

let select_commands _ _ =
  let open Lwt_result_syntax in
  return commands

let () = Client_main_run.run (module Client_config) ~select_commands
