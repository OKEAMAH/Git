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
   Component:    Node's external validator
   Invocation:   dune exec tezt/tests/main.exe -- --file
                 external_validation.ml
   Subject:      Tests the resilience of the external validator
                 failures
*)

let test_restart () =
  Test.register ~__FILE__ ~title:"restart" ~tags:["restart"] @@ fun () ->
  let loop n f =
    let rec loop cpt =
      if cpt = n then Lwt.return_unit
      else
        let () = Log.info "Run %d@." cpt in
        let* () = f () in
        loop (cpt + 1)
    in
    loop 0
  in
  let* node = Node.init [] in
  let f () =
    let* () = Node.wait_for_ready node in
    let* () = Node.terminate node in
    let* () = Node.run node [] in
    Lwt.return_unit
  in
  let* () = loop 1_000 f in
  unit

let register () = test_restart ()
