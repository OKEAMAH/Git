(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** Testing
    _______

    Component: Store
    Invocation: dune exec src/lib_store/unix/test/main.exe --file test.ml
    Subject: Store tests ( snapshots, reconstruct, history_mode_switch )
*)

module Tezt_sink : Internal_event.SINK = struct
  type t = unit

  let uri_scheme = "tezt-log"

  let configure _ = Lwt_result_syntax.return_unit

  let should_handle ?section:_ (_ : t) _m = true

  let handle (type a) (_ : t) m ?section ev =
    let module M = (val m : Internal_event.EVENT_DEFINITION with type t = a) in
    ignore section ;
    let level =
      match M.level with
      | Internal_event.Debug -> Cli.Debug
      | Internal_event.Info | Internal_event.Notice -> Cli.Info
      | Internal_event.Warning -> Cli.Warn
      | Internal_event.Fatal | Internal_event.Error -> Cli.Error
    in
    Log.log ~level "%a" (M.pp ~all_fields:true ~block:true) ev ;
    Lwt_result_syntax.return_unit


  let close (_ : t) : unit tzresult Lwt.t = Lwt_result_syntax.return_unit
end

let tezt_sink : Tezt_sink.t Internal_event.sink_definition =
  (module Tezt_sink : Internal_event.SINK with type t = Tezt_sink.t)

let activate () =
  Internal_event.All_sinks.register tezt_sink ;
  let* r =
    Internal_event.All_sinks.activate (Uri.of_string "tezt-log://")
  in
  match r with
  | Ok () -> unit
  | Error errors ->
    Tezt.Test.fail
      "Could not initialize tezt sink:\n   %a\n"
      pp_print_trace
      errors

let () =
  let open Lwt_syntax in
  Lwt_main.run
    (* we init the internal event here once and for all modules. log level is set as per Tezt's log level. *)
    (let* () = activate () in
     Alcotest_lwt.run
       ~__FILE__
       "tezos-store"
       [
         Test_snapshots.tests `Quick;
         Test_reconstruct.tests `Quick;
         Test_history_mode_switch.tests `Quick;
       ])
