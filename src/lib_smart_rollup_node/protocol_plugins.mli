(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

(** {2 Protocol registration logic} *)

type ('repo, 'tree) proto_plugin = ('repo, 'tree) Protocol_plugin_sig.typed_full

type 'a tid = 'a Context.tid

(** Register a protocol plugin for a specific protocol to be used by the
    rollup node. *)
val register : ('repo, 'tree) proto_plugin -> ('repo * 'tree) tid

(** Returns the list of registered protocols. *)
val registered_protocols : unit -> Protocol_hash.t list

(** {2 Using the correct protocol plugin} *)

(* (\** Return the protocol plugin L1 helpers for a given protocol (or an error if not *)
(*     supported). *\) *)
(* val proto_helpers_for_protocol : *)
(*   Protocol_hash.t -> (module Protocol_plugin_sig.LAYER1_HELPERS) tzresult *)

(** Return the protocol plugin for a given protocol (or an error if not
    supported). *)
val proto_plugin_for_protocol :
  ('repo * 'tree) tid -> Protocol_hash.t -> ('repo, 'tree) proto_plugin tzresult

(** Return the protocol plugin for a given level (or an error if not
    supported). *)
val proto_plugin_for_level :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  int32 ->
  ('repo, 'tree) proto_plugin tzresult Lwt.t

(** Return the protocol plugin for a given level (or an error if not
    supported). *)
val proto_plugin_for_level_with_store :
  ('repo * 'tree) tid ->
  _ Store.t ->
  int32 ->
  ('repo, 'tree) proto_plugin tzresult Lwt.t

(** Return the protocol plugin for a given block (or an error if not
    supported). *)
val proto_plugin_for_block :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  Block_hash.t ->
  ('repo, 'tree) proto_plugin tzresult Lwt.t

(** Returns the plugin corresponding to the last protocol seen by the rollup
    node. *)
val last_proto_plugin :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  ('repo, 'tree) proto_plugin tzresult Lwt.t

(** {2 Safe protocol specific constants}

    These functions provide a way to retrieve constants in a safe manner,
    depending on the context.
*)

(** Retrieve constants for a given protocol (values are cached). *)
val get_constants_of_protocol :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  Protocol_hash.t ->
  Rollup_constants.protocol_constants tzresult Lwt.t

(** Retrieve constants for a given level (values are cached). *)
val get_constants_of_level :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  int32 ->
  Rollup_constants.protocol_constants tzresult Lwt.t

(** Retrieve constants for a given block hash (values are cached). *)
val get_constants_of_block_hash :
  ('repo * 'tree) tid ->
  (_, 'repo) Node_context.t ->
  Block_hash.t ->
  Rollup_constants.protocol_constants tzresult Lwt.t
