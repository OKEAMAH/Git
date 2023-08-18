(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)

let nonce_profiler = Profiler.unplugged ()

let operation_worker_profiler = Profiler.unplugged ()

let node_rpc_profiler = Profiler.unplugged ()

let profiler = Profiler.unplugged ()

type profiler_name = Baker | Nonce | Node_rpc | Op_worker

let profiler_name_to_string profiler_name =
  match profiler_name with
  | Baker -> "baker"
  | Nonce -> "nonce"
  | Node_rpc -> "node_rpc"
  | Op_worker -> "op_worker"

let profiler_name_of_string s =
  match s with
  | "baker" -> Baker
  | "nonce" -> Nonce
  | "node_rpc" -> Node_rpc
  | "op_worker" -> Op_worker
  | _ -> Stdlib.failwith ("No profiler with name: " ^ s)

let profiler_maker data_dir ~name max_lod profiler_driver file_format =
  match file_format with
  | Profiler.Plain_text ->
      Profiler.instance
        profiler_driver
        Filename.Infix.
          ( (data_dir // profiler_name_to_string name) ^ "_profiling.txt",
            max_lod )
  | Profiler.Json ->
      Profiler.instance
        profiler_driver
        Filename.Infix.
          ( (data_dir // profiler_name_to_string name) ^ "_profiling.json",
            max_lod )

let init profiler_maker =
  let open Profiler in
  let baker_instance = profiler_maker ~name:Baker in
  plug profiler baker_instance ;
  plug Tezos_protocol_environment.Environment_profiler.profiler baker_instance ;
  plug nonce_profiler (profiler_maker ~name:Nonce) ;
  plug node_rpc_profiler (profiler_maker ~name:Node_rpc) ;
  plug operation_worker_profiler (profiler_maker ~name:Op_worker)

open Profiler

include (val wrap profiler)
