(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

module Simple = struct
  include Internal_event.Simple

  let section = ["sc_rollup_node"]

  let node_is_ready =
    declare_2
      ~section
      ~name:"smart_rollup_node_is_ready"
      ~msg:"The smart rollup node is listening to {addr}:{port}"
      ~level:Notice
      ("addr", Data_encoding.string)
      ("port", Data_encoding.uint16)

  let section = section @ ["daemon"]

  let processing_heads_iteration =
    declare_3
      ~section
      ~name:"sc_rollup_daemon_processing_heads"
      ~msg:
        "A new iteration of process_heads has been triggered: processing \
         {number} heads from level {from} to level {to}"
      ~level:Notice
      ("number", Data_encoding.int31)
      ("from", Data_encoding.int32)
      ("to", Data_encoding.int32)

  let new_heads_processed =
    declare_3
      ~section
      ~name:"sc_rollup_node_layer_1_new_heads_processed"
      ~msg:
        "Finished processing {number} layer 1 heads for levels {from} to {to}"
      ~level:Notice
      ("number", Data_encoding.int31)
      ("from", Data_encoding.int32)
      ("to", Data_encoding.int32)

  let error =
    declare_1
      ~section
      ~name:"sc_rollup_daemon_error"
      ~msg:"Fatal daemon error: {error}"
      ~level:Fatal
      ("error", trace_encoding)
      ~pp1:pp_print_trace
end

let node_is_ready ~rpc_addr ~rpc_port =
  Simple.(emit node_is_ready (rpc_addr, rpc_port))

let new_heads_iteration event = function
  | oldest :: rest ->
      let newest =
        match List.rev rest with [] -> oldest | newest :: _ -> newest
      in
      let number =
        Int32.sub (snd newest) (snd oldest) |> Int32.succ |> Int32.to_int
      in
      Simple.emit event (number, snd oldest, snd newest)
  | [] -> Lwt.return_unit

let processing_heads_iteration l =
  new_heads_iteration Simple.processing_heads_iteration l

let new_heads_processed l = new_heads_iteration Simple.new_heads_processed l

let error e = Simple.(emit error) e
