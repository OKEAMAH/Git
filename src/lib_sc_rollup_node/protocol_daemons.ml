(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

type error += Unsupported_protocol of Protocol_hash.t

let () =
  register_error_kind
    ~id:"sc_rollup.node.unsupported_protocol"
    ~title:"Protocol not supported by rollup node"
    ~description:"Protocol not supported by rollup node."
    ~pp:(fun ppf proto ->
      Format.fprintf
        ppf
        "Protocol %a is not supported by the rollup node."
        Protocol_hash.pp
        proto)
    `Permanent
    Data_encoding.(obj1 (req "protocol" Protocol_hash.encoding))
    (function Unsupported_protocol p -> Some p | _ -> None)
    (fun p -> Unsupported_protocol p)

type proto_daemon = (module Protocol_daemon_sig.S)

let proto_daemons : proto_daemon Protocol_hash.Table.t =
  Protocol_hash.Table.create 7

let register protocol daemon =
  Protocol_hash.Table.replace proto_daemons protocol daemon

let proto_daemon_for_protocol protocol =
  Protocol_hash.Table.find proto_daemons protocol
  |> Option.to_result ~none:[Unsupported_protocol protocol]

let registered_protocols () =
  Protocol_hash.Table.to_seq_keys proto_daemons |> List.of_seq
