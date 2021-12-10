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

let get_state tx_rollup_hash client =
  let* json = RPC.Tx_rollup.get_state ~tx_rollup_hash client in
  JSON.(json |-> "state" |> as_opt) |> Lwt.return

let get_block_hash block_json =
  JSON.(block_json |-> "hash" |> as_string) |> return

let test ~__FILE__ ~output_file ?(tags = []) title =
  Protocol.register_regression_test
    ~output_file
    ~__FILE__
    ~title
    ~tags:("tx_rollup" :: tags)

let setup f ~protocol =
  let enable_tx_rollup = [(["tx_rollup_enable"], Some "true")] in
  let base = Either.right protocol in
  let* parameter_file = Protocol.write_parameter_file ~base enable_tx_rollup in
  let* (node, client) =
    Client.init_with_protocol ~parameter_file `Client ~protocol ()
  in
  let bootstrap1_key = Constant.bootstrap1 in
  f node client bootstrap1_key

let test_with_setup ~__FILE__ ~output_file ?(tags = []) title f =
  test ~__FILE__ ~output_file ~tags title (fun protocol ->
      setup ~protocol (fun node client bootstrap_key ->
          f protocol node client bootstrap_key))

(*                               test                                        *)

let test_simple_use_case =
  let output_file = "tx_simple_use_case" in
  let open Tezt_tezos in
  test_with_setup
    ~__FILE__
    ~output_file
    "TX_rollup: simple use case"
    (fun _protocol _node client bootstrap1_key ->
      let* tx_rollup_hash =
        Client.originate_tx_rollup
          ~burn_cap:Tez.(of_int 9999999)
          ~storage_limit:60_000
          ~src:bootstrap1_key.public_key_hash
          client
      in
      let* () = Client.bake_for client in
      let* state = get_state tx_rollup_hash client in
      match state with
      | Some s ->
          let () = Regression.capture @@ JSON.encode s in
          unit
      | None ->
          Test.fail
            "The tx rollups was not correctly originated and no state exists \
             for %s."
            tx_rollup_hash)

let test_node_configuration =
  let output_file = "tx_node_configuration" in
  test_with_setup
    ~__FILE__
    ~output_file
    "TX_rollup: configuration"
    (fun _protocol node client bootstrap1_key ->
      let operator = bootstrap1_key.public_key_hash in
      let* tx_rollup_hash =
        Client.originate_tx_rollup
          ~burn_cap:Tez.(of_int 9999999)
          ~storage_limit:60_000
          ~src:operator
          client
      in
      let* json = RPC.get_block client in
      let* block_hash = get_block_hash json in
      let tx_rollup_node =
        Tx_rollup_node.create
          ~rollup_id:tx_rollup_hash
          ~block_hash
          ~operator
          client
          node
      in
      let* filename =
        Tx_rollup_node.config_init tx_rollup_node tx_rollup_hash block_hash
      in
      let configuration =
        let open Ezjsonm in
        match from_channel @@ open_in filename with
        | `O fields ->
            `O
              (List.map
                 (fun (k, v) ->
                   let x =
                     if k = "data-dir" || k = "block-hash" then
                       `String "<variable>"
                     else v
                   in
                   (k, x))
                 fields)
            |> to_string
        | _ -> failwith "Unexpected configuration format"
      in
      let () = Regression.capture configuration in
      unit)

let register ~protocols =
  test_simple_use_case ~protocols ;
  test_node_configuration ~protocols
