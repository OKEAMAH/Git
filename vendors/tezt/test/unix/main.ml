(* This file will be linked with tests in test/common,
   which registers tests that can be run on all backends. *)

open Tezt
module _ = Test_process

(* Run tests with the unix backend. *)
let () = Test.run ()
