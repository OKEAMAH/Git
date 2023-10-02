open Tezos_base.Profiler

let mempool_profiler = unplugged ()

let store_profiler = unplugged ()

let chain_validator_profiler = unplugged ()

let block_validator_profiler = unplugged ()

let rpc_server_profiler = unplugged ()

let may_start_block =
  let last_block = ref None in
  fun b ->
    let sec () = Format.asprintf "%a" Block_hash.pp b in
    match !last_block with
    | None ->
        let s = sec () in
        record block_validator_profiler s ;
        last_block := Some b
    | Some b' when Block_hash.equal b' b -> ()
    | Some _ ->
        stop block_validator_profiler ;
        let s = sec () in
        record block_validator_profiler s ;
        last_block := Some b

let merge_profiler = unplugged ()

let p2p_reader_profiler = unplugged ()

let requester_profiler = unplugged ()

let all_profilers =
  [
    ("mempool", mempool_profiler);
    ("store", store_profiler);
    ("chain_validator", chain_validator_profiler);
    ("block_validator", block_validator_profiler);
    ("merge", merge_profiler);
    ("p2p_reader", p2p_reader_profiler);
    ("requester", requester_profiler);
    ("rpc_server", rpc_server_profiler);
  ]

let activate_all ~profiler_maker =
  List.iter (fun (name, p) -> plug p (profiler_maker ~name)) all_profilers

let deactivate_all () =
  List.iter (fun (_name, p) -> close_and_unplug_all p) all_profilers

let activate ~profiler_maker name =
  List.assoc ~equal:( = ) name all_profilers |> function
  | None -> Format.ksprintf invalid_arg "unknown '%s' profiler" name
  | Some p -> plug p (profiler_maker ~name)

let deactivate name =
  List.assoc ~equal:( = ) name all_profilers |> function
  | None -> Format.ksprintf invalid_arg "unknown '%s' profiler" name
  | Some p -> close_and_unplug_all p
