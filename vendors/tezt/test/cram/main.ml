(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021-2022 Nomadic Labs <contact@nomadic-labs.com>           *)
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

(* The following tests are not meant to be executed directly. They are
   tools used in cram scripts (see the [.t] files in this folder) to
   test the behavior of Tezt itself. *)

let test_success () =
  Test.register ~__FILE__ ~title:"Success" ~tags:["retry"; "success"]
  @@ fun () ->
  Log.info "Success test." ;
  unit

let test_fail_every_other_run () =
  let should_fail = ref true in
  Test.register
    ~__FILE__
    ~title:"Fail every other run test"
    ~tags:["retry"; "fail"; "flake"]
  @@ fun () ->
  if !should_fail then (
    should_fail := false ;
    Test.fail "Failing test on first try")
  else (
    should_fail := true ;
    Log.info "Works on second" ;
    unit)

let test_fail_always () =
  Test.register
    ~__FILE__
    ~title:"Failing test"
    ~tags:["retry"; "fail"; "always"]
  @@ fun () -> Test.fail "Always failing test"

(* Used to test selection of tests *)
let test_selection () =
  let files = ["a/b/c.ml"; "a/b/g.ml"; "a/c.ml"; "d.ml"; "e.ml"] in
  List.iter
    (fun file ->
      Test.register ~__FILE__:file ~title:file ~tags:["selection"] (fun () ->
          unit))
    files

let test_cli_get () =
  Test.register ~__FILE__ ~title:"Cli.get" ~tags:["cli"; "options"] @@ fun () ->
  let ucase s = Some (String.uppercase_ascii s) in
  let option_to_string to_string = function
    | None -> "None"
    | Some s -> sf "Some %s" (to_string s)
  in
  Log.info
    "str_ucase: %s"
    (option_to_string Fun.id (Cli.get_opt ucase "str_ucase")) ;
  Log.info "int: %s" (option_to_string string_of_int (Cli.get_int_opt "int")) ;
  Log.info
    "bool: %s"
    (option_to_string string_of_bool (Cli.get_bool_opt "bool")) ;
  Log.info
    "float: %s"
    (option_to_string string_of_float (Cli.get_float_opt "float")) ;
  unit

let () =
  test_success () ;
  test_fail_every_other_run () ;
  test_fail_always () ;
  test_selection () ;
  test_cli_get () ;
  Test.run ()
