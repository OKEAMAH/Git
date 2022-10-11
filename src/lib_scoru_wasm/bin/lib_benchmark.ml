(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/benchmark.exe 
    Subject:      Measure nb of ticks
    
    Kernels: 
    - src/lib_scoru_wasm/test/wasm_kernels/
    - src/proto_alpha/lib_protocol/test/integration/wasm_kernel/
 

*)

open Pvm_instance

module Data = struct
  type time = float

  type datum = {
    scenario : string;
    section : string;
    label : string;
    ticks : Z.t;
    time : time;
  }

  let make_datum scenario section label ticks time =
    {scenario; section; label; ticks; time}

  type benchmark = {
    verbose : bool;
    totals : bool;
    irmin : bool;
    current_scenario : string;
    current_section : string;
    data : datum list;
    total_time : time;
    total_tick : Z.t;
  }

  let empty_benchmark ?(verbose = false) ?(totals = true) ?(irmin = true) () =
    {
      verbose;
      totals;
      irmin;
      current_scenario = "";
      current_section = "";
      data = [];
      total_time = 0.;
      total_tick = Z.zero;
    }

  let init_scenario benchmark scenario =
    {
      benchmark with
      current_scenario = scenario;
      current_section = "Booting " ^ scenario;
    }

  let switch_section benchmark current_section =
    {benchmark with current_section}

  let add_datum benchmark name ticks time =
    if (not benchmark.totals) && benchmark.current_section = name then benchmark
    else
      let datum =
        make_datum
          benchmark.current_scenario
          benchmark.current_section
          name
          ticks
          time
      in
      {benchmark with data = datum :: benchmark.data}

  let add_final_info benchmark total_time total_tick =
    if benchmark.totals then
      let datum =
        make_datum
          benchmark.current_scenario
          "all steps"
          "total"
          total_tick
          total_time
      in
      {benchmark with data = datum :: benchmark.data}
    else benchmark

  let add_decode_datum benchmark time =
    let tick = Z.zero in
    let _ =
      if benchmark.verbose then
        Printf.printf "Decode tree finished in %f s\n%!" time
    in

    if benchmark.irmin then add_datum benchmark "Decode tree" tick time
    else benchmark

  let add_encode_datum benchmark time =
    let tick = Z.zero in
    let _ =
      if benchmark.verbose then
        Printf.printf "Encode tree finished in %f s\n%!" time
    in
    if benchmark.irmin then add_datum benchmark "Encode tree" tick time
    else benchmark

  module Pp = struct
    let pp_csv_line scenario section label ticks time =
      Printf.printf
        "\"%s\" , \"%s\" , \"%s\" ,  %s ,  %f \n%!"
        scenario
        section
        label
        (Z.to_string ticks)
        time

    let pp_datum {scenario; section; label; ticks; time} =
      if section != label then pp_csv_line scenario section label ticks time
      else pp_csv_line scenario section "all phases" ticks time

    let pp_benchmark benchmark =
      let rec go = function
        | [] -> ()
        | datum :: q ->
            pp_datum datum ;
            go q
      in
      go (List.rev benchmark.data)

    let pp_header_section benchmark tree =
      let open Lwt_syntax in
      let* before_tick = get_tick_from_tree tree in
      if benchmark.verbose then
        Printf.printf
          "=========\n%s \nStart at tick %s\n-----\n%!"
          benchmark.current_section
          (Z.to_string before_tick) ;
      return (before_tick, Unix.gettimeofday ())

    let pp_footer_section benchmark tree before_tick before_time =
      let open Lwt_syntax in
      let time = Unix.gettimeofday () -. before_time in
      let* after_tick = get_tick_from_tree tree in
      let tick = Z.(after_tick - before_tick) in
      let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
      let _ = if benchmark.verbose then Printf.printf "-----\n" in
      let _ =
        if benchmark.verbose then
          Printf.printf
            "%s took %s ticks in %f s\n%!"
            benchmark.current_section
            (Z.to_string tick)
            time
      in
      let _ =
        if benchmark.verbose then
          Printf.printf
            "last tick: %s %s\n%!"
            (Z.to_string after_tick)
            (PP.tick_label tick_state)
      in
      return_unit

    let footer_action benchmark name tick time =
      if benchmark.verbose && not (benchmark.current_section = name) then
        Printf.printf
          "%s finished in %s ticks %f s\n%!"
          name
          (Z.to_string tick)
          time

    let pp_scenario_header benchmark name =
      if benchmark.verbose then
        Printf.printf
          "****************************************\n Scenario %s\n%!"
          name
  end
end