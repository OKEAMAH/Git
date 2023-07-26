let profiler_maker data_dir ~name max_lod =
  Tezos_base.Profiler.instance
    Tezos_base_unix.Simple_profiler.auto_write_to_txt_file
    Filename.Infix.((data_dir // name) ^ "_profiling.txt", max_lod)

let build_rpc_directory data_dir =
  let open Lwt_result_syntax in
  let register endpoint f directory =
    Tezos_rpc.Directory.register directory endpoint f
  in
  let open Profiler_services.S in
  Tezos_rpc.Directory.empty
  |> register activate_all (fun () lod () ->
         Shell_profiling.activate_all
           ~profiler_maker:(profiler_maker data_dir lod) ;
         return_unit)
  |> register deactivate_all (fun () () () ->
         Shell_profiling.deactivate_all () ;
         return_unit)
  |> register activate (fun ((), name) lod () ->
         Shell_profiling.activate
           ~profiler_maker:(profiler_maker data_dir lod)
           name ;
         return_unit)
  |> register deactivate (fun ((), name) () () ->
         Shell_profiling.deactivate name ;
         return_unit)
