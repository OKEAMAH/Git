(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

type error = {code : int; message : string}

(** [block_number evm_node] calls [eth_blockNumber]. *)
val block_number : Evm_node.t -> (int32, error) result Lwt.t

(** [get_block_by_number ?full_tx_objets ~block evm_node] calls
    [eth_getBlockByNumber]. [full_tx_objects] is false by default, so
    the block contains the transaction hashes. [block] can be
    ["latest"] or its number. *)
val get_block_by_number :
  ?full_tx_objects:bool ->
  block:string ->
  Evm_node.t ->
  (Block.t, error) result Lwt.t

module Syntax : sig
  val ( let*@ ) : ('a, error) result Lwt.t -> ('a -> 'c Lwt.t) -> 'c Lwt.t

  val ( let*@? ) : ('a, error) result Lwt.t -> (error -> 'c Lwt.t) -> 'c Lwt.t

  val ( let*@! ) :
    ('a option, error) result Lwt.t -> ('a -> 'c Lwt.t) -> 'c Lwt.t
end

(** [produce_block ?timestamp evm_node] calls the private RPC [produceBlock]. If
    provided the block will have timestamp [timestamp] (in RFC3339) format. *)
val produce_block : ?timestamp:string -> Evm_node.t -> int32 Lwt.t

(** [inject_upgrade ~payload evm_node] calls the private RPC [injectUpgrade].
    It will store the [payload] under the kernel upgrade path. *)
val inject_upgrade : payload:string -> Evm_node.t -> unit Lwt.t

(** [send_raw_transaction ~raw_tx evm_node] calls [eth_sendRawTransaction]
    with [raw_tx] as argument. *)
val send_raw_transaction :
  raw_tx:string -> Evm_node.t -> (string, error) result Lwt.t

(** [get_transaction_receipt ~tx_hash evm_node] calls
    [eth_getTransactionReceipt] with [tx_hash] as argument. *)
val get_transaction_receipt :
  tx_hash:string ->
  Evm_node.t ->
  (Transaction.transaction_receipt option, error) result Lwt.t

(** [estimate_gas eth_call evm_node] calls [eth_estimateGas] with [eth_call]
    as payload. *)
val estimate_gas :
  (string * Ezjsonm.value) list -> Evm_node.t -> (int, error) result Lwt.t
