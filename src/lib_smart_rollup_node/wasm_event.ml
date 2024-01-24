(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

module Simple = struct
  include Internal_event.Simple

  let section = ["smart_rollup_node"; "wasm"]

  let fast_exec_panicked =
    declare_0
      ~section
      ~name:"fast_exec_panicked"
      ~level:Warning
      ~msg:"The WASM Fast Execuction panicked. Falling back to the PVM."
      ()
end

let fast_exec_panicked () = Simple.(emit fast_exec_panicked) ()
