(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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

(** The version of the PVM to use. *)
val pvm_kind : string

(** The directory containing the input data for the kernel. *)
val kernel_inputs_path : string

(** Container grouping the different necessary components.  *)
type full_evm_setup = {
  node : Node.t;
  client : Client.t;
  sc_rollup_node : Sc_rollup_node.t;
  sc_rollup_client : Sc_rollup_client.t;
  sc_rollup_address : string;
  originator_key : string;
  rollup_operator_key : string;
  evm_proxy_server : Evm_proxy_server.t;
}

(** Encode int as a hex string with 256bit fixed length. *)
val hex_256_of : int -> string

(** Removes 0x prefix if present. *)
val no_0x : string -> string

(** Version du proxy server. *)
val evm_proxy_server_version :
  Evm_proxy_server.t -> Tezt.JSON.t Runnable.process

(** Ask the proxy for the nb of transactions (RPC eth_getTransactionCount). *)
val get_transaction_count : Evm_proxy_server.t -> string -> int64 Lwt.t

(** Ask the proxy for the status of transactions, extracted from the receipt. *)
val get_transaction_status : endpoint:string -> tx:string -> bool Lwt.t

(** Ask the rollup node for a value in durable storage,
    and check it's the expected value. *)
val check_str_in_storage :
  evm_setup:full_evm_setup ->
  address:string ->
  nth:int ->
  expected:string ->
  unit Lwt.t

(** Ask the rollup node for a value in durable storage,
    and check it's the expected value (provided as int). *)
val check_nb_in_storage :
  evm_setup:full_evm_setup ->
  address:string ->
  nth:int ->
  expected:int ->
  unit Lwt.t

(** Ask the proxy if a transaction succeeded, extracted from the receipt. *)
val check_tx_succeeded : endpoint:string -> tx:string -> unit Lwt.t

(** Ask the proxy if a transaction failed, extracted from the receipt. *)
val check_tx_failed : endpoint:string -> tx:string -> unit Lwt.t

(** Ask the rollup node the nb of values in the storage of an account. *)
val get_storage_size : Sc_rollup_client.t -> address:string -> int Lwt.t

(** [next_evm_level ~sc_rollup_node ~node ~client] moves [sc_rollup_node] to
    the [node]'s next level. *)
val next_evm_level :
  sc_rollup_node:Sc_rollup_node.t -> node:Node.t -> client:Client.t -> int Lwt.t

(** [wait_for_application ~sc_rollup_node ~node ~client apply ()] tries to
    [apply] an operation and in parallel moves [sc_rollup_node] to the [node]'s
    next level until either the operation succeeded (in which case it stops) or
    a given number of level has passed (in which case it fails). *)
val wait_for_application :
  sc_rollup_node:Sc_rollup_node.t ->
  node:Node.t ->
  client:Client.t ->
  (unit -> 'a Lwt.t) ->
  unit ->
  'a Lwt.t

(** Sends to the proxynode a transaction originating from [sender], who
    transfers [value] to [receiver]. The transaction can contain some [data].

    Returns the hash of the transaction. *)
val send :
  sender:Eth_account.t ->
  receiver:Eth_account.t ->
  value:Wei.t ->
  ?data:string ->
  full_evm_setup ->
  string Lwt.t

(** Setup a L1 node, a L1 client, a rollup node, a proxy node, and originates
    the evm kernel *)
val setup_evm_kernel :
  ?originator_key:string ->
  ?rollup_operator_key:string ->
  Protocol.t ->
  full_evm_setup Lwt.t

(** Container for the informations necessary to create a contract:
      - label: the label used to refer to ABI
      - abi: the path to the interface (json file)
      - bin: the path to the binary *)
type contract = {label : string; abi : string; bin : string}

(** Sends to the proxynode a transaction for the creation of [contract],
    emanating from [sender].

  Returns a pair [(address, tx_hash)]. *)
val deploy :
  contract:contract ->
  sender:Eth_account.t ->
  full_evm_setup ->
  (string * string) Lwt.t
