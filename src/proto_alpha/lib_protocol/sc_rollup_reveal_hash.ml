(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

(* Reserve the first byte in the encoding to support multi-versioning
   in the future. *)
module Blake2B = struct
  include
    Blake2B.Make
      (Base58)
      (struct
        let name = "Smart_rollup_reveal_data_blake2b_hash"

        let title = "A smart rollup reveal hash"

        let b58check_prefix =
          "\230\206\128\200\196" (* "scrrh1(56)" decoded from Base58. *)

        let size = Some 32
      end)

  let () = Base58.check_encoded_prefix b58check_encoding "scrrh1" 56
end

module Merkelized_bytes =
  Merkle_list.Make
    (struct
      include Bytes

      let to_bytes b = b
    end)
    (Blake2B)

type supported_hashes = Blake2B

type t =
  | Blake2B of Blake2B.t
  | Merkle_root_Blake2B of {index : int; root : Merkelized_bytes.h}

let zero ~(scheme : supported_hashes) =
  match scheme with Blake2B -> Blake2B Blake2B.zero

let pp ppf hash =
  match hash with
  | Blake2B hash -> Blake2B.pp ppf hash
  | Merkle_root_Blake2B {root; index} ->
      Format.fprintf
        ppf
        "Merkelized_Blake2B:@,Index: %a@,Root: '%a'"
        Format.pp_print_int
        index
        Blake2B.pp
        root

let equal h1 h2 =
  match (h1, h2) with
  | Blake2B h1, Blake2B h2 -> Blake2B.equal h1 h2
  | ( Merkle_root_Blake2B {root = r1; index = i1},
      Merkle_root_Blake2B {root = r2; index = i2} ) ->
      Blake2B.equal r1 r2 && Compare.Int.equal i1 i2
  | _, _ -> false

let compare h1 h2 =
  match (h1, h2) with
  | Blake2B h1, Blake2B h2 -> Blake2B.compare h1 h2
  | ( Merkle_root_Blake2B {root = r1; index = i1},
      Merkle_root_Blake2B {root = r2; index = i2} ) -> (
      match Blake2B.compare r1 r2 with 0 -> Compare.Int.compare i1 i2 | c -> c)
  | Blake2B _, Merkle_root_Blake2B _ -> -1
  | Merkle_root_Blake2B _, Blake2B _ -> 1

module Map = Map.Make (struct
  type tmp = t

  type t = tmp

  let compare = compare
end)

(* Size of the hash is the size of the inner hash plus one byte for the
   tag used to identify the hashing scheme. *)
let size ~(scheme : supported_hashes) =
  let tag_size = 1 in
  let size_without_tag = match scheme with Blake2B -> Blake2B.size in
  tag_size + size_without_tag

let encoding =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Reveal_data_hash_v0"
        (Tag 0)
        Blake2B.encoding
        (function Blake2B s -> Some s | Merkle_root_Blake2B _ -> None)
        (fun s -> Blake2B s);
      case
        ~title:"Reveal_data_hash_v1"
        (Tag 1)
        (obj2 (req "index" int31) (req "root" Blake2B.encoding))
        (function Merkle_root_Blake2B t -> Some (t.index, t.root) | _ -> None)
        (fun (index, root) -> Merkle_root_Blake2B {index; root});
    ]

let hash_string ~(scheme : supported_hashes) ?key strings =
  match scheme with Blake2B -> Blake2B (Blake2B.hash_string ?key strings)

let hash_bytes ~(scheme : supported_hashes) ?key bytes =
  match scheme with Blake2B -> Blake2B (Blake2B.hash_bytes ?key bytes)

let scheme_of_hash hash =
  match hash with
  | Blake2B _ | Merkle_root_Blake2B _ -> (Blake2B : supported_hashes)

let to_hex hash =
  let (`Hex hash) =
    (* The [encoding] of a hash here never, so [to_string_exn] is safe. *)
    Hex.of_string @@ Data_encoding.Binary.to_string_exn encoding hash
  in
  hash

let of_hex hex =
  let open Option_syntax in
  let* hash = Hex.to_bytes (`Hex hex) in
  Data_encoding.Binary.of_bytes_opt encoding hash

let reveal_hash_merkle ~index ~merkle_root =
  Merkle_root_Blake2B {index; root = merkle_root}

let rpc_arg =
  let construct = to_hex in
  let destruct hash =
    match of_hex hash with
    | None -> Error "Cannot parse reveal hash"
    | Some reveal_hash -> Ok reveal_hash
  in
  RPC_arg.make
    ~descr:"A reveal hash"
    ~name:"reveal_hash"
    ~destruct
    ~construct
    ()
