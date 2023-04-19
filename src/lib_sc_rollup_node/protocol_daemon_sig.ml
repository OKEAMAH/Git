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

module type CONTEXT = sig
  type 'a t constraint 'a = [< `Read | `Write > `Read]

  (** Read/write node context {!t}. *)
  type rw = [`Read | `Write] t

  (** Read only node context {!t}. *)
  type ro = [`Read] t

  val init :
    #Client_context.full ->
    ?head:Block_hash.t ->
    data_dir:string ->
    ?log_kernel_debug_file:string ->
    'a Store_sigs.mode ->
    Configuration.t ->
    'a t tzresult Lwt.t

  val get_l2_predecessor :
    _ t -> Block_hash.t -> ((Block_hash.t * int32) option, tztrace) result Lwt.t

  val last_processed_block : _ t -> (Block_hash.t * int32) option tzresult Lwt.t

  val origination_level : _ t -> int32

  val close : _ t -> unit tzresult Lwt.t
end

module type RPC_SERVER = sig
  type context

  val init :
    Configuration.t -> context -> Tezos_rpc_http_server.RPC_server.server
end

module type S = sig
  module Node_context : CONTEXT

  module RPC_server : RPC_SERVER with type context := Node_context.rw

  val process_block :
    Node_context.rw ->
    Block_hash.t * Block_header.shell_header ->
    unit tzresult Lwt.t

  val on_layer_1_head_extra :
    Node_context.rw ->
    Block_hash.t * Block_header.shell_header ->
    unit tzresult Lwt.t

  val enter_degraded_mode : Node_context.rw -> unit tzresult Lwt.t

  val degraded_mode_on_block :
    Block_hash.t * Block_header.shell_header -> unit tzresult Lwt.t

  val start_workers : Configuration.t -> Node_context.rw -> unit tzresult Lwt.t

  val stop_workers : _ Node_context.t -> unit tzresult Lwt.t
end
