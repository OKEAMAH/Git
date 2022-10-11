open Tezos_scoru_wasm
open Pvm_instance

module Exec = struct
  let rec eval_until_input_requested tree =
    let open Lwt_syntax in
    let* info = Wasm.get_info tree in
    match info.input_request with
    | No_input_required ->
        let* tree = Wasm.compute_step_many ~max_steps:Int64.max_int tree in
        eval_until_input_requested tree
    | Reveal_required _ | Input_required -> return tree
    
let run kernel k =
  let open Lwt_syntax in
  let* () =
    Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
        let* kernel = Lwt_io.read channel in
        k kernel)
  in
  return_unit

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

let read_message name =
  let open Tezt.Base in
  let kernel_file =
    project_root // Filename.dirname __FILE__ // "inputs" // (name ^ ".out")
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
  (context, tree)
end