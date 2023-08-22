(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
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

(** This file contains all helper functions to
    activate or deactivate a dedicated profiler.
    So far, only the RPC profiler is declared and enabled,
    but one can simply add a new profiler with corresponding
    helper functions. *)

open Tezos_base.Profiler

type profiler_name =
  | Rpc_server
  | Mempool
  | Store
  | Chain_validator
  | Block_validator
  | Merge
  | P2p_reader
  | Requester

let profiler_name_to_string profiler_name =
  match profiler_name with
  | Rpc_server -> "rpc_server"
  | Mempool -> "mempool"
  | Store -> "store"
  | Chain_validator -> "chain_validator"
  | Block_validator -> "block_validator"
  | Merge -> "merge"
  | P2p_reader -> "p2p_reader"
  | Requester -> "requester"

let profiler_name_of_string s =
  match s with
  | "rpc_server" -> Rpc_server
  | "mempool" -> Mempool
  | "store" -> Store
  | "chain_validator" -> Chain_validator
  | "block_validator" -> Block_validator
  | "merge" -> Merge
  | "p2p_reader" -> P2p_reader
  | "requester" -> Requester
  | _ -> Stdlib.failwith ("No profiler with name: " ^ s)

let mempool_profiler = unplugged ()

let store_profiler = unplugged ()

let chain_validator_profiler = unplugged ()

let block_validator_profiler = unplugged ()

let merge_profiler = unplugged ()

let p2p_reader_profiler = unplugged ()

let requester_profiler = unplugged ()

let rpc_server_profiler = unplugged ()

let all_profilers =
  [
    (Rpc_server, rpc_server_profiler);
    (Mempool, mempool_profiler);
    (Store, store_profiler);
    (Chain_validator, chain_validator_profiler);
    (Block_validator, block_validator_profiler);
    (Merge, merge_profiler);
    (P2p_reader, p2p_reader_profiler);
    (Requester, requester_profiler);
  ]

let may_start_block =
  let last_block = ref None in
  fun b ->
    let sec () = Format.asprintf "block_validation(%a)" Block_hash.pp b in
    match !last_block with
    | None ->
        let s = sec () in
        record block_validator_profiler s ;
        last_block := Some b
    | Some b' when Block_hash.equal b' b -> ()
    | Some _ ->
        stop block_validator_profiler ;
        let s = sec () in
        record block_validator_profiler s ;
        last_block := Some b

let activate_all ~profiler_maker =
  List.iter (fun (name, p) -> plug p (profiler_maker ~name)) all_profilers

let deactivate_all () =
  List.iter (fun (_name, p) -> close_and_unplug_all p) all_profilers

let activate ~profiler_maker name =
  List.assoc ~equal:( = ) name all_profilers |> function
  | None ->
      Format.ksprintf
        invalid_arg
        "unknown '%s' profiler"
        (profiler_name_to_string name)
  | Some p -> plug p (profiler_maker ~name)

let deactivate name =
  List.assoc ~equal:( = ) name all_profilers |> function
  | None ->
      Format.ksprintf
        invalid_arg
        "unknown '%s' profiler"
        (profiler_name_to_string name)
  | Some p -> close_and_unplug_all p

let profiler_maker data_dir ~name max_lod profiler_driver =
  match fst profiler_driver with
  | Plain_text ->
      instance
        (snd profiler_driver)
        Filename.Infix.
          ( (data_dir // profiler_name_to_string name) ^ "_profiling.txt",
            max_lod )
  | Json ->
      instance
        (snd profiler_driver)
        Filename.Infix.
          ( (data_dir // profiler_name_to_string name) ^ "_profiling.json",
            max_lod )
