(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxheadalpha.com>                    *)
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

type withdrawal = {
  claimer : Signature.Public_key_hash.t;
  ticket_hash : Ticket_hash_repr.t;
  amount : Tx_rollup_l2_qty.t;
}

type t = withdrawal

let encoding : withdrawal Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {claimer; ticket_hash; amount} -> (claimer, ticket_hash, amount))
    (fun (claimer, ticket_hash, amount) -> {claimer; ticket_hash; amount})
    (obj3
       (req "claimer" Signature.Public_key_hash.encoding)
       (req "ticket_hash" Ticket_hash_repr.encoding)
       (req "amount" Tx_rollup_l2_qty.encoding))

module Withdrawal = struct
  type nonrec t = t

  let to_bytes = Data_encoding.Binary.to_bytes_exn encoding
end

module Prefix = struct
  let name = "Withdrawal_list_hash"

  let title = "A merkle root hash for withdrawals"

  let b58check_prefix = Tx_rollup_prefixes.withdraw_list_hash.b58check_prefix

  let size = Some Tx_rollup_prefixes.withdraw_list_hash.hash_size
end

module H = Blake2B.Make (Base58) (Prefix)

module Merkle = struct
  module Merkle_list = Merkle_list.Make (Withdrawal) (H)

  type tree = Merkle_list.t

  type root = Merkle_list.h

  type path = Merkle_list.path

  let nil = Merkle_list.nil

  let empty = Merkle_list.empty

  let root = Merkle_list.root

  let ( = ) = H.( = )

  let compare = H.compare

  let root_encoding = H.encoding

  let root_of_b58check_opt = H.of_b58check_opt

  let pp_root = H.pp

  let path_encoding = Merkle_list.path_encoding

  let tree_of_messages = List.fold_left Merkle_list.snoc Merkle_list.nil

  let check_path = Merkle_list.check_path

  let path_depth = Merkle_list.path_depth

  let compute_path messages position =
    let tree = tree_of_messages messages in
    Merkle_list.compute_path tree position

  let merklize_list messages =
    let tree = tree_of_messages messages in
    root tree
end

let maximum_path_depth ~withdraw_count_limit =
  (* We assume that the Merkle_tree implemenation computes a tree in a
     logarithmic size of the number of leaves. *)
  let log2 n = Z.numbits (Z.of_int n) in
  log2 withdraw_count_limit

type error += Negative_withdrawal_index of int | Too_big_withdrawal_index of int

let () =
  let open Data_encoding in
  register_error_kind
    `Permanent
    ~id:"tx_rollup_negative_withdrawal_index"
    ~title:"The withdrawal index must be non-negative"
    ~description:"The withdrawal index must be non-negative"
    (obj1 (req "withdraw_position" int31))
    (function Negative_withdrawal_index i -> Some i | _ -> None)
    (fun i -> Negative_withdrawal_index i) ;
  register_error_kind
    `Permanent
    ~id:"tx_rollup_invalid_withdrawal_argument"
    ~title:"The withdrawal index must be less than 64"
    ~description:"The withdrawal index must be less than 64"
    (obj1 (req "withdraw_position" int31))
    (function Too_big_withdrawal_index i -> Some i | _ -> None)
    (fun i -> Too_big_withdrawal_index i)

type withdrawal_info = {
  contents : Script_repr.lazy_expr;
  ty : Script_repr.lazy_expr;
  ticketer : Contract_repr.t;
  amount : Tx_rollup_l2_qty.t;
  claimer : Signature.Public_key_hash.t;
}

let withdrawal_info_encoding : withdrawal_info Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {contents; ty; ticketer; amount; claimer} ->
      (contents, ty, ticketer, amount, claimer))
    (fun (contents, ty, ticketer, amount, claimer) ->
      {contents; ty; ticketer; amount; claimer})
    (obj5
       (req "contents" Script_repr.lazy_expr_encoding)
       (req "ty" Script_repr.lazy_expr_encoding)
       (req "ticketer" Contract_repr.encoding)
       (req "amount" Tx_rollup_l2_qty.encoding)
       (req "claimer" Signature.Public_key_hash.encoding))

module Withdrawal_accounting = struct
  (** Internally, the withdrawal accounting is implemented through a
      list of [int64], encoding an "infinite" bitvector [bitv], so that, intuitively:

        bitv[[ofs]] = 1 <-> [ofs]th withdrawal is consumed.

      where [bitv[[ofs]]] is the [ofs % 64]th bit of the [ofs/64]th element of [bitv].
   *)
  type t = int64 list

  let empty = []

  let encoding = Data_encoding.(list int64)

  let error_when_negative ofs =
    error_when Compare.Int.(ofs < 0) (Negative_withdrawal_index ofs)

  let error_when_out_of_bound ofs =
    error_when_negative ofs >>? fun () ->
    error_when Compare.Int.(ofs > 63) (Too_big_withdrawal_index ofs)

  (** [int64_get i ofs] returns [true] if the [ofs]th bit of [i] is
      [1].  Fails if [ofs] is negative or larger than 63. *)
  let int64_get (i : int64) (ofs : int) =
    error_when_out_of_bound ofs >>? fun () ->
    let open Int64 in
    let i = shift_right_logical i ofs in
    let i = logand i one in
    ok @@ equal i one

  (** [int64_set i ofs] sets the [ofs]th bit of [i] to [1].
      Fails if [ofs] is negative or larger than 63. *)
  let int64_set (i : int64) (ofs : int) =
    error_when_out_of_bound ofs >>? fun () ->
    let open Int64 in
    ok @@ logor i (shift_left one ofs)

  (** [get bitv ofs] returns true if the [ofs]th bit of the
      concatenation of the bitvector [bitv] is [1].

      More precisely, it returns true if the [ofs % 64]th bit of the
      [ofs/64]th element of [bitv] is [1].

      Fails if [ofs] is negative. *)
  let get (bitv : t) (ofs : int) =
    error_when_negative ofs >>? fun () ->
    match List.nth_opt bitv (ofs / 64) with
    | Some i -> int64_get i (ofs mod 64)
    | None -> ok false

  (** [set bitv ofs] sets the [ofs]th bit in the concatenation of the
      bitvector [bitv] to [1].

      More precisely, it sets the [ofs % 64]th bit of the [ofs/64]th
      element of [bitv] to [1]. If [bitv] has less than
      [ofs/64] elements, than [bitv] is right-padded with empty
      elements ([0L]) until it reaches [ofs/64] elements.

      Fails if [ofs] is negative. *)
  let rec set (bitv : t) (ofs : int) =
    error_when_negative ofs >>? fun () ->
    if Compare.Int.(ofs < 64) then
      match bitv with
      | [] -> int64_set Int64.zero ofs >|? fun i -> [i]
      | i :: bitv' -> int64_set i ofs >|? fun i -> i :: bitv'
    else
      match bitv with
      | [] -> set [] (ofs - 64) >|? fun i -> Int64.zero :: i
      | i :: bitv' -> set bitv' (ofs - 64) >|? fun bitv' -> i :: bitv'
end
