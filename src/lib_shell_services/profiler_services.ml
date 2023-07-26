module S = struct
  let profiler_names = Shell_profiling.all_profilers

  let lod_arg =
    Resto.Arg.make
      ~name:"profiler level of detail"
      ~destruct:(function
        | "terse" -> Ok Profiler.Terse
        | "verbose" -> Ok Profiler.Verbose
        | "detailed" -> Ok Profiler.Detailed
        | _ -> Error "invalid lod parameter")
      ~construct:(function
        | Profiler.Terse -> "terse"
        | Profiler.Verbose -> "verbose"
        | Profiler.Detailed -> "detailed")
      ()

  let activate_all =
    Tezos_rpc.Service.get_service
      ~description:"Activate all profilers."
      ~query:
        Tezos_rpc.Query.(
          query Fun.id |+ field "lod" lod_arg Terse Fun.id |> seal)
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "activate_all")

  let deactivate_all =
    Tezos_rpc.Service.get_service
      ~description:"Deactivate all profilers."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "deactivate_all")

  let profiler_name_arg =
    Resto.Arg.make
      ~name:"profiler name"
      ~destruct:(fun s ->
        if List.mem_assoc ~equal:String.equal s Shell_profiling.all_profilers
        then Ok s
        else Error (Printf.sprintf "no profiler named '%s' found" s))
      ~construct:Fun.id
      ()

  let activate =
    Tezos_rpc.Service.get_service
      ~description:"Activate a profiler."
      ~query:
        Tezos_rpc.Query.(
          query Fun.id |+ field "lod" lod_arg Terse Fun.id |> seal)
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "activate" /: profiler_name_arg)

  let deactivate =
    Tezos_rpc.Service.get_service
      ~description:"Deactivate a profiler."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.unit
      Tezos_rpc.Path.(root / "profiler" / "deactivate" /: profiler_name_arg)

  let list =
    Tezos_rpc.Service.get_service
      ~description:"List profilers."
      ~query:Tezos_rpc.Query.empty
      ~output:Data_encoding.(list string)
      Tezos_rpc.Path.(root / "profiler" / "list")
end
