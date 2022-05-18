(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(** Run Tezos client commands. *)

include module type of Client_base

module Time = Tezos_base.Time.System

(** Values that can be passed to the client's [--timestamp] argument *)
type timestamp = Now | Ago of Time.Span.t | At of Time.t

(** Convert [timestamp] into a concrete [Time.t], relative to
    [Time.now ()]. *)
val time_of_timestamp : timestamp -> Time.t

(** Run [tezos-client rpc /chains/<chain>/blocks/<block>/header/shell]. *)
val shell_header :
  ?endpoint:endpoint -> ?chain:string -> ?block:string -> t -> string Lwt.t

(** Same as [shell_header], but do not wait for the process to exit. *)
val spawn_shell_header :
  ?endpoint:endpoint -> ?chain:string -> ?block:string -> t -> Process.t

(** Run [shell_header] and retrieves the level. *)
val level :
  ?endpoint:endpoint -> ?chain:string -> ?block:string -> t -> int Lwt.t

(** {2 Admin Client Commands} *)

module Admin : sig
  (** Run tezos-admin-client commands. *)

  (** Ask a node to trust the address and port of another node. *)
  val trust_address : ?endpoint:endpoint -> peer:Node.t -> t -> unit Lwt.t

  (** Same as [trust_address], but do not wait for the process to exit. *)
  val spawn_trust_address : ?endpoint:endpoint -> peer:Node.t -> t -> Process.t

  (** Connect a node to another peer. *)
  val connect_address : ?endpoint:endpoint -> peer:Node.t -> t -> unit Lwt.t

  (** Same as [connect_address], but do not wait for the process to exit. *)
  val spawn_connect_address :
    ?endpoint:endpoint -> peer:Node.t -> t -> Process.t

  (** Kick a peer.

      [peer] is the identity of the peer to kick.
      You can get it with [Node.wait_for_identity] for instance. *)
  val kick_peer : ?endpoint:endpoint -> peer:string -> t -> unit Lwt.t

  (** Same as [kick_peer], but do not wait for the process to exit. *)
  val spawn_kick_peer : ?endpoint:endpoint -> peer:string -> t -> Process.t

  (** Run [tezos-admin-client inject protocol <protocol_path>].

      Returns the hash of the injected protocol. *)
  val inject_protocol :
    ?endpoint:endpoint -> protocol_path:string -> t -> string Lwt.t

  (** Same as [inject_protocol], but do not wait for the process to exit. *)
  val spawn_inject_protocol :
    ?endpoint:endpoint -> protocol_path:string -> t -> Process.t

  (** Run [tezos-admin-client list protocols] and return the list of protocol hashes. *)
  val list_protocols : ?endpoint:endpoint -> t -> string list Lwt.t

  (** Same as [list_protocols], but do not wait for the process to exit. *)
  val spawn_list_protocols : ?endpoint:endpoint -> t -> Process.t
end

(** {2 Regular Client Commands} *)

(** Run [tezos-client --version]. *)
val version : t -> unit Lwt.t

(** Same as [version], but do not wait for the process to exit. *)
val spawn_version : t -> Process.t

(** Run [tezos-client import secret key]. *)
val import_secret_key : ?endpoint:endpoint -> t -> Account.key -> unit Lwt.t

(** Run [tezos-client import secret key] for remote signer. *)
val import_signer_key :
  ?endpoint:endpoint -> ?force:bool -> t -> Account.key -> Uri.t -> unit Lwt.t

(** Same as [import_secret_key] for signer, but do not wait for the
    process to exit. *)
val spawn_import_signer_key :
  ?endpoint:endpoint -> ?force:bool -> t -> Account.key -> Uri.t -> Process.t

(** Same as [import_secret_key], but do not wait for the process to exit. *)
val spawn_import_secret_key :
  ?endpoint:endpoint -> t -> Account.key -> Process.t

(** Run [tezos-client activate protocol].

    If [timestamp] is not specified explicitely, it is set to [Ago
    timestamp_delay], where [timestamp_delay] is 365 days, which
    allows to bake plenty of blocks before their timestamp reach the
    present (at which point one would have to wait between each block
    so that peers do not reject them for being in the future). *)
val activate_protocol :
  ?endpoint:endpoint ->
  protocol:Protocol.t ->
  ?fitness:int ->
  ?key:string ->
  ?timestamp:timestamp ->
  ?parameter_file:string ->
  t ->
  unit Lwt.t

(** Same as [activate_protocol], but do not wait for the process to exit. *)
val spawn_activate_protocol :
  ?endpoint:endpoint ->
  protocol:Protocol.t ->
  ?fitness:int ->
  ?key:string ->
  ?timestamp:timestamp ->
  ?parameter_file:string ->
  t ->
  Process.t

(** [empty_mempool_file ?filename ()] creates a file containing the
   encoding of an empty mempool. This file can be given to [bake_for]
   command with the [mempool] parameter to ensure that the block baked
   will contain no operations. *)
val empty_mempool_file : ?filename:string -> unit -> string

(** Run [tezos-client bake for].

    Default [key] is {!Constant.bootstrap1.alias}.

    If you want to wait until the node switches its head to the baked block,
    consider using {!bake_for_and_wait} below. *)
val bake_for :
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?keys:string list ->
  ?minimal_fees:int ->
  ?minimal_nanotez_per_gas_unit:int ->
  ?minimal_nanotez_per_byte:int ->
  ?minimal_timestamp:bool ->
  ?mempool:string ->
  ?ignore_node_mempool:bool ->
  ?force:bool ->
  ?context_path:string ->
  t ->
  unit Lwt.t

(** Same as {!bake_for}, but bakes a block and waits until the level of the
    blockchain in the node increases by 1. It uses the node provided via argument
    [node] if any. Otherwise, it searches for a node in the client's mode, and
    fails if no node is found. *)
val bake_for_and_wait :
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?keys:string list ->
  ?minimal_fees:int ->
  ?minimal_nanotez_per_gas_unit:int ->
  ?minimal_nanotez_per_byte:int ->
  ?minimal_timestamp:bool ->
  ?mempool:string ->
  ?ignore_node_mempool:bool ->
  ?force:bool ->
  ?context_path:string ->
  ?node:Node.t ->
  t ->
  unit Lwt.t

(** Same as [bake_for], but do not wait for the process to exit. *)
val spawn_bake_for :
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?keys:string list ->
  ?minimal_fees:int ->
  ?minimal_nanotez_per_gas_unit:int ->
  ?minimal_nanotez_per_byte:int ->
  ?minimal_timestamp:bool ->
  ?mempool:string ->
  ?ignore_node_mempool:bool ->
  ?force:bool ->
  ?context_path:string ->
  t ->
  Process.t

(** Run [tezos-client endorse for].

    Default [key] is {!Constant.bootstrap1.alias}. *)
val endorse_for :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  unit Lwt.t

(** Same as [endorse_for], but do not wait for the process to exit. *)
val spawn_endorse_for :
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  Process.t

(** Run [tezos-client preendorse for].

    Default [key] is {!Constant.bootstrap1.alias}. *)
val preendorse_for :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  unit Lwt.t

(** Same as [preendorse_for], but do not wait for the process to exit. *)
val spawn_preendorse_for :
  ?endpoint:endpoint ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  Process.t

(** Run [tezos-client propose for].

    Default [key] is {!Constant.bootstrap1.alias}. *)
val spawn_propose_for :
  ?endpoint:endpoint ->
  ?minimal_timestamp:bool ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  Process.t

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2336
   refactor this *)

(** [propose_for] *)
val propose_for :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?minimal_timestamp:bool ->
  ?protocol:Protocol.t ->
  ?key:string list ->
  ?force:bool ->
  t ->
  unit Lwt.t

(** Run [tezos-client show address <alias> --show-secret] and parse
    the output into an [Account.key].
    E.g. for [~alias:"bootstrap1"] the command yields:
{v
      Hash: tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx
      Public Key: edpkuBknW28nW72KG6RoHtYW7p12T6GKc7nAbwYX5m8Wd9sDVC9yav
      Secret Key: unencrypted:edsk3gUfUPyBSfrS9CCgmCiQsTCHGkviBDusMxDJstFtojtc1zcpsh
v}
    which becomes:
{[
     { alias = "bootstrap1";
       public_key_hash = "tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx";
       public_key = "edpkuBknW28nW72KG6RoHtYW7p12T6GKc7nAbwYX5m8Wd9sDVC9yav";
       secret_key =
         Unencrypted "edsk3gUfUPyBSfrS9CCgmCiQsTCHGkviBDusMxDJstFtojtc1zcpsh"; }
]} *)
val show_address : alias:string -> t -> Account.key Lwt.t

(** Same as [show_address], but do not wait for the process to exit
    (which also implies that there is no output key to parse). *)
val spawn_show_address : alias:string -> t -> Process.t

(** Run [tezos-client gen keys] and return the key alias.

    The default value for [alias] is a fresh alias of the form [tezt_<n>]. *)
val gen_keys : ?alias:string -> t -> string Lwt.t

(** A helper to run [tezos-client gen keys] followed by
    [tezos-client show address] to get the generated key. *)
val gen_and_show_keys : ?alias:string -> t -> Account.key Lwt.t

(** Run [tezos-client bls gen keys <alias>]. *)
val bls_gen_keys :
  ?hooks:Process.hooks -> ?force:bool -> ?alias:string -> t -> string Lwt.t

(** Run [tezos-client bls list keys].

    Returns the known BLS aliases associated to their public key hash.

    Fails if the format is not of the form [<alias>: <public key hash>]. *)
val bls_list_keys : ?hooks:Process.hooks -> t -> (string * string) list Lwt.t

(** Run [tezos-client bls show address <alias>] and parse
    the output into an [Account.aggregate_key].
    E.g. for [~alias:"bls_account"] the command yields:
{v
      Hash: tz4EECtMxAuJ9UDLaiMZH7G1GCFYUWsj8HZn
      Public Key: BLpk1yUiLJ7RezbyViD5ZvWTfQndM3TRRYmvYWkUfH2EJqsLFnzzvpJss6pbuz3U1DDMpk8v16nV
      Secret Key: aggregate_unencrypted:BLsk1hKAHyGqY9qRbgoSVnjiSmDWpKGjFF3WNQ7BaiaMUA6RMA6Pfq
v}
    which becomes:
{[
    {
      aggregate_alias = "bls_account";
      aggregate_public_key_hash = "tz4EECtMxAuJ9UDLaiMZH7G1GCFYUWsj8HZn";
      aggregate_public_key =
        "BLpk1yUiLJ7RezbyViD5ZvWTfQndM3TRRYmvYWkUfH2EJqsLFnzzvpJss6pbuz3U1DDMpk8v16nV";
      aggregate_secret_key =
        Unencrypted "BLsk1hKAHyGqY9qRbgoSVnjiSmDWpKGjFF3WNQ7BaiaMUA6RMA6Pfq";
    }
]} *)
val bls_show_address :
  ?hooks:Process.hooks -> alias:string -> t -> Account.aggregate_key Lwt.t

(** A helper to run [tezos-client bls gen keys] followed by
    [tezos-client bls show address] to get the generated key. *)
val bls_gen_and_show_keys : ?alias:string -> t -> Account.aggregate_key Lwt.t

(** Run [tezos-client bls import secret key <account.aggregate_alias>
    <account.aggregate_secret_key>]. *)
val bls_import_secret_key :
  ?hooks:Process.hooks ->
  ?force:bool ->
  Account.aggregate_key ->
  t ->
  unit Lwt.t

(** Run [tezos-client transfer amount from giver to receiver]. *)
val transfer :
  ?monitor_mempool:bool ->
  ?hooks:Process.hooks ->
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  ?fee:Tez.t ->
  ?gas_limit:int ->
  ?storage_limit:int ->
  ?counter:int ->
  ?arg:string ->
  ?simulation:bool ->
  ?force:bool ->
  ?expect_failure:bool ->
  amount:Tez.t ->
  giver:string ->
  receiver:string ->
  t ->
  unit Lwt.t

(** Same as [transfer], but do not wait for the process to exit. *)
val spawn_transfer :
  ?hooks:Process.hooks ->
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  ?fee:Tez.t ->
  ?gas_limit:int ->
  ?storage_limit:int ->
  ?counter:int ->
  ?arg:string ->
  ?simulation:bool ->
  ?force:bool ->
  amount:Tez.t ->
  giver:string ->
  receiver:string ->
  t ->
  Process.t

(** Run [tezos-client multiple transfers from giver using json_batch]. *)
val multiple_transfers :
  ?monitor_mempool:bool ->
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  ?fee_cap:Tez.t ->
  ?gas_limit:int ->
  ?storage_limit:int ->
  ?counter:int ->
  ?arg:string ->
  giver:string ->
  json_batch:string ->
  t ->
  unit Lwt.t

(** Same as [multiple_transfers], but do not wait for the process to exit. *)
val spawn_multiple_transfers :
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  ?fee_cap:Tez.t ->
  ?gas_limit:int ->
  ?storage_limit:int ->
  ?counter:int ->
  ?arg:string ->
  giver:string ->
  json_batch:string ->
  t ->
  Process.t

(** Run tezos-client get delegate for <src>. Returns [Some address] if delegate
    is set or [None] otherwise. *)
val get_delegate : ?endpoint:endpoint -> src:string -> t -> string option Lwt.t

(** Run [tezos-client set delegate for <src> to <delegate>]. *)
val set_delegate :
  ?endpoint:endpoint ->
  ?wait:string ->
  ?fee:Tez.t ->
  ?fee_cap:Tez.t ->
  ?force_low_fee:bool ->
  src:string ->
  delegate:string ->
  t ->
  unit Runnable.process

(** Run [tezos-client reveal key for <src>]. *)
val reveal :
  ?endpoint:endpoint ->
  ?wait:string ->
  ?fee:Tez.t ->
  ?fee_cap:Tez.t ->
  ?force_low_fee:bool ->
  src:string ->
  t ->
  unit Runnable.process

(** Run [tezos-client withdraw delegate from <src>]. *)
val withdraw_delegate :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  src:string ->
  t ->
  unit Lwt.t

(** Same as [withdraw_delegate], but do not wait for the process to exit. *)
val spawn_withdraw_delegate :
  ?endpoint:endpoint -> ?wait:string -> src:string -> t -> Process.t

(** Run [tezos-client get balance for]. *)
val get_balance_for : ?endpoint:endpoint -> account:string -> t -> Tez.t Lwt.t

(** Same as [get_balance_for], but do not wait for the process to exit. *)
val spawn_get_balance_for :
  ?endpoint:endpoint -> account:string -> t -> Process.t

(** Run [tezos-client create mockup]. *)
val create_mockup :
  ?sync_mode:mockup_sync_mode ->
  ?parameter_file:string ->
  protocol:Protocol.t ->
  t ->
  unit Lwt.t

(** Same as [create_mockup], but do not wait for the process to exit. *)
val spawn_create_mockup :
  ?sync_mode:mockup_sync_mode ->
  ?parameter_file:string ->
  protocol:Protocol.t ->
  t ->
  Process.t

(** Run [tezos-client submit proposals for].

    If both [proto_hash] and [proto_hashes] are specified,
    the list of protocols which are proposed is [proto_hash :: proto_hashes].

    Default [key] is {!Constant.bootstrap1.alias}. *)
val submit_proposals :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?key:string ->
  ?wait:string ->
  ?proto_hash:string ->
  ?proto_hashes:string list ->
  t ->
  unit Lwt.t

(** Same as [submit_proposals], but do not wait for the process to exit. *)
val spawn_submit_proposals :
  ?endpoint:endpoint ->
  ?key:string ->
  ?wait:string ->
  ?proto_hash:string ->
  ?proto_hashes:string list ->
  t ->
  Process.t

type ballot = Nay | Pass | Yay

(** Run [tezos-client submit ballot for].

    Default [key] is {!Constant.bootstrap1.alias}. *)
val submit_ballot :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?key:string ->
  ?wait:string ->
  proto_hash:string ->
  ballot ->
  t ->
  unit Lwt.t

(** Same as [submit_ballot], but do not wait for the process to exit. *)
val spawn_submit_ballot :
  ?endpoint:endpoint ->
  ?key:string ->
  ?wait:string ->
  proto_hash:string ->
  vote:ballot ->
  t ->
  Process.t

(** Run [tezos-client set deposits limit for <src> to <limit>] *)
val set_deposits_limit :
  ?monitor_mempool:bool ->
  ?hooks:Process.hooks ->
  ?endpoint:endpoint ->
  ?wait:string ->
  src:string ->
  limit:string ->
  t ->
  string Lwt.t

(** Run [tezos-client unset deposits limit for <src>] *)
val unset_deposits_limit :
  ?monitor_mempool:bool ->
  ?hooks:Process.hooks ->
  ?endpoint:endpoint ->
  ?wait:string ->
  src:string ->
  t ->
  string Lwt.t

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2336
   [amount] should be named [transferring] *)
(* TODO: https://gitlab.com/tezos/tezos/-/issues/2336
   [src] should be named [from] and probably have type [Account.t] *)

(** Run [tezos-client originate contract alias transferring amount from src
    running prg]. Returns the originated contract hash *)
val originate_contract :
  ?monitor_mempool:bool ->
  ?hooks:Process.hooks ->
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?init:string ->
  ?burn_cap:Tez.t ->
  alias:string ->
  amount:Tez.t ->
  src:string ->
  prg:string ->
  t ->
  string Lwt.t

(** Same as [originate_contract], but do not wait for the process to exit. *)
val spawn_originate_contract :
  ?hooks:Process.hooks ->
  ?log_output:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?init:string ->
  ?burn_cap:Tez.t ->
  alias:string ->
  amount:Tez.t ->
  src:string ->
  prg:string ->
  t ->
  Process.t

(** Convert the given smart contract from Michelson to JSON string. *)
val convert_script_to_json :
  ?endpoint:endpoint -> script:string -> t -> Ezjsonm.value Lwt.t

(** Convert the given Michelson constant to JSON string. *)
val convert_data_to_json :
  ?endpoint:endpoint -> data:string -> t -> Ezjsonm.value Lwt.t

(** The information that the user has to provide for every smart contract
    they want to call during the stress test. *)
type stresstest_contract_parameters = {
  probability : float;  (** The probability of calling this smart contract *)
  invocation_fee : Tez.t;
      (** Fee to use for invocations during the stress test *)
  invocation_gas_limit : int;
      (** Gas limit to use for invocations during the stress test *)
}

(** Run [tezos-client stresstest transfer using <sources>].

    [sources] is a string containing all the [source_aliases],
    [source_pkhs], and [source_accounts] in JSON format as expected by
    the [stresstest] command. Each optional argument [source_aliases],
    [source_pkhs], and [source_accounts] defaults to an empty
    list. However, if all three are empty, then the [sources] given to
    the command are [Constant.bootstrap_keys] i.e. [bootstrap1], ...,
    [bootstrap5].

    The parameter [--seed <seed>] is always provided (because without
    it, the [stresstest] command would use a fixed seed). If the
    corresponding optional argument is not provided to the function,
    then a new random seed is generated.

    Optional parameters (provided only if the function is called with
    the corresponding optional argument):
    - [seed] is the seed used for the random number generator
    - [fee] is the custom fee to pay instead of the default one
    - [gas_limit] is the custom gas limit
    - [--transfers <transfers>]
    - [--tps <tps>]
    - [--single-op-per-pkh-per-block] (if the argument
      [single_op_per_pkh_per_block] is [true])
    - [--fresh_probabilty <probability>], probability from 0.0 to 1.0 that
      new bootstrap accounts will be created during the stress test
    - [--smart-contract-parameters] is the map of parameters for
      calling smart contracts during the smart test

    [endpoint]: cf {!create} *)
val stresstest :
  ?endpoint:endpoint ->
  ?source_aliases:string list ->
  ?source_pkhs:string list ->
  ?source_accounts:Account.key list ->
  ?seed:int ->
  ?fee:Tez.t ->
  ?gas_limit:int ->
  ?transfers:int ->
  ?tps:int ->
  ?single_op_per_pkh_per_block:bool ->
  ?fresh_probability:float ->
  ?smart_contract_parameters:(string * stresstest_contract_parameters) list ->
  t ->
  unit Lwt.t

(** Same as {!stresstest}, but do not wait for the process to exit. *)
val spawn_stresstest :
  ?endpoint:endpoint ->
  ?source_aliases:string list ->
  ?source_pkhs:string list ->
  ?source_accounts:Account.key list ->
  ?seed:int ->
  ?fee:Tez.t ->
  ?gas_limit:int ->
  ?transfers:int ->
  ?tps:int ->
  ?single_op_per_pkh_per_block:bool ->
  ?fresh_probability:float ->
  ?smart_contract_parameters:(string * stresstest_contract_parameters) list ->
  t ->
  Process.t

(** Costs of every kind of transaction used in the stress test. *)
type stresstest_gas_estimation = {
  regular : int;  (** Cost of a regular transaction. *)
  smart_contracts : (string * int) list;  (** Cost of smart contract calls. *)
}

(** Call the [stresstest estimate gas] command. *)
val stresstest_estimate_gas :
  ?endpoint:endpoint -> t -> stresstest_gas_estimation Lwt.t

(** Originate all smart contracts for use in the stress test. *)
val stresstest_originate_smart_contracts :
  ?endpoint:endpoint -> Account.key -> t -> unit Lwt.t

(** Run [tezos-client run script .. on storage .. and input ..].

    Returns the new storage as a string.

    Fails if the new storage cannot be extracted from the output. *)
val run_script :
  ?hooks:Process.hooks ->
  ?balance:Tez.t ->
  ?self_address:string ->
  ?source:string ->
  ?payer:string ->
  prg:string ->
  storage:string ->
  input:string ->
  t ->
  string Lwt.t

(** Same as [run_script] but do not wait for the process to exit. *)
val spawn_run_script :
  ?hooks:Process.hooks ->
  ?balance:Tez.t ->
  ?self_address:string ->
  ?source:string ->
  ?payer:string ->
  prg:string ->
  storage:string ->
  input:string ->
  t ->
  Process.t

(** Run [tezos-client register global constant value from src].
    Returns the address hash of the new constant. *)
val register_global_constant :
  ?monitor_mempool:bool ->
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  src:string ->
  value:string ->
  t ->
  string Lwt.t

(** Same as [register_global_constant] but do not wait for the process to exit. *)
val spawn_register_global_constant :
  ?endpoint:endpoint ->
  ?wait:string ->
  ?burn_cap:Tez.t ->
  value:string ->
  src:string ->
  t ->
  Process.t

(** Run [tezos-client hash data .. of type ...]

    Given that the output of [tezos-client] is:

    [Raw packed data: 0x050303
     Script-expression-ID-Hash: exprvDnoPjyKeR9FSnvwYg5a1v6mDyB6TmnATwWySSP6VmJxrzQb9E
     Raw Script-expression-ID-Hash: 0xe0978ddc9329cbd84d25fd15a161a7d2e7e555da91e2a335ece8c8bc11ade245
     Ledger Blake2b hash: G7iMrYNckCFRujDLFgtj3cDMCnfeSQ2cmhnDtkh9REc4
     Raw Sha256 hash: 0x35ef99f7718e7d1f065bae635780f41c0cd201e9ffb3390ba6ef428c2815fa66
     Raw Sha512 hash: 0x2c9ca967bf47f6cc76861693379b7397f65e6a1b6e633df28cf02be0b0d18319ae783b4c199fd61115e000a15a5ba8a292a3b1468c2cfe2b3e3a9fa08d419698
     Gas remaining: 1039991.350 units remaining]

    this function returns the list:

    [("Raw packed data"; "0x050303")
     ("Script-expression-ID-Hash"; "exprvDnoPjyKeR9FSnvwYg5a1v6mDyB6TmnATwWySSP6VmJxrzQb9E")
     ("Raw Script-expression-ID-Hash"; "0xe0978ddc9329cbd84d25fd15a161a7d2e7e555da91e2a335ece8c8bc11ade245")
     ("Ledger Blake2b hash"; "G7iMrYNckCFRujDLFgtj3cDMCnfeSQ2cmhnDtkh9REc4")
     ("Raw Sha256 hash"; "0x35ef99f7718e7d1f065bae635780f41c0cd201e9ffb3390ba6ef428c2815fa66")
     ("Raw Sha512 hash"; "0x2c9ca967bf47f6cc76861693379b7397f65e6a1b6e633df28cf02be0b0d18319ae783b4c199fd61115e000a15a5ba8a292a3b1468c2cfe2b3e3a9fa08d419698")
     ("Gas remaining"; "1039991.350 units remaining")]

    If some lines cannot be parsed, warnings are emitted in output and
    the corresponding lines are omitted from the result. *)
val hash_data :
  ?expect_failure:bool ->
  ?hooks:Process.hooks ->
  data:string ->
  typ:string ->
  t ->
  (string * string) list Lwt.t

(** Same as [hash_data], but do not wait for the process to exit. *)
val spawn_hash_data :
  ?hooks:Process.hooks -> data:string -> typ:string -> t -> Process.t

(** Run [tezos-client normalize data .. of type ...]*)
val normalize_data :
  ?mode:normalize_mode ->
  ?legacy:bool ->
  data:string ->
  typ:string ->
  t ->
  string Lwt.t

(** Same as [normalize_data], but do not wait for the process to exit. *)
val spawn_normalize_data :
  ?mode:normalize_mode ->
  ?legacy:bool ->
  data:string ->
  typ:string ->
  t ->
  Process.t

(** Run [tezos-client normalize script ..]*)
val normalize_script :
  ?mode:normalize_mode -> script:string -> t -> string Lwt.t

(** Same as [normalize_script], but do not wait for the process to exit. *)
val spawn_normalize_script :
  ?mode:normalize_mode -> script:string -> t -> Process.t

(** Run [tezos-client typecheck script ..]*)
val typecheck_script :
  script:string ->
  ?details:bool ->
  ?emacs:bool ->
  ?no_print_source:bool ->
  ?gas:int ->
  ?legacy:bool ->
  t ->
  string Lwt.t

(** Same as [typecheck_script], but do not wait for the process to exit. *)
val spawn_typecheck_script :
  script:string ->
  ?details:bool ->
  ?emacs:bool ->
  ?no_print_source:bool ->
  ?gas:int ->
  ?legacy:bool ->
  t ->
  Process.t

(** Same as [run_view] but does not wait for the process to exit. *)
val spawn_run_view :
  ?hooks:Process.hooks ->
  ?source:string ->
  ?payer:string ->
  ?gas:int ->
  ?unparsing_mode:normalize_mode ->
  view:string ->
  contract:string ->
  ?input:string ->
  ?unlimited_gas:bool ->
  t ->
  Process.t

(** Run [tezos-client run view .. on contract .. with input ..].

    Returns the value returned by a view as a string.

    Fails if the view or the contract does not exist. If [input] is [None], it
    runs [tezos-client run view .. on contract ..]. *)
val run_view :
  ?hooks:Process.hooks ->
  ?source:string ->
  ?payer:string ->
  ?gas:int ->
  ?unparsing_mode:normalize_mode ->
  view:string ->
  contract:string ->
  ?input:string ->
  ?unlimited_gas:bool ->
  t ->
  string Lwt.t

(** Run [tezos-client list mode protocols].

    Note: the [list protocols] command (without mode) is an admin command
    (see {!Admin.list_protocols}). *)
val list_protocols : [< `Light | `Mockup | `Proxy] -> t -> string list Lwt.t

(** Same as [list_protocols], but do not wait for the process to exit
    and do not process stdout. *)
val spawn_list_protocols : [< `Light | `Mockup | `Proxy] -> t -> Process.t

(** Run [tezos-client migrate mockup to]. *)
val migrate_mockup : next_protocol:Protocol.t -> t -> unit Lwt.t

(** Same as [migrate_mockup], but do not wait for the process to exit. *)
val spawn_migrate_mockup : next_protocol:Protocol.t -> t -> Process.t

(** Run [tezos-client sign block <hexdata> for <delegate>]. *)
val sign_block : t -> string -> delegate:string -> string Lwt.t

(** Same as [sign_block], but do not wait for the process to exit. *)
val spawn_sign_block : t -> string -> delegate:string -> Process.t

module Tx_rollup : sig
  (** Run [tezos-client originate tx rollup from <src>]. *)
  val originate :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?fee:Tez.t ->
    ?hooks:Process.hooks ->
    src:string ->
    t ->
    string Lwt.t

  (** Run [tezos-client submit tx rollup batch <batch_content> to <tx_rollup> from <src>]. *)
  val submit_batch :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    ?log_output:bool ->
    ?log_command:bool ->
    content:Hex.t ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  (** Run [tezos-client submit tx rollup commitment <content> to <tx_rollup> from <src>]. *)
  val submit_commitment :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    ?predecessor:string ->
    level:int ->
    roots:string list ->
    inbox_merkle_root:string ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  (** Run [tezos-client submit tx rollup finalize commitment to <tx_rollup> from <src>]. *)
  val submit_finalize_commitment :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  (** Run [tezos-client submit tx rollup remove commitment to <tx_rollup> from <src>]. *)
  val submit_remove_commitment :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  (** Run [tezos-client submit tx rollup rejection commitment at level
     <level> message <message> at <position> with <proof> with agreed
     context hash <context_hash> and withdraw list
     <withdraw_list_hash> to <tx_rollup> from <src>]. *)
  val submit_rejection :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    level:int ->
    message:string ->
    position:int ->
    path:string ->
    message_result_hash:string ->
    rejected_message_result_path:string ->
    agreed_message_result_path:string ->
    proof:string ->
    context_hash:string ->
    withdraw_list_hash:string ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  (** Run [tezos-client submit tx rollup return bond to <tx_rollup> from <src>]. *)
  val submit_return_bond :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    rollup:string ->
    src:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  val dispatch_tickets :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?storage_limit:int ->
    ?hooks:Process.hooks ->
    tx_rollup:string ->
    src:string ->
    level:int ->
    message_position:int ->
    context_hash:string ->
    message_result_path:string ->
    ticket_dispatch_info_data_list:string list ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t

  val transfer_tickets :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    ?hooks:Process.hooks ->
    qty:int64 ->
    src:string ->
    destination:string ->
    entrypoint:string ->
    contents:string ->
    ty:string ->
    ticketer:string ->
    t ->
    (Process.t Lwt.t, unit) Runnable.t
end

(** Run [tezos-client show voting period] and return the period name. *)
val show_voting_period : ?endpoint:endpoint -> t -> string Lwt.t

(** Same as [show_voting_period], but do not wait for the process to exit. *)
val spawn_show_voting_period : ?endpoint:endpoint -> t -> Process.t

module Sc_rollup : sig
  (** Run [tezos-client originate sc rollup from <src> of kind <kind> booting with <boot_sector>]. *)
  val originate :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    src:string ->
    kind:string ->
    boot_sector:string ->
    t ->
    string Lwt.t

  (** Same as [originate], but do not wait for the process to exit. *)
  val spawn_originate :
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    src:string ->
    kind:string ->
    boot_sector:string ->
    t ->
    Process.t

  (** Run [tezos-client send rollup message <msg> from <src> to <dst>]. *)
  val send_message :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    msg:string ->
    src:string ->
    dst:string ->
    t ->
    unit Lwt.t

  (** Same as [send_message], but do not wait for the process to exit. *)
  val spawn_send_message :
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    msg:string ->
    src:string ->
    dst:string ->
    t ->
    Process.t

  (** Run [tezos-client cemment commitment <hash> from <src> for sc rollup <rollup>]. *)
  val cement_commitment :
    ?monitor_mempool:bool ->
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    hash:string ->
    src:string ->
    dst:string ->
    t ->
    unit Lwt.t

  (** Same as [cement_commitment], but do not wait for the process to exit. *)
  val spawn_cement_commitment :
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?wait:string ->
    ?burn_cap:Tez.t ->
    hash:string ->
    src:string ->
    dst:string ->
    t ->
    Process.t
end

(** {2 High-Level Functions} *)

(** Set up a client and node(s).

    - Create a client with mode [Client], [Light], or [Proxy].
    - Import all secret [?keys] (by default, {!Constant.all_secret_keys}).

    In addition to the client, returns the first created node
    (if [`Light] is passed, a second node has been created, but it is
    not exposed). *)
val init_with_node :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?event_level:Daemon.Level.default_level ->
  ?event_sections_levels:(string * Daemon.Level.level) list ->
  ?nodes_args:Node.argument list ->
  ?keys:Account.key list ->
  [`Client | `Light | `Proxy] ->
  unit ->
  (Node.t * t) Lwt.t

(** Set up a client and node(s) and activate a protocol.

    - Create a client with mode [Client], [Light], or [Proxy]
    - Import all secret keys listed in {!Constant.all_secret_keys}
    - Create [additional_account_count] accounts with
      [default_accounts_balance]
    - Activate the given protocol with [additional_account_count]
      additional bootstrap accounts whose aliases are given by
     [Account.bootstrap].

    In addition to the client, returns the first created node
    (if [`Light] is passed, a second node has been created, but it is
    not exposed). *)
val init_with_protocol :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?event_level:Daemon.Level.default_level ->
  ?event_sections_levels:(string * Daemon.Level.level) list ->
  ?nodes_args:Node.argument list ->
  ?additional_bootstrap_account_count:int ->
  ?default_accounts_balance:int ->
  ?parameter_file:string ->
  ?timestamp:timestamp ->
  ?keys:Account.key list ->
  [`Client | `Light | `Proxy] ->
  protocol:Protocol.t ->
  unit ->
  (Node.t * t) Lwt.t

(** Create a client with mode [Mockup] and run [create mockup].

    Contrary to [init], this does not import any secret key, because
   [tezos-client create mockup] already initializes the mockup with bootstrap
   keys.
*)
val init_mockup :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?sync_mode:mockup_sync_mode ->
  ?parameter_file:string ->
  ?constants:Protocol.constants ->
  protocol:Protocol.t ->
  unit ->
  t Lwt.t

(** Create a client with mode [Light]. In addition to the client, created
    nodes are returned, as they are created by this call; and
    the light mode needs tight interaction with the nodes. The [nodes_args]
    argument allows to configure the created nodes, but note
    that arguments [Node.Connections] and [Node.Synchronisation_threshold]
    are ignored. *)
val init_light :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?min_agreement:float ->
  ?event_level:Daemon.Level.default_level ->
  ?event_sections_levels:(string * Daemon.Level.level) list ->
  ?nodes_args:Node.argument list ->
  unit ->
  (t * Node.t * Node.t) Lwt.t

(** Register public key for given account with given client. *)
val spawn_register_key : string -> t -> Process.t

(** Register public key for given account with given client. *)
val register_key : string -> t -> unit Lwt.t

(** Get contract storage for a contract. Returns a Micheline expression
    representing the storage as a string. *)
val contract_storage :
  ?unparsing_mode:normalize_mode -> string -> t -> string Lwt.t

(** Sign a string of bytes with secret key of the given account. *)
val sign_bytes : signer:string -> data:string -> t -> string Lwt.t

(** Use tezos-client to convert a script between given forms. *)
val convert_script :
  script:string ->
  src_format:[`Michelson | `Json | `Binary] ->
  dst_format:[`Michelson | `Json | `Binary] ->
  t ->
  string Lwt.t
