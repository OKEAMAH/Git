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

(*

   Helpers
   =======

*)
let test ~__FILE__ ~output_file title =
  Protocol.register_regression_test
    ~output_file
    ~__FILE__
    ~title
    ~tags:["sc_rollup"]

let setup f ~protocol =
  let enable_sc_rollup = [(["enable_sc_rollup"], Some "true")] in
  let base = Either.right protocol in
  let* parameter_file = Protocol.write_parameter_file ~base enable_sc_rollup in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  let bootstrap1_key = Constant.bootstrap1.public_key_hash in
  f node client bootstrap1_key

(*

   Tests
   =====

*)

(* Create a new rollup of the arithmetic kind.
   -------------------------------------------

   - Rollup addresses are fully determined by operation hashes and origination nonce.

*)
let test_creation =
  let output_file = "sc_rollup_creation" in
  test
    ~__FILE__
    ~output_file
    "creation of an optimistic rollup executes without error"
    (fun protocol ->
      setup ~protocol @@ fun _node client bootstrap1_key ->
      let* rollup_address =
        Client.create_rollup
          ~burn_cap:Tez.(of_int 9999999)
          ~src:bootstrap1_key
          ~kind:"hp48"
          ~boot_sector:""
          client
      in
      let* () = Client.bake_for client in
      Regression.capture rollup_address ;
      return ())

let register ~protocols = test_creation ~protocols
