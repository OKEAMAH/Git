let get_config_path () =
  Cli.get_string ~default:"scenarios.json" "configuration"
