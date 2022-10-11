open Tezos_scoru_wasm
open Wasm_pvm_state.Internal_state
open Pvm_instance

module Exec = struct
  type phase = Decoding | Initialising | Linking | Evaluating | Padding

  let run_loop f a =
    Lwt_list.fold_left_s
      f
      a
      [Decoding; Linking; Initialising; Evaluating; Padding]

  let should_continue_until_input_requested (pvm_state : pvm_state) =
    match pvm_state.tick_state with
    | Stuck _ | Snapshot -> Lwt.return false
    | _ -> Lwt.return true

  (** FIXME: very fragile, when the PVM implementation changes, the predicates produced could be way off*)
  let should_continue phase (pvm_state : pvm_state) =
    let continue =
      match (phase, pvm_state.tick_state) with
      | Initialising, Init _ -> true
      | Linking, Link _ -> true
      | Decoding, Decode _ -> true
      | ( Evaluating,
          Eval {step_kont = Tezos_webassembly_interpreter.Eval.(SK_Result _); _}
        ) ->
          false
      | Evaluating, Eval _ -> true
      | Padding, Eval _ -> true
      | _, _ -> false
    in
    Lwt.return continue

  let pp_phase = function
    | Initialising -> "Initializing"
    | Linking -> "Linking"
    | Decoding -> "Decoding"
    | Evaluating -> "Evaluating"
    | Padding -> "Padding"

  let finish_top_level_call_on_state pvm_state =
    Wasm.Internal_for_benchmark.compute_step_many_until_pvm_state
      ~max_steps:Int64.max_int
      should_continue_until_input_requested
      pvm_state

  let execute_on_state phase state =
    Wasm.Internal_for_benchmark.compute_step_many_until_pvm_state
      ~max_steps:Int64.max_int
      (should_continue phase)
      state

  let run kernel k =
    let open Lwt_syntax in
    let* res =
      Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
          let* kernel = Lwt_io.read channel in
          k kernel)
    in
    return res

  let set_input_step message_counter message tree =
    let open Lwt_syntax in
    let input_info =
      Wasm_pvm_state.
        {
          inbox_level =
            Option.value_f ~default:(fun () -> assert false)
            @@ Tezos_base.Bounded.Non_negative_int32.of_value 0l;
          message_counter = Z.of_int message_counter;
        }
    in

    (* FIXME: hack to allow multiple set_input *)
    let* pvm_state = Wasm.Internal_for_benchmark.decode tree in
    let* tree =
      Wasm.Internal_for_benchmark.encode
        {pvm_state with tick_state = Snapshot}
        tree
    in

    Wasm.set_input_step input_info message tree

  let read_message name =
    let open Tezt.Base in
    let kernel_file =
      project_root // Filename.dirname __FILE__ // "messages" // name
    in
    read_file kernel_file

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
    tree
end