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

let wait_for_sync node =
  let filter json =
    let status = JSON.as_string json in
    Log.info "%s: %s" (Node.name node) status ;
    if String.equal status "synced" then Some () else None
  in
  Node.wait_for node "synchronisation_status.v0" filter

module Network = struct
  type network = Dailynet

  let name = function
    | `Dailynet -> (
        match
          Cli.get ~default:None (fun name -> Some (Some name)) "network"
        with
        | None ->
            let year, month, day = Ptime_clock.now () |> Ptime.to_date in
            (* Format of the day should be: yyy-mm-dd *)
            Format.sprintf "dailynet-%d-%02d-%02d" year month day
        | Some network -> network)
end

let get_node client =
  let message =
    "Dal.get_node: Internal error: The client should have been initialised \
     with a local node"
  in
  match Client.get_mode client with
  | Client (endpoint, _media_type) -> (
      match endpoint with
      | Some (Node node) -> node
      | _ -> Test.fail "%s" message)
  | _ -> Test.fail "%s" message

module Faucet = struct
  let faucet_url network =
    Format.sprintf "https://faucet.%s.teztnets.xyz/" (Network.name network)

  let get_money network pkh =
    Log.info "Please fund the following address via a faucet: %s@." pkh ;
    Log.info "Faucet: %s@." (faucet_url network) ;
    Log.info "Press enter once it is done." ;
    ignore (input_line stdin)

  let rec wait_for_balance client pkh target_balance =
    let node = get_node client in
    (* Could be racy but in practice should be ok, at worst we
       should wait one more block or do a useless check. *)
    let level = Node.get_level node in
    let* _ = Node.wait_for_level node (level + 1) in
    let* balance =
      RPC.(Client.call client (get_chain_block_context_delegate_balance pkh))
    in
    if balance < target_balance then (
      Log.info
        "Delegate current balance: %f. Expect at least: %f"
        (Tez.to_float balance)
        (Tez.to_float target_balance) ;
      wait_for_balance client pkh target_balance)
    else Lwt.return_unit
end

module Wallet = struct
  let default_wallet network =
    Format.sprintf
      "%s/%s-wallet"
      (Filename.get_temp_dir_name ())
      (Network.name network)

  let wallet = Cli.get ~default:None (fun _ -> Some (Some ())) "wallet"

  let check_wallet ?on_error client aliases =
    let* result =
      Lwt_list.fold_left_s
        (fun result alias ->
          match result with
          | Error alias -> Lwt.return_error alias
          | Ok l -> (
              let process = Client.spawn_show_address ~alias client in
              let* status = Process.wait process in
              match status with
              | WEXITED n when n = 0 ->
                  let* client_output = Process.check_and_read_stdout process in
                  Lwt.return
                    (Ok (Account.parse_client_output ~alias ~client_output :: l))
              | WEXITED _ | WSIGNALED _ | WSTOPPED _ -> Lwt.return_error alias))
        (Ok [])
        aliases
    in
    match result with
    | Ok keys -> Lwt.return keys
    | Error alias -> (
        match on_error with
        | None ->
            let message =
              Format.sprintf
                "Wallet.check_wallet: Alias %s where no found in the given \
                 wallet. Wallet path: %s"
                alias
                (Client.base_dir client)
            in
            Test.fail "%s" message
        | Some f -> f alias)

  let reveal client keys =
    Log.info "Checking revelations of wallet addresses." ;
    Lwt_list.iter_s
      (fun account ->
        let*? process =
          Client.reveal ~src:account.Account.public_key_hash client
        in
        let* status = Process.wait process in
        match status with
        | WEXITED n when n = 0 ->
            Log.info "Revealing address %s." account.alias ;
            Lwt.return_unit
        | WEXITED _ | WSIGNALED _ | WSTOPPED _ ->
            Log.info "Address %s is already revealed." account.alias ;
            Lwt.return_unit)
      keys

  let initialise_wallet network client aliases =
    let default_wallet = default_wallet network in
    (* Remove directory in case a wallet already exists but is not valid. *)
    let* () = Process.run "rm" ["-rf"; default_wallet] in
    let* () = Process.run "mkdir" [default_wallet] in
    let* keys =
      Lwt_list.map_s
        (fun alias ->
          let* key = Client.gen_and_show_keys ~alias client in
          let () = Faucet.get_money network key.public_key_hash in
          Lwt.return key)
        aliases
    in
    let* () =
      Lwt_list.iter_s
        (fun key ->
          Faucet.wait_for_balance
            client
            key.Account.public_key_hash
            (Tez.of_int 10))
        keys
    in
    Lwt.return keys

  let load_wallet network client aliases =
    let has_failed = ref None in
    let on_error alias =
      has_failed := Some alias ;
      Lwt.return []
    in
    let* keys = check_wallet ~on_error client aliases in
    match !has_failed with
    | None ->
        Log.info "Existing wallet found." ;
        let* () = reveal client keys in
        Lwt.return keys
    | Some _alias ->
        Log.info "No valid wallet found. A new one will be created" ;
        let* keys = initialise_wallet network client aliases in
        let* () = reveal client keys in
        Lwt.return keys
end

let dailynet () =
  Test.register
    ~__FILE__
    ~title:"Produce slots on dailynet"
    ~tags:["dal"; "dailynet"]
  @@ fun () ->
  let load = Cli.get ~default:None (fun _ -> Some (Some ())) "load" in
  let save = Cli.get ~default:None (fun _ -> Some (Some ())) "save" in
  let node = Node.create [] in
  let tezt_data_dir = Node.data_dir node in
  let network_name = Network.name `Dailynet in
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
  let client =
    Client.create
      ~base_dir:(Wallet.default_wallet `Dailynet)
      ~endpoint:(Node node)
      ()
  in
  let indices = range 0 20 in
  let aliases =
    List.map (fun i -> "slot-producer-" ^ string_of_int i) indices
  in
  let* keys = Wallet.load_wallet `Dailynet client aliases in
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
  let dal_node = Dal_node.create ~node ~client () in
  let bootstrap_peer =
    (* There is a parsing issue so we can't use this. *)
    Format.sprintf "dal.%s.teztnets.xyz:11732" network_name
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
  let publish_slot index =
    let slot =
      String.init 30 (fun _i ->
          (* let x = (i + index) mod 26 in *)
          let x = Random.int 26 in
          Char.code 'a' + x |> Char.chr)
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
    let* _ =
      Operation.Manager.(
        inject
          [
            make ~source:(List.nth keys index)
            @@ dal_publish_slot_header ~index ~commitment:commitment_hash ~proof;
          ]
          client)
    in
    let* () = Lwt_unix.sleep 60. in
    return ()
  in
  let* () =
    Lwt_list.iter_p (fun i -> repeat 100 (fun () -> publish_slot i)) indices
  in
  let* _ = Lwt_unix.sleep 1000. in
  return ()

let register () = dailynet ()
