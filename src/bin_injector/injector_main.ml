let () =
  Client_main_run.run
    (module Client_config)
    ~select_commands:(fun _ _ -> Lwt_result_syntax.return_nil)
