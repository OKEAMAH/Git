let transaction_source = Account.Bootstrap.keys.(0).public_key_hash

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
  let injector = Injector.create node client in
  let* () = Injector.run injector in

  let* () = Lwt_unix.sleep 1. in
  let* () = Client.bake_for client in
  let* _inj_operation_hash =
    RPC.call injector
    @@ Injector.RPC.inject
         193L
         "tz1XQjK1b3P72kMcHsoPhnAg3dvX1n8Ainty"
         transaction_source
  in
  let* () = Client.bake_for client in

  unit

let register ~protocols = test_injector protocols
