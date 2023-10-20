(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021-2023 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
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

(** Helpers built upon the Sc_rollup_node and Sc_rollup_client *)

(** Hooks that handles hashes specific to smart rollups. *)
val hooks : Tezt.Process.hooks

(** [hex_encode s] returns the hexadecimal representation of the given string [s]. *)
val hex_encode : string -> string

(** [read_kernel filename] reads binary encoded WebAssembly module (e.g.
    `foo.wasm`) and returns a hex-encoded Wasm PVM boot sector, suitable for
    passing to [originate_sc_rollup].
*)
val read_kernel : ?base:string -> string -> string

val string_match : regexp:string -> string -> bool

module Installer_kernel_config : sig
  (** Moves path [from] at path [to_]. *)
  type move_args = {from : string; to_ : string}

  (** Reveals hash [hash] at path [to_]. *)
  type reveal_args = {hash : string; to_ : string}

  (** Sets value [value] at path [to_]. *)
  type set_args = {value : string; to_ : string}

  type instr = Move of move_args | Reveal of reveal_args | Set of set_args

  (** Set of instructions used by the installer-client. *)
  type t = instr list

  (** [check_dump ~config dump] checks that the given [config] is included
      in the dumped PVM state. *)
  val check_dump : config:t -> string -> unit
end

(** [prepare_installer_kernel ~base_installee ~preimages_dir ?config
    installee] feeds the [smart-rollup-installer] with a kernel
    ([installee]), and returns the boot sector corresponding to the
    installer for this specific kernel. [installee] is read from
    [base_installee] on the disk.

    A {!Installer_kernel_config.t} can optionally be provided to the installer
    via [config].

    The preimages of the [installee] are saved to [preimages_dir]. This should be the
    reveal data directory of the rollup node.

    The returned installer is hex-encoded and may be passed to [originate_sc_rollup]
    directly.
*)
val prepare_installer_kernel :
  ?runner:Runner.t ->
  ?base_installee:string ->
  preimages_dir:string ->
  ?config:[< `Config of Installer_kernel_config.t | `Path of string] ->
  string ->
  string Lwt.t

(** [prepare_installer_kernel ?runner ?base_installee ~preimages_dir
    ?display_root_hash ?config installee] will behave just as
    {!Sc_rollup_helpers.prepare_installer_kernel} but will also output
    the preimage root hash if [display_root_hash] is set to [true]. *)
val prepare_installer_kernel_gen :
  ?runner:Runner.t ->
  ?base_installee:string ->
  preimages_dir:string ->
  ?display_root_hash:bool ->
  ?config:[< `Config of Installer_kernel_config.t | `Path of string] ->
  string ->
  (string * string option) Lwt.t

(** [setup_l1 protocol] initializes a protocol with the given parameters, and
    returns the L1 node and client. *)
val setup_l1 :
  ?bootstrap_smart_rollups:Protocol.bootstrap_smart_rollup list ->
  ?bootstrap_contracts:Protocol.bootstrap_contract list ->
  ?commitment_period:int ->
  ?challenge_window:int ->
  ?timeout:int ->
  ?whitelist_enable:bool ->
  Protocol.t ->
  (Node.t * Client.t) Lwt.t

(** [originate_sc_rollup] is a wrapper above {!Client.originate_sc_rollup} that
    waits for the block to be included. *)
val originate_sc_rollup :
  ?hooks:Process_hooks.t ->
  ?burn_cap:Tez.t ->
  ?whitelist:string list ->
  ?alias:string ->
  ?src:string ->
  kind:string ->
  ?parameters_ty:string ->
  ?boot_sector:string ->
  Client.t ->
  string Lwt.t

(** [default_boot_sector_of k] returns a valid boot sector for a PVM of
    kind [kind]. *)
val default_boot_sector_of : kind:string -> string

val last_cemented_commitment_hash_with_level :
  sc_rollup:string -> Client.t -> (string * int) Lwt.t

(** [genesis_commitment ~sc_rollup client] returns the genesis
    commitment, fails if this commitment have been cleaned from the
    context. *)
val genesis_commitment :
  sc_rollup:string -> Client.t -> Sc_rollup_client.commitment Lwt.t

(** [call_rpc ~smart_rollup_node ~service] call the RPC for [service] on
    [smart_rollup_node]. *)
val call_rpc :
  smart_rollup_node:Sc_rollup_node.t -> service:string -> JSON.t Lwt.t

(** Bootstrap smart rollup setup information.*)
type bootstrap_smart_rollup_setup = {
  bootstrap_smart_rollup : Protocol.bootstrap_smart_rollup;
      (** The bootstrap smart rollup to add in the parameter files. *)
  smart_rollup_node_data_dir : string;
      (** The data dir to use for the smart rollup node, where the smart
          rollup preimages are available. *)
  smart_rollup_node_extra_args : string list;
      (** The extra arguments needed by the smart rollup node when the smart
          rollup is a bootstrap smart rollup. *)
}

(** [setup_bootstrap_smart_rollup ?name ~address ?parameters_ty ?base_installee
    ~installee ?config ()] creates a {!bootstrap_smart_rollup_setup} that can
    be used to run a bootstrap smart rollup.

    [name] is the smart rollup node data-dir's name. Defaults to ["smart-rollup"].
    [address] is the smart rollup address.
    [parameters_ty] is the smart rollup type. Defaults to ["string"].
    [base_installee] is the directory where [installee] (the kernel) can be found.
    [config] is the optional smart rollup installer configuration, see {!prepare_installer_kernel}.
*)
val setup_bootstrap_smart_rollup :
  ?name:string ->
  address:string ->
  ?parameters_ty:string ->
  ?whitelist:string list ->
  ?base_installee:string ->
  installee:string ->
  ?config:[< `Config of Installer_kernel_config.t | `Path of string] ->
  unit ->
  bootstrap_smart_rollup_setup Lwt.t
