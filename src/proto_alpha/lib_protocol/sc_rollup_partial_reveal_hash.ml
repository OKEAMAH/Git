(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

type u = {index : int; root : Sc_rollup_reveal_hash.t}

module type M = sig
  include Merkle_list.T

  val make : index:int -> root:h -> u
end

module Merkelized_bytes_Blake2B :
  M with type elt = bytes and type h = Sc_rollup_reveal_hash.Blake2B.t = struct
  include
    Merkle_list.Make
      (struct
        include Bytes

        let to_bytes b = b
      end)
      (Sc_rollup_reveal_hash.Blake2B)

  let make ~index ~root = {index; root = Sc_rollup_reveal_hash.Blake2B root}
end

let to_mod :
    type h.
    h Sc_rollup_reveal_hash.supported_hashes ->
    (module M with type elt = bytes and type h = h) = function
  | Sc_rollup_reveal_hash.Blake2B -> (module Merkelized_bytes_Blake2B)

let encoding : u Data_encoding.t =
  let open Data_encoding in
  union
    ~tag_size:`Uint8
    [
      case
        ~title:"Partial_reveal_data_hash_v0"
        (Tag 0)
        (obj2 (req "index" int31) (req "root" Sc_rollup_reveal_hash.encoding))
        (function {index; root} -> Some (index, root))
        (fun (index, root) -> {index; root});
    ]

let to_hex hash =
  let (`Hex hash) =
    (* The [hash] can be encoded safely ([Data_encoding.Binary.to_string_exn]
       doesn't fail) as its type [u] matches the type of [encoding] ([u Data_encoding.t]). *)
    Hex.of_string @@ Data_encoding.Binary.to_string_exn encoding hash
  in
  hash

let of_hex hex =
  let open Option_syntax in
  let* hash = Hex.to_bytes (`Hex hex) in
  Data_encoding.Binary.of_bytes_opt encoding hash

let merkle_tree (type t)
    (module M : Merkle_list.T with type t = t and type elt = bytes) ~elts : M.t
    =
  M.of_list elts

let merkle_root (type t h)
    (module M : Merkle_list.T with type t = t and type h = h) ~tree : M.h =
  M.root tree

let make (type h) (module M : M with type elt = bytes and type h = h) ~index
    ~(root : h) =
  M.make ~index ~root
