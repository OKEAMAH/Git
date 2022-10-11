open Tezos_scoru_wasm
module Context = Tezos_context_memory.Context_binary

type Tezos_lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tezos_tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module Tree_encoding_runner = Tezos_tree_encoding.Runner.Make (Tree)
module Wasm = Wasm_pvm.Make (Tree)

module PP = struct
  open Tezos_webassembly_interpreter
  open Wasm_pvm_state.Internal_state
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
    | IK_Eval _ -> "ik_eval"
    | IK_Stop -> "ik_stop"

  let pp_error_state = function
    | Wasm_pvm_errors.Too_many_ticks -> "Too_many_ticks"
    | Init_error _ -> "Init_error"
    | Decode_error _ -> "decode"
    | Invalid_state _ -> "invalid state"
    | Unknown_error _ -> "unknown"
    | Eval_error _ -> "eval"
    | _ -> "other"

  let tick_label = function
    | Decode _ -> "decode"
    | Init {init_kont; _} -> "init:" ^ init_kont_label init_kont
    | Eval {step_kont; _} -> "eval:" ^ step_kont_label step_kont
    | Stuck e -> "stuck: " ^ pp_error_state e
    | Link _ -> "link"
    | Snapshot -> "snapshot"
    
end