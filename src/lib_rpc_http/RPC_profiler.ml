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

open Profiler

let rpc_client_profiler = unplugged ()

type profiler_name = Rpc_client

let profiler_name_to_string profiler_name =
  match profiler_name with Rpc_client -> "rpc_client"

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
  plug rpc_client_profiler (profiler_maker ~name:Rpc_client)

include (val wrap rpc_client_profiler)
