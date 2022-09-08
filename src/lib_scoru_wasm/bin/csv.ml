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
  let+ tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree:tree
      origination_message
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
  | IK_Eval {step_kont; _} -> "ik_eval:" ^ step_kont_label step_kont
  | IK_Stop -> "ik_stop"

let tick_label = function
  | Wasm_pvm.Decode _ -> "decode"
  | Link _ -> "link"
  | Init {init_kont; _} -> "init:" ^ init_kont_label init_kont
  | Eval {step_kont; _} -> "eval:" ^ step_kont_label step_kont
  | Stuck _ -> "stuck"

let rec eval_until_input_requested context tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  match info.input_request with
  | No_input_required ->
      let* proof, _ =
        produce_proof context tree (fun tree ->
            let* tree = Wasm.compute_step tree in
            return (tree, ()))
      in
      let* tick = Wasm.Internal_for_tests.get_tick_state tree in
      Format.printf "%s, %d\n" (tick_label tick) (proof_size proof) ;
      let* tree = Wasm.compute_step tree in
      eval_until_input_requested context tree
  | Input_required -> return tree

let run kernel k =
  let open Lwt_syntax in
  let* () =
    Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
        let* kernel = Lwt_io.read channel in
        k kernel)
  in
  return_unit

let () =
  let kernel = Sys.argv.(1) in
  Lwt_main.run
  @@ run kernel (fun kernel ->
         let open Lwt_syntax in
         let* context, tree = initial_boot_sector_from_kernel kernel in
         let+ _tree = eval_until_input_requested context tree in
         ())
