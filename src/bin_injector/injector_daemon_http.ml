(* open Injector_messages *)

module Events = struct
  include Internal_event.Simple

  let section = ["injector"; "http"]

  let listening =
    declare_1
      ~section
      ~level:Notice
      ~name:"signer_listening"
      ~msg:"listening on address: {address}"
      ("address", P2p_addr.encoding)

  let accepting_requests =
    declare_2
      ~section
      ~level:Notice
      ~name:"accepting_requests"
      ~msg:"accepting {transport_protocol} requests on port {port}"
      ("transport_protocol", Data_encoding.string)
      ("port", Data_encoding.int31)
end

let start ~rpc_address ~rpc_port () =
  let open Lwt_result_syntax in
  let dir = Tezos_rpc.Directory.empty in
  let dir =
    Tezos_rpc.Directory.register0 dir Injector_messages.inject (fun () _n ->
        return_true)
  in
  let rpc_address = P2p_addr.of_string_exn rpc_address in
  let mode = `TCP (`Port rpc_port) in
  let acl = RPC_server.Acl.allow_all in
  let server =
    RPC_server.init_server dir ~acl ~media_types:Media_type.all_media_types
  in
  Lwt.catch
    (fun () ->
      let*! () = Events.(emit listening) rpc_address in
      let*! () =
        RPC_server.launch
          ~host:(Ipaddr.V6.to_string rpc_address)
          server
          ~callback:(RPC_server.resto_callback server)
          mode
      in
      Lwt_utils.never_ending ())
    (function
      | Unix.Unix_error (Unix.EADDRINUSE, "bind", "") ->
          failwith "Port already in use."
      | exn -> fail_with_exn exn)

let run ~rpc_address ~rpc_port
    (cctxt : Client_context.full) (* (configuration : Configuration.t)  *) =
  let open Lwt_result_syntax in
  let data_dir = "" in
  let signers = [] in
  let state : Injector.state =
    {cctxt; minimal_block_delay = 15L; delay_increment_per_round = 8L}
  in
  let* () = Injector.init cctxt ~data_dir state ~signers in
  let*! () = Events.(emit accepting_requests) ("HTTP", rpc_port) in
  start ~rpc_address ~rpc_port ()
