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

module Merkelized_bytes_Blake2B_raw =
  Merkle_list.Make
    (struct
      include Bytes

      let to_bytes b = b
    end)
    (Sc_rollup_reveal_hash.Blake2B)

type proof = Merkle_Blake2B of Merkelized_bytes_Blake2B_raw.path

type tree = Merkle_Blake2B of Merkelized_bytes_Blake2B_raw.t

module type M = sig
  include Merkle_list.T

  val make : index:int -> root:h -> u

  val proof_of_path : path -> proof

  val path_of_proof : proof -> path

  val t_of_tree : tree -> t

  val tree_of_t : t -> tree

  val merkle_tree : elts:elt list -> tree

  val produce_proof : tree:tree -> index:int -> proof tzresult
end

module Merkelized_bytes_Blake2B :
  M with type elt = bytes and type h = Sc_rollup_reveal_hash.Blake2B.t = struct
  include Merkelized_bytes_Blake2B_raw

  let make ~index ~root = {index; root = Sc_rollup_reveal_hash.Blake2B root}

  let proof_of_path : path -> proof = fun p -> Merkle_Blake2B p

  let path_of_proof : proof -> path = function Merkle_Blake2B p -> p

  let t_of_tree : tree -> t = function Merkle_Blake2B t -> t

  let tree_of_t : t -> tree = fun t -> Merkle_Blake2B t

  let merkle_tree ~elts : tree = tree_of_t (of_list elts)

  let produce_proof : tree:tree -> index:int -> proof tzresult =
   fun ~tree ~index ->
    let open Result_syntax in
    let* path = compute_path (t_of_tree tree) index in
    return (proof_of_path path)
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

let pp ppf (hash : u) =
  Format.(fprintf ppf "(%d, %a)" hash.index Sc_rollup_reveal_hash.pp hash.root)

let produce_proof (type t h)
    (module M : M with type t = t and type elt = bytes and type h = h)
    ~(tree : t) ~index : proof tzresult =
  let open Result_syntax in
  let* path = M.(compute_path tree index) in
  return (M.proof_of_path path)

let produce_proof_reveal_hash ~tree ({root; index} : u) =
  match root with
  | Blake2B _ -> Merkelized_bytes_Blake2B.produce_proof ~tree ~index

let verify_proof (type t h)
    (module M : M with type t = t and type elt = bytes and type h = h) ~proof
    ~index ~elt ~expected_root : bool tzresult =
  M.check_path (M.path_of_proof proof) index elt expected_root

let verify_proof_reveal_hash ~proof ~index ~elt
    ~(expected_root : Sc_rollup_reveal_hash.t) =
  match expected_root with
  | Blake2B root ->
      let (module Blake) = to_mod Sc_rollup_reveal_hash.Blake2B in
      verify_proof (module Blake) ~proof ~index ~elt ~expected_root:root

let proof_encoding : proof Data_encoding.t =
  let open Data_encoding in
  union
    [
      case
        ~title:"Merkle_Blake2B"
        (Tag 0)
        Merkelized_bytes_Blake2B_raw.path_encoding
        (function (Merkle_Blake2B p : proof) -> Some p)
        (fun p -> Merkle_Blake2B p);
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

let merkle_tree_reveal_hash ~elts ({root; _} : u) =
  match root with Blake2B _ -> Merkelized_bytes_Blake2B.merkle_tree ~elts

let merkle_root (type t h)
    (module M : Merkle_list.T with type t = t and type h = h) ~tree : M.h =
  M.root tree

let make (type h) (module M : M with type elt = bytes and type h = h) ~index
    ~(root : h) =
  M.make ~index ~root
