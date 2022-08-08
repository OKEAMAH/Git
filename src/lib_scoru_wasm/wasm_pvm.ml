(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Tezos_webassembly_interpreter

type eval_state = {module_reg : Instance.module_reg; eval_config : Eval.config}

type tick_state = Decode | Eval of eval_state

type pvm_state = {
  kernel : Lazy_containers.Chunked_byte_vector.Lwt.t;
  current_tick : Z.t;
  last_input_info : Wasm_pvm_sig.input_info option;
  consuming : bool;
  (* TODO: Remove the field as soon as we know how to implement
     [waiting_for_input : Eval.config -> bool] *)
  tick : tick_state;
}

module Make (T : Tree_encoding.TREE) :
  Gather_floppies.S with type tree = T.tree = struct
  module Raw = struct
    type tree = T.tree

    module Wasm = Tezos_webassembly_interpreter
    module Tree_encoding = Tree_encoding.Make (T)
    module Wasm_encoding = Wasm_encoding.Make (Tree_encoding)

    let tick_state_encoding ~module_reg =
      let open Tree_encoding in
      let host_funcs = Host_funcs.empty () in
      tagged_union
        (value [] Data_encoding.string)
        [
          case
            "decode"
            (value [] Data_encoding.unit)
            (function Decode -> Some () | _ -> None)
            (fun () -> Decode);
          case
            "eval"
            (Wasm_encoding.config_encoding
               ~host_funcs
               ~module_reg:(Lazy.from_val module_reg))
            (function Eval {eval_config; _} -> Some eval_config | _ -> None)
            (fun eval_config -> Eval {eval_config; module_reg});
        ]

    let pvm_state_encoding ~module_reg =
      let open Tree_encoding in
      conv
        (fun (current_tick, kernel, last_input_info, consuming, tick) ->
          {current_tick; kernel; last_input_info; consuming; tick})
        (fun {current_tick; kernel; last_input_info; consuming; tick} ->
          (current_tick, kernel, last_input_info, consuming, tick))
        (tup5
           ~flatten:true
           (value ~default:Z.zero ["wasm"; "current_tick"] Data_encoding.n)
           (scope ["durable"; "kernel"; "boot.wasm"] chunked_byte_vector)
           (optional ["wasm"; "input"] Wasm_pvm_sig.input_info_encoding)
           (value ~default:true ["wasm"; "consuming"] Data_encoding.bool)
           (scope ["wasm"] (tick_state_encoding ~module_reg)))

    let next_state state =
      let open Lwt_syntax in
      match state.tick with
      | Decode ->
          let* ast_module = Decode.decode ~name:"name" ~bytes:state.kernel in
          let module_reg = Instance.ModuleMap.create () in
          let self =
            Instance.alloc_module_ref (Instance.Module_key "name") module_reg
          in
          let host_funs = Host_funcs.empty () in
          let* module_inst = Eval.init ~self host_funs ast_module [] in
          let* name = Instance.Vector.to_list @@ Utf8.decode "main" in
          let* extern =
            Instance.NameMap.get name module_inst.Instance.exports
          in
          let main_func =
            match extern with Instance.ExternFunc f -> f | _ -> assert false
          in
          let admin_instrs = Eval.Invoke main_func in
          let admin_instr = Source.{it = admin_instrs; at = no_region} in
          let eval_config = Eval.config host_funs self [] [admin_instr] in
          let () = Instance.ModuleMap.set "main" module_inst module_reg in
          Lwt.return {state with tick = Eval {eval_config; module_reg}}
      | Eval
          {
            eval_config =
              {
                Eval.frame = {inst = _; locals};
                input;
                code = _;
                host_funcs;
                budget = _;
              };
            _;
          } ->
          let values = List.map (fun v -> !v) locals in
          (* TODO: How to get func-instance? *)
          let func_inst = assert false in
          let _ = Eval.invoke ~input host_funcs func_inst values in
          assert false

    let module_reg_from_tree tree =
      let open Lwt_syntax in
      try
        let* module_reg =
          Tree_encoding.decode Wasm_encoding.module_instances_encoding tree
        in
        return (module_reg, true)
      with _ -> return (Instance.ModuleMap.create (), false)

    let compute_step tree =
      let open Lwt_syntax in
      (* Try to decode the module registry. *)
      let* module_reg, module_reg_existed = module_reg_from_tree tree in
      let* state = Tree_encoding.decode (pvm_state_encoding ~module_reg) tree in
      let* state = next_state state in
      let state = {state with current_tick = Z.succ state.current_tick} in
      (* Write the module registry to the tree. *)
      let* tree =
        match (state.tick, module_reg_existed) with
        | Eval {module_reg; _}, false ->
            Tree_encoding.encode
              Wasm_encoding.module_instances_encoding
              module_reg
              tree
        | _ -> return tree
      in
      Tree_encoding.encode (pvm_state_encoding ~module_reg) state tree

    let get_output _ _ = Lwt.return ""

    (* TODO: #3448
       Remove the mention of exceptions from lib_scoru_wasm Make signature.
       Add try_with or similar to catch exceptions and put the machine in a
       stuck state instead. https://gitlab.com/tezos/tezos/-/issues/3448
    *)
    let get_info tree =
      let open Lwt_syntax in
      let* module_reg, _ = module_reg_from_tree tree in
      let* state = Tree_encoding.decode (pvm_state_encoding ~module_reg) tree in
      return
        Wasm_pvm_sig.
          {
            current_tick = state.current_tick;
            last_input_read = state.last_input_info;
            input_request =
              (if state.consuming then Input_required else No_input_required);
          }

    let set_input_step input_info _message tree =
      let open Lwt_syntax in
      let* module_reg, _ = module_reg_from_tree tree in
      let* state = Tree_encoding.decode (pvm_state_encoding ~module_reg) tree in
      let state =
        {
          state with
          last_input_info = Some input_info;
          current_tick = Z.succ state.current_tick;
        }
      in
      Tree_encoding.encode (pvm_state_encoding ~module_reg) state tree
  end

  include Gather_floppies.Make (T) (Raw)
end
