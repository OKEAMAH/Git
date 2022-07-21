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

(*

  This library acts as a dependency to the protocol environment. Everything that
  must be exposed to the protocol via the environment shall be added here.

*)

module Make (T : Tree.S) : Wasm_pvm_sig.S with type tree = T.tree = struct
  include
    Gather_floppies.Make
      (T)
      (struct
        type tree = T.tree

        module Wasm = Tezos_webassembly_interpreter
        module Tree_encoding_decoding =
          Tree_encoding_decoding.Make
            (Wasm.Instance.NameMap)
            (Wasm.Chunked_byte_vector.Lwt)
            (T)
        module Wasm_encoding = Wasm_encoding.Make (Tree_encoding_decoding)

        (* Get the module instance of the tree. *)
        let _module_instance_of_tree tree =
          Tree_encoding_decoding.decode
            Wasm_encoding.module_instance_encoding
            tree

        let compute_step state =
          let open Lwt.Syntax in
          (* Register the PVM host functions wrappers in a module
             ["rollup_safe_core"] into the WASM linker *)
          let* () =
            Wasm.Import.register
              ~module_name:(Wasm.Utf8.decode "rollup_safe_core")
              Host_funcs.lookup
          in
          (* Interpreter via its config *)
          let host_funcs_registry = Wasm.Host_funcs.empty () in
          Host_funcs.register_host_funcs host_funcs_registry ;
          Lwt.return state

        (* TODO: https://gitlab.com/tezos/tezos/-/issues/3092
           Implement handling of input logic.
        *)
        let set_input_step _ _ = Lwt.return

        let get_output _ _ = Lwt.return ""

        let get_info _ =
          Lwt.return
            Wasm_pvm_sig.
              {
                current_tick = Z.of_int 0;
                last_input_read = None;
                input_request = No_input_required;
              }
      end)
end
