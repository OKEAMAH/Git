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

(* Each worker gets an interval of [interval_size] ports to work with.
   The default starting port is 16384.
   With an interval size of 1000 we can use -j 16 and stay below port 32768.
   This means that we can run 500 nodes in the same test. *)
let interval_size = 1000

let next = ref 0

let starting_port = 5_000

let fresh_using_increment () =
  let slot = !next mod interval_size in
  incr next ;
  starting_port
  + (interval_size * (Test.current_worker_id () |> Option.value ~default:0))
  + slot

let fresh () =
  let rec loop remaining_attempts =
    if remaining_attempts <= 0 then
      Test.fail "failed to find a port that is not already in use" ;
    let port = fresh_using_increment () in
    let dummy_socket = Unix.(socket PF_INET SOCK_STREAM 0) in
    match
      Unix.bind dummy_socket Unix.(ADDR_INET (inet_addr_loopback, port))
    with
    | exception Unix.Unix_error (EADDRINUSE, _, _) ->
        Unix.close dummy_socket ;
        loop (remaining_attempts - 1)
    | exception exn ->
        Unix.close dummy_socket ;
        raise exn
    | () ->
        Unix.close dummy_socket ;
        port
  in
  loop 20

let () = Test.declare_reset_function @@ fun () -> next := 0
