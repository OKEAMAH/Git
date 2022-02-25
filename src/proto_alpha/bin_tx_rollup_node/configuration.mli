(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2022 Oxhead Alpha <info@oxhead-alpha.com>                   *)
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

(* provide a default configuration:
   https://gitlab.com/tezos/tezos/-/issues/2458
*)

type t = {
  data_dir : string;
  client_keys : Client_keys.Public_key_hash.t;
  rollup_id : Protocol.Alpha_context.Tx_rollup.t;
  rollup_genesis : Block_hash.t option;
  rpc_addr : string;
  rpc_port : int;
  reconnection_delay : float;
}

(** [default_data_dir] is the default value for [data_dir]. *)
val default_data_dir : string

(** [default_rpc_addr] is the default value for [rpc_addr]. *)
val default_rpc_addr : string

(** [default_rpc_port] is the default value for [rpc_port]. *)
val default_rpc_port : int

(** [default_reconnection_delay] is the default value for [reconnection-delay]*)
val default_reconnection_delay : float

(** [get_configuration_filename data_dir] returns the [configuration] filename in [data_dir]. *)
val get_configuration_filename : string -> string

(** [save configuration] overwrites [configuration] file. *)
val save : t -> unit tzresult Lwt.t

(** [load ~data_dir] loads a configuration stored in [data_dir]. *)
val load : data_dir:string -> t tzresult Lwt.t

(** [encoding] encodes a configuration. *)
val encoding : t Data_encoding.t
