(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2018-2021 Nomadic Labs. <contact@nomadic-labs.com>          *)
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

let reproduce_stream watcher =
  let stream, stopper = watcher in
  let shutdown () = Lwt_watcher.shutdown stopper in
  let next () = Lwt_stream.get stream in
  Tezos_rpc.Answer.return_stream {next; shutdown}

let reproduce_head_stream get_last_head watcher =
  let stream, stopper = watcher in
  let shutdown () = Lwt_watcher.shutdown stopper in
  let first_call = ref true in
  let next () =
    if !first_call then (
      first_call := false ;
      Lwt.return @@ get_last_head ())
    else Lwt_stream.get stream
  in
  Tezos_rpc.Answer.return_stream {next; shutdown}

let monitor_dir dir (store : Store.t option ref) get_last_head
    (head_watcher : (Block_hash.t * Block_header.t) Lwt_watcher.input)
    block_watcher =
  let dir = ref dir in
  let gen_register1 s f =
    dir := Tezos_rpc.Directory.gen_register !dir s (fun ((), a) p q -> f a p q)
  in
  let gen_register0 s f =
    dir := Tezos_rpc.Directory.gen_register !dir s (fun () p q -> f p q)
  in
  gen_register0
    Tezos_shell_services.Monitor_services.S.applied_blocks
    (fun _q () ->
      let block_stream = Lwt_watcher.create_stream block_watcher in
      reproduce_stream block_stream) ;
  gen_register1
    Tezos_shell_services.Monitor_services.S.heads
    (fun _chain _q () ->
      let open Lwt_syntax in
      let head_watcher = Lwt_watcher.create_stream head_watcher in
      let* _store =
        match !store with
        | Some store -> return store
        | None -> Lwt.fail Not_found
      in
      reproduce_head_stream get_last_head head_watcher) ;
  !dir

let build_rpc_directory get_last_head node_version config dynamic_store
    ~(head_watcher : (Block_hash.t * Block_header.t) Lwt_watcher.input)
    ~applied_blocks_watcher =
  let static_dir = Tezos_shell.Version_directory.rpc_directory node_version in
  let static_dir =
    Tezos_shell.Config_directory.build_rpc_directory_for_rpc_process
      ~user_activated_upgrades:
        config.Config_file.blockchain_network.user_activated_upgrades
      ~user_activated_protocol_overrides:
        config.blockchain_network.user_activated_protocol_overrides
      ~dal_config:config.blockchain_network.dal_config
      static_dir
  in
  let static_dir =
    Tezos_rpc.Directory.register0 static_dir Services.config (fun () () ->
        Lwt.return_ok config)
  in
  let static_dir =
    monitor_dir
      static_dir
      dynamic_store
      get_last_head
      head_watcher
      applied_blocks_watcher
  in
  Tezos_rpc.Directory.register_dynamic_directory
    static_dir
    (Tezos_rpc.Path.subst1 Tezos_shell_services.Chain_services.path)
    (fun ((), chain) ->
      let dir = Tezos_shell.Chain_directory.rpc_directory_generic () in
      let dir =
        Tezos_rpc.Directory.map
          (fun ((), _chain) ->
            let store = !dynamic_store in
            match store with
            | None -> Lwt.fail Not_found
            | Some store ->
                Tezos_shell.Chain_directory.get_chain_store_exn store chain)
          dir
      in
      Lwt.return dir)
