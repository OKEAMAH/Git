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

module Wasm = Tezos_webassembly_interpreter

type tick_state = Decode | Eval of Wasm.Eval.config

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

    module Tree_encoding = Tree_encoding.Make (T)
    module Wasm_encoding = Wasm_encoding.Make (Tree_encoding)

    let host_funcs =
      let registry = Wasm.Host_funcs.empty () in
      Host_funcs.register_host_funcs (Wasm.Host_funcs.empty ()) ;
      registry

    let tick_state_encoding ~module_reg =
      let open Tree_encoding in
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
            (function Eval eval_config -> Some eval_config | _ -> None)
            (fun eval_config -> Eval eval_config);
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

    let next_state ~module_reg state =
      let open Lwt_syntax in
      match state.tick with
      | Decode ->
          let* ast_module =
            Wasm.Decode.decode ~name:"name" ~bytes:state.kernel
          in
          let self =
            Wasm.Instance.alloc_module_ref
              (Wasm.Instance.Module_key "main")
              module_reg
          in
          (* The module instance is registered in [self] that contains the
             module registry, why we can ignore the result here. *)
          let* _module_inst = Wasm.Eval.init ~self host_funcs ast_module [] in
          let eval_config = Wasm.Eval.config host_funcs self [] [] in
          Lwt.return {state with tick = Eval eval_config}
      | Eval ({Wasm.Eval.frame; code; _} as eval_config) -> (
          match code with
          | _values, [] ->
              (* We have an empty set of admin instructions so we create one
                 that invokes the main function. *)
              let* module_inst =
                Wasm.Instance.ModuleMap.get "main" module_reg
              in
              let* name =
                Wasm.Instance.Vector.to_list @@ Wasm.Utf8.decode "main"
              in
              let* extern =
                Wasm.Instance.NameMap.get name module_inst.Wasm.Instance.exports
              in
              let main_func =
                match extern with
                | Wasm.Instance.ExternFunc func -> func
                | _ ->
                    (* We require a function with the name [main] to be exported
                       rather than any other structure. *)
                    assert false
              in
              let admin_instr' = Wasm.Eval.Invoke main_func in
              let admin_instr =
                Wasm.Source.{it = admin_instr'; at = no_region}
              in
              (* Clear the values and the locals in the frame. *)
              let code = ([], [admin_instr]) in
              let eval_config =
                {
                  eval_config with
                  Wasm.Eval.frame = {frame with locals = []};
                  code;
                }
              in
              Lwt.return {state with tick = Eval eval_config}
          | _ ->
              (* Continue execution. *)
              let* eval_config = Wasm.Eval.step eval_config in
              Lwt.return {state with tick = Eval eval_config})

    let module_reg_encoding =
      Tree_encoding.scope
        ["module-registry"]
        Wasm_encoding.module_instances_encoding

    let module_reg_from_tree tree =
      let open Lwt_syntax in
      try
        let* module_reg = Tree_encoding.decode module_reg_encoding tree in
        return (Some module_reg)
      with _ -> return None

    let compute_step tree =
      let open Lwt_syntax in
      (* Try to decode the module registry. *)
      let* module_reg_opt = module_reg_from_tree tree in
      let module_reg =
        Option.value_f ~default:Wasm.Instance.ModuleMap.create module_reg_opt
      in
      let* state = Tree_encoding.decode (pvm_state_encoding ~module_reg) tree in
      let* state = next_state state ~module_reg in
      let state = {state with current_tick = Z.succ state.current_tick} in
      (* Write the module registry to the tree in case it did not exist
         before. *)
      let* tree =
        match (state.tick, module_reg_opt) with
        | Eval _, None ->
            Tree_encoding.encode module_reg_encoding module_reg tree
        | _ -> return tree
      in
      Tree_encoding.encode (pvm_state_encoding ~module_reg) state tree

    let get_output _ _ = Lwt.return ""

    (* TODO: #3444
       Create a may-fail tree-encoding-decoding combinator.
       https://gitlab.com/tezos/tezos/-/issues/3444
    *)
    (* TODO: #3448
       Remove the mention of exceptions from lib_scoru_wasm Make signature.
       Add try_with or similar to catch exceptions and put the machine in a
       stuck state instead. https://gitlab.com/tezos/tezos/-/issues/3448
    *)
    let current_tick_encoding =
      Tree_encoding.value ["wasm"; "current_tick"] Data_encoding.z

    let level_encoding =
      Tree_encoding.value ["input"; "level"] Bounded.Int32.NonNegative.encoding

    let id_encoding = Tree_encoding.value ["input"; "id"] Data_encoding.z

    let last_input_read_encoder =
      Tree_encoding.tup2 ~flatten:true level_encoding id_encoding

    let status_encoding =
      Tree_encoding.value ["input"; "consuming"] Data_encoding.bool

    let inp_encoding level id =
      Tree_encoding.value ["input"; level; id] Data_encoding.string

    let get_info tree =
      let open Lwt_syntax in
      let* waiting =
        try Tree_encoding.decode status_encoding tree
        with _ -> Lwt.return false
      in
      let input_request =
        if waiting then Wasm_pvm_sig.Input_required
        else Wasm_pvm_sig.No_input_required
      in
      let* input =
        try
          let* t = Tree_encoding.decode last_input_read_encoder tree in
          Lwt.return @@ Some t
        with _ -> Lwt.return_none
      in
      let last_input_read =
        Option.map
          (fun (inbox_level, message_counter) ->
            Wasm_pvm_sig.{inbox_level; message_counter})
          input
      in
      let* current_tick =
        try Tree_encoding.decode current_tick_encoding tree
        with _ -> Lwt.return Z.zero
      in
      Lwt.return Wasm_pvm_sig.{current_tick; last_input_read; input_request}

    let set_input_step input_info message tree =
      let open Lwt_syntax in
      let open Wasm_pvm_sig in
      let {inbox_level; message_counter} = input_info in
      let level =
        Int32.to_string @@ Bounded.Int32.NonNegative.to_int32 inbox_level
      in
      let id = Z.to_string message_counter in
      let* current_tick = Tree_encoding.decode current_tick_encoding tree in
      let* tree =
        Tree_encoding.encode current_tick_encoding (Z.succ current_tick) tree
      in
      let* tree = Tree_encoding.encode status_encoding false tree in
      Tree_encoding.encode (inp_encoding level id) message tree
  end

  include Gather_floppies.Make (T) (Raw)
end
