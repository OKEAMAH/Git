(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

module Framed (Payload : sig
  type t

  val encoding : t Data_encoding.t
end) =
struct
  type t = {rollup_address : Sc_rollup_repr.Address.t; payload : Payload.t}

  let encoding : t Data_encoding.t =
    let open Data_encoding in
    union
      [
        case
          (Tag 0)
          ~title:(Format.sprintf "Framed message of version 0")
          (obj2
             (req "destination" Sc_rollup_repr.Address.encoding)
             (req "payload" Payload.encoding))
          (fun {rollup_address; payload} -> Some (rollup_address, payload))
          (fun (rollup_address, payload) -> {rollup_address; payload});
      ]
end

type msg =
  | Sequence of {
      delayed_messages : int32;
      (* Fix: it should be uint32 *)
      l2_messages : L2_message.t list;
      signature : Signature.V0.signature;
    }

include Framed (struct
  type t = msg

  let encoding : t Data_encoding.t =
    let open Data_encoding in
    union
      [
        case
          (Tag 0)
          ~title:(Format.sprintf "Sequence message")
          (obj3
             (req "delayed_messages" int32)
             (req "l2_messages" @@ dynamic_size
             (* Fix use binary encoding instead of hex encoding used in content_encoding *)
             @@ list L2_message.content_encoding)
             (req "signature" Signature.V0.encoding))
          (function
            | Sequence {delayed_messages; l2_messages; signature} ->
                Some
                  ( delayed_messages,
                    List.map L2_message.content l2_messages,
                    signature ))
          (fun (delayed_messages, messages, signature) ->
            Sequence
              {
                delayed_messages;
                l2_messages = List.map L2_message.make messages;
                signature;
              });
      ]
end)

let sequence_message_overhead_size messages_num =
  64 (* 64 bytes for signature *) + 4
  (* 4 bytes for delayed inbox size *)
  + (4 * messages_num)
(* each message prepended with its size *)

let encode_sequence_message rollup_address (delayed_messages : int32)
    (l2_messages : L2_message.t list) : string =
  (* Fix: actually sign a message *)
  let dummy_sig =
    Signature.V0.of_bytes_exn @@ Bytes.make Signature.V0.size @@ Char.chr 0
  in
  let sequence =
    Sequence {delayed_messages; l2_messages; signature = dummy_sig}
  in
  Data_encoding.Binary.to_string_exn encoding
  @@ {rollup_address; payload = sequence}
