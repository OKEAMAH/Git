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

(** A [withdrawal] gives right to a L1 address [destination] to
    retrieve up to [amount] tokens of a ticket [ticket_hash].
    Withdrawals result from layer-2-to-layer-1 transfers, and from
    failed layer-2 deposits.*)
type withdrawal = {
  destination : Signature.Public_key_hash.t;
  ticket_hash : Ticket_hash_repr.t;
  amount : Tx_rollup_l2_qty.t;
}

type t = withdrawal

val encoding : t Data_encoding.t

(** A [list_hash] is the hash of a list of withdrawals (as returned by
    [Tx_rollup_l2_apply.apply_message]), stored in commitments and used
    to validate the executions of withdrawals.

    Internally [list_hash] is the root hash of a merkle tree
*)
type list_hash

val list_hash_encoding : list_hash Data_encoding.t

(** A [path] is the minimal information needed to recompute a list_hash without
    having all withdrawals.

    Internally [path] is the path of sub-tree hash of a [list_hash] *)
type path

val path_encoding : path Data_encoding.t

(** [hash_list withdrawal_list] hash [withdrawal_list] into a [list_hash]. This
    is used by the rejection mecanism to validate a list of withdrawal. It can
    also be used by a rollup node to produce the valid [list_hash] for a
    withdrawal list return by [Tx_rollup_l2_apply.apply_message] *)
val hash_list : t list -> list_hash

(** [compute_path withdrawal_list index] compute the [path] of the [index]
    element of the [withdrawal_list].*)
val compute_path : t list -> int -> path

(** [check_path path withdrawal] return the [list_hash] computed for
    [withdrawal] and the index on the list. *)
val check_path : path -> t -> list_hash * int

(** [Withdrawal_accounting] provide a interface to do accounting of index. It
    has a minimal footprint.

    It is used by the storage to store which withdrawal index have already been
    submitted by a user.*)
module Withdrawal_accounting : sig
  type t = int64 list

  val empty : t

  (** [get l index] check if the [index] was set previously in [l]. Fails when
      [index] is negative. *)
  val get : t -> int -> bool tzresult

  (** [set l index] set [index] in [l] to [true]. Fails when [index] is
      negative. *)
  val set : t -> int -> t tzresult

  val encoding : t Data_encoding.t
end
