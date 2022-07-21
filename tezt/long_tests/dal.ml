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

(* Testing
   -------
   Component: Dal_node
   Invocation: dune exec tezt/long_tests/main.exe -- --file dal.ml
   Subject: Dal Node execution checks
*)

let env = String_map.singleton "DAL_TRUSTED_SETUP" (Long_test.test_data_path ())

let check_dal_node_slot_management _protocol =
  let dal_node = Dal_node.create () in
  let* _dir = Dal_node.init_config dal_node in
  let* () = Dal_node.run dal_node in
  let slot_content = "test" in
  let* slot_header = Dal_node.split_slot_rpc dal_node slot_content in
  let* received_slot_content = Dal_node.slot_content_rpc dal_node slot_header in
  assert (slot_content = received_slot_content) ;
  return ()

let register ~executors () =
  Long_test.register
    ~__FILE__
    ~title:"dal node slot management"
    ~tags:["dal"; "dal_node"]
    ~timeout:(Long_test.Minutes 5)
    ~executors
    check_dal_node_slot_management
