(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

include Tezos_context_encoding.Context

module Conf : Irmin_pack.Conf.S = struct
  let entries = 2

  let stable_hash = 2

  let inode_child_order = `Seeded_hash
end

module Hash : sig
  include Irmin.Hash.S

  val to_raw_string : t -> string

  val to_context_hash : t -> Protocol.Tx_rollup_l2_context_hash.t

  val of_context_hash : Protocol.Tx_rollup_l2_context_hash.t -> t
end = struct
  open Protocol

  module H = Digestif.Make_BLAKE2B (struct
    let digest_size = 32
  end)

  type t = H.t

  let to_raw_string = H.to_raw_string

  let of_context_hash s =
    Tx_rollup_l2_context_hash.to_bytes s |> Bytes.to_string |> H.of_raw_string

  let to_context_hash h =
    H.to_raw_string h |> Bytes.of_string
    |> Tx_rollup_l2_context_hash.of_bytes_exn

  let pp ppf t = Tx_rollup_l2_context_hash.pp ppf (to_context_hash t)

  let of_string x =
    match Tx_rollup_l2_context_hash.of_b58check_opt x with
    | Some x -> Ok (of_context_hash x)
    | None ->
        Error (`Msg "Failed to read b58check encoded tx_rollup_l2_context")

  let short_hash_string = Irmin.Type.(unstage (short_hash string))

  let short_hash ?seed t = short_hash_string ?seed (H.to_raw_string t)

  let t : t Irmin.Type.t =
    Irmin.Type.map
      ~pp
      ~of_string
      Irmin.Type.(string_of (`Fixed H.digest_size))
      ~short_hash
      H.of_raw_string
      H.to_raw_string

  let short_hash =
    let f = short_hash_string ?seed:None in
    fun t -> f (H.to_raw_string t)

  let hash_size = H.digest_size

  let hash = H.digesti_string
end
