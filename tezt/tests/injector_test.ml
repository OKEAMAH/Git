let transaction_source = Account.Bootstrap.keys.(0).public_key_hash

let transaction_amount = ref 100L

let add_pending_transaction injector =
  let* injector_operation_hash =
    RPC.call injector
    @@ Injector.RPC.add_pending_operation
         !transaction_amount
         "tz1XQjK1b3P72kMcHsoPhnAg3dvX1n8Ainty"
         transaction_source
  in
  transaction_amount := Int64.succ !transaction_amount ;
  return injector_operation_hash

let operation_status injector op_hash =
  let* injected = RPC.call injector @@ Injector.RPC.operation_status op_hash in
  return injected

let add_one_pending_transaction_per_block injector client n_blocks =
  let transactions = List.init n_blocks Fun.id in
  Lwt_list.map_s
    (fun _ ->
      let* inj_operation_hash = add_pending_transaction injector in
      let* () = Client.bake_for client in
      return inj_operation_hash)
    transactions

let check_operation_status injector ops =
  let check_status inj_operation_hash =
    let* _status = operation_status injector inj_operation_hash in
    return ()
  in
  Lwt_list.iter_s check_status ops

let inject injector =
  let* _ = RPC.call injector @@ Injector.RPC.inject () in
  Lwt.return_unit

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

  let* ops = add_one_pending_transaction_per_block injector client 5 in
  let* () = Client.bake_for client in

  let* _ = check_operation_status injector ops in

  let* ops2 = add_one_pending_transaction_per_block injector client 5 in
  let* () = Client.bake_for client in

  let* _ = inject injector in
  let* () = Client.bake_for client in

  let* _ = check_operation_status injector (ops @ ops2) in

  unit

let register ~protocols = test_injector protocols
