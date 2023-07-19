module Mempool_profiler = Tezos_base.Profiler.Make ()

module Store_profiler = Tezos_base.Profiler.Make ()

module Merge_profiler = Tezos_base.Profiler.Make ()

module P2p_reader_profiler = Tezos_base.Profiler.Make ()

module Requester_profiler = Tezos_base.Profiler.Make ()

module Chain_validator_profiler = Tezos_base.Profiler.Make ()

let init profiler_maker =
  Mempool_profiler.plug (Some (profiler_maker ~name:"mempool")) ;
  Store_profiler.plug (Some (profiler_maker ~name:"store")) ;
  Merge_profiler.plug (Some (profiler_maker ~name:"merge")) ;
  P2p_reader_profiler.plug (Some (profiler_maker ~name:"p2p_reader")) ;
  Requester_profiler.plug (Some (profiler_maker ~name:"requester")) ;
  Chain_validator_profiler.plug (Some (profiler_maker ~name:"chain_validator"))
