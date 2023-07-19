open Tezos_base.Profiler

module Nonce_profiler = Make ()

module Operation_worker_profiler = Make ()

module Node_rpc_profiler = Make ()

include Make ()

let init profiler_maker =
  let (module Profiler : DRIVER) = profiler_maker ~name:"baker" in
  plug (Some (module Profiler)) ;
  Tezos_protocol_environment.Environment_profiler.plug (Some (module Profiler)) ;
  Nonce_profiler.plug (Some (profiler_maker ~name:"nonce")) ;
  Node_rpc_profiler.plug (Some (profiler_maker ~name:"node_rpc")) ;
  Operation_worker_profiler.plug (Some (profiler_maker ~name:"op_worker"))
