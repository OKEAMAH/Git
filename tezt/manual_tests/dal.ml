(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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
   Component:    DAL
   Invocation:   dune exec tezt/manual_tests/main.exe -- --file dal.ml --test-arg output-file=<file>
   Subject:      Test getting informaton about the DAL distribution.
*)

let dal_distribution =
  Protocol.register_test
    ~__FILE__
    ~title:"Get the DAL distribution"
    ~tags:["dal"; "distribution"]
    ~supports:Protocol.(From_protocol 15)
  @@ fun protocol ->
  let _data_dir =
    Cli.get ~default:None (fun data_dir -> Some (Some data_dir)) "data-dir"
  in
  let levels =
    Cli.get ~default:10 (fun levels -> int_of_string_opt levels) "levels"
  in
  let output_file =
    match
      Cli.get
        ~default:None
        (fun output_file -> Some (Some output_file))
        "output-file"
    with
    | None ->
        Test.fail "Specify an output file with --test-arg output-file=<file>"
    | Some output_file -> output_file
  in
  let* parameter_file = Rollup.Dal.Parameters.parameter_file protocol in
  let* node, client =
    Client.init_with_protocol ~parameter_file ~protocol `Client ()
  in
  let* () = Client.bake_for_and_wait client in
  let* number_of_shards =
    let* constants =
      RPC.Client.call client (RPC.get_chain_block_context_constants ())
    in
    JSON.(constants |-> "dal_parametric" |-> "number_of_shards" |> as_int)
    |> return
  in
  let results =
    Array.init levels (fun _ ->
        Array.make number_of_shards Constant.bootstrap1.public_key_hash)
  in
  let* current_level =
    RPC.Client.call client (RPC.get_chain_block_helper_current_level ())
  in
  let rec iter offset =
    let level = current_level.level + offset in
    if offset < 0 then unit
    else
      let* json =
        RPC.(call node @@ get_chain_block_context_dal_shards ~level ())
      in
      List.iter
        (fun json ->
          let pkh = JSON.(json |=> 0 |> as_string) in
          let initial_slot = JSON.(json |=> 1 |=> 0 |> as_int) in
          let power = JSON.(json |=> 1 |=> 1 |> as_int) in
          for slot = initial_slot to initial_slot + power - 1 do
            let line = Array.get results offset in
            Array.set line slot pkh
          done)
        (JSON.as_list json) ;
      iter (offset - 1)
  in
  let* () = iter (levels - 1) in
  with_open_out output_file (fun oc ->
      output_string oc "levels, " ;
      for slot = 0 to number_of_shards - 1 do
        output_string oc (Format.asprintf "pkh for slot %d, " slot)
      done ;
      output_string oc "\n" ;
      for i = 0 to levels - 1 do
        output_string oc (Format.asprintf "level %d, " i) ;
        for slot = 0 to number_of_shards - 1 do
          let pkh = results.(i).(slot) in
          output_string oc pkh ;
          output_string oc ", "
        done ;
        output_string oc "\n"
      done) ;
  unit

let wait_for_sync node =
  let filter json =
    let status = JSON.as_string json in
    Log.info "%s: %s" (Node.name node) status ;
    if String.equal status "synced" then Some () else None
  in
  Node.wait_for node "synchronisation_status.v0" filter

let dailynet () =
  Test.register
    ~__FILE__
    ~title:"Produce slots on dailynet"
    ~tags:["dal"; "dailynet"]
  @@ fun () ->
  let default_wallet =
    Format.sprintf "%s/dailynet-wallet" (Filename.get_temp_dir_name ())
  in
  let load = Cli.get ~default:None (fun _ -> Some (Some ())) "load" in
  let save = Cli.get ~default:None (fun _ -> Some (Some ())) "save" in
  let wallet = Cli.get ~default:None (fun _ -> Some (Some ())) "wallet" in
  let* slot_producer_key =
    match wallet with
    | None ->
        let* () = Process.run "mkdir" [default_wallet] in
        Log.info "No wallet provided. One will be created in %s." default_wallet ;
        let client = Client.create ~base_dir:default_wallet () in
        let* key = Client.gen_and_show_keys ~alias:"slot-producer" client in
        Log.info
          "Key generated for the slot producer is: %s"
          key.public_key_hash ;
        Log.info "Please fund this key via a faucet." ;
        Log.info
          "Dailynet faucet: https://faucet.dailynet-2023-06-23.teztnets.xyz/" ;
        Log.info
          "Press enter once it is done (wait a bit the time the funds are \
           actually transferred)" ;
        ignore (input_line stdin) ;
        return key
    | Some _ -> (
        let client = Client.create ~base_dir:default_wallet () in
        let* addresses = Client.list_known_addresses client in
        match addresses with
        | [(alias, public_key_hash)] ->
            Log.info "Address found: %s:%s" alias public_key_hash ;
            let* key = Client.show_address ~alias client in
            return key
        | _ ->
            Test.fail
              "Please, provide a valid wallet. Run this scenario without the \
               wallet argument.")
  in
  let node = Node.create [] in
  let tezt_data_dir = Node.data_dir node in
  let year, month, day = Ptime_clock.now () |> Ptime.to_date in
  let network_name =
    (* Format of the day should be: yyy-mm-dd *)
    Format.sprintf "dailynet-%d-%02d-%02d" year month day
  in
  let network = Format.sprintf "https://teztnets.xyz/%s" network_name in
  let backup = Filename.get_temp_dir_name () // network_name in
  let load () =
    match load with
    | None ->
        let* () =
          Node.config_init
            node
            [Network network; Expected_pow 26; Synchronisation_threshold 2]
        in
        return ()
    | Some _ ->
        Log.info "Load data-dir in current tezt workspace" ;
        let* () = Process.run "cp" ["-rT"; backup; tezt_data_dir] in
        return ()
  in
  let* () = load () in
  let* () = Node.run node [Network network] in
  let* () = Node.wait_for_ready node in
  let* () = wait_for_sync node in
  let save () =
    match save with
    | None -> return ()
    | Some _ ->
        Log.info "Save the current data-dir into %s@." backup ;
        let* () = Node.terminate node in
        let* () = Process.run "cp" ["-rT"; tezt_data_dir; backup] in
        let* () = Node.run node [Network network] in
        Node.wait_for_ready node
  in
  let* () = save () in
  let client =
    Client.create ~base_dir:default_wallet ~endpoint:(Node node) ()
  in
  let dal_node = Dal_node.create ~node ~client () in
  let bootstrap_peer =
    (* There is a parsing issue so we can't use this. *)
    Format.sprintf "dal.dailynet-%d-%02d-%02d.teztnets.xyz:11732" year month day
  in
  let* () =
    Dal_node.init_config
      ~peers:[bootstrap_peer]
      ~profile:"tz1foXHgRzdYdaLgX6XhpZGxbBv42LZ6ubvE"
      dal_node
  in
  let* () = Dal_node.run dal_node in
  let* parameters = Rollup.Dal.Parameters.from_client client in
  let cryptobox = parameters.cryptobox in
  let slot =
    String.init 30 (fun i ->
        match i mod 3 with 0 -> 'a' | 1 -> 'b' | _ -> 'c')
    |> Rollup.Dal.make_slot ~slot_size:cryptobox.slot_size
  in
  let x = Ptime_clock.now () in
  let* commitment = RPC.call dal_node (Rollup.Dal.RPC.post_commitment slot) in
  let y = Ptime_clock.now () in
  Log.info "POST: %a" Ptime.Span.pp (Ptime.diff y x) ;
  let* () =
    RPC.call dal_node
    @@ Rollup.Dal.RPC.put_commitment_shards ~with_proof:true commitment
  in
  let commitment_hash =
    match Rollup.Dal.Cryptobox.Commitment.of_b58check_opt commitment with
    | None -> assert false
    | Some hash -> hash
  in
  let* proof =
    let* proof =
      RPC.call dal_node @@ Rollup.Dal.RPC.get_commitment_proof commitment
    in
    return
      (Data_encoding.Json.destruct
         Rollup.Dal.Cryptobox.Commitment_proof.encoding
         (`String proof))
  in
  let publish () =
    let level = Node.get_level node in
    (* let* _ = *)
    (*   Operation.Manager.( *)
    (*     inject [make ~source:slot_producer_key @@ reveal slot_producer_key] client) *)
    (* in *)
    let* _ =
      Operation.Manager.(
        inject
          ~force:true
          [
            make ~source:slot_producer_key
            @@ dal_publish_slot_header
                 ~index:5
                 ~level:(level + 1)
                 ~commitment:commitment_hash
                 ~proof;
          ]
          client)
    in
    let* () = Lwt_unix.sleep 60. in
    return ()
  in
  let* () = repeat 100 publish in
  let* _ = Lwt_unix.sleep 1000. in
  return ()

let register protocols =
  dal_distribution protocols ;
  dailynet ()
