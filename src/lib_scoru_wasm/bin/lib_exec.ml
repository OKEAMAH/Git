open Tezos_scoru_wasm
open Wasm_pvm_state
open Wasm_pvm_state.Internal_state
open Pvm_instance

module Exec = struct
  let input_request pvm_state =
    match pvm_state.tick_state with
    | Stuck _ | Snapshot -> Input_required
    | Eval config -> (
        match Tezos_webassembly_interpreter.Eval.is_reveal_tick config with
        | Some reveal -> Reveal_required reveal
        | None -> No_input_required)
    | _ -> No_input_required

  let eval_until_input_requested tree =
    let should_continue (pvm_state : pvm_state) =
      match input_request pvm_state with
      | No_input_required -> true
      | Reveal_required _ | Input_required -> false
    in
    Wasm.Internal_for_benchmark.compute_step_many_until
      ~max_steps:Int64.max_int
      should_continue
      tree

  (** FIXME: very fragile, when the PVM implementation changes, the predicates produced could be way off*)
  let should_continue phase (pvm_state : pvm_state) =
    match (phase, pvm_state.tick_state) with
    | `Initialising, Init _ -> true
    | `Linking, Link _ -> true
    | `Decoding, Decode _ -> true
    | ( `Evaluating,
        Eval {step_kont = Tezos_webassembly_interpreter.Eval.(SK_Result _); _} )
      ->
        false
    | `Evaluating, Eval _ -> true
    | _, _ -> false

  let finish_top_level_call tree = eval_until_input_requested tree

  let decode tree =
    Wasm.Internal_for_benchmark.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Decoding)
      tree

  let link tree =
    Wasm.Internal_for_benchmark.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Linking)
      tree

  let init tree =
    Wasm.Internal_for_benchmark.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Initialising)
      tree

  let eval tree =
    Wasm.Internal_for_benchmark.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Evaluating)
      tree

  let read_message name =
    let open Tezt.Base in
    let kernel_file =
      project_root // Filename.dirname __FILE__ // "inputs" // (name ^ ".out")
    in
    read_file kernel_file

  let set_input_step message_counter message tree =
    let input_info =
      Wasm_pvm_state.
        {
          inbox_level =
            Option.value_f ~default:(fun () -> assert false)
            @@ Tezos_base.Bounded.Non_negative_int32.of_value 0l;
          message_counter = Z.of_int message_counter;
        }
    in
    Wasm.set_input_step input_info message tree

  let initial_boot_sector_from_kernel ?(max_tick = 2_500_000_000) kernel =
    let open Lwt_syntax in
    let* index = Context.init "/tmp" in
    let context = Context.empty index in
    let tree = Context.Tree.empty context in
    let origination_message =
      Data_encoding.Binary.to_string_exn
        Gather_floppies.origination_message_encoding
      @@ Gather_floppies.Complete_kernel (String.to_bytes kernel)
    in
    let* tree =
      Wasm.Internal_for_tests.initial_tree_from_boot_sector
        ~empty_tree:tree
        origination_message
    in
    let+ tree =
      Wasm.Internal_for_tests.set_max_nb_ticks (Z.of_int max_tick) tree
    in
    (context, tree)

  let run kernel k =
    let open Lwt_syntax in
    let* () =
      Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
          let* kernel = Lwt_io.read channel in
          k kernel)
    in
    return_unit
end

