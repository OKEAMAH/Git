(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/csv.exe src/lib_scoru_wasm/test/wasm_kernels/unreachable.wasm
    Subject:      Measure nb of ticks

    Kernels: 
    -  src/lib_scoru_wasm/test/wasm_kernels/
    - src/proto_alpha/lib_protocol/test/integration/wasm_kernel/
*)

open Tezos_scoru_wasm
open Tezos_webassembly_interpreter
module Context = Tezos_context_memory.Context_binary

type Lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module Tree_encoding_runner = Tree_encoding.Runner.Make (Tree)
module Wasm = Wasm_pvm.Make (Tree)

let read_message name =
  let open Tezt.Base in
  let kernel_file =
    project_root // Filename.dirname __FILE__ // "../test/wasm_kernels"
    // (name ^ ".out")
  in
  read_file kernel_file

let initial_boot_sector_from_kernel kernel =
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
    Wasm.Internal_for_tests.set_max_nb_ticks (Z.of_int 2_500_000_000) tree
  in
  (context, tree)

let produce_proof context tree kont =
  let open Lwt_syntax in
  let* context = Context.add_tree context [] tree in
  let _hash = Context.commit ~time:Time.Protocol.epoch context in
  let index = Context.index context in
  match Context.Tree.kinded_key tree with
  | Some k -> Context.produce_tree_proof index k kont
  | None ->
      Stdlib.failwith
        "produce_proof: internal error, [kinded_key] returned [None]"

let proof_size proof =
  let encoding =
    Tezos_context_merkle_proof_encoding.Merkle_proof_encoding.V2.Tree2
    .tree_proof_encoding
  in
  let bytes = Data_encoding.Binary.to_bytes_exn encoding proof in
  Bytes.length bytes

let label_step_kont = function
  | Eval.LS_Start _ -> "ls_start"
  | LS_Craft_frame (_, _) -> "ls_craft_frame"
  | LS_Push_frame (_, _) -> "ls_push_frame"
  | LS_Consolidate_top (_, _, _, _) -> "ls_consolidate_top"
  | LS_Modify_top _ -> "ls_modify_top"

let step_kont_label = function
  | Eval.SK_Start (_, _) -> "sk_start"
  | SK_Next (_, _, kont) -> "sk_next:" ^ label_step_kont kont
  | SK_Consolidate_label_result (_, _, _, _, _, _) ->
      "sk_consolidate_label_result"
  | SK_Result _ -> "sk_result"
  | SK_Trapped _ -> "sk_trapped"

let init_kont_label = function
  | Eval.IK_Start _ -> "ik_start"
  | IK_Add_import _ -> "ik_add_import"
  | IK_Type (_, _) -> "ik_type"
  | IK_Aggregate (_, Func, _) -> "ik_aggregate_func"
  | IK_Aggregate (_, Global, _) -> "ik_aggregate_global"
  | IK_Aggregate (_, Table, _) -> "ik_aggregate_table"
  | IK_Aggregate (_, Memory, _) -> "ik_aggregate_memory"
  | IK_Aggregate_concat (_, Func, _) -> "ik_aggregate_func"
  | IK_Aggregate_concat (_, Global, _) -> "ik_aggregate_global"
  | IK_Aggregate_concat (_, Table, _) -> "ik_aggregate_concat_table"
  | IK_Aggregate_concat (_, Memory, _) -> "ik_aggregate_concat_memory"
  | IK_Exports (_, _) -> "ik_exports"
  | IK_Elems (_, _) -> "ik_elems"
  | IK_Datas (_, _) -> "ik_datas"
  | IK_Es_elems (_, _) -> "ik_es_elems"
  | IK_Es_datas (_, _, _) -> "ik_es_datas"
  | IK_Join_admin (_, _) -> "ik_join_admin"
  | IK_Eval _ -> "ik_eval:"
  | IK_Stop -> "ik_stop"

let tick_label = function
  | Wasm_pvm.Decode _ -> "decode"
  | Init {init_kont; _} -> "init:" ^ init_kont_label init_kont
  | Eval {step_kont; _} -> "eval:" ^ step_kont_label step_kont
  | Stuck _ -> "stuck"
  | Link _ -> "link"

let print_tick_info context tree =
  let open Lwt_syntax in
  let* proof, _ =
    produce_proof context tree (fun tree ->
        let* tree = Wasm.compute_step tree in
        return (tree, ()))
  in
  let* tick = Wasm.Internal_for_tests.get_tick_state tree in
  let* info = Wasm.get_info tree in
  Format.printf
    "%s: %s, %d\n"
    (Z.to_string info.current_tick)
    (tick_label tick)
    (proof_size proof) ;
  return ()

let print_info tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  let* tick = Wasm.Internal_for_tests.get_tick_state tree in
  Format.printf "%s (%s)\n%!" (Z.to_string info.current_tick) (tick_label tick) ;
  return ()

let rec eval_until_input_requested ?(tick_info = false) context tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  match info.input_request with
  | No_input_required ->
      let _ = if tick_info then print_tick_info context tree else return () in
      let* tree =
        Wasm.Internal_for_tests.compute_step_many ~max_steps:Int64.max_int tree
      in
      eval_until_input_requested ~tick_info context tree
  | Input_required -> return tree

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
    Wasm_pvm_sig.
      {
        inbox_level =
          Option.value_f ~default:(fun () -> assert false)
          @@ Tezos_base.Bounded.Non_negative_int32.of_value 0l;
        message_counter = Z.of_int message_counter;
      }
  in
  Wasm.set_input_step input_info message tree

let run_bench name tree bench =
  let open Lwt_syntax in
  let time = Unix.gettimeofday () in
  let _ = Printf.printf "=========\n%s \nStart at %f\n%!" name time in
  let* tree = bench tree in
  let time = Unix.gettimeofday () -. time in
  let _ = Printf.printf "took %f s\n%!" time in
  let _ = print_info tree in
  return tree

let () =
  let kernel = Sys.argv.(1) in
  Lwt_main.run
  @@ run kernel (fun kernel ->
         let open Lwt_syntax in
         let* context, tree = initial_boot_sector_from_kernel kernel in
         let* tree =
           run_bench "Boot on empty" tree (fun tree ->
               eval_until_input_requested ~tick_info:false context tree)
         in
         let* tree =
           run_bench "Incorrect input " tree (fun tree ->
               let message = "test" in
               let* tree = set_input_step 1_000 message tree in
               eval_until_input_requested ~tick_info:false context tree)
         in
         let* tree =
           run_bench "Deposit " tree (fun tree ->
               let message = read_message "deposit" in
               let* tree = set_input_step 1_001 message tree in
               eval_until_input_requested ~tick_info:false context tree)
         in
         let* tree =
           run_bench "Just Withdrawal " tree (fun tree ->
               let message = read_message "withdrawal" in
               let* tree = set_input_step 1_002 message tree in
               eval_until_input_requested ~tick_info:false context tree)
         in
         let* tree =
           run_bench "Deposit + Withdrawal " tree (fun tree ->
               let message = read_message "deposit" in
               let* tree = set_input_step 1_003 message tree in
               let message = read_message "withdrawal" in
               let* tree = set_input_step 1_004 message tree in
               eval_until_input_requested ~tick_info:false context tree)
         in

         let _ = print_info tree in
         return ())
