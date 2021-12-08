(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(** The type of a module packing a [filter] allowing to monitor interesting
    data from rollup operations included in each new head. *)
module type ROLLUP_MONITOR = sig
  (** The protocol for which this filter operates. *)
  module Proto : Registered_protocol.T

  (** The abstract type of a [rollup_address], implemented protocol-side. *)
  type rollup_address

  (** The type of the data we wish to extract from blocks (typically, rollup
      messages and the state of the inbox). *)
  type t

  val encoding : t Data_encoding.t

  (** The service at which a stream of type [t] will be made available.  *)
  module S : sig
    val monitor_rollup :
      ( [`GET],
        unit,
        (unit * Chain_services.chain) * rollup_address,
        unit,
        unit,
        t trace )
      RPC_service.t
  end

  (** [filter rollup ~op ~metadata] returns for each operation and its matching
      receipt a potentially empty list of elements of type [t]. The semantics
      is entirely defiend in the plugin. A typical example is be to select
      all messages sent to a particular rollup. *)
  val filter : rollup_address -> op:Operation.t -> metadata:Bytes.t -> t list
end

(** [service validator store monitor] implements a streaming RPC service
    compatible with the type of [monitor_rollup] above. *)
val service :
  Validator.t ->
  Store.t ->
  (module ROLLUP_MONITOR with type rollup_address = 'b and type t = 'a) ->
  Chain_services.chain ->
  'b ->
  unit ->
  unit ->
  'a trace RPC_answer.t Lwt.t

val register : (module ROLLUP_MONITOR) -> unit

val find : Protocol_hash.t -> (module ROLLUP_MONITOR) option

val iter : (Protocol_hash.t -> (module ROLLUP_MONITOR) -> unit) -> unit
