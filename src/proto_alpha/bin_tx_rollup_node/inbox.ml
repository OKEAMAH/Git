(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

open Protocol
open Alpha_context

type message_result =
  | Interpreted of Tx_rollup_l2_apply.Message_result.t
  | Discarded of tztrace

type inbox_message = {
  message : Tx_rollup_message.t;
  result : message_result;
  context_hash : Tx_rollup_l2_context_hash.t;
}

type t = {contents : inbox_message list; cumulated_size : int}

let pp fmt {contents; cumulated_size} =
  Format.fprintf
    fmt
    "tx rollup inbox: %d messages using %d bytes"
    (List.length contents)
    cumulated_size

let message_result_encoding =
  let open Data_encoding in
  (* FIXME/TORU Dummy value, use actual encoding *)
  conv (fun _ -> ()) (fun () -> Discarded []) unit

let inbox_message_encoding =
  let open Data_encoding in
  conv
    (fun {message; result; context_hash} -> (message, result, context_hash))
    (fun (message, result, context_hash) -> {message; result; context_hash})
    (obj3
       (req "message" Tx_rollup_message.encoding)
       (req "result" message_result_encoding)
       (req "context_hash" Tx_rollup_l2_context_hash.encoding))

let encoding =
  let open Data_encoding in
  conv
    (fun {contents; cumulated_size} -> (contents, cumulated_size))
    (fun (contents, cumulated_size) -> {contents; cumulated_size})
    (obj2
       (req "contents" @@ list inbox_message_encoding)
       (req "cumulated_size" int31))

let to_protocol_inbox {contents; cumulated_size} =
  Tx_rollup_inbox.
    {
      contents =
        List.map (fun {message; _} -> Tx_rollup_message.hash message) contents;
      cumulated_size;
    }
