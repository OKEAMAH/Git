(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* Re-export unix implementation *)

include Tezos_p2p_unix.P2p

let build_rpc_directory = Tezos_p2p_unix.P2p_directory.build_rpc_directory

module Internal_for_tests = struct
  type ('msg, 'peer, 'conn) mocked_network = unit

  let find_handle_opt _version = None

  let connect_peers _handle ~a:_ ~b:_ ~a_meta:_ ~b_meta:_ ~ab_conn_meta:_
      ~ba_conn_meta:_ ~propagation_delay:_ =
    Error "P2p.Internal_for_tests: connect_peers not implemented"

  let disconnect_peers _handle ~a:_ ~b:_ =
    Error "P2p.Internal_for_tests: disconnect_peers not implemented"

  let neighbourhood _handle _peer =
    invalid_arg "P2p.Internal_for_tests: neighbourhood not implemented"

  let iter_neighbourhood _handle _peer _f =
    invalid_arg "P2p.Internal_for_tests: iter_neighbourhood not implemented"

  let iter_neighbourhood_es _handle _peer _f =
    invalid_arg "P2p.Internal_for_tests: iter_neighbourhood not implemented"

  let sleep_on_deferred_delays _handle _peer_id =
    invalid_arg
      "P2p.Internal_for_tests: sleep_on_deferred_delays not implemented"
end
