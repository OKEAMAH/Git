open Profiler

let nonce_profiler = unplugged ()

let operation_worker_profiler = unplugged ()

let node_rpc_profiler = unplugged ()

let profiler = unplugged ()

let init profiler_maker =
  let baker_instance = profiler_maker ~name:"baker" in
  plug profiler baker_instance ;
  plug Tezos_protocol_environment.Environment_profiler.profiler baker_instance ;
  plug nonce_profiler (profiler_maker ~name:"nonce") ;
  plug node_rpc_profiler (profiler_maker ~name:"node_rpc") ;
  plug operation_worker_profiler (profiler_maker ~name:"op_worker")

let create_reset_block_section profiler =
  let last_block = ref None in
  fun b ->
    match !last_block with
    | None ->
        record profiler (Block_hash.to_b58check b) ;
        last_block := Some b
    | Some b' when Block_hash.equal b' b -> ()
    | Some _ ->
        stop profiler ;
        record profiler (Block_hash.to_b58check b) ;
        last_block := Some b

include (val wrap profiler)
