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

(*                               utils                                       *)

(** To be attached to process whose output needs to be captured by the
    regression framework. *)
let hooks = Tezos_regression.hooks

type state = {fees_per_byte : int}

type inbox = {cumulated_size : int; contents : string list}

let get_state ?hooks tx_rollup client =
  (* The state is currently empty, but the RPC can fail if [tx_rollup]
     does not exist. *)
  let* json = RPC.Tx_rollup.get_state ?hooks ~tx_rollup client in
  let fees_per_byte = JSON.(json |-> "fees_per_byte" |> as_int) in
  return {fees_per_byte}

let get_inbox ?hooks tx_rollup client =
  let* json = RPC.Tx_rollup.get_inbox ?hooks ~tx_rollup client in
  (* let obj = JSON.(json |> as_object) in *)
  let cumulated_size = JSON.(json |-> "cumulated_size" |> as_int) in
  let contents = JSON.(json |-> "contents" |> as_list |> List.map as_string) in
  return {cumulated_size; contents}

(*                               test                                        *)

let test_submit_batch ~protocols =
  let open Tezt_tezos in
  Protocol.register_regression_test
    ~__FILE__
    ~output_file:"tx_rollup_simple_use_case"
    ~title:"Simple use case"
    ~tags:["tx_rollup"]
    ~protocols
  @@ fun protocol ->
  let* parameter_file =
    Protocol.write_parameter_file
      ~base:(Either.right (protocol, None))
      [(["tx_rollup_enable"], Some "true")]
  in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  let* tx_rollup =
    Client.originate_tx_rollup
      ~burn_cap:Tez.(of_int 9999999)
      ~storage_limit:60_000
      ~src:Constant.bootstrap1.public_key_hash
      client
  in

  Regression.capture tx_rollup ;

  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in

  (* We check the rollup exists by trying to fetch its state. Since it
     is a regression test, we can detect changes to this default
     state. *)
  let* _state = get_state ~hooks tx_rollup client in

  (* Submit a batch *)
  let batch = "tezos" in

  let* () =
    Client.submit_tx_rollup_batch
      ~hooks
      ~content:batch
      ~tx_rollup
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let* () = Client.bake_for client in

  (* Without that, the test is flaky for some reason *)
  let* _ = Node.wait_for_level node 3 in

  (* Check the inbox has been created *)
  let* inbox = get_inbox ~hooks tx_rollup client in

  assert (String.length batch = inbox.cumulated_size) ;

  unit

(** [test_deposit] originates a transaction rollup, and a smart
    contract that it uses to perform a ticket deposit to this
    rollup. *)
let test_deposit ~protocols =
  let open Tezt_tezos in
  Protocol.register_regression_test
    ~__FILE__
    ~output_file:"tx_rollup_deposit"
    ~title:"Alpha: Deposit a ticket"
    ~tags:["rollup"]
    ~protocols
  @@ fun protocol ->
  let* parameter_file =
    Protocol.write_parameter_file
      ~base:(Either.right (protocol, None))
      [(["tx_rollup_enable"], Some "true")]
  in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in

  let* tx_rollup_contract =
    Client.originate_contract
      ~hooks
      ~alias:"tx_rollup_deposit"
      ~amount:Tez.zero
      ~src:Constant.bootstrap1.public_key_hash
      ~prg:"file:./tezt/tests/contracts/proto_alpha/tx_rollup_deposit.tz"
      ~init:"Unit"
      ~burn_cap:Tez.(of_int 3)
      client
  in

  Regression.capture tx_rollup_contract ;

  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in

  let* tx_rollup =
    Client.originate_tx_rollup
      ~burn_cap:Tez.(of_int 9999999)
      ~storage_limit:60_000
      ~src:Constant.bootstrap2.public_key_hash
      client
  in

  Regression.capture tx_rollup ;

  let* () = Client.bake_for client in

  let* _ = Node.wait_for_level node 3 in

  (* We check the rollup exists by trying to fetch its state. *)
  let* _state = get_state tx_rollup client in

  (* We inject a call to the smart contract *)
  let* _ =
    Client.transfer
      ~burn_cap:Tez.(of_int 9999999)
      ~amount:Tez.zero
      ~giver:"bootstrap1"
      ~receiver:tx_rollup_contract
      ~arg:(Format.sprintf "Pair \"%s\" 3" tx_rollup)
      client
  in
  let* () = Client.bake_for ~minimal_fees:0 client in
  let* _ = Node.wait_for_level node 4 in

  (* Check that the inbox has been created for [tx_rollup]. *)
  let* inbox = get_inbox ~hooks tx_rollup client in

  Check.(
    (List.length inbox.contents = 1)
      int
      ~error_msg:"The inbox should contain one message") ;

  unit

let register ~protocols =
  test_submit_batch ~protocols ;
  test_deposit ~protocols
