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

open Sigs

module Make (T : TreeS) : sig
    val step : T.tree -> T.tree Lwt.t
  end
  = struct
  module Tree = struct
    include T
  end

  module TreeEncodings = Encodings.Make (T)

  let _of_memory_instance_tree :
             Tree.tree ->
             Tezos_webassembly_interpreter.Memory.memory Tezos_webassembly_interpreter.Lazy_map.Int32Map.t Lwt.t
    =
    TreeEncodings.(Tree.Encoding.run memory_instance_encoding)

  let _of_table_instance_tree :
      Tree.tree ->
                 Tezos_webassembly_interpreter.Table.table Encodings.Decoded.t
                          Tezos_webassembly_interpreter.Lazy_map.Int32Map.t Lwt.t
    =
    TreeEncodings.(Tree.Encoding.run table_instance_encoding)

  let _of_global_instance_tree :
       Tree.tree ->
                  Tezos_webassembly_interpreter.Global.global Encodings.Decoded.t
                           Tezos_webassembly_interpreter.Lazy_map.Int32Map.t Lwt.t
    =
    TreeEncodings.(Tree.Encoding.run global_instance_encoding)

  let step x = Lwt.return x
    (* Stdlib.failwith "lib_scoru_wasm/tezos_scoru_wasm2" *)
end

let wasm_step3 = 2
