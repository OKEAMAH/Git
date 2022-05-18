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

(** Values that can be passed to the client's [--endpoint] argument *)
type endpoint =
  | Node of Node.t  (** A full-fledged node *)
  | Proxy_server of Proxy_server.t  (** A proxy server *)

(** Values that can be passed to the client's [--media-type] argument *)
type media_type = Json | Binary | Any

(** [rpc_port endpoint] returns the port on which to reach [endpoint]
    when doing RPC calls. *)
val rpc_port : endpoint -> int

(** Mode of the client *)
type mode =
  | Client of endpoint option * media_type option
  | Mockup
  | Light of float * endpoint list
  | Proxy of endpoint

(** [mode_to_endpoint mode] returns the {!endpoint} within a {!mode}
    (if any) *)
val mode_to_endpoint : mode -> endpoint option

(** The synchronization mode of the client.

    - [Asynchronous] mode is when transfer doesn't bake the block.
    - [Synchronous] is the default mode (no flag passed to [create mockup]). *)
type mockup_sync_mode = Asynchronous | Synchronous

(** The mode argument of the client's 'normalize data' command *)
type normalize_mode = Readable | Optimized | Optimized_legacy

(** Tezos client states. *)
type t

(** Get the name of a client (e.g. ["client1"]). *)
val name : t -> string

(** Get the base directory of a client.

    The base directory is the location where clients store their
    configuration files. It corresponds to the [--base-dir] option. *)
val base_dir : t -> string

(** Get [Account.key list] of all extra bootstraps.

    Additional bootstrap accounts are created when you use the
    [additional_bootstrap_account_count] argument of [init_with_protocol].
    They do not include the default accounts that are always created.
 *)
val additional_bootstraps : t -> Account.key list

(** Create a client.

    The standard output and standard error output of the node will
    be logged with prefix [name] and color [color].

    Default [base_dir] is a temporary directory
    which is always the same for each [name].

    The endpoint argument is used to know which port the client should connect to.
    This endpoint can be overridden for each command, as a client is not actually tied
    to an endpoint. Most commands require an endpoint to be specified (either with [create]
    or with the command itself). *)
val create :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?endpoint:endpoint ->
  ?media_type:media_type ->
  unit ->
  t

(** Create a client like [create] but do not assume [Client] as the mode. *)
val create_with_mode :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  mode ->
  t

(** Create a client with mode [Client] and import all secret keys
    listed in {!Constant.all_secret_keys}. *)
val init :
  ?path:string ->
  ?admin_path:string ->
  ?name:string ->
  ?color:Log.Color.t ->
  ?base_dir:string ->
  ?endpoint:endpoint ->
  ?media_type:media_type ->
  unit ->
  t Lwt.t

(** Get a client's mode. Used with [set_mode] to temporarily change
    a client's mode *)
val get_mode : t -> mode

(** Change the client's mode. This function is required for example because
    we wanna keep a client's wallet. This is impossible if we created
    a new client from scratch. *)
val set_mode : mode -> t -> unit

val mode_arg : t -> string list

(** To avoid repeating unduly the sources file name, this function returns said
    file name as string.  Do not call it from a client in Mockup or Client
    (nominal) mode. *)
val sources_file : t -> string

(** Write the [--sources] file used by the light mode. *)
val write_sources_file :
  min_agreement:float -> uris:string list -> t -> unit Lwt.t

(** Returns the [address] on which [from] can contact an endpoint. *)
val address : ?hostname:bool -> ?from:endpoint -> endpoint -> string

val set_additional_bootstraps : t -> Account.key list -> unit

(** {2 RPC calls} *)

(** Paths for RPCs.

    For instance, [["chains"; "main"; "blocks"; "head"]]
    denotes [/chains/main/blocks/head]. *)
type path = string list

(** [string_of_path ["seg1"; "seg2"]] is ["/seg1/seg2"] *)
val string_of_path : path -> string

(** Query strings for RPCs.

    For instance, [["key1", "value1"; "key2", "value2"]]
    denotes [?key1=value1&key2=value2]. *)
type query_string = (string * string) list

(** HTTP methods for RPCs. *)
type meth = GET | PUT | POST | PATCH | DELETE

(** A lowercase string of the method. *)
val string_of_meth : meth -> string

(** [rpc_path_query_to_string ["key1", "value1"; "key2", "value2")] ["seg1"; "seg2"]]
    returns [/seg1/seg2?key1=value1&key2=value2] where seg1, seg2, key1, key2,
    value1, and value2 have been appropriately encoded *)
val rpc_path_query_to_string : ?query_string:query_string -> path -> string

(** Use the client to call an RPC.

    Run [rpc meth path?query_string with data].
    Fail the test if the RPC call failed.

    See the documentation of {!Process.spawn} for information about
    [log_*], [hooks] and [env] arguments.

    In particular, [env] can be used to pass [TEZOS_LOG], e.g.
    [("TEZOS_LOG", Protocol.daemon_name protocol ^ ".proxy_rpc->debug")] to enable
    logging. *)
val rpc :
  ?log_command:bool ->
  ?log_status_on_exit:bool ->
  ?log_output:bool ->
  ?better_errors:bool ->
  ?endpoint:endpoint ->
  ?hooks:Process.hooks ->
  ?env:string String_map.t ->
  ?data:JSON.u ->
  ?query_string:query_string ->
  meth ->
  path ->
  t ->
  JSON.t Lwt.t

(** Same as [rpc], but do not wait for the process to exit. *)
val spawn_rpc :
  ?log_command:bool ->
  ?log_status_on_exit:bool ->
  ?log_output:bool ->
  ?better_errors:bool ->
  ?endpoint:endpoint ->
  ?hooks:Process.hooks ->
  ?env:string String_map.t ->
  ?data:JSON.u ->
  ?query_string:query_string ->
  meth ->
  path ->
  t ->
  Process.t

module Spawn : sig
  (* FIXME: This module is temporary and is here to make the new
     interface cohabits with the old one. *)
  val rpc :
    ?log_command:bool ->
    ?log_status_on_exit:bool ->
    ?log_output:bool ->
    ?better_errors:bool ->
    ?endpoint:endpoint ->
    ?hooks:Process.hooks ->
    ?env:string String_map.t ->
    ?data:JSON.u ->
    ?query_string:query_string ->
    meth ->
    path ->
    t ->
    JSON.t Runnable.process
end

val rpc_stream :
  ?log_command:bool ->
  ?log_status_on_exit:bool ->
  ?log_output:bool ->
  ?better_errors:bool ->
  ?endpoint:endpoint ->
  ?hooks:Process.hooks ->
  ?env:string String_map.t ->
  ?data:Ezjsonm.value ->
  ?query_string:(string * string) list ->
  meth ->
  string list ->
  t ->
  (JSON.t -> [`Continue | `Stop] Lwt.t) ->
  unit Lwt.t

(** Run [tezos-client rpc list]. *)
val rpc_list : ?endpoint:endpoint -> t -> string Lwt.t

(** Same as [rpc_list], but do not wait for the process to exit. *)
val spawn_rpc_list : ?endpoint:endpoint -> t -> Process.t

(** Spawn a low-level client command.

   Prefer using higher-level functions defined in this module, or adding a new
   one, to deferring to [spawn_command].

   It can be used, for example, for low-level one-shot customization of client
   commands.  *)
val spawn_command :
  ?log_command:bool ->
  ?log_status_on_exit:bool ->
  ?log_output:bool ->
  ?env:string String_map.t ->
  ?endpoint:endpoint ->
  ?hooks:Process.hooks ->
  ?admin:bool ->
  t ->
  string list ->
  Process.t
