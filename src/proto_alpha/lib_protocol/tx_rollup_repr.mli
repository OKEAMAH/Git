(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Marigold <contact@marigold.dev>                        *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** This module defines identifiers for transaction only rollup (or
    tx rollup).  It also specifies how to compute originated
    tx rollup's hash from origination nonce. *)

(** A specialized Blake2B implementation for hashing tx_rollup identifiers with
    "tru1" as a base58 prefix *)
module Hash : sig
  val rollup_hash : string

  include S.HASH
end

type t = private Hash.t

type tx_rollup = t

include Compare.S with type t := t

(** [in_memory_size tx_rollup] returns the number of bytes [tx_rollup]
    uses in RAM. *)
val in_memory_size : t -> Cache_memory_helpers.sint

val to_b58check : t -> string

val of_b58check : string -> t tzresult

val of_b58check_opt : string -> t option

val pp : Format.formatter -> t -> unit

val encoding : t Data_encoding.t

(** [originated_tx_rollup nonce] is the tx_rollup address originated from
    [nonce]. See [Origination_nonce.t] for more information. *)
val originated_tx_rollup : Origination_nonce.t -> t

val rpc_arg : t RPC_arg.arg

module Index : Storage_description.INDEX with type t = t

(** The entrypoint a layer-1 contract can use to deposit Michelson tickets
    into a transaction rollup. *)
val deposit_entrypoint : Entrypoint_repr.t

(** The parameters expected to be supplied to the deposit entrypoint.

    These arguments will not be supplied as-is, but encoded using
    Micheline.

    The function {!Script_ir_translator.parse_tx_rollup_deposit_parameters}
    should be used to extract a [deposit_parameters] from a Micheline value. *)
type deposit_parameters = {
  contents : Script_repr.node;
  ty : Script_repr.node;
  ticketer : Script_repr.node;
  amount : int64;
  destination : Tx_rollup_l2_address.Indexable.t;
}

val withdraw_entrypoint : Entrypoint_repr.t

type withdraw_parameters = {
  contents : Script_repr.node;
  ty : Script_repr.node;
  ticketer : Script_repr.node;
  amount : int64;
  destination_contract : Contract_repr.t;
}
