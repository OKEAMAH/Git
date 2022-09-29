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
  | (* `Permanent *) Invalid_proof

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

type internal_inbox_message = {
  payload : Script_repr.expr;
  sender : Contract_hash.t;
  source : Signature.public_key_hash;
}

type t = Internal of internal_inbox_message | External of string

let encoding =
  let open Data_encoding in
  check_size
    Constants_repr.sc_rollup_message_size_limit
    (union
       [
         case
           (Tag 0)
           ~title:"Internal"
           (obj3
              (req "payload" Script_repr.expr_encoding)
              (req "sender" Contract_hash.encoding)
              (req "source" Signature.Public_key_hash.encoding))
           (function
             | Internal {payload; sender; source} ->
                 Some (payload, sender, source)
             | External _ -> None)
           (fun (payload, sender, source) -> Internal {payload; sender; source});
         case
           (Tag 1)
           ~title:"External"
           Variable.string
           (function External msg -> Some msg | Internal _ -> None)
           (fun msg -> External msg);
       ])

type serialized = string

let serialized_encoding = Data_encoding.string

let serialize msg =
  let open Tzresult_syntax in
  match Data_encoding.Binary.to_string_opt encoding msg with
  | None -> fail Error_encode_inbox_message
  | Some str -> return str

let deserialize s =
  let open Tzresult_syntax in
  match Data_encoding.Binary.of_string_opt encoding s with
  | None -> fail Error_decode_inbox_message
  | Some msg -> return msg

let unsafe_of_string s = s

let unsafe_to_string s = s

(* 32 *)
let hash_prefix = "\003\250\174\238\238" (* scib2(55) *)

module Hash = struct
  let prefix = "scib2"

  let encoded_size = 55

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "inbox_hash"

        let title = "The hash of an inbox of a smart contract rollup"

        let b58check_prefix = hash_prefix

        (* defaults to 32 *)
        let size = None
      end)

  include H

  let () = Base58.check_encoded_prefix b58check_encoding prefix encoded_size

  include Path_encoding.Make_hex (H)
end

module Skip_list_parameters = struct
  let basis = 2
end

module Skip_list = Skip_list_repr.Make (Skip_list_parameters)

module Merkelized_messages = struct
  type message_proof = (serialized, Hash.t) Skip_list.cell

  type messages_proof = {
    current_message : message_proof;
    level : Raw_level_repr.t;
  }

  let equal_message_proof = Skip_list.equal Hash.equal String.equal

  let message_proof_encoding : message_proof Data_encoding.t =
    Skip_list.encoding Hash.encoding serialized_encoding

  let equal messages1 messages2 =
    Raw_level_repr.equal messages1.level messages2.level
    && equal_message_proof messages1.current_message messages2.current_message

  let hash {current_message; level} =
    let level_bytes =
      Raw_level_repr.to_int32 level |> Int32.to_string |> Bytes.of_string
    in
    let payload = Skip_list.content current_message in
    let back_pointers_hashes = Skip_list.back_pointers current_message in
    Bytes.of_string (payload : serialized :> string)
    :: level_bytes
    :: List.map Hash.to_bytes back_pointers_hashes
    |> Hash.hash_bytes

  let pp fmt ({current_message; level} as messages) =
    let messages_hash = hash messages in
    Format.fprintf
      fmt
      "@[hash : %a@;latest message: %a;level: %a@]"
      Hash.pp
      messages_hash
      (Skip_list.pp ~pp_content:Format.pp_print_string ~pp_ptr:Hash.pp)
      current_message
      Raw_level_repr.pp
      level

  let encoding =
    Data_encoding.conv
      (fun {current_message; level} -> (current_message, level))
      (fun (current_message, level) -> {current_message; level})
      (Data_encoding.tup2 message_proof_encoding Raw_level_repr.encoding)

  module History = struct
    include
      Bounded_history_repr.Make
        (struct
          let name = "level_inbox_history"
        end)
        (Hash)
        (struct
          type nonrec t = messages_proof

          let pp = pp

          let equal = equal

          let encoding = encoding
        end)

    let no_history = empty ~capacity:0L
  end

  let empty level =
    let first_msg = unsafe_of_string "" in
    {current_message = Skip_list.genesis first_msg; level}

  let add_to_history history messages_proof =
    let prev_cell_ptr = hash messages_proof in
    History.remember prev_cell_ptr messages_proof history

  let add_message history messages_proof payload =
    let open Tzresult_syntax in
    let prev_message = messages_proof.current_message in
    let prev_message_ptr = hash messages_proof in
    let current_message =
      Skip_list.next
        ~prev_cell:prev_message
        ~prev_cell_ptr:prev_message_ptr
        payload
    in
    let new_messages_proof = {current_message; level = messages_proof.level} in
    let* history = add_to_history history new_messages_proof in
    return (history, new_messages_proof)

  let get_number_of_messages {current_message; _} =
    Skip_list.index current_message

  let get_message_payload = Skip_list.content

  let get_current_message_payload {current_message; _} =
    get_message_payload current_message

  let get_level {level; _} = level

  let to_bytes = Data_encoding.Binary.to_bytes_exn encoding

  let of_bytes = Data_encoding.Binary.of_bytes_opt encoding

  type proof = {message : message_proof; inclusion_proof : message_proof list}

  let proof_encoding =
    let open Data_encoding in
    conv
      (fun {message; inclusion_proof} -> (message, inclusion_proof))
      (fun (message, inclusion_proof) -> {message; inclusion_proof})
      (obj2
         (req "message" message_proof_encoding)
         (req "inclusion_proof" (list message_proof_encoding)))

  let produce_proof history ~message_index messages : proof option =
    let open Option_syntax in
    let deref ptr =
      let+ {current_message; level = _} = History.find ptr history in
      current_message
    in
    let current_ptr = hash messages in
    let lift_ptr =
      let rec aux acc = function
        | [] -> None
        | [last_ptr] ->
            let+ message = History.find last_ptr history in
            {
              message = message.current_message;
              inclusion_proof = List.rev (message.current_message :: acc);
            }
        | x :: xs ->
            let* cell = deref x in
            aux (cell :: acc) xs
      in
      aux []
    in
    let* ptr_path =
      Skip_list.back_path
        ~deref
        ~cell_ptr:current_ptr
        ~target_index:message_index
    in
    lift_ptr ptr_path

  let verify_proof {message; inclusion_proof} messages =
    let open Tzresult_syntax in
    let level = messages.level in
    let hash_map, ptr_list =
      List.fold_left
        (fun (hash_map, ptr_list) message_proof ->
          let message_ptr = hash {current_message = message_proof; level} in
          ( Hash.Map.add message_ptr message_proof hash_map,
            message_ptr :: ptr_list ))
        (Hash.Map.empty, [])
        inclusion_proof
    in
    let ptr_list = List.rev ptr_list in
    let equal_ptr = Hash.equal in
    let deref ptr = Hash.Map.find ptr hash_map in
    let cell_ptr = hash messages in
    let target_ptr = hash {current_message = message; level} in
    let* () =
      error_unless
        (Skip_list.valid_back_path
           ~equal_ptr
           ~deref
           ~cell_ptr
           ~target_ptr
           ptr_list)
        Invalid_proof
    in
    return (Skip_list.content message, level, Skip_list.index message)
end
