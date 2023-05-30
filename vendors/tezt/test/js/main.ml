(* This file will be linked with tests in test/common,
   which registers tests that can be run on all backends. *)

(* Run tests with the unix backend. *)
let () = Tezt_js.Test.run ()
