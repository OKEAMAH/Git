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

let l2_account1 =
  "0x00000030b378a36ade25a9d23b684d35e4b969b11cc391858091c2393edf6fc1624cc26b21742955cc26e45c9c247a90b33182a5"

let get_cost_per_byte tx_rollup client =
  let* json = RPC.Tx_rollup.get_state ~tx_rollup client in
  JSON.(json |-> "cost_per_byte" |> as_int |> Tez.of_mutez_int |> Lwt.return)

type inbox = {content : JSON.t list; cumulated_size : int}

let parse_inbox : JSON.t -> inbox =
 fun inbox_obj ->
  let content = JSON.(inbox_obj |-> "contents" |> as_list) in
  let cumulated_size = JSON.(inbox_obj |-> "cumulated_size" |> as_int) in
  {content; cumulated_size}

let get_inbox tx_rollup client =
  let* json = RPC.Tx_rollup.get_inbox ~tx_rollup client in
  return (parse_inbox json)

(*                               test                                        *)

(** [test_simple_use_case] originates a transaction rollup and asserts no inbox
    has been created by default for it. *)
let test_simple_use_case =
  let open Tezt_tezos in
  Protocol.register_test ~__FILE__ ~title:"Simple use case" ~tags:["rollup"]
  @@ fun protocol ->
  let* parameter_file =
    Protocol.write_parameter_file
      ~base:(Either.right (protocol, None))
      [(["tx_rollup_enable"], Some "true")]
  in
  let* (_node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  let* tx_rollup =
    Client.originate_tx_rollup
      ~burn_cap:Tez.(of_int 9999999)
      ~storage_limit:60_000
      ~src:Constant.bootstrap1.public_key_hash
      client
  in
  let* () = Client.bake_for client in
  (* Check the transaction rollup exists by trying to fetch its current
     [cost_per_byte] state variable. *)
  let* _rate = get_cost_per_byte tx_rollup client in
  RPC.Tx_rollup.spawn_get_inbox ~tx_rollup client
  |> Process.check_error ~exit_code:1 ~msg:(rex "No service found at this URL")

(** [test_deposit] originates a transaction rollup, and a smart
    contract that it uses to perform a ticket deposit to this
    rollup. *)
let test_deposit =
  let open Tezt_tezos in
  Protocol.register_test
    ~__FILE__
    ~title:"Alpha: Deposit a ticket"
    ~tags:["rollup"]
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
      ~alias:"tx_rollup_deposit"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:"file:./tezt/tests/contracts/proto_alpha/tx_rollup_deposit.tz"
      ~init:"Unit"
      ~burn_cap:Tez.(of_int 3)
      client
  in
  let* tx_rollup =
    Client.originate_tx_rollup
      ~burn_cap:Tez.(of_int 9999999)
      ~storage_limit:60_000
      ~src:Constant.bootstrap2.public_key_hash
      client
  in

  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 2 in

  let* (`OpHash _) =
    Operation.inject_contract_call
      ~amount:0
      ~source:Constant.bootstrap1
      ~dest:tx_rollup_contract
      ~entrypoint:"default"
      ~arg:(`Michelson (Format.sprintf "Pair \"%s\" %s" tx_rollup l2_account1))
      client
  in

  let* () = Client.bake_for client in
  let* _ = Node.wait_for_level node 3 in

  let* inbox = get_inbox tx_rollup client in

  Check.(
    (List.length inbox.content = 1)
      int
      ~error_msg:"The inbox should contain one message") ;

  unit

let register ~protocols =
  test_simple_use_case ~protocols ;
  test_deposit ~protocols
