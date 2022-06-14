(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold. <contact@marigold.dev>                       *)
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

type error += (* `Permanent *) Invalid_event_notation of string

module Hash = struct
  let prefix = "\058\017\082" (* "ev1" (32) *)

  module H =
    Blake2B.Make
      (Base58)
      (struct
        let name = "Event"

        let title = "Event sink"

        let b58check_prefix = prefix

        let size = None
      end)

  include H

  let () = Base58.check_encoded_prefix b58check_encoding "ev1" 53

  include Path_encoding.Make_hex (H)
end

type address = Hash.t

(* Canonical contract event log entry *)
type t = {addr : address; data : Script_repr.expr}

let ty_encoding =
  Micheline.canonical_encoding
    ~variant:"michelson_v1"
    Michelson_v1_primitives.prim_encoding

(* Serialization scheme for an event log entry in Micheline format *)
let encoding =
  let open Data_encoding in
  let encoding =
    obj2 (req "address" Hash.encoding) (req "data" Script_repr.expr_encoding)
  in
  let into (addr, data) = {data; addr} in
  let from {data; addr} = (addr, data) in
  conv from into encoding

let of_b58data = function Hash.Data hash -> Some hash | _ -> None

let pp = Hash.pp

let of_b58check_opt s = Option.bind (Base58.decode s) of_b58data

let of_b58check s =
  match of_b58check_opt s with
  | Some hash -> ok hash
  | _ -> error (Invalid_event_notation s)

let to_b58check hash = Hash.to_b58check hash

let in_memory_size _ =
  let open Cache_memory_helpers in
  header_size +! word_size +! string_size_gen 32
