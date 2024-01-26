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

(* Testing
   -------
   Component:    Base, Unix
   Invocation:   dune exec src/lib_base/unix/test/main.exe
   Subject:      Check syslog primitives
*)

(* open Tezt *)
open Tezt_core.Base

(* open Tezos_base.TzPervasives *)
open Profiler

let print_file_content file_path =
  let rec read_and_print chan =
    try
      let line = input_line chan in
      print_endline line ;
      read_and_print chan
    with
    | End_of_file -> close_in chan
    | ex ->
        close_in chan ;
        raise ex
  in
  try
    let chan = open_in file_path in
    read_and_print chan
  with Sys_error msg -> Printf.eprintf "Error: %s\n" msg

let sleep10ms profiler =
  Profiler.record profiler "sleep10ms" ;
  print_endline "---sleep---" ;
  Unix.sleepf 0.01 ;
  Profiler.stop profiler

let foo profiler =
  Profiler.record profiler "foo" ;
  sleep10ms profiler ;
  sleep10ms profiler ;
  Profiler.stop profiler

let bar profiler =
  Profiler.record profiler "bar" ;
  sleep10ms profiler ;
  foo profiler ;
  foo profiler ;
  Profiler.stop profiler

let () =
  Tezt_core.Test.register
    ~__FILE__
    ~title:"Simple profiler: invoke"
    ~tags:["unix"; "profiler"]
  @@ fun () ->
  let profiler = unplugged () in
  let test_profiler_instance =
    Profiler.instance
      Tezos_base_unix.Simple_profiler.auto_write_to_txt_file
      ("/tmp/test_simple_profiling.txt", Profiler.Detailed)
  in
  plug profiler test_profiler_instance ;
  bar profiler ;

  print_endline "Profiling result\n================" ;
  print_file_content "/tmp/test_simple_profiling.txt" ;
  unit
