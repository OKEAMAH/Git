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

type t = {index : int; root : Sc_rollup_reveal_hash.t}

module Merkelized_bytes_Blake2B :
  Merkle_list.T
    with type elt = string
     and type h = Sc_rollup_reveal_hash.Blake2B.t = struct
  include
    Merkle_list.Make
      (struct
        include String

        let to_bytes = Bytes.of_string
      end)
      (Sc_rollup_reveal_hash.Blake2B)
end

let make :
    type h.
    scheme:h Sc_rollup_reveal_hash.supported_hashes -> index:int -> root:h -> t
    =
 fun ~scheme ~index ~root ->
  match scheme with
  | Sc_rollup_reveal_hash.Blake2B ->
      {index; root = Sc_rollup_reveal_hash.Blake2B root}

let merkle_list_of_scheme :
    type h.
    scheme:h Sc_rollup_reveal_hash.supported_hashes ->
    (module Merkle_list.T with type elt = string and type h = h) =
 fun ~scheme ->
  match scheme with
  | Sc_rollup_reveal_hash.Blake2B -> (module Merkelized_bytes_Blake2B)

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (function {index; root} -> (index, root))
    (fun (index, root) -> {index; root})
    (obj2 (req "index" int31) (req "root" Sc_rollup_reveal_hash.encoding))

let pp ppf (t : t) =
  Format.(fprintf ppf "(%d, %a)" t.index Sc_rollup_reveal_hash.pp t.root)

let to_hex t =
  let (`Hex t) =
    (* The [t] can be encoded safely ([Data_encoding.Binary.to_string_exn]
       doesn't fail) as its type [t] matches the type of [encoding] ([t Data_encoding.t]). *)
    Hex.of_string @@ Data_encoding.Binary.to_string_exn encoding t
  in
  t

let of_hex hex =
  let open Option_syntax in
  let* hash = Hex.to_bytes (`Hex hex) in
  Data_encoding.Binary.of_bytes_opt encoding hash
