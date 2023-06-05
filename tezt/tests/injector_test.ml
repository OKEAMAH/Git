let test_injector : Protocol.t list -> unit =
  Protocol.register_test
    ~__FILE__
    ~title:"Injector daemon"
    ~tags:["bin_injector"]
  @@ fun protocol ->
  (* I have to set the RPC port to this value, which seems hardcoded somewhere in the *)
  (* guts of the injector, need to figure out where *)
  let* node =
    Node.init ~rpc_port:8732 [Synchronisation_threshold 0; Private_mode]
  in
  let* client = Client.init ~endpoint:(Node node) () in
  let* () = Client.activate_protocol ~protocol client in
  let injector = Injector.create node in
  let* () = Injector.run injector in
  let* () = Lwt_unix.sleep 1. in
  let* b = RPC.call injector @@ Injector.RPC.inject (Bytes.of_string "op") in
  assert b ;
  unit

let register ~protocols = test_injector protocols
