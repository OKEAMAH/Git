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
let build_rpc_directory data_dir =
  let open Lwt_result_syntax in
  let register endpoint f directory =
    Tezos_rpc.Directory.register directory endpoint f
  in
  let open Profiler_services.S in
  Tezos_rpc.Directory.empty
  |> register activate_all (fun () lod () ->
         Shell_profiling.activate_all
           ~profiler_maker:(profiler_maker data_dir lod) ;
         return_unit)
  |> register deactivate_all (fun () () () ->
         Shell_profiling.deactivate_all () ;
         return_unit)
  |> register activate (fun ((), name) lod () ->
         Shell_profiling.activate
           ~profiler_maker:(profiler_maker data_dir lod)
           name ;
         return_unit)
  |> register deactivate (fun ((), name) () () ->
         Shell_profiling.deactivate name ;
         return_unit)

let profiler_maker data_dir ~name max_lod profiler_driver =
  match Tezos_base.Profiler.file_format profiler_driver with
  | Some Tezos_base.Profiler.Plain_text ->
      Tezos_base.Profiler.instance
        profiler_driver
        Filename.Infix.((data_dir // name) ^ "_profiling.txt", max_lod)
  | Some Tezos_base.Profiler.Json ->
      Tezos_base.Profiler.instance
        profiler_driver
        Filename.Infix.((data_dir // name) ^ "_profiling.json", max_lod)
  | _ -> Stdlib.failwith "impossible"
