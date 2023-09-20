(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(** [V0] is experimental DAC API. [V0] is deprecated, however for the
    time being the API will be binding. It will be used by
    1M/tps demo. The plan is to remove it once we get rid of the 
    [Legacy] mode. Use at your own risk! *)
module V0 : sig
  module S : sig
    (** Define RPC "GET v0/monitor/root_hashes". *)
    val root_hashes :
      ( [`GET],
        unit,
        unit,
        unit,
        unit,
        Dac_plugin.raw_hash )
      Tezos_rpc.Service.service

    (** Define RPC "GET v0/monitor/certificate/hex_root_hash". *)
    val certificate :
      ( [`GET],
        unit,
        unit * Dac_plugin.raw_hash,
        unit,
        unit,
        Certificate_repr.t )
      Tezos_rpc.Service.service
  end

  (** [root_hashes streamed_cctxt raw_hash] returns a stream
    of root hashes and a stopper for it.

    Stream is produced by calling RPC "GET v0/monitor/root_hashes".
*)
  val root_hashes :
    #Tezos_rpc.Context.streamed ->
    (Dac_plugin.raw_hash Lwt_stream.t * Tezos_rpc.Context.stopper)
    Error_monad.tzresult
    Lwt.t

  (** [certificate streamed_cctxt raw_hash] returns a stream and a
    stopper for monitoring certificate updates for a given root hash.
    
    Stream is produced by calling RPC "GET v0/monitor/certificate".
*)
  val certificate :
    #Tezos_rpc.Context.streamed ->
    Dac_plugin.raw_hash ->
    (Certificate_repr.t Lwt_stream.t * Tezos_rpc.Context.stopper)
    Error_monad.tzresult
    Lwt.t
end
