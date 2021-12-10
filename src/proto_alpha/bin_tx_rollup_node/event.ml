(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2021 Marigold, <team@marigold.dev>                          *)
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

  let section = ["tx_rollup_node"]

  let configuration_written =
    declare_2
      ~section
      ~name:"tx_rollup_configuration_written"
      ~msg:"configuration written in {file}"
      ~level:Notice
      ("file", Data_encoding.string)
      ("config", Configuration.encoding)

  let starting_node =
    declare_0
      ~section
      ~name:"tx_rollup_starting_node"
      ~msg:"starting the Transaction rollup node"
      ~level:Notice
      ()

  let node_is_ready =
    declare_2
      ~section
      ~name:"tx_rollup_is_ready"
      ~msg:"the transaction rollup node is listening to {addr}:{port}"
      ~level:Notice
      ("addr", Data_encoding.string)
      ("port", Data_encoding.uint16)

  let node_is_shutting_down =
    declare_1
      ~section
      ~name:"tx_rollup_shutting_down"
      ~msg:"the transaction rollup node is shutting down with code {exit_code}"
      ~level:Notice
      ("exit_code", Data_encoding.int31)

  let cannot_connect =
    declare_1
      ~section
      ~name:"oru_cannot_connect_to_node"
      ~msg:"Cannot connect to node, retrying in {delay}s"
      ~level:Warning
      ("delay", Data_encoding.float)

  let connection_lost =
    declare_0
      ~section
      ~name:"oru_connection_lost"
      ~msg:"Connection to node lost"
      ~level:Warning
      ()

  let ping =
    declare_0 ~section ~name:"tx_rollup_ping" ~msg:"ping!" ~level:Notice ()
end

let configuration_written ~into ~config =
  Simple.(emit configuration_written (into, config)) >|= ok

let starting_node () = Simple.(emit starting_node) () >|= ok

let node_is_ready ~rpc_addr ~rpc_port =
  Simple.(emit node_is_ready (rpc_addr, rpc_port)) >|= ok

let node_is_shutting_down ~exit_status =
  Simple.(emit node_is_shutting_down) exit_status

let cannot_connect ~delay = Simple.(emit cannot_connect) delay

let connection_lost = Simple.(emit connection_lost)

let ping = Simple.(emit ping)
