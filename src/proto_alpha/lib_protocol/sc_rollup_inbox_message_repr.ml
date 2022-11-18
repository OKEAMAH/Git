(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type error +=
  | (* `Permanent *) Error_encode_inbox_message
  | (* `Permanent *) Error_decode_inbox_message

let () =
  let open Data_encoding in
  let msg =
    "Failed to encode a rollup management protocol inbox message value"
  in
  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox_message_repr.error_encoding_inbox_message"
    ~title:msg
    ~pp:(fun fmt () -> Format.fprintf fmt "%s" msg)
    ~description:msg
    unit
    (function Error_encode_inbox_message -> Some () | _ -> None)
    (fun () -> Error_encode_inbox_message) ;
  let msg =
    "Failed to decode a rollup management protocol inbox message value"
  in
  register_error_kind
    `Permanent
    ~id:"sc_rollup_inbox_message_repr.error_decoding_inbox_message"
    ~title:msg
    ~pp:(fun fmt () -> Format.fprintf fmt "%s" msg)
    ~description:msg
    unit
    (function Error_decode_inbox_message -> Some () | _ -> None)
    (fun () -> Error_decode_inbox_message)

type internal_inbox_message =
  | Transfer of {
      payload : Script_repr.expr;
      sender : Contract_hash.t;
      source : Signature.public_key_hash;
      destination : Sc_rollup_repr.Address.t;
    }
  | Start_of_level
  | End_of_level

let internal_inbox_message_encoding =
  let open Data_encoding in
  let kind name = req "internal_inbox_message_kind" (constant name) in
  union
    [
      case
        (Tag 0)
        ~title:"Transfer"
        (obj5
           (kind "transfer")
           (req "payload" Script_repr.expr_encoding)
           (req "sender" Contract_hash.encoding)
           (req "source" Signature.Public_key_hash.encoding)
           (req "destination" Sc_rollup_repr.Address.encoding))
        (function
          | Transfer {payload; sender; source; destination} ->
              Some ((), payload, sender, source, destination)
          | _ -> None)
        (fun ((), payload, sender, source, destination) ->
          Transfer {payload; sender; source; destination});
      case
        (Tag 1)
        ~title:"Start_of_level"
        (obj1 (kind "start_of_level"))
        (function Start_of_level -> Some () | _ -> None)
        (fun () -> Start_of_level);
      case
        (Tag 2)
        ~title:"End_of_level"
        (obj1 (kind "end_of_level"))
        (function End_of_level -> Some () | _ -> None)
        (fun () -> End_of_level);
    ]

type t = Internal of internal_inbox_message | External of bytes

let encoding =
  let open Data_encoding in
  check_size
    Constants_repr.sc_rollup_message_size_limit
    (union
       [
         case
           (Tag 0)
           ~title:"Internal"
           internal_inbox_message_encoding
           (function
             | Internal internal_message -> Some internal_message
             | External _ -> None)
           (fun internal_message -> Internal internal_message);
         case
           (Tag 1)
           ~title:"External"
           Variable.bytes
           (function External msg -> Some msg | Internal _ -> None)
           (fun msg -> External msg);
       ])

type serialized = bytes

let serialize msg =
  let open Result_syntax in
  match Data_encoding.Binary.to_bytes_opt encoding msg with
  | None -> tzfail Error_encode_inbox_message
  | Some str -> return str

let deserialize s =
  let open Result_syntax in
  match Data_encoding.Binary.of_bytes_opt encoding s with
  | None -> tzfail Error_decode_inbox_message
  | Some msg -> return msg

let unsafe_of_bytes s = s

let unsafe_to_bytes s = s

(* 32 *)
let hash_prefix = "\003\250\174\239\012" (* scib3(55) *)

module Hash = struct
  let prefix = "scib3"

  let encoded_size = 55

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "serialized_message_hash"

        let title =
          "The hash of a serialized message of the smart contract rollup inbox."

        let b58check_prefix = hash_prefix

        (* defaults to 32 *)
        let size = None
      end)

  include H

  let () = Base58.check_encoded_prefix b58check_encoding prefix encoded_size
end

let hash_serialized_message (payload : serialized) = Hash.hash_bytes [payload]
