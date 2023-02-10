(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Tezt
open Tezt.Base
open Tezt_tezos

let download ?runner url filename =
  let open Runnable.Syntax in
  Log.info "Download %s" url ;
  let path = Tezt.Temp.file filename in
  let*! _ = RPC.Curl.get_raw ?runner ~args:["--output"; path] url in
  Log.info "%s downloaded" url ;
  Lwt.return path

let rec wait_for_funded_key node client expected_amount key =
  let* balance = Client.get_balance_for ~account:key.Account.alias client in
  if balance < expected_amount then (
    Log.info
      "Key %s is under funded (got %d, expected at least %d)"
      key.public_key_hash
      Tez.(to_mutez balance)
      Tez.(to_mutez expected_amount) ;
    let* _ = Node.wait_for_level node (Node.get_level node + 1) in
    wait_for_funded_key node client expected_amount key)
  else unit

let setup_octez_node ?runner snapshot =
  let l1_node_args =
    Node.[Expected_pow 26; Synchronisation_threshold 1; Network Testnet.network]
  in
  let node = Node.create ?runner l1_node_args in
  let* () = Node.config_init node [] in
  Log.info "Import snapshot" ;
  let* () = Node.snapshot_import node snapshot in
  Log.info "Snapshot imported" ;
  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in
  let client = Client.create ~endpoint:(Node node) () in
  Log.info "Wait for node to be bootstrapped" ;
  let* () = Client.bootstrapped client in
  Log.info "Node bootstrapped" ;
  return (client, node)

let deploy_runnable ~(runner : Runner.t) ?(r = false) local_file dst =
  let identity =
    Option.fold ~none:[] ~some:(fun i -> ["-i"; i]) runner.ssh_id
  in
  let recursive = if r then ["-r"] else [] in
  let port =
    Option.fold
      ~none:[]
      ~some:(fun p -> ["-P"; Format.sprintf "%d" p])
      runner.ssh_port
  in
  let dst =
    Format.(
      sprintf
        "%s%s:%s"
        (Option.fold ~none:"" ~some:(fun u -> sprintf "%s@" u) runner.ssh_user)
        runner.address
        dst)
  in
  let process =
    Process.spawn "scp" (identity @ recursive @ [local_file] @ port @ [dst])
  in
  Runnable.
    {
      value = process;
      run =
        (fun process ->
          let _ = Process.check process in
          Lwt.return ());
    }

let deploy ~runner ?r local_file dst =
  let open Runnable.Syntax in
  let*! () = deploy_runnable ~runner ?r local_file dst in
  Lwt.return ()
